import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

export interface PaymentRow {
  id: string;
  member_id: string;
  purpose: string;
  ref_id: string;
  status: string;
  nominal: number;
}

export async function applyPaymentStatus(
  admin: SupabaseClient,
  payment: PaymentRow,
  newStatus: 'pending' | 'paid' | 'failed' | 'expired',
  raw: Record<string, unknown>,
): Promise<void> {
  const wasPaid = payment.status === 'paid';

  await admin
    .from('payments')
    .update({ status: newStatus, raw_payload: raw })
    .eq('id', payment.id);

  if (newStatus !== 'paid' || wasPaid) return;

  if (payment.purpose === 'simpanan') {
    await admin.from('savings_transactions').insert({
      account_id: payment.ref_id,
      member_id: payment.member_id,
      jenis: 'setor',
      nominal: payment.nominal,
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
