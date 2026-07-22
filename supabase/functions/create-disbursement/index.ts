import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { getDisbursementProvider } from '../_shared/disbursement_provider.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { loan_id } = await req.json();
    if (!loan_id) {
      return jsonResponse({ error: 'Parameter tidak lengkap' }, 400);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;

    // Identifikasi staff dari JWT
    const authHeader = req.headers.get('Authorization') ?? '';
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
    } = await userClient.auth.getUser();
    if (!user) return jsonResponse({ error: 'Tidak terautentikasi' }, 401);

    const admin = createClient(supabaseUrl, serviceKey);

    const { data: staff } = await admin
      .from('staff_roles')
      .select('role')
      .eq('user_id', user.id)
      .eq('role', 'pengurus')
      .maybeSingle();
    if (!staff) {
      return jsonResponse({ error: 'Hanya pengurus yang boleh mencairkan pinjaman' }, 403);
    }

    const { data: loan } = await admin
      .from('loans')
      .select(
        'id, member_id, pokok, status, members(bank_code, account_number, account_holder_name)',
      )
      .eq('id', loan_id)
      .maybeSingle();
    if (!loan) return jsonResponse({ error: 'Pinjaman tidak ditemukan' }, 404);
    if (loan.status !== 'approved') {
      return jsonResponse({ error: 'Pinjaman belum disetujui / sudah dicairkan' }, 400);
    }

    const member = loan.members as {
      bank_code: string | null;
      account_number: string | null;
      account_holder_name: string | null;
    } | null;
    if (!member?.bank_code || !member?.account_number || !member?.account_holder_name) {
      return jsonResponse(
        { error: 'Rekening bank anggota belum lengkap. Lengkapi di halaman Anggota.' },
        400,
      );
    }

    const { data: existing } = await admin
      .from('disbursements')
      .select('id, status')
      .eq('loan_id', loan_id)
      .in('status', ['pending', 'processing', 'completed'])
      .maybeSingle();
    if (existing) {
      return jsonResponse({ error: 'Pencairan untuk pinjaman ini sudah berjalan / selesai' }, 400);
    }

    const externalId = `KSP-DSB-${crypto.randomUUID()}`;

    const { error: insErr } = await admin.from('disbursements').insert({
      loan_id: loan.id,
      member_id: loan.member_id,
      external_id: externalId,
      amount: loan.pokok,
      bank_code: member.bank_code,
      account_number: member.account_number,
      account_holder_name: member.account_holder_name,
      status: 'pending',
      created_by: user.id,
    });
    if (insErr) return jsonResponse({ error: insErr.message }, 500);

    // Buat transaksi disbursement di provider
    const provider = getDisbursementProvider();
    const tx = await provider.createDisbursement({
      externalId,
      amount: Number(loan.pokok),
      bankCode: member.bank_code,
      accountNumber: member.account_number,
      accountHolderName: member.account_holder_name,
    });

    await admin
      .from('disbursements')
      .update({
        provider_ref: tx.providerRef,
        status: tx.status === 'completed' ? 'completed' : 'processing',
      })
      .eq('external_id', externalId);

    if (tx.status === 'completed') {
      await admin.from('loans').update({ status: 'active' }).eq('id', loan.id);
    }

    return jsonResponse({ external_id: externalId, status: tx.status });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
