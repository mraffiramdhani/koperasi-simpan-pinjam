import { createClient } from '@/lib/supabase/server';
import { CashflowChart } from '@/components/DashboardCharts';
import { ExportButton } from '@/components/ExportButton';
import { formatRupiah, formatTanggal } from '@/lib/types';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';

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
        <p className="text-muted-foreground text-sm">Arus kas simpanan & daftar tunggakan</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Arus Kas Simpanan (6 Bulan Terakhir)</CardTitle>
        </CardHeader>
        <CardContent>
          <CashflowChart data={cashflow} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex-row items-start justify-between gap-4 space-y-0">
          <div>
            <CardTitle>Daftar Tunggakan</CardTitle>
            <CardDescription className="text-destructive">
              Total: {formatRupiah(totalTunggakan)} ({overdue.length} angsuran)
            </CardDescription>
          </div>
          <ExportButton rows={exportRows} filename="tunggakan.csv" />
        </CardHeader>
        <CardContent>
          <div className="overflow-hidden rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow className="bg-muted/50 hover:bg-muted/50">
                  <TableHead className="px-4">Anggota</TableHead>
                  <TableHead className="px-4">Angsuran Ke</TableHead>
                  <TableHead className="px-4">Jatuh Tempo</TableHead>
                  <TableHead className="px-4">Nominal</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {overdue.map((o, i) => (
                  <TableRow key={i}>
                    <TableCell className="px-4">
                      <div className="font-medium">{o.loans?.members?.nama ?? '-'}</div>
                      <div className="text-muted-foreground font-mono text-xs">
                        {o.loans?.members?.no_anggota ?? '-'}
                      </div>
                    </TableCell>
                    <TableCell className="px-4">{o.angsuran_ke}</TableCell>
                    <TableCell className="px-4">{formatTanggal(o.jatuh_tempo)}</TableCell>
                    <TableCell className="text-destructive px-4 font-medium">
                      {formatRupiah(o.total)}
                    </TableCell>
                  </TableRow>
                ))}
                {overdue.length === 0 && (
                  <TableRow>
                    <TableCell
                      colSpan={4}
                      className="text-muted-foreground px-4 py-10 text-center"
                    >
                      Tidak ada tunggakan
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
