export type MemberStatus = 'pending' | 'active' | 'inactive' | 'rejected';
export type SavingsType = 'pokok' | 'wajib' | 'sukarela';
export type LoanStatus = 'pengajuan' | 'approved' | 'rejected' | 'active' | 'lunas';
export type InstallmentStatus = 'belum' | 'lunas' | 'telat';
export type StaffRole = 'teller' | 'pengurus';
export type DisbursementStatus = 'pending' | 'processing' | 'completed' | 'failed';

export interface Member {
  id: string;
  no_anggota: string | null;
  user_id: string | null;
  nama: string;
  nik: string | null;
  alamat: string | null;
  phone: string | null;
  foto_ktp_path: string | null;
  status: MemberStatus;
  tanggal_gabung: string | null;
  bank_code: string | null;
  account_number: string | null;
  account_holder_name: string | null;
  created_at: string;
}

export interface SavingsAccount {
  id: string;
  member_id: string;
  tipe: SavingsType;
  saldo: number;
  created_at: string;
}

export interface Loan {
  id: string;
  member_id: string;
  pokok: number;
  tenor: number;
  jasa_persen: number;
  tujuan: string | null;
  status: LoanStatus;
  tanggal_pengajuan: string;
  approved_at: string | null;
}

export interface LoanInstallment {
  id: string;
  loan_id: string;
  angsuran_ke: number;
  jatuh_tempo: string;
  nominal_pokok: number;
  nominal_jasa: number;
  total: number;
  status: InstallmentStatus;
  paid_at: string | null;
}

export interface DashboardSummary {
  total_anggota: number;
  anggota_pending: number;
  total_simpanan: number;
  simpanan_per_tipe: Record<SavingsType, number> | null;
  pinjaman_aktif: number;
  outstanding_pinjaman: number;
  tunggakan: number;
  pengajuan_pending: number;
}

export const formatRupiah = (value: number | null | undefined): string =>
  new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0,
  }).format(value ?? 0);

export const formatTanggal = (value: string | null | undefined): string =>
  value
    ? new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeZone: 'Asia/Jakarta' }).format(new Date(value))
    : '-';
