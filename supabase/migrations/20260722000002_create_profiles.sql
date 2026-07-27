-- Migration 02: Create Profiles Table and Indexes (Auth-independent)

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Row Level Security disabled for personal / auth-disconnected usage
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles(created_at);
