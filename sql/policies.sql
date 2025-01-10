-- Enable row-level security
ALTER TABLE playlists ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Allow authenticated users to insert playlists" ON playlists;

-- Create a policy to allow authenticated users to insert rows
CREATE POLICY "Allow authenticated users to insert playlists"
ON playlists
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Create a policy to allow authenticated users to select their playlists
CREATE POLICY "Allow authenticated users to select their playlists"
ON playlists
FOR SELECT
USING (auth.uid() = user_id);

-- Create a policy to allow authenticated users to update their playlists
CREATE POLICY "Allow authenticated users to update their playlists"
ON playlists
FOR UPDATE
USING (auth.uid() = user_id);

-- Create a policy to allow authenticated users to delete their playlists
CREATE POLICY "Allow authenticated users to delete their playlists"
ON playlists
FOR DELETE
USING (auth.uid() = user_id);