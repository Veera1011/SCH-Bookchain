-- Run this in your Supabase SQL Editor to fix the login issue
-- This ensures authenticated users can always read their own profile row during login/signup,
-- even if other Row Level Security policies are blocking them.

-- 1. Ensure RLS is enabled on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. Drop the restrictive policy if it exists (to avoid conflicts)
DROP POLICY IF EXISTS "profiles_read_all" ON public.profiles;
DROP POLICY IF EXISTS "users_read_own_profile" ON public.profiles;

-- 3. Create a policy explicitly allowing users to read their own profile
CREATE POLICY "users_read_own_profile" 
ON public.profiles 
FOR SELECT 
USING ( auth.uid() = id );

-- 4. Create a policy explicitly allowing admins to read all profiles
-- Using a SECURITY DEFINER function prevents infinite recursion when querying
-- the same table that the policy is attached to.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid() AND role IN ('super_admin', 'location_admin')
  );
$$;

DROP POLICY IF EXISTS "admins_read_all_profiles" ON public.profiles;
CREATE POLICY "admins_read_all_profiles" 
ON public.profiles 
FOR SELECT 
USING ( public.is_admin() );

-- 5. (Critical for Registration) Allow users to insert their *own* profile row upon signup
DROP POLICY IF EXISTS "users_insert_own_profile" ON public.profiles;
CREATE POLICY "users_insert_own_profile"
ON public.profiles
FOR INSERT
WITH CHECK ( auth.uid() = id );
