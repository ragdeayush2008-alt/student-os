# P1 — Sleep Foundation + Assistant Foundation

## What P1 built

Sleep stays a small planned-window subsystem (bedtime/wake/days/reminders).
The Assistant remains deterministic (no LLM): it gained a standardized sleep
context, a persisted conversation history, a full Command Center screen, six
quick actions, and one real confirmed mutation (set sleep window).

## Sleep architecture

- `lib/features/sleep/models/sleep_schedule.dart` — `SleepSchedule`
  (minutes-since-midnight, overnight-aware `plannedMinutes`, safe-default
  `fromJson`) + pure `SleepScheduleValidation` (validate, duration math,
  24h/12h formatting). No medical concepts anywhere.
- `lib/features/sleep/sleep_controller.dart` — singleton `ChangeNotifier`,
  HabitController pattern: user-scoped `sleep_schedule` key in
  `StorageService`, `load()` always terminates loaded, `saveSchedule`
  validates first (returns error string), `setEnabled`, `clearSchedule`,
  `clearData` (memory only). Wired into `ControllerIsolation` reload/clear.
- Reminders reuse `NotificationService.scheduleDaily` with deterministic
  `studentLifeReminder('sleep_bedtime'/'sleep_winddown')` ids; payload type
  `sleep_schedule` deep-links to the schedule screen. Daily (not per-day:
  documented limitation — day selection constrains planning, reminders fire
  daily while enabled).

## Assistant architecture (reused, not rebuilt)

Engine, deterministic parser, intent/action models, controller, and sheet
are untouched in structure. P1 adds:

- Context: `AssistantContextSnapshot` gains `hasSleepSchedule`,
  `sleepWindowLabel`, `sleepDurationLabel`, `sleepEnabled` (guarded read of
  `SleepController`, disabled/missing → null) + `summaryLine` fragment.
- Intents: `openSleepSchedule`, `updateSleepSchedule` (+ `bedtimeMinutes` /
  `wakeMinutes` fields). Parser matches schedule keywords before the
  sleep-summary block and extracts two explicit clock times; bare numbers
  are treated as durations and ignored.
- Actions: `AssistantActionType.openSleepSchedule` (read) and
  `updateSleepSchedule` (mutating, confirmation-gated) carrying
  `sleepBedtimeMinutes`/`sleepWakeMinutes`. `executeAction` applies the
  window via `SleepController.saveSchedule` only after Confirm.
- Conversation: `AssistantMessage` (role/text/timestamp/title/kind) list in
  the controller, persisted per user (`assistant_conversation`, capped at
  30), `loadConversation()` on login, `clearConversation()` (memory +
  storage) available to the user. Ordinals/durations/confirmations keep
  working through the existing ephemeral context.
- Quick actions: `assistant_quick_actions.dart` — the six P1 ids; navigate
  (plan/sleep) or structured `ask()` prompt, never faked completion.
- UI: `assistant_result_card.dart` (result card + history bubbles) shared by
  the sheet and the new `assistant_command_center_screen.dart` (route
  `/assistant`: greeting, Next Best Action, Today + sleep summary, quick
  actions, conversation, input, clear). Sheet keeps working with history.
- Entry points: Tools Hub (Assistant Command Center, Ask Student OS,
  Sleep Schedule), Home sleep card (`SleepSummaryCard`, shared with the
  Command Center), assistant quick action, notification tap.

## Persistence & isolation

All sleep/assistant-conversation data is user-scoped (`AuthIsolation`
user id → `StorageService` keys). Logout clears memory only; login reloads
that user's data. Verified by isolation tests (sleep + conversation).

## P2 extension points (do NOT implement yet)

- `updateSleepSchedule` is the template confirmed mutation: add P2 action
  types the same way (enum + `actionClass` + handler + `executeAction`).
- Natural-language times: extend `_extractSleepWindow` / intent fields.
- Sleep-aware planning: read `SleepController.instance.schedule`
  (`appliesTo(day)`, `plannedMinutes`) inside `PlanningEngine`/context.
- Promote the sheet to thin-launcher if the Command Center absorbs it.
- Cloud sync for `sleep_schedule`/`assistant_conversation` following the
  existing Supabase upsert pattern (local-first stays authoritative).
