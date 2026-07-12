-- Fixes profile save + admin access:
--   1. PGRST204: adds the missing `gender` and `role` columns
--   2. 42501: enables RLS and adds owner-only select/insert/update policies
--   3. Admin access: lets users with role = 'admin' list and manage all profiles
--
-- Run this in the Supabase dashboard SQL editor (or `supabase db push`).

-- 1) Add columns if they do not exist yet.
alter table public.profiles
  add column if not exists gender text;

alter table public.profiles
  add column if not exists role text not null default 'user';

-- 2) Enable Row Level Security on the profiles table.
alter table public.profiles enable row level security;

-- 3) Owners can read their own profile.
drop policy if exists "Profiles are viewable by owner" on public.profiles;
create policy "Profiles are viewable by owner"
  on public.profiles for select
  using (auth.uid() = id);

-- 4) Owners can insert their own profile.
drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- 5) Owners can update their own profile.
drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- 6) Helper to detect admins without causing RLS recursion.
--    SECURITY DEFINER makes it run as the function owner, bypassing RLS,
--    so a policy can safely call it to check the caller's role.
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

-- 7) Admins can read every profile (needed for the user-management screen).
drop policy if exists "Admins can view all profiles" on public.profiles;
create policy "Admins can view all profiles"
  on public.profiles for select
  using (public.is_admin());

-- 8) Admins can update any profile (e.g. promote / demote users).
drop policy if exists "Admins can update all profiles" on public.profiles;
create policy "Admins can update all profiles"
  on public.profiles for update
  using (public.is_admin())
  with check (public.is_admin());
