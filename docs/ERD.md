# Entity Relationship Diagram

Skema database Koperasi Simpan Pinjam (Postgres/Supabase).

```mermaid
erDiagram
  auth_users ||--o| members : "user_id"
  auth_users ||--o| staff_roles : "user_id"
  members ||--o{ savings_accounts : "member_id"
  members ||--o{ savings_transactions : "member_id"
  members ||--o{ loans : "member_id"
  members ||--o{ payments : "member_id"
  members ||--o{ notifications : "member_id"
  savings_accounts ||--o{ savings_transactions : "account_id"
  loans ||--o{ loan_installments : "loan_id"
  payments ||--o| savings_transactions : "payment_id"
  payments ||--o| loan_installments : "payment_id"

  members {
    uuid id PK
    text no_anggota
    uuid user_id FK
    text nama
    text nik
    text phone
    text foto_ktp_path
    text fcm_token
    enum status
    date tanggal_gabung
  }

  staff_roles {
    uuid user_id PK
    enum role
    text nama
  }

  savings_accounts {
    uuid id PK
    uuid member_id FK
    enum tipe
    numeric saldo
  }

  savings_transactions {
    uuid id PK
    uuid account_id FK
    uuid member_id FK
    enum jenis
    numeric nominal
    enum metode
    uuid payment_id
  }

  loans {
    uuid id PK
    uuid member_id FK
    numeric pokok
    int tenor
    numeric jasa_persen
    enum status
    uuid approved_by
  }

  loan_installments {
    uuid id PK
    uuid loan_id FK
    int angsuran_ke
    date jatuh_tempo
    numeric total
    enum status
    uuid payment_id
  }

  payments {
    uuid id PK
    uuid member_id FK
    enum purpose
    uuid ref_id
    text order_id
    numeric nominal
    enum status
  }

  notifications {
    uuid id PK
    uuid member_id FK
    text judul
    text isi
    enum tipe
    timestamptz read_at
  }
```

## Aturan Bisnis Utama

- **Simpanan**: 3 rekening (pokok/wajib/sukarela) dibuat otomatis saat anggota
  dibuat (trigger `create_default_savings`). Saldo diupdate otomatis oleh trigger
  `apply_savings_txn` (menolak penarikan melebihi saldo).
- **Pinjaman**: pengajuan oleh anggota (`rpc_ajukan_pinjaman`), disetujui pengurus
  (`rpc_approve_pinjaman`) yang otomatis membuat jadwal angsuran (jasa flat per
  bulan dari pokok).
- **Pembayaran**: mutasi keuangan via gateway ditangani `payment-webhook` dengan
  service role (setelah verifikasi signature Midtrans). Transaksi tunai via RPC
  `rpc_setor_tunai` / `rpc_tarik_tunai` / `rpc_bayar_angsuran_tunai` (khusus staff).
- **Keamanan**: RLS memastikan anggota hanya melihat datanya sendiri; staff sesuai
  peran. Semua perhitungan uang dieksekusi server-side.
