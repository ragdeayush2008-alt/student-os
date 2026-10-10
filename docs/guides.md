# Interactive Guides — Developer Guide

Student OS teaches itself through a reusable **Interactive Guide Engine**
(`lib/features/guides/`). Guides take users into REAL screens and verify
REAL actions against live controllers. No slideshows, no fake completion.

## Architecture

| Piece | File | Role |
|---|---|---|
| Models | `models/guide_models.dart` | `GuideDefinition`, `GuideStep`, `GuideExpectationKind`, `GuideProgress` |
| Catalog | `guides_catalog.dart` | All 16 guide definitions (data only) |
| Registry | `guide_registry.dart` | Lookup, category lists, `isUnlocked` (progressive discovery), `matchQuery` (Assistant keywords, pure) |
| Engine | `guide_controller.dart` | Session lifecycle, navigation, live expectation detection |
| Navigation | `guide_navigator.dart` | Destination → existing `AppRouter` helpers (no new routes) |
| Targets | `guide_targets.dart` | `GuideTargetAnchor(id, child)` + `GuideTargetRegistry` (GlobalKey → screen rect) |
| Overlay | `guide_overlay.dart` | Dim + spotlight hole (taps pass through), emerald ring, coach card, completion view |
| Persistence | `guide_progress_store.dart` | User-scoped `StorageService` keys (`guide_progress_v1`, `guide_tour_v1`, `guide_tour_offer_v1`) |
| Learn center | `learn_screen.dart` | Permanent grouped catalog with states |
| Assistant bridge | `guide_assistant_bridge.dart` | Pure teach-me matcher + honest launch copy |

## Adding "How to use X"

1. **Register anchors** in the real screen (one-line wraps, no logic changes):
   ```dart
   GuideTargetAnchor(
     id: 'feature.control',
     child: MyRealButton(...),
   )
   ```
2. **Define the guide** in `guides_catalog.dart`:
   ```dart
   GuideDefinition(
     id: 'my_feature',
     title: 'How to use My Feature',
     description: '...',
     category: GuideCategory.focus,
     unlockAfter: ['sprintx'], // optional progressive gate
     steps: [
       GuideStep(
         id: 'mf_open',
         title: '...',
         message: '...',
         destination: GuideDestination.focusCenter,
         targetAnchorId: 'feature.control',
         expectation: GuideExpectationKind.focusSessionStarted,
       ),
     ],
   );
   ```
3. **Expectations** available: `screenSeen`, `continueTap`, `focusSessionStarted`,
   `sleepScheduleSaved`, `taskCreated`, `examCreated`, `planningBlockCreated`.
   Count-based ones capture baselines on step entry and auto-advance on real
   change. Steps without anchors show a coach card only (graceful fallback).
4. **Launch it**: `GuideOverlayManager.ensureListening();` then
   `GuideController.instance.startGuide('my_feature');`
   Add a card automatically — `LearnScreen` renders every registered guide.
   For Assistant discovery, add keywords to `GuideRegistry.matchQuery`.

## Key behaviors

- **Navigation**: existing `AppRouter` helpers; failures fall back to
  coach-card mode, never crash. Back stack is preserved (push/switch only).
- **Resume/restart/replay**: progress persists per user; `exitGuide` keeps
  position, `restartGuide` resets, completed guides replay from Learn.
- **First-time tour**: onboarding sets `tourOfferPending`; Home offers once
  (Start/Skip both dismiss; completing `quick_tour` records `completed`).
- **Assistant**: explicit teach-me phrasing short-circuits `ask()` with an
  honest message and stages `pendingGuideId`; the sheet/command center
  consumes it post-frame (sheet pops first). All other queries reach the
  engine untouched.
- **Colors**: forest/emerald/sage only. Reduced motion disables pulse,
  breathing, and animated transitions. Touch targets ≥ 44dp; Semantics on
  overlay, card, and step counter.
- **Timers**: anchor settling uses cancellable `Timer`s; never pend past
  step change/exit/dispose (widget-test invariant safe).

## Tests

- `test/unit/guides/` — registry, unlocking, query matching, model json.
- `test/widget/guides/` — overlay, Learn center (use `settleGuide` helper:
  `pump(3s)` + settle, to flush production settle timers under FakeAsync).
- `test/integration/guides/` — real detection, tour lifecycle, user
  isolation, Assistant staging.
