# P3 — Autonomous Student OS + Adaptive Sleep-Aware Assistant

## What P3 added on top of P1/P2

P1/P2 structures are preserved (no rebuilds). P3 adds the daily loop
around them: preparation flags, proactive triggers with anti-spam,
morning/evening flows, adaptation, safety levels, preferences, and
briefing notifications. The Assistant analyzes and prepares automatically;
consequential changes still need Confirm.

## Daily loop architecture

- `assistant_daily_state.dart` — `DailyAssistantState` (date, prepared,
  planVersion, reviewed, adaptations, applied counts, dismissals, action
  log ≤20, sleep fingerprint; rolls over daily, corrupt-tolerant) and
  `AssistantPreferences` (6 toggles, calm defaults).
- `daily_assistant_controller.dart` — owns state + prefs (user-scoped
  storage), diff-based observation of Task/Focus/Sleep/Exam/Planning
  controllers (focus ticks filtered, 2s notify throttle), trigger
  evaluation, preference-gated sleep access
  (`effectiveSleepSchedule()` — the single choke point), briefing
  notification reconciliation, action log. Wired into
  `ControllerIsolation` reload/clear.
- Automation levels on `AssistantActionClass`: read→L1 information,
  safeNavigation→L2 preparation, mutating/highImpact→L3 consequential.
  Proactive surfaces only ever lead to L1/L2 outcomes (prompts and staged
  proposals); L3 executes solely via the P2 confirm gate.

## Morning / evening / tomorrow (engine intents)

- `morningBriefing` ("prepare my day", "brief me", …): empty → honest
  empty; work → P2 proposal staged once per day (`prepared` + version;
  repeats report status instead of duplicating). Buttons: Apply,
  Review My Day, Start First Task.
- `eveningReview`: real completions/focus/applied counts, tomorrow's top
  unfinished item, sleep line; "Nothing to review yet." when empty;
  marks reviewed. Buttons: Prepare tomorrow, View Tomorrow.
- `prepareTomorrow`: wake-anchored sessions + carry-over moves, confirm-gated.
- Sleep change after preparation lapses `prepared` and surfaces a rebuild
  trigger; re-preparing records the new fingerprint.

## Triggers + anti-spam

`buildTriggers()` (on demand, no timers): sleepChanged, sleepBoundary
(<60m to bed), fixDay (overload), overdueTask, examPrep (≤7d), catchUp
(5+ backlog), aheadOfPlan (15m+ early finish, per-session id). Suppressed
by: preferences off, active focus, dismissed-today, completed work; capped
at 3, deduped, stable order. `evaluationKey()` exposes state-change
detection for "recalculate when useful".

## Adaptation rules (deterministic, documented in code/tests)

- Sessions never cross the sleep boundary (authoritative items are
  trimmed with honest deferral notes; empty result → "Evening Protected").
- Priority tiers are exclusive (overdue no longer double-counts
  due-today).
- Fix-day keeps what fits, moves the rest to tomorrow (moves only).
- No auto-apply anywhere; no background monitoring; no evening
  automation beyond surfacing.

## UI

Command Center: morning briefing card (5–12h, unprepared, work exists),
attention triggers (tap → prompt, ✕ dismisses for today), NBA with
reason bullets + Later, evening review card (19h+ or active day),
tomorrow prep, activity log. Non-const section widgets so singleton
reads rebuild with the screen. Settings gains a real Assistant group
(6 toggles). No Home redesign.

## Notifications

Existing daily primitive only: morning briefing at wake (or 7:30) and
optional 9 PM review, both preference- + permission-gated, reconciled on
load/prefs/sleep change. Payloads `briefing`/`review` open the Command
Center.
