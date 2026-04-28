create extension if not exists pgcrypto;

create table if not exists public.users (
  uid text primary key,
  email text,
  name text,
  role text,
  department text,
  semester text,
  "createdAt" timestamptz,
  "createdBy" text
);

create table if not exists public.departments (
  id text primary key,
  name text,
  "createdAt" timestamptz,
  "createdBy" text
);

create table if not exists public.classes (
  id text primary key,
  "departmentId" text,
  "departmentName" text,
  "className" text,
  semester text,
  section text,
  "createdAt" timestamptz,
  "createdBy" text
);

create table if not exists public.faculties (
  id text primary key,
  name text,
  email text,
  "departmentId" text,
  "departmentName" text,
  subjects jsonb default '[]'::jsonb,
  "unavailableTimes" jsonb default '[]'::jsonb,
  "createdAt" timestamptz,
  "createdBy" text
);

create table if not exists public.subjects (
  id text primary key,
  "subjectName" text,
  "departmentId" text,
  "departmentName" text,
  "classId" text,
  semester text,
  "assignedFacultyId" text,
  "assignedFacultyName" text,
  "createdAt" timestamptz,
  "createdBy" text
);

create table if not exists public.rooms (
  id text primary key,
  "roomId" text,
  capacity integer
);

create table if not exists public.timetables (
  id text primary key,
  "className" text,
  "workingDays" integer,
  "slotsPerDay" integer,
  subjects jsonb default '[]'::jsonb,
  rooms jsonb default '[]'::jsonb,
  "facultyAvailability" jsonb default '[]'::jsonb,
  entries jsonb default '[]'::jsonb,
  "timeSlots" jsonb default '[]'::jsonb,
  "createdAt" timestamptz,
  department text,
  semester text,
  published boolean default false,
  "createdBy" text
);

create table if not exists public.notices (
  id text primary key,
  title text,
  description text,
  "targetAudience" text,
  "createdBy" text,
  "createdByName" text,
  "createdAt" timestamptz
);

create table if not exists public.messages (
  id text primary key,
  title text,
  content text,
  priority text,
  "createdBy" text,
  "createdByName" text,
  "createdAt" timestamptz
);

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

alter table public.users enable row level security;
alter table public.departments enable row level security;
alter table public.classes enable row level security;
alter table public.faculties enable row level security;
alter table public.subjects enable row level security;
alter table public.rooms enable row level security;
alter table public.timetables enable row level security;
alter table public.notices enable row level security;
alter table public.messages enable row level security;
alter table public.notes enable row level security;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'users',
    'departments',
    'classes',
    'faculties',
    'subjects',
    'rooms',
    'timetables',
    'notices',
    'messages',
    'notes'
  ]
  loop
    execute format('drop policy if exists "Allow select for testing" on public.%I', table_name);
    execute format('drop policy if exists "Allow insert for testing" on public.%I', table_name);
    execute format('drop policy if exists "Allow update for testing" on public.%I', table_name);
    execute format('drop policy if exists "Allow delete for testing" on public.%I', table_name);

    execute format(
      'create policy "Allow select for testing" on public.%I for select to anon, authenticated using (true)',
      table_name
    );
    execute format(
      'create policy "Allow insert for testing" on public.%I for insert to anon, authenticated with check (true)',
      table_name
    );
    execute format(
      'create policy "Allow update for testing" on public.%I for update to anon, authenticated using (true) with check (true)',
      table_name
    );
    execute format(
      'create policy "Allow delete for testing" on public.%I for delete to anon, authenticated using (true)',
      table_name
    );
  end loop;
end $$;

insert into storage.buckets (id, name, public)
values ('notes', 'notes', true)
on conflict (id) do update set public = true;

drop policy if exists "Allow read notes files for testing" on storage.objects;
drop policy if exists "Allow upload notes files for testing" on storage.objects;
drop policy if exists "Allow update notes files for testing" on storage.objects;
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

create policy "Allow update notes files for testing"
on storage.objects
for update
to anon, authenticated
using (bucket_id = 'notes')
with check (bucket_id = 'notes');

create policy "Allow delete notes files for testing"
on storage.objects
for delete
to anon, authenticated
using (bucket_id = 'notes');
