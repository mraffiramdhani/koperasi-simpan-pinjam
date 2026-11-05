-- ============================================================
-- Data demo untuk showcase publik (jalankan setelah seed.sql)
-- Idempotent: menghapus & membuat ulang semua baris demo
-- (members.id berawalan d0000000-), data seed.sql tidak tersentuh.
--
--   npx supabase db query --remote -f supabase/demo-seed.sql
-- ============================================================

do $$
declare
  v_teller   constant uuid := '22222222-2222-2222-2222-222222222222';
  v_pengurus constant uuid := '11111111-1111-1111-1111-111111111111';
  v_names text[] := array[
    'Agus Prasetyo', 'Dewi Lestari', 'Rudi Hartono', 'Sri Wahyuni', 'Andi Saputra',
    'Rina Marlina', 'Joko Susilo', 'Fitri Handayani', 'Hendra Gunawan', 'Nurul Hidayah',
    'Bambang Setiawan', 'Yuni Kartika', 'Eko Purnomo', 'Ratna Sari', 'Dedi Kurniawan',
    'Lina Marliana', 'Wahyu Nugroho', 'Ani Rahmawati', 'Slamet Riyadi', 'Maya Anggraini',
    'Teguh Santoso', 'Indah Permata', 'Fajar Ramadhan', 'Putri Ayuningtyas'];
  v_streets text[] := array['Merdeka', 'Sudirman', 'Diponegoro', 'Melati', 'Kenanga',
    'Pahlawan', 'Gatot Subroto', 'Ahmad Yani', 'Cendana', 'Flamboyan'];
  v_cities text[] := array['Jakarta', 'Bandung', 'Bekasi', 'Bogor', 'Depok', 'Tangerang'];
  v_banks text[] := array['BCA', 'BNI', 'BRI', 'MANDIRI', 'BSI'];
  v_tujuan text[] := array['Modal usaha warung', 'Biaya pendidikan anak', 'Renovasi rumah',
    'Tambahan stok dagangan', 'Biaya kesehatan', 'Pembelian motor untuk usaha',
    'Modal usaha katering', 'Peralatan bengkel'];

  v_member uuid; v_loan uuid; v_pay uuid; v_inst uuid;
  v_pokok_acc uuid; v_wajib_acc uuid; v_sukarela_acc uuid;
  v_status member_status; v_joined timestamptz; v_t timestamptz; v_due date;
  v_bank text; v_metode payment_method; v_jenis savings_txn_type;
  v_amt numeric(14, 2); v_bal numeric(14, 2);
  v_pokok_bln numeric(14, 2); v_jasa_bln numeric(14, 2);
  v_approved timestamptz; v_ajukan timestamptz;
  v_months int; v_count int; v_last_due int;
  n int; k int; r record;
begin
  delete from members where id::text like 'd0000000-%';
  perform setseed(0.42);

  -- ---------- ANGGOTA + SIMPANAN ----------
  for n in 1 .. array_length(v_names, 1) loop
    v_member := ('d0000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid;
    v_status := case when n >= 23 then 'pending' when n = 22 then 'inactive' else 'active' end;
    v_joined := case
      when v_status = 'pending' then now() - make_interval(days => n - 20)
      when n <= 13 then now() - make_interval(days => 300 + floor(random() * 60)::int)
      else now() - make_interval(days => 30 + floor(random() * 250)::int)
    end;
    v_bank := v_banks[1 + floor(random() * array_length(v_banks, 1))::int];

    insert into members (id, no_anggota, nama, nik, alamat, phone, status, tanggal_gabung,
      bank_code, account_number, account_holder_name, created_at)
    values (
      v_member,
      'KSP-' || to_char(v_joined, 'YYYY') || '-' || lpad((100 + n)::text, 6, '0'),
      v_names[n],
      '32' || lpad(floor(random() * 1e14)::bigint::text, 14, '0'),
      'Jl. ' || v_streets[1 + floor(random() * array_length(v_streets, 1))::int]
        || ' No. ' || (1 + floor(random() * 120))::int
        || ', ' || v_cities[1 + floor(random() * array_length(v_cities, 1))::int],
      '0812' || lpad(floor(random() * 1e8)::bigint::text, 8, '0'),
      v_status,
      case when v_status = 'pending' then null else v_joined::date end,
      v_bank,
      lpad(floor(random() * 1e10)::bigint::text, 10, '0'),
      v_names[n],
      v_joined);

    continue when v_status = 'pending';

    select id into v_pokok_acc from savings_accounts where member_id = v_member and tipe = 'pokok';
    select id into v_wajib_acc from savings_accounts where member_id = v_member and tipe = 'wajib';
    select id into v_sukarela_acc from savings_accounts where member_id = v_member and tipe = 'sukarela';

    insert into savings_transactions (account_id, member_id, jenis, nominal, metode, keterangan, created_by, created_at)
    values (v_pokok_acc, v_member, 'setor', 100000, 'cash', 'Simpanan pokok', v_teller, v_joined);

    -- Simpanan wajib bulanan (anggota nonaktif berhenti setor di tengah jalan)
    v_months := floor(extract(epoch from now() - v_joined) / (30 * 86400))::int;
    if v_status = 'inactive' then v_months := v_months / 2; end if;
    for k in 0 .. v_months loop
      v_t := v_joined + make_interval(months => k, hours => floor(random() * 8)::int);
      exit when v_t > now();
      v_metode := case when random() < 0.4 then 'gateway' else 'cash' end;
      v_pay := null;
      if v_metode = 'gateway' then
        insert into payments (member_id, purpose, ref_id, order_id, nominal, status, created_at, updated_at)
        values (v_member, 'simpanan', v_wajib_acc, 'DEMO-SMP-' || replace(gen_random_uuid()::text, '-', ''),
                50000, 'paid', v_t, v_t)
        returning id into v_pay;
      end if;
      insert into savings_transactions (account_id, member_id, jenis, nominal, metode, payment_id, keterangan, created_by, created_at)
      values (v_wajib_acc, v_member, 'setor', 50000, v_metode, v_pay, 'Simpanan wajib',
              case when v_metode = 'cash' then v_teller end, v_t);
    end loop;

    -- Simpanan sukarela: setoran & penarikan kronologis, saldo tak pernah minus
    v_bal := 0;
    v_count := 2 + floor(random() * 6)::int;
    for k in 1 .. v_count loop
      v_t := v_joined + (now() - v_joined) * (k::numeric / (v_count + 1));
      if v_bal > 300000 and random() < 0.35 then
        v_jenis := 'tarik';
        v_amt := round(v_bal * (0.2 + random() * 0.4)::numeric, -4);
        v_metode := 'cash';
        v_bal := v_bal - v_amt;
      else
        v_jenis := 'setor';
        v_amt := (1 + floor(random() * 20)) * 100000;
        v_metode := case when random() < 0.5 then 'gateway' else 'cash' end;
        v_bal := v_bal + v_amt;
      end if;
      v_pay := null;
      if v_metode = 'gateway' then
        insert into payments (member_id, purpose, ref_id, order_id, nominal, status, created_at, updated_at)
        values (v_member, 'simpanan', v_sukarela_acc, 'DEMO-SMP-' || replace(gen_random_uuid()::text, '-', ''),
                v_amt, 'paid', v_t, v_t)
        returning id into v_pay;
      end if;
      insert into savings_transactions (account_id, member_id, jenis, nominal, metode, payment_id, keterangan, created_by, created_at)
      values (v_sukarela_acc, v_member, v_jenis, v_amt, v_metode, v_pay,
              case when v_jenis = 'setor' then 'Setoran sukarela' else 'Penarikan sukarela' end,
              case when v_metode = 'cash' then v_teller end, v_t);
    end loop;
  end loop;

  -- ---------- PINJAMAN ----------
  -- months_ago: umur pinjaman sejak disetujui; telat: angsuran jatuh tempo terakhir belum dibayar
  for r in
    select * from (values
      ( 1,  5000000, 12, 'active',    5, false),
      ( 2,  2000000,  6, 'active',    3, true ),
      ( 3, 10000000, 12, 'active',    8, false),
      ( 5,  3000000,  6, 'active',    2, false),
      ( 6,  7500000, 10, 'active',    6, true ),
      ( 8,  1500000,  3, 'active',    1, false),
      ( 9,  4000000,  8, 'active',    4, false),
      (11,  6000000, 12, 'active',    9, true ),
      ( 4,  2500000,  6, 'lunas',     8, false),
      ( 7,  1000000,  3, 'lunas',     5, false),
      (10,  5000000,  6, 'lunas',     9, false),
      (12,  8000000, 12, 'approved',  0, false),
      (13,  3500000,  6, 'approved',  0, false),
      (14,  2000000,  6, 'pengajuan', 0, false),
      (15, 12000000, 12, 'pengajuan', 0, false),
      (16,  1500000,  4, 'pengajuan', 0, false),
      (17, 20000000, 24, 'rejected',  1, false)
    ) as x(mn, pokok, tenor, status, months_ago, telat)
  loop
    v_member := ('d0000000-0000-0000-0000-' || lpad(r.mn::text, 12, '0'))::uuid;
    v_loan := ('d1000000-0000-0000-0000-' || lpad(r.mn::text, 12, '0'))::uuid;
    select bank_code into v_bank from members where id = v_member;

    v_approved := case
      when r.status in ('active', 'lunas') then now() - make_interval(months => r.months_ago)
      when r.status = 'approved' then now() - make_interval(days => 1 + floor(random() * 3)::int)
    end;
    v_ajukan := case
      when r.status = 'pengajuan' then now() - make_interval(hours => 2 + floor(random() * 96)::int)
      when r.status = 'rejected' then now() - make_interval(months => r.months_ago)
      else v_approved - interval '3 days'
    end;

    insert into loans (id, member_id, pokok, tenor, jasa_persen, tujuan, status,
      tanggal_pengajuan, approved_by, approved_at, created_at)
    values (v_loan, v_member, r.pokok, r.tenor, 1.5,
      v_tujuan[1 + (r.mn % array_length(v_tujuan, 1))], r.status::loan_status,
      v_ajukan, case when v_approved is not null then v_pengurus end, v_approved, v_ajukan);

    continue when r.status in ('pengajuan', 'rejected');

    v_pokok_bln := round(r.pokok::numeric / r.tenor, 2);
    v_jasa_bln := round(r.pokok * 1.5 / 100, 2);
    v_last_due := 0;
    for k in 1 .. r.tenor loop
      if (v_approved::date + make_interval(months => k))::date < current_date then v_last_due := k; end if;
    end loop;

    for k in 1 .. r.tenor loop
      v_due := (v_approved::date + make_interval(months => k))::date;
      v_inst := gen_random_uuid();
      if v_due >= current_date then
        insert into loan_installments (id, loan_id, angsuran_ke, jatuh_tempo, nominal_pokok, nominal_jasa, total, status)
        values (v_inst, v_loan, k, v_due, v_pokok_bln, v_jasa_bln, v_pokok_bln + v_jasa_bln, 'belum');
      elsif r.telat and k = v_last_due then
        insert into loan_installments (id, loan_id, angsuran_ke, jatuh_tempo, nominal_pokok, nominal_jasa, total, status)
        values (v_inst, v_loan, k, v_due, v_pokok_bln, v_jasa_bln, v_pokok_bln + v_jasa_bln, 'telat');
        insert into notifications (member_id, judul, isi, tipe, created_at)
        values (v_member, 'Angsuran Jatuh Tempo',
                'Angsuran ke-' || k || ' pinjaman Anda telah jatuh tempo. Segera lakukan pembayaran.',
                'angsuran', v_due::timestamptz + interval '8 hours');
      else
        v_t := v_due::timestamptz - make_interval(days => floor(random() * 4)::int, hours => -9);
        v_pay := null;
        if random() < 0.5 then
          insert into payments (member_id, purpose, ref_id, order_id, nominal, status, created_at, updated_at)
          values (v_member, 'angsuran', v_inst, 'DEMO-ANG-' || replace(gen_random_uuid()::text, '-', ''),
                  v_pokok_bln + v_jasa_bln, 'paid', v_t, v_t)
          returning id into v_pay;
        end if;
        insert into loan_installments (id, loan_id, angsuran_ke, jatuh_tempo, nominal_pokok, nominal_jasa, total, status, paid_at, payment_id)
        values (v_inst, v_loan, k, v_due, v_pokok_bln, v_jasa_bln, v_pokok_bln + v_jasa_bln, 'lunas', v_t, v_pay);
      end if;
    end loop;

    if r.status in ('active', 'lunas') then
      insert into disbursements (loan_id, member_id, external_id, provider_ref, amount, bank_code,
        account_number, account_holder_name, status, created_by, created_at, updated_at)
      select v_loan, v_member, 'KSP-DSB-demo-' || lpad(r.mn::text, 4, '0'), 'demo-ref-' || r.mn, r.pokok,
             bank_code, account_number, account_holder_name, 'completed', v_pengurus,
             v_approved + interval '2 hours', v_approved + interval '3 hours'
      from members where id = v_member;
    elsif r.mn = 13 then
      -- Pencairan gagal (rekening tidak valid): pinjaman tetap 'approved' dan bisa dicairkan ulang
      insert into disbursements (loan_id, member_id, external_id, provider_ref, amount, bank_code,
        account_number, account_holder_name, status, created_by, created_at, updated_at)
      select v_loan, v_member, 'KSP-DSB-demo-' || lpad(r.mn::text, 4, '0'), 'demo-ref-' || r.mn, r.pokok,
             bank_code, account_number, account_holder_name, 'failed', v_pengurus,
             v_approved + interval '1 hour', v_approved + interval '1 hour'
      from members where id = v_member;
    end if;

    insert into notifications (member_id, judul, isi, tipe, created_at)
    values (v_member, 'Pinjaman Disetujui',
            'Pinjaman Anda telah disetujui dan sedang menunggu pencairan dana.', 'pinjaman', v_approved);
  end loop;
end;
$$;
