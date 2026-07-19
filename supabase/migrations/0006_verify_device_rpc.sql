-- Registers (upserts) the current user's device and returns its verification
-- status. The app calls this via supabase.rpc('verify_device', ...) at startup
-- and on every launch. It was missing from the project, so no device rows were
-- ever written to user_devices and the admin device list stayed empty.
--
-- The function runs as SECURITY DEFINER so the INSERT succeeds even though the
-- user_devices RLS policies only grant select/update to admins (no insert
-- policy for normal users).

create or replace function public.verify_device(
  p_installation_id text,
  p_fingerprint_hash text,
  p_platform text,
  p_manufacturer text,
  p_model text,
  p_device_name text,
  p_os_version text,
  p_app_version text
)
returns table (device_id uuid, status text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_device_id uuid;
  v_approved boolean;
  v_revoked_at timestamptz;
begin
  if v_user_id is null then
    raise exception 'verify_device requires an authenticated user';
  end if;

  -- Upsert the device keyed by (user_id, installation_id).
  insert into public.user_devices (
    user_id,
    installation_id,
    fingerprint_hash,
    platform,
    manufacturer,
    model,
    device_name,
    os_version,
    app_version,
    first_seen_at,
    last_seen_at
  )
  values (
    v_user_id,
    p_installation_id,
    p_fingerprint_hash,
    p_platform,
    p_manufacturer,
    p_model,
    p_device_name,
    p_os_version,
    p_app_version,
    now(),
    now()
  )
  on conflict (user_id, installation_id)
  do update set
    fingerprint_hash = coalesce(p_fingerprint_hash, user_devices.fingerprint_hash),
    platform = coalesce(p_platform, user_devices.platform),
    manufacturer = coalesce(p_manufacturer, user_devices.manufacturer),
    model = coalesce(p_model, user_devices.model),
    device_name = coalesce(p_device_name, user_devices.device_name),
    os_version = coalesce(p_os_version, user_devices.os_version),
    app_version = coalesce(p_app_version, user_devices.app_version),
    last_seen_at = now();

  -- Read the resulting row to derive status.
  select id, approved, revoked_at
  into v_device_id, v_approved, v_revoked_at
  from public.user_devices
  where user_id = v_user_id
    and installation_id = p_installation_id;

  return query
  select v_device_id,
         case
           when v_revoked_at is not null then 'revoked'
           when v_approved then 'approved'
           else 'pending'
         end::text;
end;
$$;

-- Allow the device owner to insert their own device directly (in case the app
-- ever writes via .insert instead of the RPC). Not required for verify_device
-- since that is SECURITY DEFINER, but keeps the table consistent and safe.
drop policy if exists "Users can insert their own devices" on public.user_devices;
create policy "Users can insert their own devices"
  on public.user_devices for insert
  with check (auth.uid() = user_id);
