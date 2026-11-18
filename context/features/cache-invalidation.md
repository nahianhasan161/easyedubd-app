# Feature: Cache + Invalidation

## Why
Content changes rarely. The app caches courses, enrollments, and profiles in Hive for offline browsing, and refreshes only
when the server says data changed. Idle users make no background calls.

## Pieces
- `lib/core/cache/cache_service.dart`: static Hive wrapper. Boxes `course_cache`, `enrollment_cache`,
  `profile_cache`, `cache_meta`. Keys come from `CacheService.courseKey(courseId|year,subject,type,offset,limit,includeChapters,search)`.
  All methods no-op if `init()` hasn't run (`_ready`).
- `lib/core/cache/realtime_cache_invalidator.dart`: reads `public.cache_version`. If the value is newer than
  `last_seen_cache_version`, it wipes the local boxes and emits on `invalidations`. API: `start()`, `checkNow()`,
  `invalidateAllLocal()`, `stop()`, `dispose()`. Despite the name it **polls on demand** (no timer, no realtime channel;
  see `test/realtime_cache_invalidator_no_timer_test.dart`).
- `supabase/migrations/0008_cache_version_mechanism.sql`: table + `bump_cache_version()` + statement triggers on
  `course, chapter, lesson, enrollments, bundle, bundle_courses, promotion, promotion_course`.
- `cache_version` checks happen at app start (`RealtimeCacheInvalidator.start()` in `main.dart`) and on resume
  (`checkNow()` in `app_lifecycle_handler.dart`). Pull-to-refresh / tab change in `dashboard_tab_screen.dart`
  (`_handleRefresh`) does **not** call `checkNow()`. It invalidates `enrolledCourseIdsProvider` and refreshes the
  dashboard providers directly. (`AppRefreshWrapper` is just a `RefreshIndicator`.)
- `AppLifecycleHandler._onCacheInvalidated` (skipped when offline) invalidates `enrolledCourseIdsProvider` and calls
  `courseListProvider(false/true).notifier.loadInitial()`.

## Rules
- New content table → add a 4-line trigger block in a **new** migration (don't edit 0008 after it's applied).
- Per-user, high-churn data (progress) must **not** be tracked, or it wipes everyone's cache.
- Enrollment writes are tracked, so one admin enrollment invalidates all clients. That's known and accepted.

## Known issues
- Commits `ecacaed` and `5190bb3` mention stale-cache / admin-update bugs. 0008 and the provider changes target them but are
  **uncommitted and unverified**. See the bugs list in `progress-tracker.md`.

## Tests
`test/cache_version_e2e_test.dart`, `test/cache_version_migration_test.dart`, `test/course_refresh_test.dart`,
`test/realtime_cache_invalidator_*_test.dart`, `test/dashboard_courses_provider*_test.dart`.
