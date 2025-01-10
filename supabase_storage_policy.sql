-- Create policy for authenticated users to upload files
CREATE POLICY "Allow authenticated users to upload files"
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (bucket_id = 'playlist_covers');

-- Create policy for public to view files
CREATE POLICY "Allow public to view files"
ON storage.objects FOR SELECT 
TO public 
USING (bucket_id = 'playlist_covers');

-- Create policy for users to update their own files
CREATE POLICY "Allow users to update their own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'playlist_covers' AND owner = auth.uid())
WITH CHECK (bucket_id = 'playlist_covers' AND owner = auth.uid());

-- Create policy for users to delete their own files
CREATE POLICY "Allow users to delete their own files"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'playlist_covers' AND owner = auth.uid());
