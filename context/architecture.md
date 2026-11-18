# Architecture

## Stack
| Layer | Tech | Where |
|---|---|---|
| UI | Flutter 3.44.2, Material 3 (`ColorScheme.fromSeed`) | `lib/features/presentation/screens/` |
| State | Riverpod 3 (`AsyncNotifier`, `FutureProvider`) | `*/providers/`, `core/providers/` |
| Routing | go_router 17, single `GoRouter` with redirect | `core/router/app_router.dart` |
| Backend | Supabase (Postgres, RLS, RPC, Auth) | `core/providers/supabase_provider.dart`, `*_repository.dart` |
| Local cache | Hive boxes | `core/cache/cache_service.dart` |
| Video | youtube_player_flutter | `pages/lesson_player.dart`, `shared/widgets/youtube_player.dart` |
| Analytics | PostHog (us host) | `lib/main.dart` |
| CI | GitHub Actions → APK/AAB/Windows, Play internal track | `.github/workflows/` |

## System Boundaries
- The **client talks directly to Supabase** via PostgREST (`.from(...)`) and RPCs. There's no custom server or edge functions in the repo.
  All authorization is enforced by **RLS + SECURITY DEFINER functions**.
- **Repositories** own the Supabase queries, and providers/screens call repositories:
  - Student content: `courses/screens/pages/course_list/repository/course_repository.dart`, `enrollment_repository.dart`,
    `courses/repository/promotion_repository.dart`
  - Admin: `admin/course_repository.dart`, `admin/course_management_repository.dart`, `admin/user_repository.dart`
  - Profile: `profile/profile_repository.dart`; Device: `core/device/device_repository.dart`; Progress: `core/progress/lesson_progress.dart`
- **Startup gate**: `core/startup/startup_controller.dart` decides the `AppStartupState`, and the router redirect maps state to route.
- **Lifecycle**: `core/services/app_lifecycle_handler.dart` wraps `MaterialApp.router`. On resume it calls
  `RealtimeCacheInvalidator.checkNow()` and `startupProvider.recheckOnResume()`, and retries errored providers.

## Storage Model
Supabase `public` tables (the base schema predates the migrations, so there's no 0001):
| Table | Purpose | Notes |
|---|---|---|
| `profiles` | user profile + `role` | RLS: owner, or admin via `is_admin()` (0002, 0004) |
| `user_devices` | device registrations, `approved`, `revoked_at` | written via the `verify_device` RPC (0005, 0006) |
| `course`, `chapter`, `lesson` | content tree | `lesson."isComplete"` is legacy and not read for students |
| `bundle`, `bundle_courses` | course bundles | |
| `enrollments` | `profile_id` + `course_id` or `bundle_id`, `status`, `expires_at` | |
| `promotion`, `promotion_course` | discounts | |
| `cache_version` | single-row bigint counter | bumped by statement triggers on the 8 content tables (0008) |
| `lesson_progress` | per (user, lesson_id text) completion | not tracked by `cache_version` (0009) |

RPCs: `verify_device(...)`, `search_profiles(search_term)`, `is_admin()`, `bump_cache_version()`.

Client-side Hive boxes: `course_cache`, `enrollment_cache`, `profile_cache`, `cache_meta`
(`last_invalidated_ms`, `last_seen_cache_version`). Progress is cached under key `progress_<userId>`.
More detail in `context/features/cache-invalidation.md`.

Secure storage: device installation id (see `core/device/`). Assets: `assets/icons/`, and `.env` bundled.

## Auth and Access Model
- **Auth**: Supabase Auth with email/password or Google ID token (`AuthController` in `core/providers/auth_notifier.dart`).
- **Roles**: `profiles.role` = `'admin'`, otherwise a student. TBD (ask): any other roles (teacher?).
- **Device gate**: `verify_device` returns approved / pending / blocked. If unreachable, the last cached status is used.
- **Route checks**: `app_router.dart` redirect sends startup state to the matching screen, and `/admin/*` requires the admin role
  (otherwise → `/dashboard`). The client guard is UX only. **RLS is the real guard.**
- **Lesson access**: `CourseAccessService.canWatchLesson(isFree, hasCourseEnrollment, hasBundleEnrollment)`.
  This is client-side only. TBD (ask): is server-side protection of video ids required?

## Invariants
1. Authorization lives in RLS / SECURITY DEFINER SQL. Never rely on client checks alone for admin writes.
2. Lesson completion is per user (`lesson_progress`). Never mutate shared `lesson` rows on student actions.
3. `cache_version` is the single source of truth for cache freshness. Any new content table must get a bump trigger.
4. Resume or background checks must not put `startupProvider` into loading (that would bounce the user to `/splash`).
5. Every startup network step has a timeout, and the app must boot offline from the cache.
6. Migrations are additive and re-runnable, and never drop user data.
7. Screen security is enabled before `runApp`.
