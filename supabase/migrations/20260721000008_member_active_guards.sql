-- ============================================================
-- Guard: anggota harus status 'active' untuk ajukan pinjaman
-- & setor/tarik tunai. Update RPC terkait.
-- ============================================================

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
  v_status member_status;
begin
  if not is_teller() then
    raise exception 'Hanya teller/pengurus yang boleh mencatat setoran tunai';
  end if;

  select status into v_status from members where id = p_member_id;
  if v_status is null then
    raise exception 'Anggota tidak ditemukan';
  end if;
  if v_status <> 'active' then
    raise exception 'Anggota belum aktif. Status saat ini: %', v_status;
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
  v_status member_status;
begin
  if not is_teller() then
    raise exception 'Hanya teller/pengurus yang boleh mencatat penarikan tunai';
  end if;

  select status into v_status from members where id = p_member_id;
  if v_status is null then
    raise exception 'Anggota tidak ditemukan';
  end if;
  if v_status <> 'active' then
    raise exception 'Anggota belum aktif. Status saat ini: %', v_status;
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
  v_status member_status;
begin
  v_member_id := current_member_id();
  if v_member_id is null then
    raise exception 'Anggota tidak ditemukan / belum terdaftar';
  end if;

  select status into v_status from members where id = v_member_id;
  if v_status <> 'active' then
    raise exception 'Keanggotaan belum aktif. Menunggu verifikasi pengurus.';
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
