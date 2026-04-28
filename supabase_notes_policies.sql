create extension if not exists pgcrypto;

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  title text,
  description text,
  file_name text,
  file_url text,
  storage_path text,
  department text,
  class_name text,
  file_type text
);

alter table public.notes enable row level security;

drop policy if exists "Allow read notes for testing" on public.notes;
drop policy if exists "Allow insert notes for testing" on public.notes;
drop policy if exists "Allow delete notes for testing" on public.notes;

create policy "Allow read notes for testing"
on public.notes
for select
to anon, authenticated
using (true);

create policy "Allow insert notes for testing"
on public.notes
for insert
to anon, authenticated
with check (true);

create policy "Allow delete notes for testing"
on public.notes
for delete
to anon, authenticated
using (true);

insert into storage.buckets (id, name, public)
values ('notes', 'notes', true)
on conflict (id) do update set public = true;

drop policy if exists "Allow read notes files for testing" on storage.objects;
drop policy if exists "Allow upload notes files for testing" on storage.objects;
drop policy if exists "Allow delete notes files for testing" on storage.objects;

create policy "Allow read notes files for testing"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'notes');

create policy "Allow upload notes files for testing"
on storage.objects
for insert
to anon, authenticated
with check (bucket_id = 'notes');

create policy "Allow delete notes files for testing"
on storage.objects
for delete
to anon, authenticated
using (bucket_id = 'notes');
