-- Smart Timetable Builder: professional timetable management additions
-- Safe to run on an existing Supabase project. It keeps current tables/data.

create extension if not exists pgcrypto;

-- ── Rooms table (create if it doesn't exist yet) ─────────────────────────────
create table if not exists public.rooms (
  id text primary key,
  room_id text not null,
  capacity integer default 40,
  room_type text default 'Classroom'
);

alter table public.rooms enable row level security;

drop policy if exists "Rooms full access" on public.rooms;
create policy "Rooms full access"
  on public.rooms
  for all
  to anon, authenticated
  using (true)
  with check (true);
-- ─────────────────────────────────────────────────────────────────────────────

alter table if exists public.faculties
  add column if not exists max_lectures_per_day integer default 6,
  add column if not exists available_days jsonb default '[]'::jsonb,
  add column if not exists available_slots jsonb default '[]'::jsonb;

alter table if exists public.subjects
  add column if not exists hours_per_week integer default 3,
  add column if not exists subject_type text default 'Theory';

-- Add room_type to existing rooms tables that were created before this schema
alter table if exists public.rooms
  add column if not exists room_type text default 'Classroom';

alter table if exists public.timetables
  add column if not exists department text default '',
  add column if not exists semester text default '',
  add column if not exists published boolean default false,
  add column if not exists created_by text;

create table if not exists public.allocations (
  id text primary key,
  timetable_id text not null,
  department text default '',
  class_name text default '',
  semester text default '',
  subject_name text default '',
  faculty_name text default '',
  room_id text default '',
  day integer not null,
  slot integer not null,
  start_time text default '',
  end_time text default '',
  created_at timestamptz default now(),
  created_by text
);

create index if not exists allocations_timetable_idx
  on public.allocations (timetable_id);

create index if not exists allocations_faculty_slot_idx
  on public.allocations (faculty_name, day, slot);

create index if not exists allocations_room_slot_idx
  on public.allocations (room_id, day, slot);

create index if not exists allocations_class_slot_idx
  on public.allocations (class_name, day, slot);

create unique index if not exists allocations_unique_class_slot_idx
  on public.allocations (timetable_id, class_name, day, slot);

alter table public.allocations enable row level security;

drop policy if exists "Allocations full access" on public.allocations;
create policy "Allocations full access"
  on public.allocations
  for all
  to anon, authenticated
  using (true)
  with check (true);
