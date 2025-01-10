-- Enable row-level security
ALTER TABLE playlists ENABLE ROW LEVEL SECURITY;

-- Create a policy to allow authenticated users to insert rows
CREATE POLICY "Allow authenticated users to insert playlists"
ON playlists
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Add user_id column to playlists table
ALTER TABLE playlists ADD COLUMN user_id uuid REFERENCES auth.users(id);