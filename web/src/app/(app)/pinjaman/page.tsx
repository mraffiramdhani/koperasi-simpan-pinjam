import { createClient } from '@/lib/supabase/server';
import { LoanActions } from '@/components/LoanActions';
import { formatRupiah, formatTanggal, type LoanStatus } from '@/lib/types';

const statusStyle: Record<LoanStatus, string> = {
  pengajuan: 'bg-amber-100 text-amber-700',
  approved: 'bg-blue-100 text-blue-700',
  active: 'bg-green-100 text-green-700',
  rejected: 'bg-red-100 text-red-700',
  lunas: 'bg-teal-100 text-teal-700',
};

const statusLabel: Record<LoanStatus, string> = {
  pengajuan: 'Menunggu',
  approved: 'Disetujui',
  active: 'Aktif',
  rejected: 'Ditolak',
  lunas: 'Lunas',
};

type LoanRow = {
  id: string;
  pokok: number;
  tenor: number;
  jasa_persen: number;
  tujuan: string | null;
  status: LoanStatus;
  tanggal_pengajuan: string;
  members: { nama: string; no_anggota: string | null } | null;
};

export default async function PinjamanPage() {
  const supabase = await createClient();
  const { data } = await supabase
    .from('loans')
    .select('id, pokok, tenor, jasa_persen, tujuan, status, tanggal_pengajuan, members(nama, no_anggota)')
    .order('tanggal_pengajuan', { ascending: false });

  const loans = (data ?? []) as unknown as LoanRow[];

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold">Pinjaman</h1>
        <p className="text-sm text-slate-500">Pengajuan dan status pinjaman anggota</p>
      </div>

      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white">
        <table className="w-full text-sm">
          <thead className="border-b border-slate-200 bg-slate-50 text-left text-slate-500">
            <tr>
              <th className="px-4 py-3 font-medium">Anggota</th>
              <th className="px-4 py-3 font-medium">Jumlah</th>
              <th className="px-4 py-3 font-medium">Tenor</th>
              <th className="px-4 py-3 font-medium">Jasa</th>
              <th className="px-4 py-3 font-medium">Tujuan</th>
              <th className="px-4 py-3 font-medium">Tgl Pengajuan</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Aksi</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {loans.map((l) => (
              <tr key={l.id} className="hover:bg-slate-50">
                <td className="px-4 py-3">
                  <div className="font-medium">{l.members?.nama ?? '-'}</div>
                  <div className="font-mono text-xs text-slate-400">
                    {l.members?.no_anggota ?? '-'}
                  </div>
                </td>
                <td className="px-4 py-3 font-medium">{formatRupiah(l.pokok)}</td>
                <td className="px-4 py-3">{l.tenor} bln</td>
                <td className="px-4 py-3">{l.jasa_persen}%/bln</td>
                <td className="px-4 py-3">{l.tujuan ?? '-'}</td>
                <td className="px-4 py-3">{formatTanggal(l.tanggal_pengajuan)}</td>
                <td className="px-4 py-3">
                  <span
                    className={`rounded-full px-2.5 py-1 text-xs font-medium ${statusStyle[l.status]}`}
                  >
                    {statusLabel[l.status]}
                  </span>
                </td>
                <td className="px-4 py-3">
                  {l.status === 'pengajuan' ? (
                    <LoanActions loanId={l.id} />
                  ) : (
                    <span className="text-xs text-slate-400">-</span>
                  )}
                </td>
              </tr>
            ))}
            {loans.length === 0 && (
              <tr>
                <td colSpan={8} className="px-4 py-10 text-center text-slate-400">
                  Belum ada pinjaman
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
