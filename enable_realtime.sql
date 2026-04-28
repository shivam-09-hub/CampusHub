-- ═══════════════════════════════════════════════════════════
-- Enable Supabase Realtime on all tables
-- Run this in Supabase SQL Editor if you haven't already
-- This is required for StreamBuilder to auto-update
-- ═══════════════════════════════════════════════════════════

-- Enable Realtime for all application tables
ALTER PUBLICATION supabase_realtime ADD TABLE departments;
ALTER PUBLICATION supabase_realtime ADD TABLE classes;
ALTER PUBLICATION supabase_realtime ADD TABLE faculties;
ALTER PUBLICATION supabase_realtime ADD TABLE subjects;
ALTER PUBLICATION supabase_realtime ADD TABLE rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE notes;
ALTER PUBLICATION supabase_realtime ADD TABLE notices;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE timetables;
ALTER PUBLICATION supabase_realtime ADD TABLE users;
