-- ═══════════════════════════════════════════════════════════
-- CampusHub: Storage Bucket Policies for Notes
-- Run this AFTER creating the 'notes' bucket in Storage
-- ═══════════════════════════════════════════════════════════

-- Allow authenticated users to upload to the notes bucket
CREATE POLICY "Allow authenticated uploads to notes"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'notes');

-- Allow anyone to read from notes bucket (public)
CREATE POLICY "Allow public read from notes"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'notes');

-- Allow authenticated users to delete from notes bucket
CREATE POLICY "Allow authenticated deletes from notes"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'notes');
