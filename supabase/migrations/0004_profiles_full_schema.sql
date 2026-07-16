-- Ensures the full `public.profiles` schema matches the app model.
-- Safe to re-run: every change uses `if not exists` / `ADD COLUMN IF NOT EXISTS`
-- and the primary key / foreign key are only created when missing, so any
-- data already in the table is preserved.
--
-- Run in the Supabase SQL editor (or `supabase db push`).

-- 1) Base table (already exists in most setups).
create table if not exists public.profiles (
  id uuid not null,
  full_name text null,
  avatar_url text null,
  created_at timestamp with time zone null default now(),
  constraint profiles_pkey primary key (id)
);

-- 2) Add the remaining columns if they are missing.
alter table public.profiles
  add column if not exists current_level text;

alter table public.profiles
  add column if not exists institute text;

alter table public.profiles
  add column if not exists faculty text;

alter table public.profiles
  add column if not exists department text;

alter table public.profiles
  add column if not exists session text;

alter table public.profiles
  add column if not exists current_year text;

alter table public.profiles
  add column if not exists role text not null default 'user';

alter table public.profiles
  add column if not exists gender text default 'Male';

-- 3) Foreign key to auth.users (idempotent).
do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where constraint_name = 'profiles_id_fkey'
      and table_schema = 'public'
      and table_name = 'profiles'
  ) then
    alter table public.profiles
      add constraint profiles_id_fkey
      foreign key (id) references auth.users (id) on delete cascade;
  end if;
end $$;
