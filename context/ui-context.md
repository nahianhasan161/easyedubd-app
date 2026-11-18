# UI Context

## Theme
- Single light theme in `lib/main.dart`: `ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple))`
  (Material 3 default).
- **No dark mode**: there's no `darkTheme` / `ThemeMode` anywhere. TBD (ask): is dark mode wanted?
- No central token or theme-extension file. Colours are mostly inline `Colors.*`.

## Colors (as used today)
| Token / usage | Purpose | Value |
|---|---|---|
| `colorScheme.primary` (seed) | app bars, primary buttons | from `Colors.deepPurple` seed |
| `Colors.deepPurple` | accents, explicit brand purple | #673AB7 |
| `Colors.white` | card/background surfaces, text on primary | #FFFFFF |
| `Colors.grey` / `.shade200–700` | secondary text, borders, placeholders | Material grey ramp |
| `Colors.red` (+ shades) | errors, locked/blocked, destructive actions | Material red |
| `Colors.green` (+ shade100) | success, approved, completed | Material green |
| `Colors.orange` / `amber.shade700` | pending, warnings, promotions | Material orange/amber |
| `Color(0xFF7A4F01)` | dark-amber text (badge/promo) | #7A4F01 |
| Screen-protect overlay | `ScreenProtector.protectDataLeakageWithColor(Colors.white)` | white |

Dark-mode values: n/a (no dark mode).
Rule for new UI: use `Theme.of(context).colorScheme.*` (primary, surface, error, onSurfaceVariant) instead of
adding new literals.

## Typography
- Default Material 3 text theme (Roboto on Android). No custom fonts (`pubspec.yaml` has no `fonts:`).
- Use `Theme.of(context).textTheme.*` and avoid ad-hoc `TextStyle(fontSize: ...)`.

## Border radius
Commonly used `BorderRadius.circular`: **10** (most common), 8, 12, 14, 16, 18, 20; pills 28–30.
New cards: 12–16. Inputs/buttons: 10. Chips/badges: 6–8.

## Component library
- Material widgets only (no third-party UI kit).
- Shared: `shared/widgets/course_slider.dart` (horizontal course carousels), `App_cached_image.dart`
  (`cached_network_image` wrapper), `app_refresh_wrapper.dart` (pull-to-refresh), `confirm_dialog.dart`,
  `youtube_player.dart`.
- Course card: `courses/widgets/course_card.dart` (554 lines, read in ranges).

## Layout patterns
- **Splash / auth / device status**: centered column, logo `assets/icons/eeb-logo.png`.
- **Onboarding**: multi-step forms (`onboarding_screen.dart`, `missing_profile_onboarding_screen.dart`).
- **Dashboard**: tab scaffold (`dashboard_screen.dart` + `dashboard_tab_screen.dart`) with sliders and pull-to-refresh.
  Admins get `admin_drawer.dart`.
- **Course list**: search + filters + paginated list (`course_list_screen.dart`).
- **Course details**: header + expandable chapters → lesson tiles with lock/complete state.
- **Lesson player**: YouTube player on top, details and "Mark as complete" below.
- **Admin**: list → detail → nested management screens (`admin/*_screen.dart`), confirm dialogs for destructive actions.

## Icons
- Mostly Material `Icons.*` (~220 uses). `font_awesome_flutter` and `cupertino_icons` are dependencies but barely used.
- App launcher icon: `assets/icons/logo.png` (generated via `flutter_launcher_icons`).
