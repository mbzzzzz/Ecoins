-- Create campaigns bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('campaigns', 'campaigns', true) ON CONFLICT (id) DO NOTHING;

-- Policies for campaigns
DROP POLICY IF EXISTS "Public View Campaigns" ON storage.objects;
CREATE POLICY "Public View Campaigns" ON storage.objects FOR SELECT USING (bucket_id = 'campaigns');

DROP POLICY IF EXISTS "Authenticated Upload Campaigns" ON storage.objects;
CREATE POLICY "Authenticated Upload Campaigns" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'campaigns' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated Update Campaigns" ON storage.objects;
CREATE POLICY "Authenticated Update Campaigns" ON storage.objects FOR UPDATE USING (bucket_id = 'campaigns' AND auth.role() = 'authenticated');

-- Policies for avatars
DROP POLICY IF EXISTS "Public View Avatars" ON storage.objects;
CREATE POLICY "Public View Avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Authenticated Upload Avatars" ON storage.objects;
CREATE POLICY "Authenticated Upload Avatars" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users Update Own Avatars" ON storage.objects;
CREATE POLICY "Users Update Own Avatars" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND owner = auth.uid());

DROP POLICY IF EXISTS "Users Delete Own Avatars" ON storage.objects;
CREATE POLICY "Users Delete Own Avatars" ON storage.objects FOR DELETE USING (bucket_id = 'avatars' AND owner = auth.uid());
