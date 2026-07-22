-- ============================================================
-- Jadwalkan reminder harian via Edge Function (in-app + FCM push).
-- Fallback ke generate_due_reminders() jika URL/key belum dikonfigurasi.
-- ============================================================

create or replace function invoke_daily_reminder()
returns void
language plpgsql
security definer
set search_path = public, extensions, net
as $$
declare
  v_url text := nullif(current_setting('app.settings.edge_reminder_url', true), '');
  v_key text := nullif(current_setting('app.settings.service_role_key', true), '');
begin
  if v_url is null or v_key is null then
    -- Belum dikonfigurasi: tetap buat notifikasi in-app
    perform generate_due_reminders();
    return;
  end if;

  -- Edge function reminder memanggil generate_due_reminders + kirim FCM
  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || v_key,
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
end;
$$;

do $$
begin
  create extension if not exists pg_cron;
  create extension if not exists pg_net;
exception when others then
  raise notice 'extension: %', sqlerrm;
end;
$$;

do $$
begin
  -- Ganti job lama (in-app only) dengan invoke yang bisa push
  begin
    perform cron.unschedule('daily-angsuran-reminders');
  exception when others then
    null;
  end;
  begin
    perform cron.unschedule('daily-reminder-push');
  exception when others then
    null;
  end;
  perform cron.schedule(
    'daily-reminder-push',
    '0 8 * * *',
    'select invoke_daily_reminder()'
  );
exception when others then
  raise notice 'pg_cron tidak tersedia, lewati penjadwalan: %', sqlerrm;
end;
$$;

comment on function invoke_daily_reminder() is
  'Panggil edge /reminder bila app.settings.edge_reminder_url + service_role_key diset; else generate_due_reminders().';
