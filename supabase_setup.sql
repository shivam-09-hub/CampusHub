-- ═══════════════════════════════════════════════════════════
-- CampusHub: Complete Table Setup with RLS Policies
-- Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════

-- 1) USERS TABLE
CREATE TABLE IF NOT EXISTS users (
  uid TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT NOT NULL DEFAULT '',
  role TEXT NOT NULL DEFAULT 'student',
  department TEXT DEFAULT '',
  semester TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by TEXT
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users are viewable by authenticated users" ON users;
CREATE POLICY "Users are viewable by authenticated users"
  ON users FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can be deleted" ON users;
CREATE POLICY "Users can be deleted"
  ON users FOR DELETE
  TO authenticated
  USING (true);

-- 2) MESSAGES TABLE
CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL DEFAULT '',
  content TEXT DEFAULT '',
  priority TEXT DEFAULT 'normal',
  created_by TEXT,
  created_by_name TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Messages readable by all authenticated" ON messages;
CREATE POLICY "Messages readable by all authenticated"
  ON messages FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Messages insertable by authenticated" ON messages;
CREATE POLICY "Messages insertable by authenticated"
  ON messages FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Messages updatable by authenticated" ON messages;
CREATE POLICY "Messages updatable by authenticated"
  ON messages FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "Messages deletable by authenticated" ON messages;
CREATE POLICY "Messages deletable by authenticated"
  ON messages FOR DELETE TO authenticated USING (true);

-- 3) NOTICES TABLE
CREATE TABLE IF NOT EXISTS notices (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL DEFAULT '',
  description TEXT DEFAULT '',
  target_audience TEXT DEFAULT 'all',
  created_by TEXT,
  created_by_name TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE notices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Notices readable by all authenticated" ON notices;
CREATE POLICY "Notices readable by all authenticated"
  ON notices FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Notices insertable by authenticated" ON notices;
CREATE POLICY "Notices insertable by authenticated"
  ON notices FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Notices updatable by authenticated" ON notices;
CREATE POLICY "Notices updatable by authenticated"
  ON notices FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "Notices deletable by authenticated" ON notices;
CREATE POLICY "Notices deletable by authenticated"
  ON notices FOR DELETE TO authenticated USING (true);

-- 4) NOTES TABLE (auto-increment ID)
CREATE TABLE IF NOT EXISTS notes (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL DEFAULT '',
  description TEXT DEFAULT '',
  file_name TEXT DEFAULT '',
  file_url TEXT DEFAULT '',
  storage_path TEXT DEFAULT '',
  department TEXT DEFAULT '',
  class_name TEXT DEFAULT '',
  file_type TEXT DEFAULT 'file',
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Notes readable by all authenticated" ON notes;
CREATE POLICY "Notes readable by all authenticated"
  ON notes FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Notes insertable by authenticated" ON notes;
CREATE POLICY "Notes insertable by authenticated"
  ON notes FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Notes deletable by authenticated" ON notes;
CREATE POLICY "Notes deletable by authenticated"
  ON notes FOR DELETE TO authenticated USING (true);

-- 5) DEPARTMENTS TABLE
CREATE TABLE IF NOT EXISTS departments (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by TEXT
);

ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Departments full access" ON departments;
CREATE POLICY "Departments full access"
  ON departments FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 6) CLASSES TABLE
CREATE TABLE IF NOT EXISTS classes (
  id TEXT PRIMARY KEY,
  department_id TEXT DEFAULT '',
  department_name TEXT DEFAULT '',
  class_name TEXT DEFAULT '',
  semester TEXT DEFAULT '',
  section TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by TEXT
);

ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Classes full access" ON classes;
CREATE POLICY "Classes full access"
  ON classes FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 7) FACULTIES TABLE
CREATE TABLE IF NOT EXISTS faculties (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  email TEXT DEFAULT '',
  department_id TEXT DEFAULT '',
  department_name TEXT DEFAULT '',
  subjects JSONB DEFAULT '[]',
  unavailable_times JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by TEXT
);

ALTER TABLE faculties ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Faculties full access" ON faculties;
CREATE POLICY "Faculties full access"
  ON faculties FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 8) SUBJECTS TABLE
CREATE TABLE IF NOT EXISTS subjects (
  id TEXT PRIMARY KEY,
  subject_name TEXT DEFAULT '',
  department_id TEXT DEFAULT '',
  department_name TEXT DEFAULT '',
  class_id TEXT DEFAULT '',
  semester TEXT DEFAULT '',
  assigned_faculty_id TEXT DEFAULT '',
  assigned_faculty_name TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by TEXT
);

ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Subjects full access" ON subjects;
CREATE POLICY "Subjects full access"
  ON subjects FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 9) ROOMS TABLE
CREATE TABLE IF NOT EXISTS rooms (
  id TEXT PRIMARY KEY,
  room_id TEXT DEFAULT '',
  capacity INTEGER DEFAULT 0
);

ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Rooms full access" ON rooms;
CREATE POLICY "Rooms full access"
  ON rooms FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 10) TIMETABLES TABLE
CREATE TABLE IF NOT EXISTS timetables (
  id TEXT PRIMARY KEY,
  class_name TEXT DEFAULT '',
  working_days INTEGER DEFAULT 5,
  slots_per_day INTEGER DEFAULT 6,
  subjects JSONB DEFAULT '[]',
  rooms JSONB DEFAULT '[]',
  faculty_availability JSONB DEFAULT '[]',
  entries JSONB DEFAULT '[]',
  time_slots JSONB DEFAULT '[]',
  "createdAt" TIMESTAMPTZ DEFAULT now(),
  department TEXT DEFAULT '',
  semester TEXT DEFAULT '',
  published BOOLEAN DEFAULT false,
  created_by TEXT
);

ALTER TABLE timetables ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Timetables full access" ON timetables;
CREATE POLICY "Timetables full access"
  ON timetables FOR ALL TO authenticated USING (true) WITH CHECK (true);
