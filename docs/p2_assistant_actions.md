# P2 — Intelligent Assistant + Sleep-Aware Actions

## What P2 added on top of P1

P1's foundation (sleep schedule, context, conversation, cards, confirm gate)
is untouched in structure. P2 makes the Assistant propose and — only after
Confirm — execute through existing controllers. Everything stays
deterministic and local-first; no LLM, no medical sleep content.

## Intent system (extends `AssistantIntentType`, no duplicate system)

New: `createTask`, `prioritizeTask`, `rescheduleTask`, `breakTask`,
`catchUp`, `examPlan`, `revisionPlan`, `refinePlan`. Reused: `planTime`
(sleep-trimmed + appliable), `rebalanceDay` (now an analyzed Fix-My-Day),
`completeTask`, `startFocus`, `updateSleepSchedule` (single-field updates),
existing show/intelligence intents. New slots: `taskPriority`,
`subtaskCount`, `eveningCutoffMinutes`, `refineOp`/`refineIndex`.

Parser (`_parseP2Command`, runs before broad rules): create/prioritize/
move-to-date/break/complete-by-title, fix-day, catch-up backlog phrasings,
exam/revision plans, bedtime-only/wake-only/duration sleep inputs, evening
cutoffs ("don't schedule after 10pm"), plan-around-sleep. Guarded so
note-creation, sleep-summary, and recovery phrasings keep their owners.
Title matching is best-first with top-score ties clarifying; bare
this/it/that falls through to existing flows.

## Planning engine (`assistant_planning_engine.dart`, pure)

`proposeDayPlan`: overdue → due-today → exam-linked → high → normal → low
(exclusive tiers), 25–50m sessions, 10m breaks, budget + 8h ceiling,
sleep-boundary and evening-cutoff clamping, session cap, honest
`unscheduled` reasons, `conflicts` notes, deterministic order, anchored
start times for previews. Already-scheduled items are never duplicated.

## Proposal flow (controller-staged, engine-rendered)

Preview (`_previewProposal`: timed steps, moves, creations, sleep line,
buffer/unscheduled footnotes, Apply/Edit/Cancel) → staged as
`pendingProposal` → Confirm applies item-by-item via `scheduleBlock` /
`updateTask` / `createTask` with success/partial/failed reporting; Cancel
or any fresh question clears staging. "Remove X" / "make Y first" refine
against staged titles (unmatched verbs clarify with real item titles;
clarifications preserve staging; exact-title answers complete them).
`Edit` prefills + focuses the input. Create-task title follow-ups and
sleep wake-time follow-ups resolve through pending clarification intents.

## Task actions (all confirmed, all through `TaskController`)

Create (title/date/priority/subject, missing title clarifies), prioritize,
reschedule to weekday/tomorrow/today, break into 2–7 subtasks, complete.
Ambiguity clarifies with real titles; execution failures report without
deleting anything.

## Fix My Day / Catch-Up / Exam / Revision

- Fix My Day: remaining due work vs time-to-sleep; fits → on-track
  message, else keep/move-to-tomorrow proposal (moves only, capped).
- Catch-Up: overdue+high → tomorrow, next → day+2, rest noted (cap 8).
- Exam plan: nearest or subject-matched dated exam → core/practice/
  revision/final phases from real topics (or honest no-topics note) →
  confirm creates ≤6 prep tasks. Dateless/absent exams degrade honestly.
- Revision plan: due topics → 30m sessions over 3 days as tasks.
- Focus: existing start flows carry task/topic context; proposals keep
  Start alongside Apply.

## Sleep commands

Bedtime-only / wake-only keep the other end; "N hours of sleep" asks for
wake time (choices incl. current); cutoff-aware planning; conflicts with
sleep surface as [Keep Sleep] (default preview) vs [Adjust Sleep Schedule]
(screen/assistant entry) — never silent changes.

## UI

Proposal previews share one card (Apply/Edit/Cancel); Edit affordance only
for staged proposals. Entry points: Tasks "Organize", Planning "Optimize",
Sleep "Plan around my sleep" (all via `openAssistant` prefills), Home +
Tools Hub unchanged. Command Center chips reorder contextually (no sleep
→ sleep first, overdue → urgent first, exam → study first).

## Persistence / isolation / offline

Proposals are session-only (never stored); conversation/tasks/blocks/sleep
stay user-scoped local-first. Verified A→B→A through the real
`ControllerIsolation` path. All actions work offline (deterministic).

## P3 readiness (not implemented)

Proposal applier is the automation seam: P3 adds triggers + review UI
around `pendingProposal`-shaped flows. No background monitoring, no
autonomous execution, no morning/evening automation exists.
