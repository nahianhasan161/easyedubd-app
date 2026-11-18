-- ============================================================
-- Per-user lesson progress
-- ============================================================
-- Before this, "Mark as complete" in the lesson player updated
-- `lesson."isComplete"` directly. That column is shared by every
-- student, so one student completing a lesson marked it complete for
-- everyone. It also bumped cache_version (lesson has a trigger), so
-- every toggle wiped every user's course cache.
--
-- This table stores completion per (user, lesson). It is NOT tracked
-- by cache_version, so toggling progress doesn't invalidate caches.
--
-- `lesson_id` is text (the app treats lesson ids as strings) so this
-- works whether `lesson.id` is bigint or uuid. No FK for that reason.
--
-- SAFETY: purely additive and idempotent. Existing `lesson."isComplete"`
-- values are left untouched (the app no longer reads them for students).
-- ============================================================

create table if not exists public.lesson_progress (
  profile_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  lesson_id text not null,
  completed_at timestamptz not null default now(),
  primary key (profile_id, lesson_id)
);

alter table public.lesson_progress enable row level security;

drop policy if exists "lesson_progress_select_own" on public.lesson_progress;
create policy "lesson_progress_select_own" on public.lesson_progress
  for select using (auth.uid() = profile_id);

drop policy if exists "lesson_progress_insert_own" on public.lesson_progress;
create policy "lesson_progress_insert_own" on public.lesson_progress
  for insert with check (auth.uid() = profile_id);

drop policy if exists "lesson_progress_delete_own" on public.lesson_progress;
create policy "lesson_progress_delete_own" on public.lesson_progress
  for delete using (auth.uid() = profile_id);

drop policy if exists "lesson_progress_admin_select" on public.lesson_progress;
create policy "lesson_progress_admin_select" on public.lesson_progress
  for select using (public.is_admin());
