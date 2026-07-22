-- ============================================================
-- Seed data untuk development lokal
-- Login semua akun: password123
--   pengurus@koperasi.test  (pengurus)
--   teller@koperasi.test    (teller)
--   budi@koperasi.test      (anggota)
--   siti@koperasi.test      (anggota)
-- ============================================================

-- ---------- AUTH USERS ----------
-- Token fields harus '' (bukan NULL), kalau tidak GoTrue cloud error:
-- "Database error querying schema"
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
values
  ('00000000-0000-0000-0000-000000000000', '11111111-1111-1111-1111-111111111111',
   'authenticated', 'authenticated', 'pengurus@koperasi.test',
   crypt('password123', gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{"nama":"Pengurus Koperasi"}', now(), now(),
   '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '22222222-2222-2222-2222-222222222222',
   'authenticated', 'authenticated', 'teller@koperasi.test',
   crypt('password123', gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{"nama":"Teller Kasir"}', now(), now(),
   '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '33333333-3333-3333-3333-333333333333',
   'authenticated', 'authenticated', 'budi@koperasi.test',
   crypt('password123', gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{"nama":"Budi Santoso"}', now(), now(),
   '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '44444444-4444-4444-4444-444444444444',
   'authenticated', 'authenticated', 'siti@koperasi.test',
   crypt('password123', gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{"nama":"Siti Aminah"}', now(), now(),
   '', '', '', '');

insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
values
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
   '{"sub":"11111111-1111-1111-1111-111111111111","email":"pengurus@koperasi.test"}', 'email', now(), now(), now()),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222',
   '{"sub":"22222222-2222-2222-2222-222222222222","email":"teller@koperasi.test"}', 'email', now(), now(), now()),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', '33333333-3333-3333-3333-333333333333',
   '{"sub":"33333333-3333-3333-3333-333333333333","email":"budi@koperasi.test"}', 'email', now(), now(), now()),
  (gen_random_uuid(), '44444444-4444-4444-4444-444444444444', '44444444-4444-4444-4444-444444444444',
   '{"sub":"44444444-4444-4444-4444-444444444444","email":"siti@koperasi.test"}', 'email', now(), now(), now());

-- ---------- STAFF ----------
insert into staff_roles (user_id, role, nama) values
  ('11111111-1111-1111-1111-111111111111', 'pengurus', 'Pengurus Koperasi'),
  ('22222222-2222-2222-2222-222222222222', 'teller', 'Teller Kasir');

-- ---------- MEMBERS (trigger membuat rekening simpanan otomatis) ----------
insert into members (id, no_anggota, user_id, nama, nik, alamat, phone, status, tanggal_gabung,
  bank_code, account_number, account_holder_name) values
  ('a0000000-0000-0000-0000-000000000001', 'KSP-2026-000001', '33333333-3333-3333-3333-333333333333',
   'Budi Santoso', '3201010101010001', 'Jl. Merdeka No. 1, Jakarta', '081200000001', 'active', '2026-01-10',
   'BCA', '1234567890', 'Budi Santoso'),
  ('a0000000-0000-0000-0000-000000000002', 'KSP-2026-000002', '44444444-4444-4444-4444-444444444444',
   'Siti Aminah', '3201010101010002', 'Jl. Melati No. 2, Bandung', '081200000002', 'active', '2026-02-15',
   'BNI', '0987654321', 'Siti Aminah');

-- ---------- SIMPANAN (trigger otomatis update saldo) ----------
-- Budi
insert into savings_transactions (account_id, member_id, jenis, nominal, metode, keterangan, created_by)
select id, 'a0000000-0000-0000-0000-000000000001', 'setor', 100000, 'cash', 'Simpanan pokok awal',
  '22222222-2222-2222-2222-222222222222'
from savings_accounts where member_id = 'a0000000-0000-0000-0000-000000000001' and tipe = 'pokok';
insert into savings_transactions (account_id, member_id, jenis, nominal, metode, keterangan, created_by)
select id, 'a0000000-0000-0000-0000-000000000001', 'setor', 150000, 'cash', 'Simpanan wajib',
  '22222222-2222-2222-2222-222222222222'
from savings_accounts where member_id = 'a0000000-0000-0000-0000-000000000001' and tipe = 'wajib';
insert into savings_transactions (account_id, member_id, jenis, nominal, metode, keterangan, created_by)
select id, 'a0000000-0000-0000-0000-000000000001', 'setor', 500000, 'gateway', 'Top up sukarela',
  '22222222-2222-2222-2222-222222222222'
from savings_accounts where member_id = 'a0000000-0000-0000-0000-000000000001' and tipe = 'sukarela';

-- Siti
insert into savings_transactions (account_id, member_id, jenis, nominal, metode, keterangan, created_by)
select id, 'a0000000-0000-0000-0000-000000000002', 'setor', 100000, 'cash', 'Simpanan pokok awal',
  '22222222-2222-2222-2222-222222222222'
from savings_accounts where member_id = 'a0000000-0000-0000-0000-000000000002' and tipe = 'pokok';
insert into savings_transactions (account_id, member_id, jenis, nominal, metode, keterangan, created_by)
select id, 'a0000000-0000-0000-0000-000000000002', 'setor', 300000, 'cash', 'Simpanan wajib',
  '22222222-2222-2222-2222-222222222222'
from savings_accounts where member_id = 'a0000000-0000-0000-0000-000000000002' and tipe = 'wajib';

-- ---------- PINJAMAN (Budi, aktif dengan jadwal angsuran) ----------
insert into loans (id, member_id, pokok, tenor, jasa_persen, tujuan, status, approved_by, approved_at)
values ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001',
        3000000, 6, 1.5, 'Modal usaha warung', 'active',
        '11111111-1111-1111-1111-111111111111', now() - interval '2 month');

-- Pencairan sudah selesai (sesuai status pinjaman 'active')
insert into disbursements (loan_id, member_id, external_id, provider_ref, amount,
  bank_code, account_number, account_holder_name, status, created_by)
values ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001',
        'KSP-DSB-seed-0001', 'seed-provider-ref-0001', 3000000,
        'BCA', '1234567890', 'Budi Santoso', 'completed',
        '11111111-1111-1111-1111-111111111111');

-- Jadwal angsuran: pokok/bln = 500000, jasa/bln = 45000, total = 545000
-- Angsuran 1 lunas, angsuran 2 telat (menunggak), sisanya belum
insert into loan_installments (loan_id, angsuran_ke, jatuh_tempo, nominal_pokok, nominal_jasa, total, status, paid_at)
values
  ('b0000000-0000-0000-0000-000000000001', 1, (now() - interval '1 month')::date, 500000, 45000, 545000, 'lunas', now() - interval '1 month'),
  ('b0000000-0000-0000-0000-000000000001', 2, (now() - interval '2 day')::date,   500000, 45000, 545000, 'telat', null),
  ('b0000000-0000-0000-0000-000000000001', 3, (now() + interval '1 month')::date,  500000, 45000, 545000, 'belum', null),
  ('b0000000-0000-0000-0000-000000000001', 4, (now() + interval '2 month')::date,  500000, 45000, 545000, 'belum', null),
  ('b0000000-0000-0000-0000-000000000001', 5, (now() + interval '3 month')::date,  500000, 45000, 545000, 'belum', null),
  ('b0000000-0000-0000-0000-000000000001', 6, (now() + interval '4 month')::date,  500000, 45000, 545000, 'belum', null);

-- ---------- NOTIFIKASI contoh ----------
insert into notifications (member_id, judul, isi, tipe) values
  ('a0000000-0000-0000-0000-000000000001', 'Angsuran Jatuh Tempo',
   'Angsuran ke-2 pinjaman Anda telah jatuh tempo. Segera lakukan pembayaran.', 'angsuran');
