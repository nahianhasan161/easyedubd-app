-- ============================================================
-- Cache version mechanism
-- ============================================================
-- This migration creates a server-side counter that bumps whenever
-- any tracked table changes. The Flutter app reads this counter on
-- lifecycle events (resume, tab change, pull-to-refresh) and
-- invalidates its local Hive cache when the value moves.
--
-- For the rarely-changing data in this app, this is the right
-- cadence: the cache stays valid until the user does something
-- that suggests they expect fresh data. Idle users make zero
-- background network calls.
--
-- SAFETY: This migration is purely additive. It creates a new table
-- (cache_version), a new function (bump_cache_version), new triggers
-- on the listed tables, and RLS for the new table. It does NOT
-- drop, alter, or delete any existing data in your database.
-- All operations are idempotent (CREATE IF NOT EXISTS, CREATE OR
-- REPLACE, DROP TRIGGER IF EXISTS, INSERT ... ON CONFLICT).
--
-- To add a new tracked table in the future, copy any 4-line
-- trigger block and change the table name.
-- ============================================================

-- 1. The version-counter table (single row, single bigint).
create table if not exists public.cache_version (
  id int primary key default 1,
  version bigint not null default 1,
  updated_at timestamptz not null default now(),
  constraint single_row check (id = 1)
);

insert into public.cache_version (id, version) values (1, 1)
  on conflict (id) do nothing;

-- 2. The bump function. Called by every trigger after a write
--    to a tracked table.
create or replace function public.bump_cache_version()
returns trigger as $$
begin
  update public.cache_version
     set version = version + 1, updated_at = now()
   where id = 1;
  return null;
end;
$$ language plpgsql security definer;

-- 3. One trigger per tracked table. Add a new table by copying
--    any 4-line block and changing the names.

-- Courses
drop trigger if exists trg_bump_course on public.course;
create trigger trg_bump_course
  after insert or update or delete on public.course
  for each statement execute function public.bump_cache_version();

-- Chapters
drop trigger if exists trg_bump_chapter on public.chapter;
create trigger trg_bump_chapter
  after insert or update or delete on public.chapter
  for each statement execute function public.bump_cache_version();

-- Lessons
drop trigger if exists trg_bump_lesson on public.lesson;
create trigger trg_bump_lesson
  after insert or update or delete on public.lesson
  for each statement execute function public.bump_cache_version();

-- Enrollments (manual enrollment by admin)
drop trigger if exists trg_bump_enrollment on public.enrollments;
create trigger trg_bump_enrollment
  after insert or update or delete on public.enrollments
  for each statement execute function public.bump_cache_version();

-- Bundles
drop trigger if exists trg_bump_bundle on public.bundle;
create trigger trg_bump_bundle
  after insert or update or delete on public.bundle
  for each statement execute function public.bump_cache_version();

-- Bundle-to-course join table
drop trigger if exists trg_bump_bundle_courses on public.bundle_courses;
create trigger trg_bump_bundle_courses
  after insert or update or delete on public.bundle_courses
  for each statement execute function public.bump_cache_version();

-- Promotions
drop trigger if exists trg_bump_promotion on public.promotion;
create trigger trg_bump_promotion
  after insert or update or delete on public.promotion
  for each statement execute function public.bump_cache_version();

-- Promotion-to-course join table
drop trigger if exists trg_bump_promotion_course on public.promotion_course;
create trigger trg_bump_promotion_course
  after insert or update or delete on public.promotion_course
  for each statement execute function public.bump_cache_version();

-- 4. RLS so the client can read the version row.
alter table public.cache_version enable row level security;

create policy "cache_version_read" on public.cache_version
  for select using (true);

-- 5. (Reference only - not executed)
--    Loop pattern for adding many triggers at once. Add new table
--    names to the array; the loop creates the trigger for each.
--
-- do $$
-- declare t text;
-- begin
--   foreach t in array array[
--     'course', 'chapter', 'lesson', 'enrollments',
--     'bundle', 'bundle_courses', 'promotion', 'promotion_course'
--   ] loop
--     execute format(
--       'drop trigger if exists trg_bump_%I on public.%I', t, t);
--     execute format(
--       'create trigger trg_bump_%I
--          after insert or update or delete on public.%I
--          for each statement execute function public.bump_cache_version()',
--       t, t);
--   end loop;
-- end $$;
