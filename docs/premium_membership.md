# Premium Membership Foundation

## What was built

Complete Free-vs-Pro foundation with no live billing: central catalog,
plans, entitlement service, provider-neutral billing layer, purchase/
benefits/membership UI, feature gates with direct paywall redirects, and a
debug-only Pro preview. Normal users default to FREE; nothing claims a
purchase without a future verified provider.

## Architecture (all under `lib/features/premium/` + reused core)

- `models/premium_catalog.dart` — 20 stable feature IDs with
  ACTIVE/COMING_SOON status, Free baseline, Free-vs-Pro comparison rows.
  Only ACTIVE features gate; COMING_SOON never opens, even for Pro.
- `models/premium_plan.dart` — 4 plans (₹79 / ₹199 / ₹349 / ₹599),
  integer-paise math, effective-monthly + savings derived programmatically
  (₹66.33/₹58.17/₹49.92; Save 16/26/37%), yearly recommended.
- `models/premium_subscription.dart` — provider-neutral states
  (free/active/cancelledPendingExpiry/expired/pending/gracePeriod/unknown),
  provider + verification source. Only verified/development ACTIVE (and
  grace, unexpired cancellations) grant access; corrupt data degrades to
  free.
- `services/entitlement_service.dart` — THE gate: dev override (debug
  only) → stored subscription → legacy trial/XP (existing behavior kept)
  → locked. User-scoped storage, wired into `ControllerIsolation`.
- `services/premium_gate.dart` — one-line UI check → feature or contextual
  paywall. `services/premium_analytics.dart` — event names, debug-only
  logging; verified-purchase event asserts if ever misused pre-provider.
- Providers: existing `SubscriptionProvider` interface extended
  (`initialize`, `loadProducts`); Google stub updated; Apple StoreKit and
  Razorpay stubs added (all unavailable, no SDKs, no secrets).
- UI: `PremiumPurchaseScreen` (`/premium`, source-feature header),
  `PremiumBenefitsScreen`, `MembershipScreen` (`/membership`), shared
  widgets (plan/benefit/badge/gate/membership cards). Continue/Restore/
  Manage report provider-unavailable honestly.
- Entry points: Tools Hub Pro item, Account membership section, exam
  "Exam Plan" card, Settings Assistant prefs (existing) + Developer Tools
  (debug-only Unlock/Reset). Old rewards `PremiumScreen` untouched.

## Gates (free taps redirect straight to the paywall)

Deep Focus (mission setup) · Strict Focus (guard tile) · Smart Planning
(Optimize) · Exam Intelligence (exam card) · Advanced Analytics
(`openAnalytics`) · Sleep-Aware Planning (sleep button) · Proactive
Assistant (morning Prepare + triggers for fixDay/catchUp/exam/sleep) ·
Advanced Assistant (Command Center upsell card). Manual chat, basic
planning/focus/sleep/progress stay free.

## Developer preview (DEV ONLY — REMOVE BEFORE PRODUCTION BILLING)

Settings → Developer Tools → DEV ONLY — UNLOCK PRO / RESET TO FREE.
Debug-only UI (`kDebugMode`) + debug-only setter; per-user persisted,
runtime-cleared on logout, restored per user. Never a purchase, never
verified, never counted, no receipts.

## Future billing integration

1. Add Play/App Store/Razorpay SDKs + fill the three provider stubs.
2. Verify purchases server-side; call
   `EntitlementService.applyVerifiedSubscription` with source verified.
3. Add provider product IDs to `ProviderProductMappings`.
4. Wire restore/manage to store account sheets.
5. Remove the Developer Tools group.

## Verification

Unit (catalog math, entitlement states, bypass, isolation), widget
(purchase/benefits/membership/developer/responsive/redirects), integration
(A/B isolation through `ControllerIsolation`), plus one extended existing
focus test (free paywall + pro pass-through). Full suite green; web + APK
builds green.
