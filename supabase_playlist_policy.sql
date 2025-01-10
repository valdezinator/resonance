-- First, drop existing policies if any
DROP POLICY IF EXISTS "Users can create their own playlists" ON playlist;
DROP POLICY IF EXISTS "Users can view their own playlists" ON playlist;
DROP POLICY IF EXISTS "Users can update their own playlists" ON playlist;
DROP POLICY IF EXISTS "Users can delete their own playlists" ON playlist;

-- Enable RLS
ALTER TABLE playlist ENABLE ROW LEVEL SECURITY;

-- Create policy for inserting playlists (more permissive)
CREATE POLICY "Users can create their own playlists"
ON playlist
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid()::text = user_id::text -- Convert both to text for comparison
);

-- Create policy for viewing playlists
CREATE POLICY "Users can view their own playlists"
ON playlist
FOR SELECT
TO authenticated
USING (
    auth.uid()::text = user_id::text
);

-- Create policy for updating playlists
CREATE POLICY "Users can update their own playlists"
ON playlist
FOR UPDATE
TO authenticated
USING (
    auth.uid()::text = user_id::text
)
WITH CHECK (
    auth.uid()::text = user_id::text
);

-- Create policy for deleting playlists
CREATE POLICY "Users can delete their own playlists"
ON playlist
FOR DELETE
TO authenticated
USING (
    auth.uid()::text = user_id::text
);

-- Allow public read access to all playlists (optional, remove if not needed)
CREATE POLICY "Public can view all playlists"
ON playlist
FOR SELECT
TO public
USING (true);
