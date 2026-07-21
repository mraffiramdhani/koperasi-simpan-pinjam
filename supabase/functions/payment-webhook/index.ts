import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { getPaymentProvider } from '../_shared/payment_provider.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const provider = getPaymentProvider();
    const result = await provider.parseWebhook(payload);

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: payment } = await admin
      .from('payments')
      .select('id, member_id, purpose, ref_id, status')
      .eq('order_id', result.orderId)
      .maybeSingle();

    if (!payment) return jsonResponse({ error: 'Payment tidak ditemukan' }, 404);

    const wasPaid = payment.status === 'paid';

    await admin
      .from('payments')
      .update({ status: result.status, raw_payload: result.raw })
      .eq('id', payment.id);

    // Terapkan efek hanya sekali saat transisi menjadi paid
    if (result.status === 'paid' && !wasPaid) {
      if (payment.purpose === 'simpanan') {
        await admin.from('savings_transactions').insert({
          account_id: payment.ref_id,
          member_id: payment.member_id,
          jenis: 'setor',
          nominal: payload.gross_amount,
          metode: 'gateway',
          payment_id: payment.id,
          keterangan: 'Setoran via payment gateway',
        });
      } else if (payment.purpose === 'angsuran') {
        await admin
          .from('loan_installments')
          .update({
            status: 'lunas',
            paid_at: new Date().toISOString(),
            payment_id: payment.id,
          })
          .eq('id', payment.ref_id)
          .neq('status', 'lunas');

        // Cek apakah seluruh angsuran sudah lunas
        const { data: inst } = await admin
          .from('loan_installments')
          .select('loan_id')
          .eq('id', payment.ref_id)
          .maybeSingle();

        if (inst?.loan_id) {
          const { count } = await admin
            .from('loan_installments')
            .select('id', { count: 'exact', head: true })
            .eq('loan_id', inst.loan_id)
            .neq('status', 'lunas');
          if ((count ?? 0) === 0) {
            await admin.from('loans').update({ status: 'lunas' }).eq('id', inst.loan_id);
          }
        }
      }

      await admin.from('notifications').insert({
        member_id: payment.member_id,
        judul: 'Pembayaran Berhasil',
        isi: `Pembayaran ${payment.purpose} Anda telah diterima.`,
        tipe: 'pembayaran',
      });
    }

    return jsonResponse({ ok: true });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 400);
  }
});
