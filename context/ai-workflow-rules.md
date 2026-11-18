# AI Workflow Rules

## Approach
- Work in small, verifiable steps. Follow `progress-tracker.md` "Next Up" and these context files.
- Don't invent product behaviour (pricing, access rules, roles). If it's not in code or docs, ask.
- Prefer fixing in the existing file/pattern over new abstractions. The user is credit-constrained, so be concise
  and avoid re-exploring what CLAUDE.md already maps.

## Session Start
1. Read `CLAUDE.md` and `context/progress-tracker.md`.
2. `git status` + `git log --oneline -5` to confirm state matches the tracker.
3. Read only the context file(s) relevant to the task.
4. For big files, grep first, then read ranges.

## Scoping Rules
- One concern per change: e.g. "fix stale course list after admin edit", not "refactor caching".
- Don't touch unrelated uncommitted files listed in the tracker.
- Don't rename or move files unless asked (duplicated `course_provider.dart` / `course_repository.dart` names are known).

## When to Split Work
- The change needs a **new migration** and app code: do SQL first (user applies it), then Dart.
- It touches **startup/router/lifecycle** (`startup_controller.dart`, `app_router.dart`, `app_lifecycle_handler.dart`)
  plus feature screens: split, since these are high-risk for redirect loops and splash bounces.
- More than ~3 screens or more than one big file → plan first, then do it in units.
- Admin feature and student feature in one request → separate units.

## Handling Missing Requirements
- Mark as `TBD (ask)` in docs, collect questions, and ask in one batch.
- When a reasonable default exists and it's reversible, choose it, state it, and continue.

## Ask Before
- Running any SQL / migration on the live Supabase project.
- `git push` (any branch push triggers CI; non-main → Play internal upload; main → release build).
- Committing (only when asked; branch is `dev`).
- Deleting data, tables, columns, policies, or Hive boxes' schema.
- Adding or upgrading dependencies in `pubspec.yaml`, bumping `version:`.
- Changing RLS policies, `verify_device`, screen-security, or the device-approval logic.
- Anything touching `.env`, keystores, `android/key.properties`, CI secrets.

## Protected Files
- `.env` (never read or print), `android/key.properties`, `*.jks`, `.github/workflows/*` (ask), applied migrations
  `0002–0009` (never edit, add new), `build/`, `.dart_tool/`, `.kilo/`, generated platform folders unless needed.

## Keeping Docs in Sync
| Change | Update |
|---|---|
| Any meaningful work | `progress-tracker.md` (Session Notes, Completed/In Progress) |
| New route, dir, helper, command, big file | `CLAUDE.md` Layout / Commands |
| New table / RPC / RLS / role | `architecture.md` Storage + Auth, plus `CLAUDE.md` conventions if non-obvious |
| Cache behaviour | `features/cache-invalidation.md` |
| New pattern or rule | `code-standards.md` |
| Colours / theme / shared widget | `ui-context.md` |
| Scope or product decision | `project-overview.md` + tracker "Architecture Decisions" |

## Before Moving to the Next Unit (Definition of Done)
1. `flutter analyze` has no new issues.
2. `flutter test` passes (or failures are reported with output).
3. `flutter build apk --debug` (or `flutter run`) compiles for platform-affecting changes.
4. Manual check described: what screen, what steps (e.g. admin edits course → student resumes → sees update).
5. Migration (if any) is idempotent and the user was told to apply it.
6. `progress-tracker.md` updated.
