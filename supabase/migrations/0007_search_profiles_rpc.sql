-- Search profiles by name, email, or phone.
--
-- The app calls this via supabase.rpc('search_profiles', ...) from the
-- enrollment user picker. It replaces the previous PostgREST .or() approach
-- that failed with "failed to parse logic tee" because PostgREST cannot
-- parse relation-qualified columns such as auth.users.email inside .or().

create or replace function public.search_profiles(search_term text)
returns table (
  id uuid,
  full_name text,
  avatar_url text,
  current_level text,
  institute text,
  department text,
  session text,
  current_year text,
  gender text,
  role text,
  email text,
  phone text
)
language sql
security definer
set search_path = public
as $$
  select
    p.id,
    p.full_name,
    p.avatar_url,
    p.current_level,
    p.institute,
    p.department,
    p.session,
    p.current_year,
    p.gender,
    p.role,
    u.email,
    u.phone
  from public.profiles p
  left join auth.users u on u.id = p.id
  where
    p.full_name ilike '%' || search_term || '%'
    or u.email ilike '%' || search_term || '%'
    or u.phone ilike '%' || search_term || '%'
  order by p.full_name
  limit 20;
$$;
