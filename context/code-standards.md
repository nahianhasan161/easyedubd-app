# Code Standards

Derived from existing code. Follow what's there and don't introduce new patterns without asking.

## General
- Small, focused edits. Big screens (see CLAUDE.md "Big files") should be split into widgets, not grown further.
- Comments explain **why** (see the long rationale comments in `startup_controller.dart`, `main.dart`, migrations).
- Use `debugPrint`, not `print` (`avoid_print` from flutter_lints).
- Don't leave helper scripts in the root (e.g. `_patch_course_card.py`, `flutter_0*.log` are leftovers).

## Language (Dart)
- Null-safe, `final` fields, `const` constructors where possible.
- Models: plain immutable classes with `fromJson`/`toJson` (or `fromMap`), no codegen (no freezed/json_serializable).
  Examples: `courses/models/course.dart`, `courses/models/profile.dart`, `admin/user_device.dart`.
- IDs: `int` for course/chapter/enrollment/promotion, `String` for user/profile/device/lesson ids.
- Imports: package imports `package:easyedubd_app/...` preferred; relative imports exist only inside `core/`.
- Wrap every awaited network/plugin call in `.timeout(Duration(...))` with a meaningful `TimeoutException` or fallback.

## Framework rules
- **Riverpod 3**
  - Async state: `AsyncNotifier` + `AsyncNotifierProvider` (`AuthController`, `StartupController`).
  - Return the value from `build()`. Don't set `state` inside `build()` (it causes flicker; see the comment in `startup_controller.dart`).
  - Read the Supabase client via `ref.read(supabaseProvider)` in providers. `main.dart` also exposes a global `supabase`.
  - Errored providers are auto-invalidated by `_RiverpodErrorObserver` (`main.dart`). Still handle errors in UI with `.when`.
  - Family providers for variants, e.g. `courseListProvider(bool)`.
- **go_router**
  - Add routes only in `core/router/app_router.dart`, with both `name:` and `path:`. Admin routes go under `/admin/...`
    (the redirect guards that prefix).
  - Navigate with `context.go/push` or `pushNamed` using the route names.
- **Screens** are `ConsumerWidget` / `ConsumerStatefulWidget`.

## Styling
- See `context/ui-context.md`. Prefer `Theme.of(context).colorScheme` over new hard-coded `Colors.*` / hex.

## i18n
- None. UI strings are hard-coded English in widgets. TBD (ask): is Bangla localisation planned?

## Data access (Supabase "API")
- No custom API routes. All queries go in a `*_repository.dart` class, never inside widgets.
- Auth: rely on `supabase.auth.currentUser`. Authorization is RLS. A client role check (`profile.role == 'admin'`)
  is UX only.
- Errors: catch in repository/provider, `debugPrint`, rethrow or return cached data. Offline → serve from `CacheService`.
- PostgREST `.or()` can't use relation-qualified columns. Use an RPC instead (see `0007_search_profiles_rpc.sql`).
- Writes that need to bypass RLS go through a `SECURITY DEFINER` function, not by loosening policies.

## Data & migrations
- File name `supabase/migrations/NNNN_snake_name.sql`, next number = 0010.
- Header comment: what, why, and a `SAFETY:` note. Must be idempotent: `create table if not exists`,
  `add column if not exists`, `create or replace function`, `drop policy/trigger if exists` before create.
- Enable RLS on every new table, with owner policies plus admin policies via `public.is_admin()`.
- Content tables need a `cache_version` bump trigger. Per-user tables must not have one.
- Never edit an already-applied migration. Add a new one.
- Add a test for migration-dependent logic when feasible (`test/cache_version_migration_test.dart`).

## File organization
- Feature code: `lib/features/presentation/screens/<feature>/{models,repository,providers,widgets,screens|pages}`.
- Cross-feature infrastructure: `lib/core/<area>/`. Shared widgets: `lib/shared/widgets/`.
- Tests: `test/<subject>_test.dart`, flat folder.
- Note: there are duplicated names (`core/providers/course_provider.dart`, `admin/course_provider.dart`,
  `courses/providers/course_provider.dart`; two `course_repository.dart`). Check the import path before editing.
