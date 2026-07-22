'use client';

import Link from 'next/link';
import {
  BookOpen,
  Smartphone,
  Monitor,
  GitBranch,
  CircleHelp,
} from 'lucide-react';
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '@/components/ui/accordion';
import { Badge } from '@/components/ui/badge';
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

function StepList({ steps }: { steps: React.ReactNode[] }) {
  return (
    <ol className="text-muted-foreground list-decimal space-y-1.5 pl-5 text-sm">
      {steps.map((step, i) => (
        <li key={i}>{step}</li>
      ))}
    </ol>
  );
}

function BulletList({ items }: { items: React.ReactNode[] }) {
  return (
    <ul className="text-muted-foreground list-disc space-y-1.5 pl-5 text-sm">
      {items.map((item, i) => (
        <li key={i}>{item}</li>
      ))}
    </ul>
  );
}

function Callout({ children }: { children: React.ReactNode }) {
  return (
    <p className="bg-accent text-accent-foreground mt-3 rounded-lg px-3 py-2 text-sm">
      {children}
    </p>
  );
}

export default function PanduanPage() {
  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <div>
        <h1 className="flex items-center gap-2 text-2xl font-bold">
          <BookOpen className="text-primary size-6" />
          Panduan Pengguna
        </h1>
        <p className="text-muted-foreground text-sm">
          Cara memakai dashboard web dan aplikasi mobile koperasi
        </p>
      </div>

      <Tabs defaultValue="web">
        <TabsList className="h-auto w-full flex-wrap justify-start gap-1">
          <TabsTrigger value="web" className="gap-1.5">
            <Monitor className="size-3.5" />
            Dashboard Web
          </TabsTrigger>
          <TabsTrigger value="mobile" className="gap-1.5">
            <Smartphone className="size-3.5" />
            Aplikasi Mobile
          </TabsTrigger>
          <TabsTrigger value="alur" className="gap-1.5">
            <GitBranch className="size-3.5" />
            Alur & Status
          </TabsTrigger>
          <TabsTrigger value="faq" className="gap-1.5">
            <CircleHelp className="size-3.5" />
            FAQ
          </TabsTrigger>
        </TabsList>

        {/* —— WEB —— */}
        <TabsContent value="web" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Peran di dashboard</CardTitle>
              <CardDescription>
                Login hanya untuk akun pengurus atau teller
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Peran</TableHead>
                    <TableHead>Tugas utama</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  <TableRow>
                    <TableCell>
                      <Badge>Pengurus</Badge>
                    </TableCell>
                    <TableCell className="text-muted-foreground text-sm">
                      Verifikasi anggota, setujui/tolak pinjaman, cairkan via
                      Xendit, laporan, serta semua kemampuan teller
                    </TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell>
                      <Badge variant="secondary">Teller</Badge>
                    </TableCell>
                    <TableCell className="text-muted-foreground text-sm">
                      POS setor/tarik tunai, bayar angsuran tunai, lihat data
                      anggota & pinjaman
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Menu & cara pakai</CardTitle>
            </CardHeader>
            <CardContent>
              <Accordion type="multiple" defaultValue={['login', 'anggota', 'pinjaman']}>
                <AccordionItem value="login">
                  <AccordionTrigger>Masuk & reset password</AccordionTrigger>
                  <AccordionContent>
                    <StepList
                      steps={[
                        <>
                          Buka halaman login → isi <strong>Email</strong> +{' '}
                          <strong>Password</strong> → <strong>Masuk</strong>
                        </>,
                        <>
                          Lupa password: <strong>Lupa password?</strong> → kirim
                          link reset ke email
                        </>,
                        <>
                          Dari email, atur <strong>Password Baru</strong> lalu{' '}
                          <strong>Simpan Password</strong>
                        </>,
                      ]}
                    />
                    <Callout>
                      Akun anggota tidak bisa masuk web — gunakan aplikasi
                      mobile.
                    </Callout>
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="dashboard">
                  <AccordionTrigger>Dashboard</AccordionTrigger>
                  <AccordionContent>
                    <BulletList
                      items={[
                        <>
                          <strong>Anggota Aktif</strong> — jumlah anggota aktif
                          (+ menunggu verifikasi)
                        </>,
                        <>
                          <strong>Total Simpanan</strong>,{' '}
                          <strong>Outstanding Pinjaman</strong>,{' '}
                          <strong>Tunggakan</strong>
                        </>,
                        'Grafik simpanan per jenis & distribusi status pinjaman',
                      ]}
                    />
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="anggota">
                  <AccordionTrigger>Anggota — verifikasi & rekening</AccordionTrigger>
                  <AccordionContent className="space-y-3">
                    <StepList
                      steps={[
                        <>
                          Buka menu <Link href="/anggota" className="text-primary underline">Anggota</Link>
                        </>,
                        <>
                          Cari nama / no. anggota, filter status →{' '}
                          <strong>Filter</strong>
                        </>,
                        <>
                          Status <Badge variant="secondary" className="bg-amber-100 text-amber-700">Menunggu</Badge>{' '}
                          → tekan <strong>Aktifkan</strong> atau{' '}
                          <strong>Tolak</strong>
                        </>,
                        <>
                          Klik nama untuk detail: profil, KTP, saldo, riwayat
                          mutasi
                        </>,
                      ]}
                    />
                    <p className="text-sm font-medium">Rekening pencairan</p>
                    <StepList
                      steps={[
                        <>
                          Jika <strong>Belum diisi</strong> → <strong>Edit</strong>
                        </>,
                        'Pilih bank, isi no. rekening & nama pemilik → Simpan',
                        'Rekening wajib lengkap sebelum pinjaman bisa dicairkan',
                      ]}
                    />
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="pinjaman">
                  <AccordionTrigger>Pinjaman — setujui & cairkan</AccordionTrigger>
                  <AccordionContent className="space-y-3">
                    <p className="text-sm font-medium">Persetujuan (pengurus)</p>
                    <StepList
                      steps={[
                        <>
                          Buka <Link href="/pinjaman" className="text-primary underline">Pinjaman</Link> → filter{' '}
                          <strong>Menunggu</strong>
                        </>,
                        <>
                          <strong>Setujui</strong> → status jadi Menunggu
                          Pencairan + jadwal angsuran dibuat
                        </>,
                        <>
                          atau <strong>Tolak</strong> → status Ditolak
                        </>,
                      ]}
                    />
                    <p className="text-sm font-medium">Pencairan (pengurus)</p>
                    <StepList
                      steps={[
                        'Pastikan rekening anggota sudah diisi',
                        <>
                          Tekan <strong>Cairkan via Xendit</strong>
                        </>,
                        <>
                          Jika gagal: perbaiki rekening lalu{' '}
                          <strong>Coba Cairkan Lagi</strong>
                        </>,
                      ]}
                    />
                    <p className="text-sm font-medium">Bayar angsuran tunai</p>
                    <BulletList
                      items={[
                        <>
                          Expand baris pinjaman <strong>Aktif</strong> →{' '}
                          <strong>Bayar Tunai</strong> pada angsuran yang belum
                          lunas
                        </>,
                      ]}
                    />
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="teller">
                  <AccordionTrigger>POS Teller — setor & tarik tunai</AccordionTrigger>
                  <AccordionContent>
                    <StepList
                      steps={[
                        <>
                          Buka <Link href="/teller" className="text-primary underline">POS Teller</Link>
                        </>,
                        'Cari dan pilih anggota aktif',
                        <>
                          Pilih <strong>Jenis Simpanan</strong> (Pokok / Wajib /
                          Sukarela) dan isi <strong>Nominal</strong>
                        </>,
                        <>
                          Tekan <strong>Setor</strong> atau <strong>Tarik</strong>
                        </>,
                      ]}
                    />
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="laporan">
                  <AccordionTrigger>Laporan</AccordionTrigger>
                  <AccordionContent>
                    <BulletList
                      items={[
                        <>
                          <strong>Arus Kas Simpanan</strong> — 6 bulan terakhir
                        </>,
                        <>
                          <strong>Daftar Tunggakan</strong> — angsuran lewat
                          jatuh tempo
                        </>,
                        <>
                          <strong>Ekspor CSV</strong> untuk unduh data tunggakan
                        </>,
                      ]}
                    />
                  </AccordionContent>
                </AccordionItem>
              </Accordion>
            </CardContent>
          </Card>
        </TabsContent>

        {/* —— MOBILE —— */}
        <TabsContent value="mobile" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Aplikasi anggota</CardTitle>
              <CardDescription>
                Navigasi: Beranda · Simpanan · Pinjaman · Profil
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Accordion type="multiple" defaultValue={['daftar', 'simpanan', 'pinjaman-m']}>
                <AccordionItem value="daftar">
                  <AccordionTrigger>Daftar, masuk & profil</AccordionTrigger>
                  <AccordionContent className="space-y-3">
                    <StepList
                      steps={[
                        <>
                          <strong>Daftar</strong>: Nama, No. HP, Email, Password
                        </>,
                        <>
                          Status awal biasanya <strong>Menunggu</strong> sampai
                          pengurus mengaktifkan
                        </>,
                        <>
                          Lupa password: kirim link reset dari layar login
                        </>,
                      ]}
                    />
                    <Callout>
                      Anggota baru otomatis punya 3 rekening: Pokok, Wajib, dan
                      Sukarela.
                    </Callout>
                    <p className="text-sm font-medium">Lengkapi profil</p>
                    <BulletList
                      items={[
                        'Profil → Edit Profil: NIK, alamat, rekening pencairan',
                        'Unggah Foto KTP dari halaman Profil',
                        'Rekening wajib diisi sebelum pinjaman bisa dicairkan',
                      ]}
                    />
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="simpanan">
                  <AccordionTrigger>Setor simpanan online</AccordionTrigger>
                  <AccordionContent>
                    <StepList
                      steps={[
                        'Tab Simpanan → pilih jenis rekening, atau Beranda → Setor',
                        <>
                          Masukkan nominal → <strong>Lanjut Bayar</strong>
                        </>,
                        'Selesaikan pembayaran di layar Xendit',
                        'Saldo bertambah setelah status pembayaran sukses',
                      ]}
                    />
                    <Callout>
                      Penarikan tunai hanya lewat POS Teller di web, bukan dari
                      mobile.
                    </Callout>
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="pinjaman-m">
                  <AccordionTrigger>Ajukan pinjaman & bayar angsuran</AccordionTrigger>
                  <AccordionContent className="space-y-3">
                    <StepList
                      steps={[
                        'Pastikan rekening pencairan sudah diisi',
                        <>
                          Tab Pinjaman → <strong>Ajukan</strong>
                        </>,
                        <>
                          Isi jumlah (min. Rp 100.000), tenor 3–24 bulan, tujuan
                        </>,
                        <>
                          Cek estimasi angsuran → <strong>Ajukan Sekarang</strong>
                        </>,
                      ]}
                    />
                    <Callout>
                      Tidak bisa mengajukan jika masih ada pinjaman Menunggu
                      Persetujuan, Menunggu Pencairan, atau Aktif.
                    </Callout>
                    <p className="text-sm font-medium">Bayar angsuran</p>
                    <StepList
                      steps={[
                        'Buka detail pinjaman berstatus Aktif',
                        <>
                          Tekan <strong>Bayar</strong> pada angsuran yang belum
                          lunas
                        </>,
                        'Selesaikan di layar Pembayaran (Xendit)',
                      ]}
                    />
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="bayar">
                  <AccordionTrigger>Layar Pembayaran (Xendit)</AccordionTrigger>
                  <AccordionContent>
                    <BulletList
                      items={[
                        'Bayar via QRIS / VA sesuai opsi di halaman Xendit',
                        <>
                          Gunakan <strong>Cek Status</strong> atau{' '}
                          <strong>Saya Sudah Bayar</strong> jika belum update
                        </>,
                        'Jangan tutup layar sebelum pembayaran selesai',
                      ]}
                    />
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="notif">
                  <AccordionTrigger>Notifikasi</AccordionTrigger>
                  <AccordionContent>
                    <BulletList
                      items={[
                        'Ikon lonceng di Beranda',
                        'Contoh: pengajuan diterima, pinjaman disetujui/ditolak, pengingat angsuran, pembayaran diterima',
                      ]}
                    />
                  </AccordionContent>
                </AccordionItem>
              </Accordion>
            </CardContent>
          </Card>
        </TabsContent>

        {/* —— ALUR —— */}
        <TabsContent value="alur" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Alur bisnis</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4 text-sm">
              <div>
                <p className="mb-1 font-medium">Keanggotaan</p>
                <p className="text-muted-foreground font-mono text-xs leading-relaxed">
                  Daftar (mobile) → Menunggu → Pengurus Aktifkan → Aktif
                  <br />
                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;→ atau Tolak → Ditolak
                </p>
              </div>
              <div>
                <p className="mb-1 font-medium">Pinjaman</p>
                <p className="text-muted-foreground font-mono text-xs leading-relaxed">
                  Ajukan → Menunggu → Setujui → Menunggu Pencairan → Cairkan
                  Xendit → Aktif → Lunas
                  <br />
                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;→ atau Tolak → Ditolak
                </p>
              </div>
              <div>
                <p className="mb-1 font-medium">Setoran & angsuran</p>
                <BulletList
                  items={[
                    'Online: anggota bayar via Xendit di mobile',
                    'Tunai: teller/pengurus lewat POS Teller atau Bayar Tunai',
                  ]}
                />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Status pinjaman</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Status</TableHead>
                    <TableHead>Arti</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {[
                    ['Menunggu', 'Pengajuan menunggu keputusan pengurus'],
                    ['Menunggu Pencairan', 'Disetujui, menunggu transfer dana'],
                    ['Aktif', 'Dana sudah cair; angsuran bisa dibayar'],
                    ['Ditolak', 'Pengajuan tidak disetujui'],
                    ['Lunas', 'Semua angsuran sudah dibayar'],
                  ].map(([status, arti]) => (
                    <TableRow key={status}>
                      <TableCell>
                        <Badge variant="secondary">{status}</Badge>
                      </TableCell>
                      <TableCell className="text-muted-foreground text-sm">
                        {arti}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Status anggota</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex flex-wrap gap-2">
                <Badge className="bg-amber-100 text-amber-700 hover:bg-amber-100">
                  Menunggu
                </Badge>
                <Badge className="bg-green-100 text-green-700 hover:bg-green-100">
                  Aktif
                </Badge>
                <Badge variant="secondary">Nonaktif</Badge>
                <Badge variant="destructive">Ditolak</Badge>
              </div>
              <p className="text-muted-foreground mt-3 text-sm">
                Jenis simpanan: <strong>Pokok</strong>, <strong>Wajib</strong>,{' '}
                <strong>Sukarela</strong>. Estimasi jasa pinjaman flat 1,5%/bulan.
              </p>
            </CardContent>
          </Card>
        </TabsContent>

        {/* —— FAQ —— */}
        <TabsContent value="faq" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Pertanyaan umum</CardTitle>
            </CardHeader>
            <CardContent>
              <Accordion type="multiple" defaultValue={['cair']}>
                <AccordionItem value="cair">
                  <AccordionTrigger>
                    Mengapa tidak bisa cairkan pinjaman?
                  </AccordionTrigger>
                  <AccordionContent className="text-muted-foreground text-sm">
                    Pastikan status pinjaman <strong>Menunggu Pencairan</strong>{' '}
                    dan rekening bank anggota sudah lengkap (bank, no. rekening,
                    nama pemilik).
                  </AccordionContent>
                </AccordionItem>
                <AccordionItem value="akses">
                  <AccordionTrigger>
                    Mengapa anggota ditolak masuk web?
                  </AccordionTrigger>
                  <AccordionContent className="text-muted-foreground text-sm">
                    Dashboard hanya untuk pengurus/teller. Anggota memakai
                    aplikasi mobile.
                  </AccordionContent>
                </AccordionItem>
                <AccordionItem value="saldo">
                  <AccordionTrigger>
                    Saldo belum bertambah setelah bayar?
                  </AccordionTrigger>
                  <AccordionContent className="text-muted-foreground text-sm">
                    Tunggu konfirmasi di layar Pembayaran, atau tekan Cek Status
                    / Saya Sudah Bayar. Hubungi pengurus jika tetap pending
                    setelah pembayaran berhasil.
                  </AccordionContent>
                </AccordionItem>
                <AccordionItem value="tarik">
                  <AccordionTrigger>
                    Bisa tarik simpanan dari mobile?
                  </AccordionTrigger>
                  <AccordionContent className="text-muted-foreground text-sm">
                    Tidak. Penarikan dilakukan teller/pengurus di menu{' '}
                    <strong>POS Teller</strong>.
                  </AccordionContent>
                </AccordionItem>
              </Accordion>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Akun demo (seed lokal)</CardTitle>
              <CardDescription>Password semua: password123</CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Email</TableHead>
                    <TableHead>Peran</TableHead>
                    <TableHead>Aplikasi</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  <TableRow>
                    <TableCell className="font-mono text-xs">
                      pengurus@koperasi.test
                    </TableCell>
                    <TableCell>Pengurus</TableCell>
                    <TableCell>Web</TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell className="font-mono text-xs">
                      teller@koperasi.test
                    </TableCell>
                    <TableCell>Teller</TableCell>
                    <TableCell>Web</TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell className="font-mono text-xs">
                      budi@koperasi.test
                    </TableCell>
                    <TableCell>Anggota</TableCell>
                    <TableCell>Mobile</TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell className="font-mono text-xs">
                      siti@koperasi.test
                    </TableCell>
                    <TableCell>Anggota</TableCell>
                    <TableCell>Mobile</TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
