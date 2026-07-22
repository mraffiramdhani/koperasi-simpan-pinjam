import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { applyPaymentStatus } from '../_shared/payment_effects.ts';
import { getPaymentProvider } from '../_shared/payment_provider.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const provider = getPaymentProvider();
    const result = await provider.parseWebhook(payload, req.headers);

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: payment } = await admin
      .from('payments')
      .select('id, member_id, purpose, ref_id, status, nominal')
      .eq('order_id', result.orderId)
      .maybeSingle();

    if (!payment) return jsonResponse({ error: 'Payment tidak ditemukan' }, 404);

    await applyPaymentStatus(admin, payment, result.status, result.raw);

    return jsonResponse({ ok: true });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 400);
  }
});
