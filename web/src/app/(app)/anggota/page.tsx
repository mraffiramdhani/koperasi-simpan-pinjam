import { createClient } from '@/lib/supabase/server';
import { MemberActions } from '@/components/MemberActions';
import { formatRupiah, formatTanggal, type MemberStatus } from '@/lib/types';

const statusStyle: Record<MemberStatus, string> = {
  active: 'bg-green-100 text-green-700',
  pending: 'bg-amber-100 text-amber-700',
  inactive: 'bg-slate-100 text-slate-600',
  rejected: 'bg-red-100 text-red-700',
};

const statusLabel: Record<MemberStatus, string> = {
  active: 'Aktif',
  pending: 'Menunggu',
  inactive: 'Nonaktif',
  rejected: 'Ditolak',
};

export default async function AnggotaPage() {
  const supabase = await createClient();
  const { data: members } = await supabase
    .from('members')
    .select('id, no_anggota, nama, phone, status, tanggal_gabung, savings_accounts(saldo)')
    .order('created_at', { ascending: false });

  const rows = (members ?? []).map((m) => ({
    ...m,
    total: (m.savings_accounts as { saldo: number }[] | null)?.reduce(
      (s, a) => s + Number(a.saldo),
      0,
    ) ?? 0,
  }));

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold">Anggota</h1>
        <p className="text-sm text-slate-500">Kelola dan verifikasi keanggotaan</p>
      </div>

      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white">
        <table className="w-full text-sm">
          <thead className="border-b border-slate-200 bg-slate-50 text-left text-slate-500">
            <tr>
              <th className="px-4 py-3 font-medium">No. Anggota</th>
              <th className="px-4 py-3 font-medium">Nama</th>
              <th className="px-4 py-3 font-medium">No. HP</th>
              <th className="px-4 py-3 font-medium">Total Simpanan</th>
              <th className="px-4 py-3 font-medium">Bergabung</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Aksi</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {rows.map((m) => (
              <tr key={m.id} className="hover:bg-slate-50">
                <td className="px-4 py-3 font-mono text-xs">{m.no_anggota ?? '-'}</td>
                <td className="px-4 py-3 font-medium">{m.nama}</td>
                <td className="px-4 py-3">{m.phone ?? '-'}</td>
                <td className="px-4 py-3">{formatRupiah(m.total)}</td>
                <td className="px-4 py-3">{formatTanggal(m.tanggal_gabung)}</td>
                <td className="px-4 py-3">
                  <span
                    className={`rounded-full px-2.5 py-1 text-xs font-medium ${statusStyle[m.status as MemberStatus]}`}
                  >
                    {statusLabel[m.status as MemberStatus]}
                  </span>
                </td>
                <td className="px-4 py-3">
                  {m.status === 'pending' ? (
                    <MemberActions memberId={m.id} />
                  ) : (
                    <span className="text-xs text-slate-400">-</span>
                  )}
                </td>
              </tr>
            ))}
            {rows.length === 0 && (
              <tr>
                <td colSpan={7} className="px-4 py-10 text-center text-slate-400">
                  Belum ada anggota
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
