# Onboarding Step 2 — Premium Redesign (UI-only)

## Scope

Visual/UX transformation of the middle onboarding page ("Select Your
Goal": search + Popular Exams & Goals + All Categories + hierarchy
drill-in + Continue CTA). Selection state, catalog source, validation,
persistence, Step 3 navigation, and dark-mode behavior are unchanged.

## What changed (all in `onboarding_screen.dart`)

- Tonal backdrop: ivory → mist → pale sage gradient (light) and deep
  emerald depth (dark), plus two static ~4%-opacity discs (zero repaint,
  zero animation cost).
- Header: back button gains a soft shadow; progress keeps the shared
  animated segmented bar with its semantics.
- Title block: eyebrow line, larger display title, relaxed subtitle,
  staggered mount entrances (fast, reduce-motion aware).
- Search: white filled surface, focus elevation + shadow, new
  placeholder, accessible label, same filtering logic.
- Popular items: pill buttons → compact cards (icon tile, two-line
  title, chevron, 48dp touch target, pressed feedback).
- Category cards: tonal surfaces, sage icon tiles, two-line
  descriptions, circled arrow affordance, soft shadows, haptics.
- Search results, families, and programs share one `_GoalListTile`
  geometry (previously three near-identical row layouts).
- Level chips: 40dp targets, selected shadow; program detail untouched
  except inherited surfaces.
- Continue: arrow affordance, enabled elevation, hairline top divider,
  safe-area preserved; exact labels kept (`Continue`, etc.).
- Kept verbatim for tests/UX: `Select Your Goal`, `Popular Exams &
  Goals`, `All Categories`, `Continue`, all catalog content.

## Verification

`test/widget/onboarding/onboarding_step2_redesign_test.dart` (10 tests:
open, back, progress semantics, search, empty state, popular/category
selection, CTA gating, Step 3 reach, 320dp, semantics). Full suite
green; analyze clean; web build green.

## Widgets explicitly NOT included

No home-screen widgets, no billing, no auth changes, no catalog content
changes, no selection-logic changes.
