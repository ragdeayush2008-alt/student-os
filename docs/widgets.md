# Home-Screen Widgets

## Architecture

```
Existing controllers (Task/Exam/Planning/Focus/Sleep/Study/Assistant/…)
        ↓  (read-only, each section independently guarded)
WidgetDataService.buildSnapshot()
        ↓  (one compact JSON string)
Platform-shared storage (`home_widget` → SharedPreferences /
App Group, key `student_os_widget_snapshot`)
        ↓  (event-driven updateWidget + 30-min passive cadence)
Android AppWidgetProviders / iOS WidgetKit timelines
        ↓  (tap)
studentos://widget/... deep link
        ↓  (auth + ownership + entitlement checks in-app)
Existing Student OS feature
```

Widgets are a projection, not an app: no second database, no business
logic, no secrets, no network in native code.

## Flutter layer (`lib/features/widgets/`)

- `models/widget_snapshot.dart` — tolerant snapshot + per-widget payloads
  (caps: 4 exams, 6 plan items/lines; clamps; never throws on corruption).
- `widget_catalog.dart` — 20 widget defs (tiers, sizes, deep links,
  premium mapping). Tier 1 ships native layouts; Tier 2/3 ride the same
  snapshot with extension points.
- `widget_deep_links.dart` — `studentos://` parser (no-underscore scheme,
  disjoint from the `login-callback` OAuth host).
- `services/widget_data_service.dart` — projection, 2s-coalesced
  event listeners (focus ticks filtered), logout clearing, OS refresh.
- `widget_link_handler.dart` — click stream + app_links stream + cold-start
  parking, all funneled to `AppRouter.handleWidgetDeepLink`.
- `presentation/widgets_screen.dart` — in-app catalog + platform
  instructions + debug-only refresh/clear tools.

## Android (`StudentOsWidgets.kt` + res/)

8 `AppWidgetProvider`s (exam countdown, tasks, plan, focus incl. 15/25/45
quick buttons, assistant, sleep, study, brief) share one abstract base:
read snapshot → bind RemoteViews → deep-link PendingIntents via the
home_widget launch mechanism. Logged-out/empty/corrupt states render safe
defaults. `updatePeriodMillis` 30 min covers passive refresh; the app
pushes updates on every meaningful change.

## iOS (`ios/StudentOSWidgets/`)

Source-complete WidgetKit (model, provider, 8 widgets, locked/logged-out
views, App Group `group.com.ragdetechnologies.studentos.widgets`).
**Not wired**: no Xcode extension target, no paid team, no signing.
See `WIRING.md` for the exact steps. No Dart/snapshot changes needed when
wiring lands. `studentos://` scheme is already in `Info.plist`.

## Auth / isolation / premium

- Logged-out taps park as `pendingWidgetLink`, open Home (login), and are
  consumed post-auth by `AppShell`.
- Logout writes the logged-out empty snapshot (verified: no prior-user
  data visible).
- Exam ids verify against the authenticated user's exams.
- Pro widgets (`daily_brief`, `focus_stats`) render locked natively when
  the snapshot says so; taps route to the existing paywall with feature
  context. Free Tier-1 widgets stay free.

## Verification status

- Unit/widget/integration tests for projection, catalog, deep links,
  refresh, isolation, edge cases: green.
- `flutter analyze`: clean on widget areas. `flutter test`: full suite
  green. `flutter build web`: green (no widget code runs on web).
- Android: debug + release APKs compile with receivers/layouts.
  On-device add/resize/tap testing: BLOCKED (no device/emulator here).
- iOS: BLOCKED (no extension target/signing — see WIRING.md).

## Adding a future widget

1. Add the def to `WidgetCatalog` (+ tier, sizes, deep link, premium id).
2. Add the payload to `WidgetSnapshot` (or reuse a section).
3. Project it in `WidgetDataService` (guarded, capped).
4. Android: provider + layout + xml + manifest receiver.
5. iOS: SwiftUI view + bundle entry.
6. Cover with projection + edge-case tests.
