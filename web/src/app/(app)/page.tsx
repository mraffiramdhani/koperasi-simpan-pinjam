import { createClient } from '@/lib/supabase/server';
import { SimpananBarChart, LoanStatusPie } from '@/components/DashboardCharts';
import { formatRupiah, type DashboardSummary } from '@/lib/types';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';

function StatCard({
  label,
  value,
  hint,
  accent,
}: {
  label: string;
  value: string;
  hint?: string;
  accent?: string;
}) {
  return (
    <Card>
      <CardHeader className="pb-0">
        <CardDescription>{label}</CardDescription>
        <CardTitle className={`text-2xl font-bold ${accent ?? ''}`}>{value}</CardTitle>
        {hint && <p className="text-muted-foreground text-xs">{hint}</p>}
      </CardHeader>
    </Card>
  );
}

export default async function DashboardPage() {
  const supabase = await createClient();

  const { data: summaryData } = await supabase.rpc('get_dashboard_summary');
  const s = (summaryData ?? {}) as Partial<DashboardSummary>;

  const { data: loans } = await supabase.from('loans').select('status');
  const statusCount = (loans ?? []).reduce<Record<string, number>>((acc, l) => {
    acc[l.status] = (acc[l.status] ?? 0) + 1;
    return acc;
  }, {});
  const loanPie = Object.entries(statusCount).map(([status, jumlah]) => ({
    status,
    jumlah,
  }));

  const perTipe = (s.simpanan_per_tipe ?? {}) as Record<string, number>;
  const simpananBar = (['pokok', 'wajib', 'sukarela'] as const).map((tipe) => ({
    tipe,
    total: Number(perTipe[tipe] ?? 0),
  }));

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold">Dashboard</h1>
        <p className="text-muted-foreground text-sm">Ringkasan operasional koperasi</p>
      </div>

      <div className="mb-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          label="Anggota Aktif"
          value={`${s.total_anggota ?? 0}`}
          hint={`${s.anggota_pending ?? 0} menunggu verifikasi`}
        />
        <StatCard
          label="Total Simpanan"
          value={formatRupiah(s.total_simpanan)}
          accent="text-primary"
        />
        <StatCard
          label="Outstanding Pinjaman"
          value={formatRupiah(s.outstanding_pinjaman)}
          hint={`${s.pinjaman_aktif ?? 0} pinjaman aktif`}
        />
        <StatCard
          label="Tunggakan"
          value={formatRupiah(s.tunggakan)}
          accent="text-destructive"
          hint={`${s.pengajuan_pending ?? 0} pengajuan menunggu`}
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Simpanan per Jenis</CardTitle>
          </CardHeader>
          <CardContent>
            <SimpananBarChart data={simpananBar} />
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>Distribusi Status Pinjaman</CardTitle>
          </CardHeader>
          <CardContent>
            {loanPie.length > 0 ? (
              <LoanStatusPie data={loanPie} />
            ) : (
              <p className="text-muted-foreground py-16 text-center">Belum ada data pinjaman</p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
