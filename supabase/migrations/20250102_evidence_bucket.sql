-- Create 'activity_evidence' bucket for user uploads
INSERT INTO storage.buckets (id, name, public) 
VALUES ('activity_evidence', 'activity_evidence', true) 
ON CONFLICT (id) DO NOTHING;

-- Policies for activity_evidence

-- 1. Public Read (Admins/Brands need to see it, maybe friends later)
DROP POLICY IF EXISTS "Public View Evidence" ON storage.objects;
CREATE POLICY "Public View Evidence" ON storage.objects 
FOR SELECT USING (bucket_id = 'activity_evidence');

-- 2. Authenticated Upload (Users uploading their own proof)
-- Restrict folder path to user_id to prevent tampering with others? 
-- For now, simple authenticated upload is enough.
DROP POLICY IF EXISTS "Authenticated Upload Evidence" ON storage.objects;
CREATE POLICY "Authenticated Upload Evidence" ON storage.objects 
FOR INSERT WITH CHECK (
  bucket_id = 'activity_evidence' 
  AND auth.role() = 'authenticated'
);

-- 3. Users can only update/delete their own
DROP POLICY IF EXISTS "Users Manage Own Evidence" ON storage.objects;
CREATE POLICY "Users Manage Own Evidence" ON storage.objects 
FOR ALL USING (
  bucket_id = 'activity_evidence' 
  AND auth.uid() = owner
);
