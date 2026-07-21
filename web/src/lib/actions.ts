'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';
import type { SavingsType } from '@/lib/types';

export async function activateMember(memberId: string) {
  const supabase = await createClient();
  const { error } = await supabase
    .from('members')
    .update({ status: 'active', tanggal_gabung: new Date().toISOString().slice(0, 10) })
    .eq('id', memberId);
  if (error) return { error: error.message };
  revalidatePath('/anggota');
  return { ok: true };
}

export async function rejectMember(memberId: string) {
  const supabase = await createClient();
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
