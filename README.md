# Koperasi Simpan Pinjam POS

Aplikasi POS untuk Koperasi Simpan Pinjam. Terdiri dari:

- `mobile/` — Aplikasi anggota (Flutter). Lihat saldo simpanan, ajukan pinjaman, bayar angsuran, notifikasi.
- `web/` — Dashboard pengurus/teller (Next.js). Kelola anggota, approval pinjaman, mode POS teller, laporan.
- `supabase/` — Database Postgres, migrations, RLS policies, seed, dan Edge Functions.
- `docs/` — Dokumentasi setup, ERD, dan panduan menjalankan.

## Tech Stack

| Layer     | Teknologi                                             |
| --------- | ----------------------------------------------------- |
| Mobile    | Flutter 3, Riverpod, go_router, supabase_flutter      |
| Web       | Next.js (App Router), Tailwind, shadcn/ui, Recharts, @supabase/ssr |
| Backend   | Supabase (Postgres, Auth, Storage, Realtime, Edge Functions) |
| Payment   | Xendit Invoice, abstraksi `PaymentProvider`          |
| Notifikasi| Firebase Cloud Messaging (FCM) + `pg_cron`            |

## Quick Start

Lihat panduan lengkap di [`docs/SETUP.md`](docs/SETUP.md).

Ringkas:

```bash
# 1. Jalankan Supabase lokal (butuh Docker)
npx supabase start
npx supabase db reset   # apply migrations + seed

# 2. Web
cd web && cp .env.local.example .env.local   # isi kredensial
npm run dev

# 3. Mobile
cd mobile && cp .env.example .env             # isi kredensial
flutter run --dart-define-from-file=.env
```

## Roles

- **anggota** — akses via mobile app.
- **teller** — akses via web (mode POS, catat setor/tarik tunai).
- **pengurus** — akses via web (approval pinjaman, laporan, kelola anggota).

## Struktur Biaya (Supabase)

- **Free**: $0 — cukup untuk MVP & development.
- **Pro**: ~$25/bln — production awal (8GB DB, 100k MAU, daily backup, no auto-pause).
- Bisa **self-host** (open source) untuk menghindari vendor lock-in.
