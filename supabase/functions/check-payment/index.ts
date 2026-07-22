import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { applyPaymentStatus } from '../_shared/payment_effects.ts';
import { getPaymentProvider } from '../_shared/payment_provider.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { order_id, simulate } = await req.json();
    if (!order_id) return jsonResponse({ error: 'order_id wajib diisi' }, 400);

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;

    const authHeader = req.headers.get('Authorization') ?? '';
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
    } = await userClient.auth.getUser();
    if (!user) return jsonResponse({ error: 'Tidak terautentikasi' }, 401);

    const admin = createClient(supabaseUrl, serviceKey);

    const { data: member } = await admin
      .from('members')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();
    if (!member) return jsonResponse({ error: 'Anggota tidak ditemukan' }, 404);

    const { data: payment } = await admin
      .from('payments')
      .select('id, member_id, purpose, ref_id, status, nominal, snap_token, order_id')
      .eq('order_id', order_id)
      .eq('member_id', member.id)
      .maybeSingle();

    if (!payment) return jsonResponse({ error: 'Payment tidak ditemukan' }, 404);

    if (payment.status !== 'pending') {
      return jsonResponse({ status: payment.status });
    }

    if (!payment.snap_token) {
      return jsonResponse({ status: 'pending' });
    }

    const provider = getPaymentProvider();
    const result = simulate === true
      ? await provider.simulateQrPayment(payment.order_id, Number(payment.nominal))
      : await provider.getInvoiceStatus(payment.snap_token);

    if (result.orderId && result.orderId !== payment.order_id) {
      return jsonResponse({ error: 'Invoice tidak cocok dengan order' }, 400);
    }

    await applyPaymentStatus(admin, payment, result.status, result.raw);

    return jsonResponse({
      status: result.status,
      test_mode: provider.isTestMode(),
    });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 400);
  }
});
