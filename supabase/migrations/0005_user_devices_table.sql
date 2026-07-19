-- Creates the user_devices table that backs the admin device-management
-- screens. Previous migrations (0003) only enabled RLS and created policies,
-- assuming this table already existed. Because it was never created, the
-- verify_device RPC / getUserDevices queries returned nothing (or errored),
-- so no devices showed up. This migration builds the table to match the
-- UserDevice model used by the app.
--
-- Safe to re-run: every statement is conditional.

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  installation_id text not null,
  fingerprint_hash text,
  platform text not null,
  manufacturer text,
  model text,
  device_name text,
  os_version text,
  app_version text,
  approved boolean not null default false,
  approved_at timestamptz,
  approved_by uuid references auth.users (id),
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  ip_address text
);

-- Helpful indexes for the admin lookups.
create index if not exists user_devices_user_id_idx
  on public.user_devices (user_id);

create index if not exists user_devices_last_seen_idx
  on public.user_devices (last_seen_at desc);
