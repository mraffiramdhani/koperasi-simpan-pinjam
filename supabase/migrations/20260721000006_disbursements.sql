-- ============================================================
-- Pencairan pinjaman via Xendit Disbursement
-- ============================================================

create type disbursement_status as enum ('pending', 'processing', 'completed', 'failed');

-- ---------- Rekening bank anggota (tujuan pencairan) ----------
alter table members
  add column bank_code text,
  add column account_number text,
  add column account_holder_name text;

-- ---------- DISBURSEMENTS ----------
create table disbursements (
  id                   uuid primary key default gen_random_uuid(),
  loan_id              uuid not null references loans (id) on delete cascade,
  member_id            uuid not null references members (id) on delete cascade,
  external_id          text unique not null,
  provider             text not null default 'xendit',
  provider_ref         text,
  amount               numeric(14, 2) not null check (amount > 0),
  bank_code            text not null,
  account_number       text not null,
  account_holder_name  text not null,
  status               disbursement_status not null default 'pending',
  raw_payload          jsonb,
  created_by           uuid references auth.users (id),
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

create index idx_disbursements_loan on disbursements (loan_id);
create index idx_disbursements_member on disbursements (member_id);
create index idx_disbursements_status on disbursements (status);

-- Hanya satu pencairan yang sedang berjalan/berhasil per pinjaman
create unique index uq_disbursements_active_per_loan on disbursements (loan_id)
  where status in ('pending', 'processing', 'completed');

create trigger trg_disbursements_touch before update on disbursements
  for each row execute function touch_updated_at();

-- ---------- RLS ----------
alter table disbursements enable row level security;

create policy disbursements_select on disbursements
  for select using (
    member_id = current_member_id() or is_staff()
  );

-- Insert/update dilakukan lewat Edge Functions (service role, bypass RLS).

-- ---------- Perbaikan alur status pinjaman ----------
-- rpc_approve_pinjaman() sekarang menandai pinjaman sebagai 'approved'
-- (menunggu pencairan) bukan 'active'. Status 'active' baru diset saat
-- pencairan (disbursement) sukses, lihat Edge Function disbursement-webhook.
create or replace function rpc_approve_pinjaman(p_loan_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_loan loans%rowtype;
  v_pokok_per_bulan numeric(14, 2);
  v_jasa_per_bulan numeric(14, 2);
  i int;
begin
  if not is_pengurus() then
    raise exception 'Hanya pengurus yang boleh menyetujui pinjaman';
  end if;

  select * into v_loan from loans where id = p_loan_id for update;
  if v_loan.id is null then
    raise exception 'Pinjaman tidak ditemukan';
  end if;
  if v_loan.status <> 'pengajuan' then
    raise exception 'Pinjaman tidak dalam status pengajuan';
  end if;

  -- Jasa flat per bulan dari pokok awal
  v_pokok_per_bulan := round(v_loan.pokok / v_loan.tenor, 2);
  v_jasa_per_bulan := round(v_loan.pokok * v_loan.jasa_persen / 100, 2);

  for i in 1..v_loan.tenor loop
    insert into loan_installments
      (loan_id, angsuran_ke, jatuh_tempo, nominal_pokok, nominal_jasa, total)
    values
      (p_loan_id, i, (now()::date + (i || ' month')::interval)::date,
       v_pokok_per_bulan, v_jasa_per_bulan, v_pokok_per_bulan + v_jasa_per_bulan);
  end loop;

  update loans
     set status = 'approved', approved_by = auth.uid(), approved_at = now()
   where id = p_loan_id;

  insert into notifications (member_id, judul, isi, tipe)
  values (v_loan.member_id, 'Pinjaman Disetujui',
          'Pinjaman Anda telah disetujui dan sedang menunggu pencairan dana.', 'pinjaman');

  insert into audit_log (actor, action, entity, entity_id, payload)
  values (auth.uid(), 'approve_pinjaman', 'loans', p_loan_id,
          jsonb_build_object('pokok', v_loan.pokok, 'tenor', v_loan.tenor));
end;
$$;

-- Pinjaman yang masih bisa diajukan ulang: tambahkan 'approved' ke daftar
-- status yang menahan pengajuan baru (sudah tercakup karena existing check
-- memakai status in ('pengajuan', 'approved', 'active')).
