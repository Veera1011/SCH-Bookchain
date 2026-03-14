-- Run this in the Supabase SQL Editor

-- 1. Locations Table
CREATE TABLE public.locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    city TEXT NOT NULL,
    address TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- 2. Profiles Table (extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'employee',
    status TEXT NOT NULL DEFAULT 'pending',
    location_id UUID REFERENCES public.locations(id) ON DELETE SET NULL,
    manager_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    department TEXT,
    points INTEGER NOT NULL DEFAULT 0,
    reading_goal INTEGER NOT NULL DEFAULT 12,
    avatar_url TEXT,
    fcm_token TEXT,
    rejection_reason TEXT,
    verified_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Books Table
CREATE TABLE public.books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    isbn TEXT,
    description TEXT,
    genre TEXT[] NOT NULL DEFAULT '{}',
    language TEXT NOT NULL DEFAULT 'en',
    location_id UUID REFERENCES public.locations(id) ON DELETE SET NULL,
    total_copies INTEGER NOT NULL DEFAULT 1,
    available_copies INTEGER NOT NULL DEFAULT 1,
    cover_url TEXT,
    ebook_url TEXT,
    avg_rating FLOAT8 NOT NULL DEFAULT 0,
    rating_count INTEGER NOT NULL DEFAULT 0,
    condition TEXT NOT NULL DEFAULT 'good',
    qr_code TEXT UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Borrow Records Table
CREATE TABLE public.borrow_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id UUID REFERENCES public.books(id) ON DELETE CASCADE,
    book_title TEXT NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    location_id UUID REFERENCES public.locations(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    borrowed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    due_date TIMESTAMPTZ NOT NULL,
    returned_at TIMESTAMPTZ,
    summary TEXT,
    summary_score INTEGER,
    rating INTEGER,
    review TEXT,
    is_overdue BOOLEAN NOT NULL DEFAULT false,
    status TEXT NOT NULL DEFAULT 'borrowed',
    points_awarded INTEGER NOT NULL DEFAULT 0
);

-- 5. Notifications Table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Setup Row Level Security (RLS) policies (Optional basics to prevent full lockdown or allow all while testing)
-- You can run these if you want to allow anonymous/authenticated read-write during initial testing:
/*
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all operations for locations" ON public.locations FOR ALL USING (true);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all operations for profiles" ON public.profiles FOR ALL USING (true);

ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all operations for books" ON public.books FOR ALL USING (true);

ALTER TABLE public.borrow_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all operations for borrow_records" ON public.borrow_records FOR ALL USING (true);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all operations for notifications" ON public.notifications FOR ALL USING (true);
*/
