'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';
import type { SavingsType } from '@/lib/types';

async function requirePengurus() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { supabase, error: 'Tidak terautentikasi' as string };
  const { data: staff } = await supabase
    .from('staff_roles')
    .select('role')
    .eq('user_id', user.id)
    .maybeSingle();
  if (staff?.role !== 'pengurus') {
    return { supabase, error: 'Hanya pengurus yang boleh melakukan aksi ini' as string };
  }
  return { supabase, error: null };
}

export async function activateMember(memberId: string) {
  const { supabase, error: authErr } = await requirePengurus();
  if (authErr) return { error: authErr };
  const { error } = await supabase
    .from('members')
    .update({ status: 'active', tanggal_gabung: new Date().toISOString().slice(0, 10) })
    .eq('id', memberId);
  if (error) return { error: error.message };
  revalidatePath('/anggota');
  return { ok: true };
}

export async function rejectMember(memberId: string) {
  const { supabase, error: authErr } = await requirePengurus();
  if (authErr) return { error: authErr };
  const { error } = await supabase
    .from('members')
    .update({ status: 'rejected' })
    .eq('id', memberId);
  if (error) return { error: error.message };
  revalidatePath('/anggota');
  return { ok: true };
}

export async function approveLoan(loanId: string) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('rpc_approve_pinjaman', { p_loan_id: loanId });
  if (error) return { error: error.message };
  revalidatePath('/pinjaman');
  return { ok: true };
}

export async function rejectLoan(loanId: string, alasan?: string) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('rpc_reject_pinjaman', {
    p_loan_id: loanId,
    p_alasan: alasan ?? null,
  });
  if (error) return { error: error.message };
  revalidatePath('/pinjaman');
  return { ok: true };
}

export async function cairkanPinjaman(loanId: string) {
  const supabase = await createClient();
  const { data, error } = await supabase.functions.invoke('create-disbursement', {
    body: { loan_id: loanId },
  });
  if (error) {
    let message = error.message;
    try {
      const body = await (error as { context?: Response }).context?.json();
      if (body?.error) message = body.error;
    } catch {
      // biarkan pesan generik jika response tidak bisa di-parse
    }
    return { error: message };
  }
  if (data?.error) return { error: data.error as string };
  revalidatePath('/pinjaman');
  return { ok: true };
}

export async function updateRekening(
  memberId: string,
  bankCode: string,
  accountNumber: string,
  accountHolderName: string,
) {
  if (!bankCode || !accountNumber || !accountHolderName) {
    return { error: 'Semua field rekening wajib diisi' };
  }
  const supabase = await createClient();
  const { error } = await supabase
    .from('members')
    .update({
      bank_code: bankCode,
      account_number: accountNumber,
      account_holder_name: accountHolderName,
    })
    .eq('id', memberId);
  if (error) return { error: error.message };
  revalidatePath('/anggota');
  revalidatePath('/pinjaman');
  return { ok: true };
}

export async function setorTunai(
  memberId: string,
  tipe: SavingsType,
  nominal: number,
  keterangan?: string,
) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('rpc_setor_tunai', {
    p_member_id: memberId,
    p_tipe: tipe,
    p_nominal: nominal,
    p_keterangan: keterangan ?? null,
  });
  if (error) return { error: error.message };
  revalidatePath('/teller');
  return { ok: true };
}

export async function tarikTunai(
  memberId: string,
  tipe: SavingsType,
  nominal: number,
  keterangan?: string,
) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('rpc_tarik_tunai', {
    p_member_id: memberId,
    p_tipe: tipe,
    p_nominal: nominal,
    p_keterangan: keterangan ?? null,
  });
  if (error) return { error: error.message };
  revalidatePath('/teller');
  return { ok: true };
}

export async function bayarAngsuranTunai(installmentId: string) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('rpc_bayar_angsuran_tunai', {
    p_installment_id: installmentId,
  });
  if (error) return { error: error.message };
  revalidatePath('/pinjaman');
  return { ok: true };
}
