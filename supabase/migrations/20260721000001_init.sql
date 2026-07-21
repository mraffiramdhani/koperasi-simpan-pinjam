-- ============================================================
-- Koperasi Simpan Pinjam POS - Skema Awal
-- ============================================================

create extension if not exists "pgcrypto";

-- ---------- ENUMS ----------
create type member_status as enum ('pending', 'active', 'inactive', 'rejected');
create type savings_type as enum ('pokok', 'wajib', 'sukarela');
create type savings_txn_type as enum ('setor', 'tarik');
create type payment_method as enum ('cash', 'gateway');
create type loan_status as enum ('pengajuan', 'approved', 'rejected', 'active', 'lunas');
create type installment_status as enum ('belum', 'lunas', 'telat');
create type payment_status as enum ('pending', 'paid', 'failed', 'expired');
create type payment_purpose as enum ('simpanan', 'angsuran');
create type staff_role as enum ('teller', 'pengurus');
create type notification_type as enum ('info', 'angsuran', 'pinjaman', 'pembayaran');

-- ---------- STAFF ----------
create table staff_roles (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  role        staff_role not null,
  nama        text not null,
  created_at  timestamptz not null default now()
);

-- ---------- MEMBERS (anggota) ----------
create table members (
  id             uuid primary key default gen_random_uuid(),
  no_anggota     text unique,
  user_id        uuid unique references auth.users (id) on delete set null,
  nama           text not null,
  nik            text,
  alamat         text,
  phone          text,
  foto_ktp_path  text,
  fcm_token      text,
  status         member_status not null default 'pending',
  tanggal_gabung date,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index idx_members_user_id on members (user_id);
create index idx_members_status on members (status);

-- Nomor anggota otomatis: KSP-YYYY-000001
create sequence if not exists member_no_seq;

create or replace function set_member_no()
returns trigger language plpgsql as $$
begin
  if new.no_anggota is null then
    new.no_anggota := 'KSP-' || to_char(now(), 'YYYY') || '-' ||
                      lpad(nextval('member_no_seq')::text, 6, '0');
  end if;
  return new;
end;
$$;

create trigger trg_set_member_no
  before insert on members
  for each row execute function set_member_no();

-- ---------- SAVINGS (simpanan) ----------
create table savings_accounts (
  id         uuid primary key default gen_random_uuid(),
  member_id  uuid not null references members (id) on delete cascade,
  tipe       savings_type not null,
  saldo      numeric(14, 2) not null default 0,
  created_at timestamptz not null default now(),
  unique (member_id, tipe)
);

create index idx_savings_accounts_member on savings_accounts (member_id);

-- Buat 3 rekening simpanan otomatis saat anggota dibuat
create or replace function create_default_savings()
returns trigger language plpgsql as $$
begin
  insert into savings_accounts (member_id, tipe)
  values (new.id, 'pokok'), (new.id, 'wajib'), (new.id, 'sukarela');
  return new;
end;
$$;

create trigger trg_create_default_savings
  after insert on members
  for each row execute function create_default_savings();

create table savings_transactions (
  id          uuid primary key default gen_random_uuid(),
  account_id  uuid not null references savings_accounts (id) on delete cascade,
  member_id   uuid not null references members (id) on delete cascade,
  jenis       savings_txn_type not null,
  nominal     numeric(14, 2) not null check (nominal > 0),
  metode      payment_method not null default 'cash',
  payment_id  uuid,
  keterangan  text,
  created_by  uuid references auth.users (id),
  created_at  timestamptz not null default now()
);

create index idx_savings_txn_member on savings_transactions (member_id);
create index idx_savings_txn_account on savings_transactions (account_id);

-- Update saldo rekening otomatis
create or replace function apply_savings_txn()
returns trigger language plpgsql as $$
declare
  cur_saldo numeric(14, 2);
begin
  select saldo into cur_saldo from savings_accounts where id = new.account_id for update;
  if new.jenis = 'setor' then
    update savings_accounts set saldo = saldo + new.nominal where id = new.account_id;
  else
    if cur_saldo < new.nominal then
      raise exception 'Saldo tidak cukup untuk penarikan (saldo: %, minta: %)', cur_saldo, new.nominal;
    end if;
    update savings_accounts set saldo = saldo - new.nominal where id = new.account_id;
  end if;
  return new;
end;
$$;

create trigger trg_apply_savings_txn
  after insert on savings_transactions
  for each row execute function apply_savings_txn();

-- ---------- LOANS (pinjaman) ----------
create table loans (
  id               uuid primary key default gen_random_uuid(),
  member_id        uuid not null references members (id) on delete cascade,
  pokok            numeric(14, 2) not null check (pokok > 0),
  tenor            int not null check (tenor > 0),
  jasa_persen      numeric(5, 2) not null default 1.5,  -- jasa flat per bulan (%)
  tujuan           text,
  status           loan_status not null default 'pengajuan',
  tanggal_pengajuan timestamptz not null default now(),
  approved_by      uuid references auth.users (id),
  approved_at      timestamptz,
  created_at       timestamptz not null default now()
);

create index idx_loans_member on loans (member_id);
create index idx_loans_status on loans (status);

create table loan_installments (
  id            uuid primary key default gen_random_uuid(),
  loan_id       uuid not null references loans (id) on delete cascade,
  angsuran_ke   int not null,
  jatuh_tempo   date not null,
  nominal_pokok numeric(14, 2) not null,
  nominal_jasa  numeric(14, 2) not null,
  total         numeric(14, 2) not null,
  status        installment_status not null default 'belum',
  paid_at       timestamptz,
  payment_id    uuid,
  unique (loan_id, angsuran_ke)
);

create index idx_installments_loan on loan_installments (loan_id);
create index idx_installments_due on loan_installments (jatuh_tempo);
create index idx_installments_status on loan_installments (status);

-- ---------- PAYMENTS (gateway) ----------
create table payments (
  id                uuid primary key default gen_random_uuid(),
  member_id         uuid not null references members (id) on delete cascade,
  purpose           payment_purpose not null,
  ref_id            uuid not null,  -- installment id atau savings_account id
  provider          text not null default 'midtrans',
  order_id          text unique not null,
  external_id       text,
  nominal           numeric(14, 2) not null check (nominal > 0),
  status            payment_status not null default 'pending',
  snap_token        text,
  snap_redirect_url text,
  raw_payload       jsonb,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index idx_payments_member on payments (member_id);
create index idx_payments_status on payments (status);

-- ---------- NOTIFICATIONS ----------
create table notifications (
  id         uuid primary key default gen_random_uuid(),
  member_id  uuid not null references members (id) on delete cascade,
  judul      text not null,
  isi        text not null,
  tipe       notification_type not null default 'info',
  read_at    timestamptz,
  created_at timestamptz not null default now()
);

create index idx_notifications_member on notifications (member_id);

-- ---------- AUDIT LOG ----------
create table audit_log (
  id         uuid primary key default gen_random_uuid(),
  actor      uuid references auth.users (id),
  action     text not null,
  entity     text not null,
  entity_id  uuid,
  payload    jsonb,
  created_at timestamptz not null default now()
);

-- ---------- updated_at helper ----------
create or replace function touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger trg_members_touch before update on members
  for each row execute function touch_updated_at();
create trigger trg_payments_touch before update on payments
  for each row execute function touch_updated_at();
