# Core UX Fixes + Assistant Unification + Exam Planning

## What changed and why

All four areas already had strong foundations; the batch fixed real gaps
instead of rebuilding.

- Home XP opened Progress. It now opens the existing Reward Centre
  (`AppRouter.openRewards` → `RewardsScreen`); no duplicate created.
- Custom Focus durations already flowed into the Focus engine. Added the
  missing piece: explicit validation errors (empty/non-numeric/zero/
  negative/over-max) with a 360-minute ceiling constant, instead of the
  Set button silently ignoring bad input. Presets kept (15/25/35/45/60
  + Custom). Custom stays FREE; Deep/Strict keep existing premium gates.
- Tools Hub showed two assistant entries. Now exactly one —
  "Student OS Assistant" → the canonical Command Center screen. The
  quick-ask sheet remains for contextual entry points: same controller,
  conversation, context, and actions (one system, overlay + full-screen
  presentations). Updated the affected Tools Hub test.
- Exam CRUD, countdown, detail, and delete-confirmation already existed.
  Added: centralized inclusive preparation-window math
  (`preparationWindowDays`, `preparationStart`), post-save "Plan
  preparation?" offer (create + date-change; never touches existing
  work), Home empty-state add-exam tile, assistant exam-date moves
  ("Move my Accounts exam to 12 October" → preview → confirm →
  `updateExam`), exam-prep quick action, and contextual suggestion
  ordering. Fixed a real dialog-after-pop bug found during testing
  (navigator captured before dismissal).

## Countdown rule (centralized on `StudentExam`)

`daysUntilExam` = examDay − today in full days (1 Oct → 10 Oct = 9).
`preparationWindowDays` = difference + 1, i.e. 10 calendar days
inclusive (Oct 1 → Oct 10); 1 for today, 0 for past, null without a
date. Covered by `test/unit/exams/exam_dates_test.dart` including the
exact 1-Oct→10-Oct scenario.

## Assistant exam integration

Parser: exam-date moves (absolute "12 October" + weekday/tomorrow
fallbacks), new `updateExamDate` intent, ambiguity clarification,
date-answer follow-ups via pending intent. Engine previews the move,
executes through `ExamController.updateExam` (time of day preserved),
and suggests preparation recalculation. Exam context (countdown,
exam-plan proposals) flows through existing handlers.

## Entry points

Home (XP → Rewards, exam tile/add-exam, assistant bar), Tasks
(Organize), Planning (Optimize, Pro-gated), Sleep (plan-around, Pro),
Exam detail (Exam Intelligence card, Pro), Tools Hub (unified
Assistant + Pro). Assistant route `/assistant` canonical; sheet kept
for in-context asks.

## Verification

New tests: Home XP navigation (3), focus custom durations (5), Tools
merge (1), exam dates (8), creation sheet (4), exam delete (1), Home
exam tiles (2), assistant exam moves (4), full exam flow incl. isolation
(2), extended exam-plan coverage (3). Full suite 2665 green; analyze
clean on touched areas; web + release/debug APKs build.

## Explicitly not implemented

Phone home-screen widgets (no widget code of any kind), new billing
providers, duplicate controllers/databases, fake syllabus/progress/AI,
medical sleep features.
