-- ============================================================
-- Storage bucket untuk foto KTP anggota
-- Path konvensi: <auth.uid()>/ktp.jpg
-- ============================================================

insert into storage.buckets (id, name, public)
values ('ktp', 'ktp', false)
on conflict (id) do nothing;

-- Anggota upload / lihat file miliknya (folder = uid)
create policy ktp_insert_own on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'ktp'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy ktp_select_own on storage.objects
  for select to authenticated
  using (
    bucket_id = 'ktp'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or is_staff()
    )
  );

create policy ktp_update_own on storage.objects
  for update to authenticated
  using (
    bucket_id = 'ktp'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
