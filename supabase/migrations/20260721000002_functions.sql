-- ============================================================
-- Helper functions + RPC (semua perhitungan keuangan server-side)
-- ============================================================

-- ---------- HELPERS (dipakai juga oleh RLS) ----------
create or replace function current_member_id()
returns uuid language sql stable security definer set search_path = public as $$
  select id from members where user_id = auth.uid();
$$;

create or replace function is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from staff_roles where user_id = auth.uid());
$$;

create or replace function is_pengurus()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from staff_roles where user_id = auth.uid() and role = 'pengurus');
$$;

create or replace function is_teller()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from staff_roles where user_id = auth.uid() and role in ('teller', 'pengurus'));
$$;

-- ---------- SIMPANAN: setor (teller/pengurus, tunai) ----------
create or replace function rpc_setor_tunai(
  p_member_id uuid,
  p_tipe savings_type,
  p_nominal numeric,
  p_keterangan text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_account_id uuid;
  v_txn_id uuid;
begin
  if not is_teller() then
    raise exception 'Hanya teller/pengurus yang boleh mencatat setoran tunai';
  end if;

  select id into v_account_id from savings_accounts
    where member_id = p_member_id and tipe = p_tipe;
  if v_account_id is null then
    raise exception 'Rekening simpanan tidak ditemukan';
  end if;

  insert into savings_transactions (account_id, member_id, jenis, nominal, metode, keterangan, created_by)
  values (v_account_id, p_member_id, 'setor', p_nominal, 'cash', p_keterangan, auth.uid())
  returning id into v_txn_id;

  insert into audit_log (actor, action, entity, entity_id, payload)
  values (auth.uid(), 'setor_tunai', 'savings_transactions', v_txn_id,
          jsonb_build_object('member_id', p_member_id, 'tipe', p_tipe, 'nominal', p_nominal));

  return v_txn_id;
end;
$$;

-- ---------- SIMPANAN: tarik (teller/pengurus, tunai) ----------
create or replace function rpc_tarik_tunai(
  p_member_id uuid,
  p_tipe savings_type,
  p_nominal numeric,
  p_keterangan text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_account_id uuid;
  v_txn_id uuid;
begin
  if not is_teller() then
    raise exception 'Hanya teller/pengurus yang boleh mencatat penarikan tunai';
  end if;

  select id into v_account_id from savings_accounts
    where member_id = p_member_id and tipe = p_tipe;
  if v_account_id is null then
    raise exception 'Rekening simpanan tidak ditemukan';
  end if;

  insert into savings_transactions (account_id, member_id, jenis, nominal, metode, keterangan, created_by)
  values (v_account_id, p_member_id, 'tarik', p_nominal, 'cash', p_keterangan, auth.uid())
  returning id into v_txn_id;

  insert into audit_log (actor, action, entity, entity_id, payload)
  values (auth.uid(), 'tarik_tunai', 'savings_transactions', v_txn_id,
          jsonb_build_object('member_id', p_member_id, 'tipe', p_tipe, 'nominal', p_nominal));

  return v_txn_id;
end;
$$;

-- ---------- PINJAMAN: pengajuan oleh anggota ----------
create or replace function rpc_ajukan_pinjaman(
  p_pokok numeric,
  p_tenor int,
  p_tujuan text default null,
  p_jasa_persen numeric default 1.5
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_member_id uuid;
  v_loan_id uuid;
  v_active_count int;
begin
  v_member_id := current_member_id();
  if v_member_id is null then
    raise exception 'Anggota tidak ditemukan / belum terdaftar';
  end if;

  select count(*) into v_active_count from loans
    where member_id = v_member_id and status in ('pengajuan', 'approved', 'active');
  if v_active_count > 0 then
    raise exception 'Masih ada pinjaman aktif / pengajuan yang belum selesai';
  end if;

  insert into loans (member_id, pokok, tenor, jasa_persen, tujuan)
  values (v_member_id, p_pokok, p_tenor, p_jasa_persen, p_tujuan)
  returning id into v_loan_id;

  insert into notifications (member_id, judul, isi, tipe)
  values (v_member_id, 'Pengajuan Pinjaman Diterima',
          'Pengajuan pinjaman sebesar Rp ' || to_char(p_pokok, 'FM999,999,999') || ' sedang diproses.',
          'pinjaman');

  return v_loan_id;
end;
$$;

-- ---------- PINJAMAN: approve (pengurus) + generate jadwal angsuran ----------
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
     set status = 'active', approved_by = auth.uid(), approved_at = now()
   where id = p_loan_id;

  insert into notifications (member_id, judul, isi, tipe)
  values (v_loan.member_id, 'Pinjaman Disetujui',
          'Pinjaman Anda telah disetujui. Silakan cek jadwal angsuran.', 'pinjaman');

  insert into audit_log (actor, action, entity, entity_id, payload)
  values (auth.uid(), 'approve_pinjaman', 'loans', p_loan_id,
          jsonb_build_object('pokok', v_loan.pokok, 'tenor', v_loan.tenor));
end;
$$;

-- ---------- PINJAMAN: reject (pengurus) ----------
create or replace function rpc_reject_pinjaman(p_loan_id uuid, p_alasan text default null)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_member uuid;
begin
  if not is_pengurus() then
    raise exception 'Hanya pengurus yang boleh menolak pinjaman';
  end if;

  update loans set status = 'rejected'
   where id = p_loan_id and status = 'pengajuan'
  returning member_id into v_member;

  if v_member is null then
    raise exception 'Pinjaman tidak ditemukan / tidak dalam status pengajuan';
  end if;

  insert into notifications (member_id, judul, isi, tipe)
  values (v_member, 'Pengajuan Pinjaman Ditolak',
          coalesce(p_alasan, 'Pengajuan pinjaman Anda tidak dapat disetujui saat ini.'), 'pinjaman');
end;
$$;

-- ---------- ANGSURAN: bayar tunai (teller) ----------
create or replace function rpc_bayar_angsuran_tunai(p_installment_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_loan_id uuid;
  v_sisa int;
  v_member uuid;
begin
  if not is_teller() then
    raise exception 'Hanya teller/pengurus yang boleh mencatat pembayaran tunai';
  end if;

  update loan_installments
     set status = 'lunas', paid_at = now()
   where id = p_installment_id and status <> 'lunas'
  returning loan_id into v_loan_id;

  if v_loan_id is null then
    raise exception 'Angsuran tidak ditemukan / sudah lunas';
  end if;

  select count(*) into v_sisa from loan_installments
    where loan_id = v_loan_id and status <> 'lunas';
  if v_sisa = 0 then
    update loans set status = 'lunas' where id = v_loan_id
      returning member_id into v_member;
    insert into notifications (member_id, judul, isi, tipe)
    values (v_member, 'Pinjaman Lunas', 'Selamat! Pinjaman Anda telah lunas.', 'pinjaman');
  end if;
end;
$$;

-- ---------- DASHBOARD: ringkasan agregat (staff) ----------
create or replace function get_dashboard_summary()
returns json
language plpgsql security definer set search_path = public as $$
declare
  result json;
begin
  if not is_staff() then
    raise exception 'Akses ditolak';
  end if;

  select json_build_object(
    'total_anggota', (select count(*) from members where status = 'active'),
    'anggota_pending', (select count(*) from members where status = 'pending'),
    'total_simpanan', (select coalesce(sum(saldo), 0) from savings_accounts),
    'simpanan_per_tipe', (
      select json_object_agg(tipe, total) from (
        select tipe, coalesce(sum(saldo), 0) as total
        from savings_accounts group by tipe
      ) s
    ),
    'pinjaman_aktif', (select count(*) from loans where status = 'active'),
    'outstanding_pinjaman', (
      select coalesce(sum(total), 0) from loan_installments where status <> 'lunas'
    ),
    'tunggakan', (
      select coalesce(sum(total), 0) from loan_installments
      where status <> 'lunas' and jatuh_tempo < now()::date
    ),
    'pengajuan_pending', (select count(*) from loans where status = 'pengajuan')
  ) into result;

  return result;
end;
$$;
