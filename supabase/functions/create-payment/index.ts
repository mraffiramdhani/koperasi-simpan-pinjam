import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { getPaymentProvider } from '../_shared/payment_provider.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { purpose, ref_id, nominal } = await req.json();
    if (!['simpanan', 'angsuran'].includes(purpose) || !ref_id || !nominal) {
      return jsonResponse({ error: 'Parameter tidak lengkap' }, 400);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;

    // Identifikasi user dari JWT
    const authHeader = req.headers.get('Authorization') ?? '';
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
    } = await userClient.auth.getUser();
    if (!user) return jsonResponse({ error: 'Tidak terautentikasi' }, 401);

    // Operasi DB dengan service role (bypass RLS, aman di server)
    const admin = createClient(supabaseUrl, serviceKey);

    const { data: member } = await admin
      .from('members')
      .select('id, nama')
      .eq('user_id', user.id)
      .maybeSingle();
    if (!member) return jsonResponse({ error: 'Anggota tidak ditemukan' }, 404);

    // Validasi kepemilikan ref_id
    if (purpose === 'simpanan') {
      const { data: acc } = await admin
        .from('savings_accounts')
        .select('id')
        .eq('id', ref_id)
        .eq('member_id', member.id)
        .maybeSingle();
      if (!acc) return jsonResponse({ error: 'Rekening tidak valid' }, 400);
    } else {
      const { data: inst } = await admin
        .from('loan_installments')
        .select('id, loans!inner(member_id)')
        .eq('id', ref_id)
        .maybeSingle();
      const ownerId = (inst?.loans as { member_id: string } | null)?.member_id;
      if (!inst || ownerId !== member.id) {
        return jsonResponse({ error: 'Angsuran tidak valid' }, 400);
      }
    }

    const orderId = `KSP-${purpose}-${crypto.randomUUID()}`;

    const { error: insErr } = await admin.from('payments').insert({
      member_id: member.id,
      purpose,
      ref_id,
      order_id: orderId,
      nominal,
      status: 'pending',
    });
    if (insErr) return jsonResponse({ error: insErr.message }, 500);

    // Buat transaksi di payment gateway
    const provider = getPaymentProvider();
    const tx = await provider.createTransaction({
      orderId,
      amount: Number(nominal),
      customerName: member.nama,
      customerEmail: user.email ?? undefined,
    });

    await admin
      .from('payments')
      .update({ snap_token: tx.token, snap_redirect_url: tx.redirectUrl })
      .eq('order_id', orderId);

    return jsonResponse({ order_id: orderId, redirect_url: tx.redirectUrl });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
