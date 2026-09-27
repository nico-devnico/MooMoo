-- Profile photos: the bucket existed without any size or type limit, and was
-- never declared in a migration. Declare it and enforce what the app accepts
-- (JPEG, PNG, WebP, 2 MB), so a direct upload cannot bypass the client checks.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('avatars', 'avatars', true, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE
SET public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Each user only writes in the folder named after their id. The read policy
-- is kept for listing; the files themselves are served from the public URL.
DROP POLICY IF EXISTS users_upload_own_avatar ON storage.objects;
CREATE POLICY users_upload_own_avatar ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars' AND (auth.uid())::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS users_update_own_avatar ON storage.objects;
CREATE POLICY users_update_own_avatar ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars' AND (auth.uid())::text = (storage.foldername(name))[1])
  WITH CHECK (bucket_id = 'avatars' AND (auth.uid())::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS users_delete_own_avatar ON storage.objects;
CREATE POLICY users_delete_own_avatar ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'avatars' AND (auth.uid())::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS users_read_own_avatar ON storage.objects;
CREATE POLICY users_read_own_avatar ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'avatars' AND (auth.uid())::text = (storage.foldername(name))[1]);
