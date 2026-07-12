-- Admin access to the user_devices table (used by the device-management screen).
-- Assumes the table from the provided schema already exists:
--   create table public.user_devices ( ... );
--
-- Run this in the Supabase dashboard SQL editor (or `supabase db push`).

-- 1) Enable Row Level Security.
alter table public.user_devices enable row level security;

-- 2) Admins can read every device row (needed to list a user's devices).
drop policy if exists "Admins can view all devices" on public.user_devices;
create policy "Admins can view all devices"
  on public.user_devices for select
  using (public.is_admin());

-- 3) Admins can update device rows (approve / revoke a device).
drop policy if exists "Admins can update all devices" on public.user_devices;
create policy "Admins can update all devices"
  on public.user_devices for update
  using (public.is_admin())
  with check (public.is_admin());
