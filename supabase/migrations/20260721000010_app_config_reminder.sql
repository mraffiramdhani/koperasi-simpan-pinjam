-- ============================================================
-- Konfigurasi reminder via tabel (Supabase Cloud tidak izinkan
-- ALTER DATABASE SET app.settings.*)
-- ============================================================

create table if not exists app_config (
  key   text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

alter table app_config enable row level security;
-- Tidak ada policy untuk anon/authenticated → hanya service_role / security definer

revoke all on table app_config from anon, authenticated;
grant select, insert, update, delete on table app_config to service_role;
grant select, insert, update, delete on table app_config to postgres;

create or replace function invoke_daily_reminder()
returns void
language plpgsql
security definer
set search_path = public, extensions, net
as $$
declare
  v_url text;
  v_key text;
begin
  select value into v_url from app_config where key = 'edge_reminder_url';
  select value into v_key from app_config where key = 'service_role_key';

  v_url := nullif(trim(coalesce(v_url, '')), '');
  v_key := nullif(trim(coalesce(v_key, '')), '');

  if v_url is null or v_key is null then
    perform generate_due_reminders();
    return;
  end if;

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

comment on function invoke_daily_reminder() is
  'Panggil edge /reminder bila app_config edge_reminder_url + service_role_key diisi; else generate_due_reminders().';

comment on table app_config is
  'Konfigurasi server (reminder URL/key). Isi via SQL Editor; tidak diekspos ke client.';
