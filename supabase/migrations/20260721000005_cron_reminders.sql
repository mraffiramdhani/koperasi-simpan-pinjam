-- ============================================================
-- Reminder jatuh tempo angsuran (in-app) + penjadwalan pg_cron
-- ============================================================

-- Membuat notifikasi in-app untuk angsuran yang mendekati / lewat jatuh tempo,
-- serta menandai angsuran terlambat sebagai 'telat'.
create or replace function generate_due_reminders()
returns void
language plpgsql security definer set search_path = public as $$
declare
  r record;
begin
  -- Tandai angsuran yang lewat jatuh tempo sebagai 'telat'
  update loan_installments
     set status = 'telat'
   where status = 'belum' and jatuh_tempo < now()::date;

  -- Buat reminder untuk angsuran jatuh tempo dalam 3 hari ke depan atau menunggak
  for r in
    select li.id, li.jatuh_tempo, li.total, l.member_id
    from loan_installments li
    join loans l on l.id = li.loan_id
    where li.status in ('belum', 'telat')
      and li.jatuh_tempo <= (now()::date + interval '3 day')
  loop
    -- Dedupe: hindari notifikasi ganda pada hari yang sama untuk angsuran ini
    if not exists (
      select 1 from notifications
      where member_id = r.member_id
        and tipe = 'angsuran'
        and created_at::date = now()::date
        and isi like '%' || to_char(r.jatuh_tempo, 'DD-MM-YYYY') || '%'
    ) then
      insert into notifications (member_id, judul, isi, tipe)
      values (
        r.member_id,
        'Pengingat Angsuran',
        'Angsuran Rp ' || to_char(r.total, 'FM999,999,999') ||
        ' jatuh tempo ' || to_char(r.jatuh_tempo, 'DD-MM-YYYY') || '.',
        'angsuran'
      );
    end if;
  end loop;
end;
$$;

-- Aktifkan pg_cron & jadwalkan tiap hari pukul 08:00 (waktu server DB).
-- Dibungkus DO/EXCEPTION agar migration tidak gagal bila pg_cron belum
-- tersedia (mis. sebagian lingkungan lokal). Di Supabase Cloud, aktifkan
-- pg_cron via Dashboard > Database > Extensions bila perlu.
do $$
begin
  create extension if not exists pg_cron;
  perform cron.schedule(
    'daily-angsuran-reminders',
    '0 8 * * *',
    'select generate_due_reminders();'
  );
exception when others then
  raise notice 'pg_cron tidak tersedia, lewati penjadwalan: %', sqlerrm;
end;
$$;
