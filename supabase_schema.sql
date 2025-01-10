-- Drop and recreate users table
DROP TABLE IF EXISTS public.users CASCADE;

CREATE TABLE public.users (
    id uuid PRIMARY KEY,
    display_name text,
    photo_url text,
    firebase_uid text,
    created_at timestamptz DEFAULT now(),
    CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Recreate playlist table with proper foreign key
DROP TABLE IF EXISTS public.playlist CASCADE;

CREATE TABLE public.playlist (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    playlist_name text NOT NULL,
    image_url text,
    user_id uuid NOT NULL,
    created_at timestamptz DEFAULT now(),
    CONSTRAINT playlist_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- Enable RLS on users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Allow users to view their own data
CREATE POLICY "Users can view own data" ON public.users
FOR SELECT
USING (auth.uid() = id);

-- Allow users to update their own data
CREATE POLICY "Users can update own data" ON public.users
FOR UPDATE
USING (auth.uid() = id);

-- Allow insert during signup
CREATE POLICY "Enable insert for authenticated users" ON public.users
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);
