# Progress Tracker

Update after every meaningful change. Newest notes on top.

## Current Phase
Stabilisation on branch `dev`: fixing cache freshness and admin-update bugs after the dashboard, offline mode, and search work.
App version `1.0.0+14`.

## Current Goal
Make cached content refresh reliably after admin edits, and make lesson completion per user, without breaking
startup or resume. Known bugs are still open (the user deferred fixing them, 2026-11-19).

## Completed (from git history)
- Auth: email + Google sign-in; onboarding + missing-profile onboarding (`723c9ce`, `5ecd86b`)
- Device fingerprint + approval, unsupported-device fix (`82dcbde`)
- Admin: users, devices, course enrollment (`37cc8dc`), course/chapter/lesson management, promotions (`c4d3d39`)
- Lesson progress UI (`c6ad8e2`), course loading optimisation (`2cb0288`), pagination fix (`51faac0`)
- Offline mode via Hive (`ecacaed`), search (`964caeb`), dashboard (`5190bb3`)
- Cache refresh on open, resume, tab change, and pull (`6c04005`), admin update bug fix (`9209ab7`)
- PostHog tracking (`1c2fa0a`), Windows release build, 32-bit ABI filter (`0685edf`)
- CI: main Play upload gated behind manual run; other branches auto-upload to internal (`14b1800`)

## In Progress (uncommitted, per `git status` on 2026-11-19)
- New: `supabase/migrations/0008_cache_version_mechanism.sql`, `0009_lesson_progress.sql`.
  **Unknown whether they've been applied to the live DB** (ask).
- New: `lib/core/progress/lesson_progress.dart` (`LessonProgressRepository`, `completedLessonIdsProvider`)
- New tests: `test/cache_version_e2e_test.dart`, `test/cache_version_migration_test.dart`
- Modified (16 files, +214/−108): `main.dart`, `cache_service.dart`, `device_service.dart`, `auth_provider.dart`,
  `router_provider.dart`, `app_router.dart`, `app_lifecycle_handler.dart`, `startup_controller.dart` (`recheckOnResume`),
  `course.dart`, `courses/providers/course_provider.dart`, `course_details_screen.dart`, `course_list_provider.dart`,
  `course_list/repository/course_repository.dart`, `lesson_player.dart`, `course_card.dart`, `dashboard_tab_screen.dart`

## Known Bugs (deferred, not fixing now)
- Details TBD (ask). The user said "some bugs exist". The commit history points at:
  - Cache not invalidated by new data / stale lists after admin edits (`ecacaed`, `5190bb3`)
  - Admin update bugs (`5190bb3`, partly fixed in `9209ab7`)
- Observation: pull-to-refresh / tab change doesn't call `RealtimeCacheInvalidator.checkNow()`, so only start and resume
  check `cache_version` (see `features/cache-invalidation.md`).

## Next Up
1. Get the bug list from the user, then reproduce each one.
2. Confirm 0008/0009 are applied, run `flutter analyze` + `flutter test`, then commit the uncommitted work.
3. TBD (ask): roadmap items (exam, live stream placeholders exist).

## Open Questions
- Which bugs exactly, and in what priority order?
- Are migrations 0008/0009 applied on the live Supabase project?
- Product goals, success metrics, and payment flow (enrollments are manual by admin today).
- Exam / live stream: planned, and when?
- iOS / web releases planned? Dark mode? Bangla localisation?
- Roles beyond admin/student?
- `.env` is tracked in git and bundled in the app. Intended? (OK for the publishable key; must never hold service-role keys.)
- Should video access also be protected server-side (today `CourseAccessService` is client-only)?

## Architecture Decisions
- **2026-11 (0008):** server `cache_version` counter + statement triggers. Clients check on start/resume and wipe Hive
  when it changes. Why: content changes rarely, and idle users should make no background calls.
- **2026-11 (0009):** per-user `lesson_progress` (lesson_id as text, no FK). Why: `lesson."isComplete"` was shared
  across all students and bumped the cache for everyone.
- **2026-11:** `recheckOnResume()` never sets loading. Why: loading → router → `/splash` kicked users out of the lesson player.
- **Earlier:** device approval via a SECURITY DEFINER `verify_device` RPC; admin checks via `is_admin()` to avoid RLS recursion.

## Session Notes
- **2026-11-19:** Branch flow `local-dev` (no Play) → `dev` (Play alpha) → `main` (production, manual upload).
  Commit `d6d200e` (workflows only). Not pushed yet.
- **2026-11-19:** Created `CLAUDE.md` + `context/` docs. No code changes. Bugs left for later at the user's request.
