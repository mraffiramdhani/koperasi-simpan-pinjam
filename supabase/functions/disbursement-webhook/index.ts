import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { getDisbursementProvider } from '../_shared/disbursement_provider.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const provider = getDisbursementProvider();
    const result = await provider.parseWebhook(payload, req.headers);

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: disbursement } = await admin
      .from('disbursements')
      .select('id, loan_id, member_id, status, amount')
      .eq('external_id', result.externalId)
      .maybeSingle();

    if (!disbursement) {
      return jsonResponse({ error: 'Disbursement tidak ditemukan' }, 404);
    }

    const wasCompleted = disbursement.status === 'completed';

    await admin
      .from('disbursements')
      .update({ status: result.status, raw_payload: result.raw })
      .eq('id', disbursement.id);

    if (result.status === 'completed' && !wasCompleted) {
      await admin
        .from('loans')
        .update({ status: 'active' })
        .eq('id', disbursement.loan_id)
        .eq('status', 'approved');

      await admin.from('notifications').insert({
        member_id: disbursement.member_id,
        judul: 'Pencairan Pinjaman Berhasil',
        isi: 'Dana pinjaman Anda telah dicairkan ke rekening yang terdaftar.',
        tipe: 'pinjaman',
      });
    } else if (result.status === 'failed') {
      // Loan tetap 'approved' agar pengurus bisa mencoba mencairkan ulang.
      await admin.from('notifications').insert({
        member_id: disbursement.member_id,
        judul: 'Pencairan Pinjaman Gagal',
        isi: 'Pencairan dana pinjaman Anda gagal. Koperasi akan mencoba ulang.',
        tipe: 'pinjaman',
      });
    }

    return jsonResponse({ ok: true });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 400);
  }
});
