import { createClient } from '@/lib/supabase/server';
import { CashflowChart } from '@/components/DashboardCharts';
import { ExportButton } from '@/components/ExportButton';
import { formatRupiah, formatTanggal } from '@/lib/types';

const BULAN = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

type TxnRow = { jenis: string; nominal: number; created_at: string };
type OverdueRow = {
  angsuran_ke: number;
  jatuh_tempo: string;
  total: number;
  loans: { members: { nama: string; no_anggota: string | null } | null } | null;
};

export default async function LaporanPage() {
  const supabase = await createClient();

  const sinceDate = new Date();
  sinceDate.setMonth(sinceDate.getMonth() - 5);
  sinceDate.setDate(1);

  const { data: txns } = await supabase
    .from('savings_transactions')
    .select('jenis, nominal, created_at')
    .gte('created_at', sinceDate.toISOString());

  // Agregasi arus kas per bulan (6 bulan terakhir)
  const buckets = new Map<string, { masuk: number; keluar: number }>();
  for (let i = 5; i >= 0; i--) {
    const d = new Date();
    d.setMonth(d.getMonth() - i);
    buckets.set(`${d.getFullYear()}-${d.getMonth()}`, { masuk: 0, keluar: 0 });
  }
  for (const t of (txns ?? []) as TxnRow[]) {
    const d = new Date(t.created_at);
    const key = `${d.getFullYear()}-${d.getMonth()}`;
    const b = buckets.get(key);
    if (b) {
      if (t.jenis === 'setor') b.masuk += Number(t.nominal);
      else b.keluar += Number(t.nominal);
    }
  }
  const cashflow = [...buckets.entries()].map(([key, v]) => {
    const month = Number(key.split('-')[1]);
    return { bulan: BULAN[month], masuk: v.masuk, keluar: v.keluar };
  });

  const { data: overdueData } = await supabase
    .from('loan_installments')
    .select('angsuran_ke, jatuh_tempo, total, loans(members(nama, no_anggota))')
    .neq('status', 'lunas')
    .lt('jatuh_tempo', new Date().toISOString().slice(0, 10))
    .order('jatuh_tempo');

  const overdue = (overdueData ?? []) as unknown as OverdueRow[];

  const exportRows = overdue.map((o) => ({
    anggota: o.loans?.members?.nama ?? '-',
    no_anggota: o.loans?.members?.no_anggota ?? '-',
    angsuran_ke: o.angsuran_ke,
    jatuh_tempo: o.jatuh_tempo,
    nominal: o.total,
  }));

  const totalTunggakan = overdue.reduce((s, o) => s + Number(o.total), 0);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Laporan</h1>
        <p className="text-sm text-slate-500">Arus kas simpanan & daftar tunggakan</p>
      </div>

      <div className="rounded-xl border border-slate-200 bg-white p-5">
        <h2 className="mb-4 font-semibold">Arus Kas Simpanan (6 Bulan Terakhir)</h2>
        <CashflowChart data={cashflow} />
      </div>

      <div className="rounded-xl border border-slate-200 bg-white p-5">
        <div className="mb-4 flex items-center justify-between">
          <div>
            <h2 className="font-semibold">Daftar Tunggakan</h2>
            <p className="text-sm text-red-600">
              Total: {formatRupiah(totalTunggakan)} ({overdue.length} angsuran)
            </p>
          </div>
          <ExportButton rows={exportRows} filename="tunggakan.csv" />
        </div>

        <div className="overflow-hidden rounded-lg border border-slate-200">
          <table className="w-full text-sm">
            <thead className="border-b border-slate-200 bg-slate-50 text-left text-slate-500">
              <tr>
                <th className="px-4 py-3 font-medium">Anggota</th>
                <th className="px-4 py-3 font-medium">Angsuran Ke</th>
                <th className="px-4 py-3 font-medium">Jatuh Tempo</th>
                <th className="px-4 py-3 font-medium">Nominal</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {overdue.map((o, i) => (
                <tr key={i} className="hover:bg-slate-50">
                  <td className="px-4 py-3">
                    <div className="font-medium">{o.loans?.members?.nama ?? '-'}</div>
                    <div className="font-mono text-xs text-slate-400">
                      {o.loans?.members?.no_anggota ?? '-'}
                    </div>
                  </td>
                  <td className="px-4 py-3">{o.angsuran_ke}</td>
                  <td className="px-4 py-3">{formatTanggal(o.jatuh_tempo)}</td>
                  <td className="px-4 py-3 font-medium text-red-600">
                    {formatRupiah(o.total)}
                  </td>
                </tr>
              ))}
              {overdue.length === 0 && (
                <tr>
                  <td colSpan={4} className="px-4 py-10 text-center text-slate-400">
                    Tidak ada tunggakan 🎉
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
