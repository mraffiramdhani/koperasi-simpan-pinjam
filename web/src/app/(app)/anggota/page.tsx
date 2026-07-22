import Link from 'next/link';
import { createClient } from '@/lib/supabase/server';
import { MemberActions } from '@/components/MemberActions';
import { BankAccountForm } from '@/components/BankAccountForm';
import { formatRupiah, formatTanggal, type MemberStatus } from '@/lib/types';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { NativeSelect } from '@/components/ui/native-select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { cn } from '@/lib/utils';

const PAGE_SIZE = 20;

const statusStyle: Record<MemberStatus, string> = {
  active: 'bg-green-100 text-green-700 hover:bg-green-100',
  pending: 'bg-amber-100 text-amber-700 hover:bg-amber-100',
  inactive: 'bg-muted text-muted-foreground hover:bg-muted',
  rejected: 'bg-destructive/10 text-destructive hover:bg-destructive/10',
};

const statusLabel: Record<MemberStatus, string> = {
  active: 'Aktif',
  pending: 'Menunggu',
  inactive: 'Nonaktif',
  rejected: 'Ditolak',
};

export default async function AnggotaPage({
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

  let query = supabase
    .from('members')
    .select(
      'id, no_anggota, nama, phone, status, tanggal_gabung, bank_code, account_number, account_holder_name, savings_accounts(saldo)',
      { count: 'exact' },
    )
    .order('created_at', { ascending: false });

  if (q?.trim()) {
    const term = `%${q.trim()}%`;
    query = query.or(`nama.ilike.${term},no_anggota.ilike.${term}`);
  }
  if (status && status !== 'all') {
    query = query.eq('status', status);
  }

  const { data: members, count } = await query.range(from, to);
  const totalPages = Math.max(1, Math.ceil((count ?? 0) / PAGE_SIZE));

  const rows = (members ?? []).map((m) => ({
    ...m,
    total:
      (m.savings_accounts as { saldo: number }[] | null)?.reduce(
        (s, a) => s + Number(a.saldo),
        0,
      ) ?? 0,
  }));

  function pageUrl(p: number) {
    const params = new URLSearchParams();
    if (q) params.set('q', q);
    if (status) params.set('status', status);
    params.set('page', String(p));
    const qs = params.toString();
    return `/anggota${qs ? `?${qs}` : ''}`;
  }

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold">Anggota</h1>
        <p className="text-muted-foreground text-sm">Kelola dan verifikasi keanggotaan</p>
      </div>

      <form method="get" className="mb-4 flex flex-wrap gap-3">
        <Input
          name="q"
          defaultValue={q ?? ''}
          placeholder="Cari nama / no. anggota..."
          className="min-w-[200px] flex-1"
        />
        <NativeSelect name="status" defaultValue={status ?? 'all'} className="w-auto">
          <option value="all">Semua status</option>
          <option value="pending">Menunggu</option>
          <option value="active">Aktif</option>
          <option value="inactive">Nonaktif</option>
          <option value="rejected">Ditolak</option>
        </NativeSelect>
        <Button type="submit">Filter</Button>
      </form>

      <div className="bg-card overflow-hidden rounded-xl ring-1 ring-foreground/10">
        <Table>
          <TableHeader>
            <TableRow className="bg-muted/50 hover:bg-muted/50">
              <TableHead className="px-4">No. Anggota</TableHead>
              <TableHead className="px-4">Nama</TableHead>
              <TableHead className="px-4">No. HP</TableHead>
              <TableHead className="px-4">Total Simpanan</TableHead>
              <TableHead className="px-4">Rekening Pencairan</TableHead>
              <TableHead className="px-4">Bergabung</TableHead>
              <TableHead className="px-4">Status</TableHead>
              <TableHead className="px-4">Aksi</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {rows.map((m) => (
              <TableRow key={m.id}>
                <TableCell className="px-4 font-mono text-xs">{m.no_anggota ?? '-'}</TableCell>
                <TableCell className="px-4 font-medium">
                  <Link href={`/anggota/${m.id}`} className="text-primary hover:underline">
                    {m.nama}
                  </Link>
                </TableCell>
                <TableCell className="px-4">{m.phone ?? '-'}</TableCell>
                <TableCell className="px-4">{formatRupiah(m.total)}</TableCell>
                <TableCell className="px-4">
                  <BankAccountForm
                    memberId={m.id}
                    bankCode={m.bank_code}
                    accountNumber={m.account_number}
                    accountHolderName={m.account_holder_name}
                  />
                </TableCell>
                <TableCell className="px-4">{formatTanggal(m.tanggal_gabung)}</TableCell>
                <TableCell className="px-4">
                  <Badge
                    variant="secondary"
                    className={cn(statusStyle[m.status as MemberStatus])}
                  >
                    {statusLabel[m.status as MemberStatus]}
                  </Badge>
                </TableCell>
                <TableCell className="px-4">
                  {m.status === 'pending' ? (
                    <MemberActions memberId={m.id} canManage={canManage} />
                  ) : (
                    <span className="text-muted-foreground text-xs">-</span>
                  )}
                </TableCell>
              </TableRow>
            ))}
            {rows.length === 0 && (
              <TableRow>
                <TableCell colSpan={8} className="text-muted-foreground px-4 py-10 text-center">
                  Belum ada anggota
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      {totalPages > 1 && (
        <div className="text-muted-foreground mt-4 flex items-center justify-between text-sm">
          <span>
            Halaman {page} dari {totalPages} ({count ?? 0} anggota)
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
