import Link from 'next/link';
import { createClient } from '@/lib/supabase/server';
import { LoanRow, type LoanRowData } from '@/components/LoanRow';
import type { LoanStatus } from '@/lib/types';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { NativeSelect } from '@/components/ui/native-select';
import {
  Table,
  TableBody,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';

const PAGE_SIZE = 20;

const statusOptions: { value: string; label: string }[] = [
  { value: 'all', label: 'Semua status' },
  { value: 'pengajuan', label: 'Menunggu' },
  { value: 'approved', label: 'Menunggu Pencairan' },
  { value: 'active', label: 'Aktif' },
  { value: 'lunas', label: 'Lunas' },
  { value: 'rejected', label: 'Ditolak' },
];

export default async function PinjamanPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; status?: string; page?: string }>;
}) {
  const { q, status, page: pageParam } = await searchParams;
  const page = Math.max(1, Number(pageParam) || 1);
  const from = (page - 1) * PAGE_SIZE;
  const to = from + PAGE_SIZE - 1;

  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  const { data: staff } = user
    ? await supabase.from('staff_roles').select('role').eq('user_id', user.id).maybeSingle()
    : { data: null };
  const canManage = staff?.role === 'pengurus';

  let memberIds: string[] | null = null;
  if (q?.trim()) {
    const term = `%${q.trim()}%`;
    const { data: matched } = await supabase
      .from('members')
      .select('id')
      .or(`nama.ilike.${term},no_anggota.ilike.${term}`);
    memberIds = matched?.map((m) => m.id) ?? [];
    if (memberIds.length === 0) {
      return (
        <PinjamanPageShell
          q={q}
          status={status}
          page={page}
          totalPages={1}
          count={0}
        >
          <tr>
            <td colSpan={8} className="text-muted-foreground px-4 py-10 text-center">
              Tidak ada pinjaman ditemukan
            </td>
          </tr>
        </PinjamanPageShell>
      );
    }
  }

  let query = supabase
    .from('loans')
    .select(
      `id, pokok, tenor, jasa_persen, tujuan, status, tanggal_pengajuan,
       members(nama, no_anggota, bank_code, account_number, account_holder_name),
       disbursements(status, created_at),
       loan_installments(id, angsuran_ke, jatuh_tempo, nominal_pokok, nominal_jasa, total, status, paid_at)`,
      { count: 'exact' },
    )
    .order('tanggal_pengajuan', { ascending: false });

  if (memberIds) query = query.in('member_id', memberIds);
  if (status && status !== 'all') {
    query = query.eq('status', status as LoanStatus);
  }

  const { data, count } = await query.range(from, to);
  const loans = (data ?? []) as unknown as LoanRowData[];
  const totalPages = Math.max(1, Math.ceil((count ?? 0) / PAGE_SIZE));

  function pageUrl(p: number) {
    const params = new URLSearchParams();
    if (q) params.set('q', q);
    if (status) params.set('status', status);
    params.set('page', String(p));
    const qs = params.toString();
    return `/pinjaman${qs ? `?${qs}` : ''}`;
  }

  return (
    <PinjamanPageShell
      q={q}
      status={status}
      page={page}
      totalPages={totalPages}
      count={count ?? 0}
      pageUrl={pageUrl}
    >
      {loans.map((l) => (
        <LoanRow key={l.id} loan={l} canManage={canManage} />
      ))}
      {loans.length === 0 && (
        <tr>
          <td colSpan={8} className="text-muted-foreground px-4 py-10 text-center">
            Belum ada pinjaman
          </td>
        </tr>
      )}
    </PinjamanPageShell>
  );
}

function PinjamanPageShell({
  q,
  status,
  page,
  totalPages,
  count,
  pageUrl,
  children,
}: {
  q?: string;
  status?: string;
  page: number;
  totalPages: number;
  count: number;
  pageUrl?: (p: number) => string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold">Pinjaman</h1>
        <p className="text-muted-foreground text-sm">Pengajuan dan status pinjaman anggota</p>
      </div>

      <form method="get" className="mb-4 flex flex-wrap gap-3">
        <Input
          name="q"
          defaultValue={q ?? ''}
          placeholder="Cari nama / no. anggota..."
          className="min-w-[200px] flex-1"
        />
        <NativeSelect name="status" defaultValue={status ?? 'all'} className="w-auto">
          {statusOptions.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </NativeSelect>
        <Button type="submit">Filter</Button>
      </form>

      <div className="bg-card overflow-hidden rounded-xl ring-1 ring-foreground/10">
        <Table>
          <TableHeader>
            <TableRow className="bg-muted/50 hover:bg-muted/50">
              <TableHead className="px-4">Anggota</TableHead>
              <TableHead className="px-4">Jumlah</TableHead>
              <TableHead className="px-4">Tenor</TableHead>
              <TableHead className="px-4">Jasa</TableHead>
              <TableHead className="px-4">Tujuan</TableHead>
              <TableHead className="px-4">Tgl Pengajuan</TableHead>
              <TableHead className="px-4">Status</TableHead>
              <TableHead className="px-4">Aksi</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>{children}</TableBody>
        </Table>
      </div>

      {totalPages > 1 && pageUrl && (
        <div className="text-muted-foreground mt-4 flex items-center justify-between text-sm">
          <span>
            Halaman {page} dari {totalPages} ({count} pinjaman)
          </span>
          <div className="flex gap-2">
            {page > 1 && (
              <Button variant="outline" size="sm" asChild>
                <Link href={pageUrl(page - 1)}>← Sebelumnya</Link>
              </Button>
            )}
            {page < totalPages && (
              <Button variant="outline" size="sm" asChild>
                <Link href={pageUrl(page + 1)}>Selanjutnya →</Link>
              </Button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
