# CLAUDE.md — easyedubd_app

**Easy Education Bangladesh**: a Flutter app (Android, Windows, plus iOS/web/macOS/linux scaffolds) where students watch
paid or free YouTube-hosted course lessons. Content and auth come from Supabase. Device-lock approval, screenshot blocking, and an in-app admin panel.

## Context files
- **Always read first:** `context/progress-tracker.md` (current state, uncommitted work, known bugs).
- Read the others only when the task touches them:
  - `context/project-overview.md`: product goals, user flows, scope
  - `context/architecture.md`: system boundaries, Supabase tables, cache model, auth/roles, invariants
  - `context/code-standards.md`: Dart/Riverpod/go_router patterns, repository + migration rules
  - `context/ui-context.md`: theme, colours, radii, icons (before any UI work)
  - `context/ai-workflow-rules.md`: scoping, what to ask before, definition of done
  - `context/features/cache-invalidation.md`: before touching Hive cache, `cache_version`, lifecycle refresh
- Update `context/progress-tracker.md` after meaningful work.

## Stack
- Flutter **3.44.2** (pinned in CI), Dart SDK `^3.12.2`, app version `1.0.0+14` (`pubspec.yaml`)
- State: `flutter_riverpod ^3.3.2` (Riverpod 3: `AsyncNotifier`, `ProviderObserverContext`)
- Routing: `go_router ^17.3.0`
- Backend: `supabase_flutter ^2.15.0` (Postgres + RLS + RPC, Auth); `google_sign_in ^7.2.0` (v7 `GoogleSignIn.instance` API)
- Local cache: `hive ^2.2.3` / `hive_flutter`; secure storage: `flutter_secure_storage ^10`
- Video: `youtube_player_flutter ^9.1.1`; analytics/session replay: `posthog_flutter ^5.24`
- Security: `screen_protector`, `device_info_plus`, `crypto` (device fingerprint)
- Riverpod 3, go_router 17, and google_sign_in 7 changed their APIs from older versions. Check pub.dev changelogs and don't rely on memory.

## Commands
```bash
flutter pub get
flutter run                      # needs .env in project root (bundled as an asset)
flutter analyze                  # lint (flutter_lints ^6, default rules)
flutter test                     # unit/widget tests in test/
flutter build apk --release      # needs android/key.properties + keystore
flutter build windows --release
```
- **Deploy = CI only. Branch flow: `local-dev` → `dev` → `main`.**
  - `local-dev`: daily work. `dev.yml` builds APK + Windows artifacts only, **never** reaches Play.
  - `dev`: alpha testing. `dev.yml` artifacts + `play-internal.yml` uploads the AAB to Play **alpha** (closed testing).
  - `main`: production. `main.yml` builds + GitHub `stable` release; Play upload only on manual `workflow_dispatch`.
  - Other branches: no CI. **Push only when asked.**
- **Migrations**: `supabase/migrations/*.sql` are applied by hand in the Supabase SQL editor (or `supabase db push`).
  **Only when asked**, because they run against the live DB. There's no local Supabase config in the repo.

## Layout (where to look)
- `lib/main.dart`: boot order: dotenv → PostHog + screen security → Supabase.initialize → `CacheService.init` →
  `RealtimeCacheInvalidator.start` → `ProviderScope` (with auto-invalidating error observer)
- `lib/core/`
  - `router/app_router.dart`: all routes + redirect (startup state + admin guard); `providers/router_provider.dart`
  - `startup/startup_controller.dart`: `AppStartupState` (loading/unauthenticated/authenticated/pendingDevice/blockedDevice/profileIncomplete)
  - `providers/auth_notifier.dart` (`AuthController`: email + Google sign-in), `auth_provider.dart`, `supabase_provider.dart`
  - `cache/cache_service.dart` (Hive boxes), `cache/realtime_cache_invalidator.dart` (polls `cache_version`)
  - `services/app_lifecycle_handler.dart` (resume → cache check + silent startup recheck),
    `screen_security_service.dart`, `course_access_service.dart` (free/enrolled gate)
  - `device/`: fingerprint + `verify_device` RPC (`device_repository.dart`)
  - `progress/lesson_progress.dart`: per-user `lesson_progress` (new, uncommitted)
  - `network/`: connectivity provider, `retry.dart`
- `lib/features/presentation/screens/<feature>/`: one folder per area: `courses/` (models, repository, providers,
  pages, widgets), `dashboard/`, `admin/`, `onboarding/`, `profile/`, `login/`, `device_status/`, `settings/`, `splash/`.
  `auth/`, `exam/`, `live_stream/` are empty placeholders.
- `lib/shared/widgets/`: `course_slider.dart`, `app_refresh_wrapper.dart`, `App_cached_image.dart`, `youtube_player.dart`, `confirm_dialog.dart`
- `supabase/migrations/`: 0002–0009 (there's no 0001; the base schema was created in the dashboard)
- `test/`: provider/cache/recommendation tests (plain `flutter_test`)

## Big files: grep or read ranges, don't read whole
`course_list/course_list_screen.dart` (899), `onboarding/missing_profile_onboarding_screen.dart` (751),
`pages/lesson_player.dart` (650), `admin/user_detail_screen.dart` (650), `onboarding/onboarding_screen.dart` (576),
`widgets/course_card.dart` (554), `pages/course_details_screen.dart` (539), `admin/course_enrollment_screen.dart` (526),
`profile/profile_screen.dart` (502), `course_list/providers/course_list_provider.dart` (450), `core/router/app_router.dart` (429).

## Conventions (non-obvious)
- IDs: `course`/`enrollment`/`promotion` = `int`; `profiles.id`/user ids = `String` (uuid); **lesson ids treated as `String`**.
- Admin = `profiles.role == 'admin'` (compare lowercase). DB side uses the `public.is_admin()` SECURITY DEFINER helper in RLS.
- Lesson completion is **per user** in `lesson_progress`. Never write `lesson."isComplete"` for students.
- Any write to `course, chapter, lesson, enrollments, bundle, bundle_courses, promotion, promotion_course` bumps
  `cache_version` via a trigger, which wipes every client's Hive cache. Don't add high-frequency writes to tracked tables.
- Cache keys are built only through `CacheService.courseKey(...)` (search is normalised by trim + lowercase).
- Startup/resume must never set `AsyncLoading` on resume (the router sends loading → `/splash`). Use `recheckOnResume()`.
- Every network/init call gets a `.timeout(...)`. Startup is capped at 15s and falls back to cached device status.
- Migrations must be **idempotent and additive** (`if not exists`, `create or replace`, `drop trigger if exists`) and numbered `NNNN_name.sql`.
- Env keys (in `.env`): `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `WEBCLIENTID`, `IOSCLIENTID`, `POSTHOG_API_KEY`. PostHog is skipped if its key is empty.
- UI uses raw `Colors.*` and `ColorScheme.fromSeed(deepPurple)`; there's no token layer yet (see `context/ui-context.md`).

## Current state
Branch `dev`. Cache-version + per-user lesson progress work is uncommitted, and known bugs are still open. Details are in
`context/progress-tracker.md`.

## Safety
- Never print or read `.env` values. Note: `.env` is **tracked in git and bundled into the app** (`pubspec.yaml` assets).
- Don't touch `build/`, `.dart_tool/`, `android/key.properties`, keystores, `.kilo/`.
- Ask before running SQL on the live Supabase project, pushing to `main`/`dev` (it triggers Play uploads), deleting data, or adding deps.
