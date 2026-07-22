import Image from 'next/image';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { BankAccountForm } from '@/components/BankAccountForm';
import { formatRupiah, formatTanggal, type MemberStatus } from '@/lib/types';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import {
  Card,
  CardContent,
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
import { cn } from '@/lib/utils';

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

export default async function AnggotaDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: member } = await supabase
    .from('members')
    .select(
      'id, no_anggota, nama, nik, alamat, phone, status, tanggal_gabung, foto_ktp_path, bank_code, account_number, account_holder_name',
    )
    .eq('id', id)
    .maybeSingle();

  if (!member) notFound();

  const { data: accounts } = await supabase
    .from('savings_accounts')
    .select('id, tipe, saldo')
    .eq('member_id', id)
    .order('tipe');

  const { data: transactions } = await supabase
    .from('savings_transactions')
    .select('id, jenis, nominal, metode, keterangan, created_at, savings_accounts(tipe)')
    .eq('member_id', id)
    .order('created_at', { ascending: false })
    .limit(100);

  let ktpUrl: string | null = null;
  if (member.foto_ktp_path) {
    const { data } = await supabase.storage
      .from('ktp')
      .createSignedUrl(member.foto_ktp_path, 3600);
    ktpUrl = data?.signedUrl ?? null;
  }

  const totalSaldo =
    accounts?.reduce((s, a) => s + Number(a.saldo), 0) ?? 0;

  return (
    <div>
      <div className="mb-6">
        <Button variant="link" className="h-auto p-0" asChild>
          <Link href="/anggota">← Kembali ke daftar anggota</Link>
        </Button>
        <h1 className="mt-2 text-2xl font-bold">{member.nama}</h1>
        <p className="text-muted-foreground font-mono text-sm">{member.no_anggota ?? '-'}</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Profil</CardTitle>
          </CardHeader>
          <CardContent>
            <dl className="space-y-3 text-sm">
              <div className="flex justify-between">
                <dt className="text-muted-foreground">Status</dt>
                <dd>
                  <Badge
                    variant="secondary"
                    className={cn(statusStyle[member.status as MemberStatus])}
                  >
                    {statusLabel[member.status as MemberStatus]}
                  </Badge>
                </dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-muted-foreground">NIK</dt>
                <dd>{member.nik ?? '-'}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-muted-foreground">No. HP</dt>
                <dd>{member.phone ?? '-'}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-muted-foreground">Alamat</dt>
                <dd className="max-w-xs text-right">{member.alamat ?? '-'}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-muted-foreground">Bergabung</dt>
                <dd>{formatTanggal(member.tanggal_gabung)}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-muted-foreground">Total Simpanan</dt>
                <dd className="font-medium">{formatRupiah(totalSaldo)}</dd>
              </div>
            </dl>

            <Separator className="my-4" />
            <p className="mb-2 text-sm font-medium">Rekening Pencairan</p>
            <BankAccountForm
              memberId={member.id}
              bankCode={member.bank_code}
              accountNumber={member.account_number}
              accountHolderName={member.account_holder_name}
            />

            {ktpUrl && (
              <>
                <Separator className="my-4" />
                <p className="mb-2 text-sm font-medium">Foto KTP</p>
                <Image
                  src={ktpUrl}
                  alt="Foto KTP"
                  width={400}
                  height={250}
                  className="rounded-lg border object-contain"
                  unoptimized
                />
              </>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Saldo per Rekening</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="mb-6 grid grid-cols-3 gap-3">
              {(accounts ?? []).map((a) => (
                <div key={a.id} className="rounded-lg border p-3 text-center">
                  <p className="text-muted-foreground text-xs capitalize">{a.tipe}</p>
                  <p className="text-sm font-bold">{formatRupiah(a.saldo)}</p>
                </div>
              ))}
            </div>

            <CardTitle className="mb-3 text-lg">Riwayat Mutasi</CardTitle>
            <div className="max-h-96 overflow-auto">
              <Table>
                <TableHeader>
                  <TableRow className="hover:bg-transparent">
                    <TableHead className="sticky top-0 bg-card">Tanggal</TableHead>
                    <TableHead className="sticky top-0 bg-card">Rekening</TableHead>
                    <TableHead className="sticky top-0 bg-card">Jenis</TableHead>
                    <TableHead className="sticky top-0 bg-card">Nominal</TableHead>
                    <TableHead className="sticky top-0 bg-card">Metode</TableHead>
                    <TableHead className="sticky top-0 bg-card">Keterangan</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {(transactions ?? []).map((t) => {
                    const raw = t.savings_accounts as
                      | { tipe: string }
                      | { tipe: string }[]
                      | null;
                    const acc = Array.isArray(raw) ? raw[0] : raw;
                    return (
                      <TableRow key={t.id}>
                        <TableCell className="text-xs">{formatTanggal(t.created_at)}</TableCell>
                        <TableCell className="text-xs capitalize">{acc?.tipe ?? '-'}</TableCell>
                        <TableCell className="text-xs capitalize">{t.jenis}</TableCell>
                        <TableCell
                          className={`text-xs font-medium ${t.jenis === 'setor' ? 'text-green-700' : 'text-destructive'}`}
                        >
                          {t.jenis === 'setor' ? '+' : '-'}
                          {formatRupiah(t.nominal)}
                        </TableCell>
                        <TableCell className="text-xs capitalize">{t.metode}</TableCell>
                        <TableCell className="text-xs">{t.keterangan ?? '-'}</TableCell>
                      </TableRow>
                    );
                  })}
                  {(transactions ?? []).length === 0 && (
                    <TableRow>
                      <TableCell
                        colSpan={6}
                        className="text-muted-foreground py-8 text-center"
                      >
                        Belum ada mutasi
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
