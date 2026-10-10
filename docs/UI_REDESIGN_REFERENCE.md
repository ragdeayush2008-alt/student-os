# Student OS — UI/UX Redesign Reference

> **Purpose:** Human-readable reference for manually drawing the new Student OS UI
> **Source of Truth:** `docs/UI_FUNCTIONAL_INVENTORY.md` (complete technical inventory)
> **Status:** This document describes ALL current functionality. It does NOT redesign anything.
> **Rule:** Every functional capability must be preserved in the new UI, even if navigation changes dramatically.

---

## 1. COMPLETE APP STRUCTURE

### 1.1 Top-Level Architecture

Student OS uses a **bottom-tab shell** with **4 primary destinations** for authenticated users, plus a full **authentication flow** for unauthenticated users.

```
APP LAUNCH
    │
    ├── NOT AUTHENTICATED → Auth Experience
    │   ├── Welcome Screen
    │   ├── Sign In (email/password + Google)
    │   ├── Sign Up
    │   ├── Forgot Password
    │   ├── Update Password
    │   ├── Verification Pending
    │   ├── Onboarding (education profile setup)
    │   └── Auth Loading
    │
    └── AUTHENTICATED → App Shell (4 bottom tabs)
        ├── TAB 1: Home
        ├── TAB 2: Plan
        ├── TAB 3: Study
        └── TAB 4: More
```

### 1.2 All Major Modules/Sections

| # | MODULE | TABS/PATHS | DESCRIPTION |
|---|--------|------------|-------------|
| 1 | **Authentication** | Full app flow | Welcome, sign in, sign up, forgot password, verification, onboarding |
| 2 | **Home** | Tab 1 `/home` | Intelligent dashboard, daily briefing, recommendations, quick actions |
| 3 | **Planning** | Tab 2 `/plan` | Daily plan generation, planning blocks, schedule management, rebalance, recovery |
| 4 | **Study** | Tab 3 `/study` | Study sessions, recommendations, revision, practice, focus integration |
| 5 | **Focus** | Pushed routes | Focus sessions (Timer/Stopwatch/FocusGuard), missions, history, insights, distraction inbox, FocusGuard settings |
| 6 | **Tasks** | `/tasks` + More | Task list, task detail, task creation |
| 7 | **Subjects** | `/subjects`, More | Subject list, subject detail with chapters/topics |
| 8 | **Exams** | `/exams` + More | Exam list with countdowns, exam detail |
| 9 | **Knowledge/Practice** | `/knowledge`, `/practice-center` | Subject/topic browsing, practice questions, practice sessions |
| 10 | **Calendar** | `/calendar`, Plan tab | Week/day/month views, events, conflicts, availability |
| 11 | **Revision** | `/revision` | Revision queue, active recall sessions, spaced repetition |
| 12 | **Notes** | `/note-editor`, `/note-detail` | Create/edit/view notes with subject/topic context |
| 13 | **Resources** | `/resources`, `/search` | Resource library, search, download, favoriting |
| 14 | **Progress** | `/progress` | Overall progress dashboard, XP, level |
| 15 | **Analytics** | More tab | Academic performance charts and trends |
| 16 | **Leaderboard** | More tab | Rankings |
| 17 | **Achievements** | More tab | Badges and milestones |
| 18 | **Rewards** | More tab | Marketplace, redeem XP for themes/perks |
| 19 | **Premium** | More tab, Profile | Subscription, trial, feature gating |
| 20 | **Streak** | More tab | Streak tracking and details |
| 21 | **Goals** | `/goals`, More tab | Goal creation, tracking, planning |
| 22 | **Notifications** | `/notifications` | Notification center with filters |
| 23 | **Settings** | `/settings` | Theme, autopilot, focus duration, notifications, preferences |
| 24 | **Profile** | `/profile` | User identity, education info, links to features |
| 25 | **Account Data** | More tab | Account data management, cloud sync |
| 26 | **Assistant** | Bottom sheet overlay | AI-powered personal assistant with natural language |
| 27 | **Intelligence** | Backend (not a screen) | 24 engines: recommendations, autopilot, risk detection, daily briefing |
| 28 | **Gamification** | Throughout app | XP, levels, streaks, achievements, leaderboard, rewards |

### 1.3 Sheets (Modal Bottom Sheets)

| SHEET | OPENED FROM | PURPOSE |
|-------|-------------|---------|
| **TaskCreationSheet** | HomeScreen, GlobalAddSheet, PlanningScreen | Create new task |
| **AddEditEventSheet** | CalendarScreen, PlanningScreen, GlobalAddSheet | Create/edit calendar events |
| **DailyPlanSheet** | PlanningScreen, GlobalAddSheet, UniversalActionLauncher | Generate daily study plan |
| **FocusModeSelectionSheet** | TaskDetailScreen, SubjectDetailScreen, ExamDetailScreen, FocusCenterScreen | Select focus mode with entity context |
| **StudentAssistantSheet** | HomeScreen, More tab, UniversalActionLauncherSheet, GlobalAddSheet | AI assistant (natural language) |
| **GlobalAddSheet** | HomeScreen FAB, UniversalActionExecutor | Global quick creation (7 options) |
| **UniversalActionLauncherSheet** | UniversalActionExecutor | Universal action launcher ("What do you want to do?") |
| **EntityActionSheet** | All entity detail screens | Contextual action menu per entity type |
| **PracticeModeSelectionSheet** | KnowledgeCenterScreen | Select practice mode for a topic |
| **SubjectCreationSheet** | SubjectsScreen, GlobalAddSheet | Create new subject |
| **ExamCreationSheet** | ExamScreen, GlobalAddSheet | Create new exam |
| **ResourceCreationSheet** | ResourcesScreen, GlobalAddSheet | Create new resource |
| **LevelUpDialog** | AppShell (automatic) | Level up notification |
| **ConflictDialog** | CalendarScreen | Schedule conflict resolution |
| **EditProfileSheet** | MoreScreen | Edit profile information |
| **RewardRedemptionFlow** | RewardsScreen | Redeem rewards with XP |

### 1.4 Dialogs

| DIALOG | TRIGGERED FROM | PURPOSE |
|--------|---------------|---------|
| **Delete Confirmation** | TaskDetailScreen, Calendar, Notes | Confirm destructive action |
| **Sign Out Confirmation** | HamburgerMenu | Confirm logout |
| **FocusGuard Permission Dialogs** | FocusGuardSettingsScreen | Android Usage Access, Overlay permissions |

### 1.5 Menus

| MENU | FILE | DESCRIPTION |
|------|------|-------------|
| **HamburgerMenu** | `lib/core/widgets/hamburger_menu.dart` | Slide-from-left overlay (80% width, max 330dp). Sections: HOME, PLAN & STUDY, PROGRESS, ASSISTANT, ACCOUNT. Shows streak badge, unread notification count, profile header, sign out. |

### 1.6 Hidden / Less Visible Features

| FEATURE | WHERE | HOW TO ACCESS | WHAT IT DOES |
|---------|-------|---------------|-------------|
| FocusGuard overlay | FocusGuardService | Automatic when FocusGuard mode active | Blocks apps, shows overlay intervention during focus |
| FocusGuard blocked app detection | FocusGuardController | Automatic 1-second monitoring | Detects blocked app usage, records distraction |
| Focus checkpoints | FocusController | Automatic at 15/30/45 minutes | Awards checkpoint bonus to focus score |
| Focus distraction capture | FocusController | Automatic during FocusGuard sessions | Captures distractions |
| Missed session recovery | AcademicIntelligenceController | From HomeScreen Today card | Reschedules missed work |
| Day rebalancing | AcademicIntelligenceController | From HomeScreen Today card | Rebalances overloaded schedule |
| 30-minute burst | StudentOSIntelligenceEngine | From HomeScreen hero | Quick focus burst recommendation |
| Autopilot mode | UserPreferencesController | SettingsScreen | Automatic planning mode |
| Edit profile | _EditProfileSheet | From MoreScreen | Edits profile information |
| Theme variant unlocking | ThemeManager | RewardsScreen | Unlock cosmetic themes with XP |
| Feature gating | FeatureGate | Throughout app | Controls feature availability based on entitlements |
| Focus launch context preservation | FocusLaunchContext | Automatic | Preserves subject/topic/chapter/task/exam/block across entity-to-focus flows |
| Idempotent focus→study bridge | StudyController | Automatic | Prevents double XP when focus completes |
| PlanningBlock status derivation | UniversalActionExecutor | Automatic | Computes block display status (upcoming/current/completed/missed/skipped) |
| Notification reconciliation | NotificationCoordinator | Automatic on app launch | Cancels outdated notifications |
| Deep link OAuth handling | AppLinks plugin | App launch/callback | Handles OAuth callbacks automatically |
| Session restoration | AuthIsolation | App launch | Restores previous session automatically |

---

## 2. SCREEN-BY-SCREEN BREAKDOWN

### 2.1 HOME SCREEN (`lib/features/home/home_screen.dart` — 1760 lines)

**Purpose:** The intelligent student dashboard. Answers "What should I do now?" by aggregating all data sources into one contextual view.

**What the student needs to see:**
- Greeting with their name and the current time of day
- Their current streak and XP level
- The single most important action for them right now (the "hero" card)
- How their day is going (planned minutes, completed minutes, remaining time)
- Their next scheduled block
- Whether they have missed any work that needs recovery
- Whether today is overloaded and needs rebalancing
- Quick access to the most common actions
- A way to ask the assistant
- Upcoming exams, revision items, and goals
- Their progress toward the next level

**All Important Information Displayed:**
1. **Header:** Greeting ("Good morning, [Name]"), date label, streak badge, XP badge, Add button (FAB), Profile avatar
2. **Primary Hero Card:** Contextual — shows "Start My Day", "Continue My Day", or active focus recommendation. Displays the AI's recommended action. Includes 30-minute burst button. Shows day hint text (overload/recovery messages).
3. **First-Time Empty State:** If no data exists at all (no tasks, no blocks, no subjects, no exams), shows a guided setup prompt
4. **Today's Overview Card:** Health state badge (clear/onTrack/busy/overloaded/recoveryNeeded), planned vs completed minutes, progress bar, stats line (remaining/available/overdue/focus minutes), next block strip, missed session recovery banner, overload warning banner, early completion notification, "View Plan" button
5. **Today's Plan Section:** List of PlanningBlocks for the current day with their status
6. **Today's Schedule (Agenda):** Calendar commitments from AcademicScheduleController, color-coded timeline
7. **Needs Attention (Academic Risk Banner):** Contextual risk alerts (exam pressure, overdue tasks, etc.)
8. **Quick Actions Grid:** 7 tiles — Focus, Plan Day, Study, Revise, Add Task, Exams, Ask OS
9. **Assistant Bar:** Quick entry to ask Student OS
10. **Upcoming & Goals Section:** Next exam, revision count, personal goal
11. **Progression Footer Bar:** Level indicator, XP progress bar, taps to open full progress

**All Available Actions/Buttons:**
- Tap profile avatar → ProfileScreen
- Tap "Add" FAB → GlobalAddSheet
- Tap hero action → UniversalActionExecutor.executeAction()
- Tap 30-min burst → startQuickFocus()
- Tap Rebalance (on overload) → AcademicIntelligenceController.rebalanceDay()
- Tap Recover (on missed session) → recoverMissedSession()
- Toggle Done Today → setDoneForToday()
- Tap Quick Action tiles → respective screens/sheets
- Tap Assistant bar → StudentAssistantSheet
- Tap "More" in Upcoming section → MoreScreen
- Tap Progression bar → ProgressScreen
- Tap risk banner → ExamDetailScreen / SubjectDetailScreen / TasksScreen

**Secondary Actions:**
- View Plan button → PlanningScreen
- Add Task in Quick Actions → TaskCreationSheet

**Hidden/Contextual Actions:**
- The hero card itself IS the contextual action — it changes based on AI recommendation
- Risk banner items have context-dependent navigation targets

**Navigation Destinations:**
- TaskDetailScreen, FocusCenterScreen, FocusMissionSetupScreen, PlanningScreen, StudyScreen, ProgressScreen, ExamDetailScreen, SubjectDetailScreen, TasksScreen, GlobalAddSheet, StudentAssistantSheet, ProfileScreen, MoreScreen

**Modals/Sheets Opened:**
- TaskCreationSheet, GlobalAddSheet

**Important States:**
- **First Launch:** Guided empty state with setup prompt
- **Loading:** Loading indicator while 19 controllers load (each with 8s timeout)
- **Error:** "Couldn't load your day" message with retry button
- **Empty (no data):** Empty state with quick actions
- **Populated:** Full dashboard
- **Offline:** Cached data shown, most actions still available
- **Overloaded:** Overload warning banner with Rebalance button
- **Recovery Needed:** Recovery suggestion with Recover button
- **Done For Today:** Progress summary
- **Focus Active:** Focus indicator in header

**Empty/Loading/Error/Offline States:**
- Loading: Shows _HomeLoadingState
- Error: Shows AppErrorState with retry
- Empty: Shows _FirstTimeEmptyState (guided setup)
- Offline: Cached data shown, UI indicates limited connectivity

**Related Features:**
- All controllers feed into this screen: DailyOsCoordinator, AcademicIntelligenceController, TaskController, ExamController, StudyController, SubjectController, StudentService, GoalController, ResourceController, PlanningBlockController, FocusController, AcademicScheduleController, ProgressionController, StreakService, AuthService
- AutopilotEngine, StudentOSIntelligenceEngine, AcademicIntelligenceEngine

---

### 2.2 PLANNING SCREEN (`lib/features/planning/planning_screen.dart` — 1475 lines)

**Purpose:** Daily planning and schedule management. The automated intelligent planner that generates and manages the student's day.

**What the student needs to see:**
- The current date and day selector (previous/next week navigation)
- Their primary/next action hero card (only on today)
- Whether they have missed sessions that need recovery
- Day workload and capacity summary
- Any upcoming exam context
- Overdue tasks (only on today)
- The agenda/scheduled sessions for the selected day
- Upcoming deadlines

**All Important Information Displayed:**
1. **Header:** "Plan" title, date context (Today/Tomorrow/Yesterday/day name), Plan Day button, Create Task button, Previous/Next week navigation
2. **Day Selector:** Visual day picker with overload indicators
3. **Missed Sessions Banner (today only):** List of missed sessions with Reschedule and Dismiss options
4. **Primary Action Card (today only):** The AI's next action — Start Focus with context, Complete task, View task detail, Plan day. Includes task-specific focus with auto-calculated duration.
5. **Day Workload Card:** Workload summary, capacity indicator, Rebalance button
6. **Upcoming Exam Context:** Next exam details with countdown
7. **Overdue Work Section (today only):** List of overdue tasks
8. **Day Agenda:** Scheduled sessions, tasks, planning blocks for the selected day, with Start Focus buttons on planning blocks
9. **Upcoming Deadlines:** List of upcoming tasks

**All Available Actions/Buttons:**
- Plan Day button → DailyPlanSheet
- Create button → TaskCreationSheet (pre-filled with selected date)
- Previous/Next week navigation
- Reschedule missed session → rescheduleMissedSession()
- Dismiss missed session → dismisses banner
- Rebalance → AcademicIntelligenceController.rebalanceDay()
- Complete task → TaskController.completeTask()
- Open task detail → TaskDetailScreen
- Start Focus from block → AppRouter.startPlanningBlockFocus()
- View all tasks → TasksScreen
- Start Focus from task → AppRouter.startContextualFocus()

**Navigation Destinations:**
- TaskCreationSheet, DailyPlanSheet, TaskDetailScreen, FocusSessionScreen, FocusModeSelectionSheet, TasksScreen

**Modals/Sheets:**
- DailyPlanSheet, TaskCreationSheet

**Important States:**
- Loading, Empty, Populated
- Block status: upcoming/current/completed/missed/skipped (each has different actions)
- Missed sessions visible only on today
- Overdue tasks visible only on today
- Workload states: clear/onTrack/busy/overloaded/recoveryNeeded

---

### 2.3 STUDY SCREEN (`lib/features/study/study_screen.dart` — 1622 lines)

**Purpose:** Academic execution hub with AI-powered recommendations. Tells the student what to study, provides focus integration, and tracks study activity.

**What the student needs to see:**
- Whether a focus session is currently active (with timer display)
- The AI's study recommendation ("What should I study?")
- Alternative study recommendations
- Revision items due
- Today's study activity and progress (120 min target)
- Available time allocation suggestions
- Upcoming exams with pressure indicators
- Pending study tasks
- Weekly study rhythm
- Recent study activity

**All Important Information Displayed:**
1. **Header:** "Study" title, streak, active focus indicator ("Focus session active" or "Academic execution hub")
2. **Active Focus Card (if session running):** Elapsed time, remaining time, session objective
3. **What Should I Study? Card:** Primary recommendation with alternatives, Start Focus button, Plan It button
4. **Today's Study Activity Card:** Minutes studied vs 120 min target, progress bar, session count, View Plan link
5. **Available Time Allocation Card:** AI-suggested study blocks based on available time
6. **Upcoming Exams Pressure Strip:** Exams with countdown, Study Exam action
7. **Revision Due Section:** Revision items due, Revise action (starts contextual focus)
8. **Study on a Task Section:** Pending study tasks, Focus Task action (starts mission-based focus)
9. **Weekly Study Rhythm:** Visual representation of study consistency
10. **Recent Activity:** Recent study sessions, Start First action

**All Available Actions/Buttons:**
- Start Focus (from recommendation) → AppRouter.startContextualFocus()
- Study subject → SubjectDetailScreen or StudyScreen
- Practice topic → PracticeCenterScreen
- Revise topic → RevisionScreen
- View Plan → PlanningScreen
- Study Exam → starts contextual focus with exam context
- Revise item → starts contextual focus with revision context
- Focus Task → starts mission-based focus for the task
- Start First → starts focus with "General" subject

**Navigation Destinations:**
- FocusCenterScreen, FocusSessionScreen, KnowledgeCenterScreen, RevisionScreen, ExamDetailScreen, SubjectDetailScreen, PracticeCenterScreen, PlanningScreen

**Modals/Sheets:**
- PracticeModeSelectionSheet (when selecting a topic to practice)

**Important States:**
- Loading, Empty, Populated
- Focus Active vs Not Active (changes layout significantly)
- Study streak displayed
- Progress toward 120 min daily target
- Study streak days, week durations, strongest day

---

### 2.4 FOCUS CENTER SCREEN (`lib/features/focus/presentation/screens/focus_center_screen.dart` — 1402 lines)

**Purpose:** The Focus hub. Command center for all focus-related activity: starting sessions, viewing history, managing FocusGuard, and accessing insights.

**What the student needs to see:**
- Current streak and weekly minutes
- A ready-to-focus hero card (if a subject is recommended)
- Quick start presets (sprint, pomodoro, deep focus, deep work)
- Mode selector buttons (Timer, Stopwatch, FocusGuard)
- FocusGuard live status
- Recent session history with scores

**All Important Information Displayed:**
1. **Momentum Stats Row:** Streak (days), This Week (hours/minutes, session count)
2. **Ready to Focus Hero (if subject recommended):** READY TO FOCUS badge, subject icon/name/description, "35 min suggested", Start Focus button
3. **Empty State (no subjects):** "Nothing to focus on yet" message, "Add Subject" button → SubjectCreationSheet
4. **Quick Start Presets:** Sprint, Pomodoro, Deep Focus, Deep Work preset cards
5. **Mode Selector Buttons:** Timer, Stopwatch, FocusGuard (3 equal-width buttons)
6. **FocusGuard Live Status Pill:** Current FocusGuard status
7. **Recent Sessions:** List of recent focus sessions with scores, outcomes

**All Available Actions/Buttons:**
- Tap recommended subject → FocusModeSelectionSheet (with subject context, 35 min)
- Tap preset card → starts preset focus session
- Tap Timer → _openTimerSetup() → FocusModeSelectionSheet
- Tap Stopwatch → _openStopwatchSetup() → FocusModeSelectionSheet
- Tap FocusGuard → _openFocusGuardSetup() → FocusModeSelectionSheet
- FocusGuard settings icon button → FocusGuardSettingsScreen
- History icon button → FocusHistoryScreen
- Add Subject (empty state) → SubjectCreationSheet

**Navigation Destinations:**
- FocusMissionSetupScreen, FocusHistoryScreen, FocusInsightsScreen, FocusDistractionInboxScreen, FocusGuardSettingsScreen, BlockedAppsPickerScreen, FocusModeSelectionSheet, SubjectCreationSheet

**Modals/Sheets:**
- FocusModeSelectionSheet (primary entry to starting a focus session)

**Important States:**
- Idle (no active session)
- Active session (if fc.hasActiveSession, redirects to FocusSessionScreen automatically)
- FocusGuard states: notReady, usageAccessRequired, overlayRequired, ready, unsupported
- Focus session modes: Timer, Stopwatch, FocusGuard

---

### 2.5 FOCUS SESSION SCREEN (`lib/features/focus/presentation/screens/focus_session_screen.dart`)

**Purpose:** The active focus session experience. Displays the timer/stopwatch, controls, and FocusGuard overlay.

**What the student needs to see:**
- Current timer/stopwatch display
- Session objective/title
- Subject/topic context
- Progress bar and checkpoint indicators
- Pause/Resume/End controls
- FocusGuard overlay (when FocusGuard mode is active)

**All Available Actions:**
- Pause session
- Resume session
- End session early

**States:**
- Focusing, Paused, Completed, Interrupted
- Focus phases: focusing, paused, completed, interrupted
- Focus modes: Timer, Stopwatch, FocusGuard

**Automations:**
- Checkpoints at 15/30/45 minutes
- Score calculation (duration/minute ratios + completion + checkpoint bonus - distraction penalty, max 100)
- XP award on completion
- Streak update
- Task completion bridge
- Focus→Study bridge (idempotent)

---

### 2.6 TASKS SCREEN (`lib/features/tasks/presentation/tasks_screen.dart`)

**Purpose:** Task list management.

**All Available Actions:**
- Add Task → TaskCreationSheet
- Filter (all/uncompleted/completed)
- Sort
- Search
- Tap task → TaskDetailScreen

**States:** Loading, Empty ("No tasks yet"), Populated, Error, Offline

---

### 2.7 TASK DETAIL SCREEN (`lib/features/tasks/presentation/task_detail_screen.dart`)

**Purpose:** View and manage a single task.

**What the student sees:**
- Task title, description, priority, estimated effort
- Due date, scheduled blocks
- Subtasks with progress bar
- Linked subject/exam/goal rows
- Completion status banners (completed, overdue)
- Metadata cards

**All Available Actions:**
- Start Focus (uses estimatedMinutes or 25min default) → FocusModeSelectionSheet
- Complete task → TaskController.completeTask()
- Edit → edit task
- Delete → confirmation dialog → TaskController.deleteTask()
- Schedule → PlanningScreen
- Reschedule → PlanningScreen
- View

**States:** Active, Completed, Overdue

---

### 2.8 CALENDAR SCREEN (`lib/features/calendar/presentation/calendar_screen.dart`)

**Purpose:** Academic calendar with unified time layer for events, exams, tasks, and planning blocks.

**What the student sees:**
- View mode selector (Week/Day/Month)
- Today jump button
- Add Commitment button (FAB)
- Day schedule view with timeline
- Conflicts banner
- Availability summary (committed/planned/free)
- Color-coded items (events/exams/tasks/planning blocks/free slots)

**All Available Actions:**
- Today → jump to today
- Add Commitment → AddEditEventSheet
- Switch view mode (Week/Day/Month)
- Previous/Next week/day navigation
- Plan Around event → PlanningScreen
- View Day/Week
- Edit event → AddEditEventSheet
- Delete event → confirmation → AcademicScheduleController.deleteEvent()
- Resolve conflicts → ConflictDialog
- Start Focus from planning block → FocusSessionScreen

**Modals/Sheets:**
- AddEditEventSheet, ConflictDialog

---

### 2.9 REWARDS SCREEN (`lib/features/rewards/rewards_screen.dart`)

**Purpose:** Reward marketplace where students spend XP to unlock features, themes, and perks.

**What the student sees:**
- Marketplace summary (current level, XP, next unlock)
- Next unlock preview
- Affordable rewards carousel
- Category filters: All, For You, Featured, Cosmetic, Academic, Premium, Feature, Badge
- 15 rewards with pricing tiers: starter, progress, advanced, premium, elite

**All Available Actions:**
- Browse rewards by category
- Redeem reward → Redemption flow (atomic: validate eligibility → deduct XP → grant entitlement → persist → notify; rollback on failure)
- View next unlock
- Unlock themes via XP

**States:** Free, Active Trial, Subscribed, Trial Expired

---

### 2.10 SETTINGS SCREEN (`lib/features/settings/settings_screen.dart`)

**Purpose:** All application preferences and configuration.

**What the student sees:**
- **Appearance Mode:** Light/Dark/System theme selector
- **Cosmetic Themes:** Default, Focus Dark, Academic Light, Midnight Scholar (plus locked variants unlocked via XP)
- **Default Focus Duration:** Picker
- **Week Start Day:** Selector (0-6, Sun-Sat)
- **Autopilot Mode:** Suggest/Autopilot/Manual
- **Notification Toggles:** 6 categories (study/planning, tasks/exams/focus, achievements/streak/leaderboard)

**All Available Actions:**
- Toggle theme mode → AppShellController.setThemeMode()
- Select cosmetic variant → ThemeManager.setThemeVariant() (locked shows "Unlock" button → RewardsScreen)
- Set focus duration → FocusController default
- Set week start day → Calendar calculations
- Set autopilot mode → PlanningEngine behavior
- Toggle notifications → UserPreferencesController

---

### 2.11 PROFILE SCREEN (`lib/features/profile/profile_screen.dart`)

**Purpose:** User identity and account management.

**What the student sees:**
- Identity card: Avatar (initials), name, journey label, education level
- Premium badge card (trial/subscribed/free)
- Academic summary (course/board/level/institution/focus)
- Goals wrap
- Links: Achievements, Rewards, Tasks, Settings, Sign Out

**All Available Actions:**
- Edit profile → _EditProfileSheet
- Navigate to: AchievementsScreen, RewardsScreen, TasksScreen, SettingsScreen
- Sign Out → confirmation → clears controllers + session → AuthGate

**States:** Authenticated, Demo mode (detected by `!supaReady || user == null`)

---

### 2.12 MORE SCREEN (`lib/features/more/more_screen.dart`)

**Purpose:** Central hub for all secondary features and settings access.

**What the student sees:**
- **Profile Hero Card:** Avatar, name, level, XP
- **Academic & Goals section:** Academic Schedule, Goals & Targets, Rewards Marketplace, Achievements & Badges, Leaderboard, Progress & Analytics, Knowledge Base & Notes, Study Resources, Subjects
- **Preferences & System section:** Settings, Account & Data
- Footer: "Student OS" version

**All Available Actions:**
- Each row navigates to its respective screen
- Edit profile → _EditProfileSheet

---

### 2.13 STUDENT ASSISTANT SHEET (`lib/core/assistant/presentation/student_assistant_sheet.dart`)

**Purpose:** AI-powered personal assistant accessed via bottom sheet.

**What the student sees:**
- Input field at bottom
- Message history above
- "Student OS Assistant" header
- "Ask questions or plan your time" subtitle
- Response cards with actions

**All Available Actions:**
- Type and send a query → StudentAssistantController → StudentAssistantEngine → parses intent → generates result → executes StudentAssistantAction via AppRouter/UniversalActionExecutor
- Close the sheet

**Special Features:**
- 34 intent types supported (greeting, help, planning, study, revision, practice, exams, tasks, calendar, notes, goals, progress, focus, recovery, rescheduling, etc.)
- 31 action types (navigation, action execution, data queries)
- Natural language parsing
- Clarification support
- Confidence scoring
- Some commands require confirmation
- Empty state guidance
- Initial query support

---

### 2.14 GLOBAL ADD SHEET (`lib/core/navigation/universal_action_executor.dart`)

**Purpose:** Quick creation menu accessible from anywhere via the HomeScreen FAB.

**All Options:**
1. New Commitment / Class (calendar_month) → AddEditEventSheet
2. New Task (checklist) → TaskCreationSheet
3. New Exam (school) → ExamCreationSheet
4. New Subject (school) → SubjectCreationSheet
5. New Note (description) → NoteEditorScreen
6. New Resource (sticky_note_2) → ResourceCreationSheet
7. Plan My Day (auto_awesome) → DailyPlanSheet

---

### 2.15 UNIVERSAL ACTION LAUNCHER SHEET

**Purpose:** Action menu accessible via assistant or UniversalActionExecutor.

**All Options:**
1. Ask Student OS (auto_awesome) → StudentAssistantSheet
2. Start Focus Session (timer) → FocusCenterScreen
3. Plan My Day (auto_awesome) → DailyPlanSheet
4. Manage Tasks (checklist) → TasksScreen
5. Review Exams (school) → ExamScreen
6. Revise Materials (replay) → RevisionScreen
7. Practice & Quizzes (quiz) → PracticeCenterScreen

---

### 2.16 NOTIFICATION CENTER (`lib/features/notifications/presentation/notification_center_screen.dart`)

**Purpose:** All user notifications in one place.

**What the student sees:**
- Notification list (200-item cap)
- Filter tabs: All, Unread, Tasks, Exams, Focus, Progression

**All Available Actions:**
- Filter notifications
- Tap notification → navigates to relevant screen
- Mark as read

**Important States:** Loading, Empty, Populated, Error

---

### 2.17 PROGRESS SCREEN (`lib/features/progress/progress_screen.dart`)

**Purpose:** Overall progress dashboard.

**What the student sees:**
- Level indicator, total XP, current XP, progress to next level
- Achievements section
- Insights section
- Milestones section
- Streak info
- XP history
- Level-up dialog (automatic via AppShell)

**All Available Actions:**
- Tap to view ProgressWorkspaceScreen
- Tap to view XpHistoryScreen
- Tap to view AchievementsScreen

---

## 3. COMPLETE FUNCTIONAL ACTION MAP

### 3.1 ALL TASK ACTIONS (via UniversalActionExecutor)

| ACTION | WHAT IT DOES | DESTINATION | DATA CHANGED | SIDE EFFECTS | CONFIRMATION |
|--------|-------------|-------------|-------------|-------------|-------------|
| View | Opens task detail | TaskDetailScreen | None | Navigates | No |
| Start | Opens task detail | TaskDetailScreen | None | Navigates | No |
| Edit | Opens task edit | TaskDetailScreen | Updates task | Saves task | No |
| Complete | Marks task complete | TaskDetailScreen → back | task.isCompleted = true | Awards XP, updates PlanningBlock, notifications | No |
| Delete | Removes task | TasksScreen (back) | Removes task | Data removed | YES |
| Schedule | Opens plan | PlanningScreen | None | Navigates | No |
| Reschedule | Opens plan | PlanningScreen | None | Navigates | No |
| Focus | Opens focus mode selection | FocusModeSelectionSheet | None | Opens focus with task context | No |

### 3.2 ALL FOCUS ACTIONS

| ACTION | WHAT IT DOES | DESTINATION | DATA CHANGED | SIDE EFFECTS | PERMISSIONS |
|--------|-------------|-------------|-------------|-------------|-------------|
| Start Timer | Begins timer focus | FocusSessionScreen | FocusController.startTimer() | XP on completion | None |
| Start Stopwatch | Begins stopwatch | FocusSessionScreen | FocusController.startStopwatch() | None | None |
| Start FocusGuard | Begins FocusGuard mode | FocusSessionScreen | FocusController.startFocusGuard() | App blocking, overlay | Usage Access + Overlay (Android) |
| Pause | Pauses active session | FocusSessionScreen | FocusController.pauseSession() | Timer paused | None |
| Resume | Resumes paused session | FocusSessionScreen | FocusController.resumeSession() | Timer resumes | None |
| End | Ends session early | FocusSessionScreen → FocusCenterScreen | FocusController.endSessionEarly() | Awards XP, updates streak, bridges to Study/Task | None |
| Recover | Reschedules missed block | PlanningScreen | PlanningBlockController.rescheduleBlock() | Block rescheduled | None |
| Skip | Marks block skipped | PlanningScreen | PlanningBlockController.unscheduleBlock() | Block skipped | None |
| Unschedule | Unschedules block | PlanningScreen | PlanningBlockController.unscheduleBlock() | Block unscheduled | None |

### 3.3 ALL PLANNING ACTIONS

| ACTION | WHAT IT DOES | DESTINATION | DATA CHANGED | SIDE EFFECTS |
|--------|-------------|-------------|-------------|-------------|
| Plan My Day | Opens plan generation | DailyPlanSheet (modal) | None | Opens modal |
| Apply Plan | Applies generated plan | PlanningScreen | PlanController.applyDailyPlan() | Creates PlanningBlocks, notifications |
| Rebalance | Rebalances overloaded day | None (snackbar) | AcademicIntelligenceController.rebalanceDay() | Blocks rescheduled, snackbar shown |
| Recover | Recovers missed session | None (snackbar) | AcademicIntelligenceController.recoverMissedSession() | Block rescheduled, snackbar shown |
| Start Focus (block) | Starts focus for planning block | FocusSessionScreen | FocusController.startTimer() | XP on completion |
| View | Views plan | PlanningScreen | None | Navigates |
| Reschedule | Reschedules block | PlanningScreen | None | Navigates |
| Skip | Skips block | PlanningScreen | PlanningBlockController.unscheduleBlock() | Block skipped |
| Unschedule | Unschedules block | PlanningScreen | PlanningBlockController.unscheduleBlock() | Block unscheduled |

### 3.4 ALL NOTE ACTIONS

| ACTION | WHAT IT DOES | DESTINATION | DATA CHANGED | CONFIRMATION |
|--------|-------------|-------------|-------------|-------------|
| Create/Save | Creates/updates note | NoteEditorScreen → NoteDetailScreen | StudentNoteController.createNote()/updateNote() | No |
| Edit | Opens editor | NoteEditorScreen | None | No |
| Open | Views note | NoteDetailScreen | None | No |
| Focus | Starts focus from note | FocusSessionScreen | FocusController.startContextualFocus() | No |
| Study | Starts study from note | StudyScreen | StudyController.startSession() | No |
| Practice | Opens practice | PracticeCenterScreen | None | No |
| Revise | Opens revision | RevisionScreen | None | No |
| Plan | Opens daily plan | PlanningScreen/DailyPlanSheet | None | No |
| Pin | Toggles pin | NoteDetailScreen | StudentNoteController.togglePinned() | No |
| Archive/Restore | Toggles archive | NoteDetailScreen | StudentNoteController.archiveNote()/restoreNote() | No |
| Delete | Deletes note | NoteDetailScreen (back) | StudentNoteController.deleteNote() | No explicit confirmation documented |

### 3.5 ALL CALENDAR EVENT ACTIONS

| ACTION | WHAT IT DOES | DESTINATION | DATA CHANGED | CONFIRMATION |
|--------|-------------|-------------|-------------|-------------|
| Create/Save | Creates/updates event | AddEditEventSheet | AcademicScheduleController.createEvent()/updateEvent() | No |
| Edit | Opens editor | AddEditEventSheet | None | No |
| Delete | Deletes event | CalendarScreen | AcademicScheduleController.deleteEvent() | YES |
| Plan Around | Plans around event | PlanningScreen | None | No |
| View Day | Switches to day view | CalendarScreen (day) | None | No |
| View Week | Switches to week view | CalendarScreen (week) | None | No |
| View | Views event | AddEditEventSheet | None | No |

### 3.6 ALL ENTITY ACTIONS VIA UNIVERSALACTIONEXECUTOR

**Subject Actions:** Study → SubjectDetailScreen, Revise → RevisionScreen, Focus → FocusModeSelectionSheet, Timer → FocusController.startTimer(), Stopwatch → FocusController.startStopwatch(), View Syllabus → SubjectDetailScreen

**Topic Actions:** Study → SubjectDetailScreen/StudyScreen, Practice → PracticeModeSelectionSheet, Revise → RevisionScreen, Focus → FocusModeSelectionSheet, Timer → FocusController.startTimer(), Stopwatch → FocusController.startStopwatch(), View → SubjectDetailScreen/StudyScreen

**Exam Actions:** Study → ExamDetailScreen, Revise → RevisionScreen, Plan → PlanningScreen, Focus → FocusModeSelectionSheet, View → ExamDetailScreen

**PlanningBlock Actions (status-dependent):**
- Upcoming: Start Focus, View, Reschedule, Skip, Unschedule
- Current: Start Focus, View
- Completed: View
- Missed: Recover, Reschedule, View
- Skipped: View, Reschedule, Unschedule

**Resource Actions:** Open → ResourceDetailScreen, Download → ResourceDetailScreen, Toggle Favorite → ResourceController.toggleFavorite()

**Goal Actions:** View → GoalsScreen, Plan → PlanningScreen, Progress → ProgressScreen

**Focus Actions (session-state-dependent):**
- No session: Start → FocusCenterScreen
- Active: Continue → FocusSessionScreen, Pause/Resume → toggle, End → endSessionEarly()

**CalendarEvent Actions:** View, Edit → AddEditEventSheet, Plan Around → PlanningScreen, View Day, View Week, Delete → AcademicScheduleController.deleteEvent()

---

### 3.7 ALL ASSISTANT COMMANDS (34 Intent Types)

**Navigation Intents:** OpenHome, OpenPlan, OpenStudy, OpenFocus, OpenTasks, OpenExams, OpenGoals, OpenProgress, OpenRevision, OpenCalendar, OpenPractice, OpenKnowledge, OpenNote, SearchNotes

**Action Intents:** StartFocus, StartPlanningBlock, StartTopic, StartTask, StartRevision, StartPlan, ApplyPlan, Reschedule, Recover, Rebalance, CompleteTask, StartPractice, ResolveConflict, CreateNote

**Query Intents:** WhatShouldIDo, WhatShouldIStudy, WhatShouldIRevise, AvailableTime, ShowTasks, ShowTodayPlan, ShowExams, ShowGoals, ShowProgress, ShowWeakAreas, ShowOverdue, ShowScheduleToday/Tomorrow/Week, ShowNextClass, CheckFreeTime, ShowScheduleConflicts, ShowBusiestDay, ShowNotes, ShowPinnedNotes, ShowRecentNotes

**Creation Intents:** CreateNote

**Intent Commands:** StartMyDay, ContinueMyDay, PlanTime, StartFocus, StudySubject, StudyTopic, ReviseTopic, FocusSubject, FocusTopic, StartTask, CompleteTask, Reschedule, RecoverMissedSession, RebalanceDay, PracticeTopic, PracticeWeakest, ShowPracticeHistory, ShowScheduleToday, ShowScheduleTomorrow, ShowWeekSchedule, ShowNextClass, CheckFreeTime, ShowScheduleConflicts, ShowBusiestDay, SearchNotes, OpenNote, ShowNotes

---

## 4. FEATURE → SUBFEATURE MAP

### FOCUS — 30 subfeatures
```
Focus
├── Focus session lifecycle (active/paused/completed/cancelled/interrupted)
├── Timer mode (configurable duration countdown)
├── Stopwatch mode (unlimited elapsed time)
├── FocusGuard mode (app blocking)
├── Focus missions (objective + duration + style)
├── Focus checkpoints (at 15/30/45 minutes)
├── Focus score calculation (max 100)
├── Focus history (past sessions with scores)
├── Focus insights (analytics, trends)
├── Focus distraction inbox (captured distractions)
├── Focus Guard settings (mode: gentle/standard/strict)
├── Focus Guard permissions (Usage Access, Overlay)
├── Focus Guard safe packages (12 pre-defined Android apps)
├── Focus Guard overlay (intervention display)
├── Focus Guard blocked app detection (1-second periodic monitoring)
├── Focus Guard intervention (gentle vs strict)
├── Focus launch context preservation
├── Focus → Study completion bridge (idempotent)
├── Focus → Task completion bridge
├── Focus → XP award
├── Focus → Streak update
├── Focus → Notification update
├── Focus → Progression level-up detection
├── Quick start presets (sprint/pomodoro/deepFocus/deepWork)
├── 30-minute burst focus
├── Contextual focus (from subject/topic/task/exam/planning block)
├── Resume existing session vs start new
├── End session early
├── Cancel session
└── Pause/resume with state preservation
```

### TASKS — 17 subfeatures
```
Tasks
├── Task creation (title, priority, estimatedMinutes, dates, subtasks, description, category, recurrence, reminder, exam link, subject link, goal link)
├── Task editing
├── Task completion
├── Task deletion (with confirmation)
├── Task filtering (all/uncompleted/completed)
├── Task sorting
├── Task searching
├── Task scheduling (→ PlanningBlock)
├── Task rescheduling
├── Task linking (subject, exam, goal)
├── Subtask management with progress bar
├── Priority levels (critical/high/medium/low)
├── Due date management
├── Recurrence rules
├── Reminder time setting
├── Overdue detection and display
└── Task completion → XP award, PlanningBlock status update
```

### PLANNING — 16 subfeatures
```
Planning
├── Daily plan generation (PlanningEngine)
├── Plan my day (bottom sheet with budget presets)
├── Planning block creation
├── Planning block management
├── Rebalance day (overload correction)
├── Recover missed session
├── Skip block
├── Unschedule block
├── Schedule-aware planning
├── Overload detection
├── Early completion detection
├── Recovery session generation
├── Budget management (default 180 min)
├── PlanningBlock status derivation (upcoming/current/completed/missed/skipped)
├── Autopilot mode (suggest/autopilot/manual)
└── Plan transition notifications
```

### STUDY — 13 subfeatures
```
Study
├── Study session management (start/pause/resume/end/cancel)
├── Study streak tracking
├── Daily focus target (120 min)
├── Study recommendations (AI-powered)
├── Revision recommendations
├── Study consistency analytics
├── Strongest day identification
├── Study session history
├── Today sessions tracking
├── Study progress vs target
├── Week durations tracking
├── Study streak days calculation
└── Focus completion → study recording (idempotent)
```

### INTELLIGENCE — 24 subfeatures
```
Intelligence
├── Daily briefing generation
├── What should I do now
├── Daily academic snapshot
├── Academic risk detection
├── Goal intelligence assessment
├── Autopilot planning
├── Health state computation (clear/onTrack/busy/overloaded/recoveryNeeded)
├── Next action determination
├── Start my day action
├── Continue my day action
├── Recovery session generation
├── Early completion detection
├── 30-minute burst recommendation
├── Exam pressure assessment
├── Study/revision recommendations
├── Unified recommendations
├── Study time allocation with breaks
├── Weekly plan generation
├── Adaptive priority
├── Smart resource recommendations
├── Focus items derivation
├── Notification evaluation (8 categories)
├── Performance snapshot
└── Consistency analysis
```

### ASSISTANT — 11 subfeatures
```
Assistant
├── Natural language input
├── Intent classification (34 types)
├── Deterministic intent parser
├── Action execution (31 types)
├── Context-aware responses
├── Clarification support
├── Confidence scoring
├── Empty state guidance
├── Initial query support
├── Command confirmation (some require confirmation)
└── Navigation + action execution via UniversalActionExecutor
```

### NOTIFICATIONS — 12 subfeatures
```
Notifications
├── Notification list (200-item cap)
├── Filter (all/unread/tasks/exams/focus/progression)
├── Local notification scheduling
├── One-shot notifications
├── Daily notifications
├── Notification cancellation (before rescheduling for idempotency)
├── Notification tap → navigation
├── Deep link notification handling
├── Permission management
├── Evaluation triggers (12 types)
├── Duplicate prevention
└── Notification reconciliation
```

### GAMIFICATION — 14 subfeatures
```
Gamification
├── XP earning (tasks: 10+priority, study: 15+per30min max50, syllabus: 25, exam: 50, streak milestones: 20/40/60/100, consistency: 30, revision: 15/25)
├── Level progression (based on total XP)
├── Streak tracking (current, best, activity today)
├── Achievement unlocking (via NotificationController)
├── Leaderboard rankings (rank movement notifications)
├── Level-up dialog (automatic via AppShell)
├── XP spending (reward redemption)
├── Reward transactions
├── Entitlement management
├── Feature gating
├── Cosmetic theme unlocking (via XP)
├── Streak milestones (3/7/14/30 days)
├── Weekly consistency bonus
└── Discount computation (level-based 5-20% + redeemed, capped 50%)
```

### REWARDS — 11 subfeatures
```
Rewards
├── Reward catalog browsing (15 rewards, pricing tiers: starter/progress/advanced/premium/elite)
├── Category filtering (All/For You/Featured/Cosmetic/Academic/Premium/Feature/Badge)
├── Reward redemption (atomic: validate → deduct XP → grant entitlement → persist → notify; rollback on failure)
├── Entitlement query
├── Premium subscription
├── Trial management (7-day default)
├── Discount computation
├── Feature gating
├── Google Play billing
├── Reward history
└── Unlock notifications
```

### SETTINGS — 7 subfeatures
```
Settings
├── Theme mode (light/dark/system)
├── Cosmetic theme variants (locked/unlocked via XP)
├── Default focus duration
├── Week start day
├── Autopilot mode (suggest/autopilot/manual)
├── Notification toggles (6 categories)
└── User preferences persistence
```

---

## 5. CROSS-MODULE CONNECTIONS

### Core Workflow: Task → Planning → Focus → Study → Analytics → XP
```
Task (StudentTask)
├── Links to PlanningBlock via TaskController
│   └── PlanningBlock → PlanningScreen → PlanController
│       └── PlanningBlock.startFocus → AppRouter.startPlanningBlockFocus() → FocusController.startTimer()
│           └── FocusSession completes → FocusController → TaskController.completeTask() → XP award
│               └→ StudyController.recordFocusCompletion() → Study streak
│               └→ NotificationController.onTaskCompleted()
│               └→ ProgressionController → XP → Level-up detection
└── Task overdue → AcademicIntelligenceEngine → Risk banner → HomeScreen
```

### Academic Hierarchy: Subject → Chapter → Topic → Practice → Revision → Focus
```
Subject (Subject)
├── Contains Chapters → Chapter contains Topics
│   ├── Topic → KnowledgeCenterScreen → AcademicKnowledgeController
│   │   ├── Practice → PracticeCenterScreen → PracticeModeSelectionSheet → PracticeSessionScreen → PracticeResultScreen
│   │   └── Revision → RevisionScreen → RevisionSessionScreen → RevisionController (spaced repetition)
│   │       └→ RevisionRecord → ease factor update → next review scheduled
│   └── Focus → FocusModeSelectionSheet → FocusController.startContextualFocus()
│       └→ FocusSession → XP + Streak + Study bridge
```

### Calendar Flow: Calendar → Free Time → Planning → Autopilot → Focus
```
Calendar (AcademicCalendarEvent)
├── Integrated with PlanningBlock → PlanningScreen → PlanController
│   ├── AutopilotEngine generates daily plan from all data
│   │   ├── Health state (clear/onTrack/busy/overloaded/recoveryNeeded)
│   │   ├── Overload detection → Rebalance suggestion
│   │   └── Recovery session generation → Missed session recovery
│   └── Free time → AvailableTime → Study recommendations → Focus
│       └→ ContextualFocus → FocusSessionScreen
```

### Assistant Flow: Assistant → Universal Actions → All Features
```
StudentAssistantSheet (natural language input)
├── StudentAssistantController → StudentAssistantEngine → DeterministicStudentIntentParser
│   └→ StudentAssistantIntent (34 types)
│       └→ StudentAssistantAction (31 types)
│           └→ AppRouter / UniversalActionExecutor
│               ├── Navigate to any screen
│               ├── Execute actions (start focus, complete task, etc.)
│               ├── Query data (show tasks, exams, schedule, etc.)
│               └→ All features reachable via assistant
```

### Focus Integration: Focus → All Modules
```
FocusController
├── → TaskController.completeTask() (if linked task)
├── → StudyController.recordFocusCompletion() (idempotent)
├── → StreakService (streak update)
├── → NotificationController (notifications)
├── → ProgressionController (XP award, level-up detection)
└── → AcademicIntelligenceEngine (intelligence updates)
```

### Notification Flow
```
NotificationController
├── Evaluates 12 triggers (task completed, exam approaching, focus completed, etc.)
│   └→ IntelligentNotificationEngine → schedules local notifications
├── → NotificationCoordinator (reconciliation on app launch)
└── → Deep link handling → AppRouter.handleNotificationPayload()
```

---

## 6. MULTIPLE ENTRY POINTS

### Features Accessible from Multiple Places

| FUNCTION | ENTRY POINTS |
|----------|-------------|
| **Focus** | HomeScreen hero, FocusCenterScreen, StudyScreen, SubjectDetailScreen, TaskDetailScreen, PlanningScreen (blocks), NotesScreen (note actions), ExamDetailScreen, StudentAssistantSheet, UniversalActionLauncherSheet, GlobalAddSheet, Notes action menu |
| **Tasks** | HomeScreen (add task, quick actions), TasksScreen directly, More tab → GoalsScreen, StudentAssistantSheet, GlobalAddSheet, PlanningScreen |
| **Calendar** | Plan tab, More tab → Academic Schedule, StudentAssistantSheet, UniversalActionLauncherSheet, HomeScreen (agenda) |
| **Goals** | GoalsScreen, More tab → Goals (GoalsScreen), HomeScreen (upcoming goals preview) |
| **Achievements** | AchievementsScreen, More tab → Achievements, ProfileScreen → Achievements |
| **Leaderboard** | LeaderboardScreen, More tab → Leaderboard |
| **Rewards** | RewardsScreen, More tab → Rewards, ProfileScreen → Rewards |
| **Settings** | SettingsScreen, More tab → Settings, ProfileScreen → Settings |
| **Notifications** | NotificationCenterScreen, More tab → Notifications |
| **Knowledge** | KnowledgeCenterScreen, More tab → Knowledge Base, StudyScreen, SubjectDetailScreen |
| **Resources** | ResourcesScreen, More tab → Study Resources, GlobalAddSheet, StudentAssistantSheet |
| **Subjects** | SubjectsScreen, More tab → Subjects, GlobalAddSheet |
| **Practice** | PracticeCenterScreen, KnowledgeCenterScreen, SubjectDetailScreen, NotesScreen, StudyScreen, StudentAssistantSheet |
| **Revision** | RevisionScreen, SubjectDetailScreen, Topic actions, NotesScreen, StudyScreen, StudentAssistantSheet |
| **Planning** | Plan tab, HomeScreen (today's plan), GlobalAddSheet, StudentAssistantSheet, CalendarScreen |
| **Study** | Study tab (StudyScreen), SubjectDetailScreen, NotesScreen |
| **Notes** | KnowledgeCenterScreen, GlobalAddSheet, StudentAssistantSheet, NotesScreen action menu |
| **Exams** | ExamScreen, More tab → Exams, SubjectDetailScreen |

---

## 7. HIDDEN / EASY-TO-MISS FUNCTIONALITY

| FEATURE | WHERE FOUND | HOW TO ACCESS | WHAT IT DOES |
|---------|------------|---------------|-------------|
| FocusGuard overlay & blocked app detection | FocusGuardService | Automatic (Android) | Blocks apps during FocusGuard, shows overlay |
| Focus checkpoints | FocusController | Automatic (15/30/45 min) | Awards bonus to focus score |
| Focus distraction capture | FocusController | Automatic | Captures distractions during FocusGuard |
| Missed session recovery | AcademicIntelligenceController | HomeScreen Today card → Recover button | Reschedules missed work |
| Day rebalancing | AcademicIntelligenceController | HomeScreen Today card → Rebalance button | Rebalances overloaded schedule |
| 30-min burst | StudentOSIntelligenceEngine | HomeScreen hero → 30-min burst button | Quick focus burst |
| Autopilot mode | UserPreferencesController | SettingsScreen | Automatic planning |
| Edit profile | _EditProfileSheet | MoreScreen → tap profile | Edits profile info |
| Theme variant unlocking | ThemeManager | RewardsScreen → "Unlock" button | Unlock cosmetic themes |
| Feature gating | FeatureGate | Throughout app | Controls feature availability |
| Focus launch context | FocusLaunchContext | Automatic | Preserves entity context across navigation |
| Idempotent focus→study bridge | StudyController | Automatic | Prevents double XP |
| Deep link OAuth | AppLinks plugin | App launch/callback | Handles authentication automatically |
| Session restoration | AuthIsolation | App launch | Restores previous session |
| Notification reconciliation | NotificationCoordinator | Automatic on launch | Cleans outdated notifications |
| Practice mode selection | PracticeModeSelectionSheet | KnowledgeCenterScreen → topic tap | Selects practice mode |

---

## 8. STATES

### Global App States
| STATE | DESCRIPTION |
|-------|-------------|
| **Checking** | AuthGate determining auth state |
| **Authenticated** | AppShell visible, all features available |
| **Unauthenticated** | AuthExperience visible (welcome, sign in, etc.) |
| **Loading** | Controllers loading (19 controllers, 8s timeout each) |
| **Error** | Error message with retry button |
| **Offline** | Cached data shown, most actions available |
| **Session Restored** | Previous session restored automatically |
| **Session Expired** | Requires re-authentication |

### Screen-Specific States
| SCREEN | STATES |
|--------|--------|
| **HomeScreen** | First Launch, Loading, Error, Empty, Populated, Offline, Overloaded, Recovery Needed, Done For Today, Focus Active |
| **PlanningScreen** | Loading, Empty, Populated, Overloaded, Recovery Needed, Block: Upcoming/Current/Completed/Missed/Skipped |
| **StudyScreen** | Loading, Empty, Populated, Focus Active |
| **FocusCenterScreen** | Idle, Active session (auto-redirects to FocusSessionScreen) |
| **FocusSessionScreen** | Focusing, Paused, Completed, Interrupted |
| **TasksScreen** | Loading, Empty, Populated, Error, Offline |
| **TaskDetailScreen** | Active, Completed, Overdue |
| **FocusGuard** | notReady, usageAccessRequired, overlayRequired, ready, unsupported |
| **CalendarScreen** | Loading, Week View, Day View, Month View, Conflict detected |
| **NotificationCenterScreen** | Loading, Empty, Populated, Error |
| **ProfileScreen** | Authenticated, Demo mode |
| **RewardsScreen** | Free, Active Trial, Subscribed, Trial Expired |
| **Level** | Level Up Detected → LevelUpDialog |

### Focus Session States
| STATE | DESCRIPTION |
|-------|-------------|
| **Idle** | No active session |
| **Active** | Timer/stopwatch/FocusGuard running |
| **Paused** | Session paused |
| **Completed** | Session finished successfully |
| **Interrupted** | Session interrupted |

### Form States
| FORM | STATES |
|------|--------|
| **Task** | Creating, Editing, Completed, Overdue |
| **Calendar Event** | Creating, Editing, Existing |
| **Note** | Creating, Editing, Pinned, Archived |
| **Revision** | Forgot, Partially Knew, Knew |
| **Practice** | In Progress, Completed |

---

## 9. AUTOMATION

### ALL AUTOMATIC BEHAVIORS

| AUTOMATION | TRIGGER | LOGIC SOURCE | OUTPUT | USER CONTROL | SIDE EFFECTS |
|-----------|---------|-------------|--------|-------------|-------------|
| **Daily briefing** | App launch, periodic | DailyOsCoordinator | DailyAcademicSnapshot | No | Updates home screen |
| **What should I do now** | User views home | StudentOSIntelligenceEngine | Recommended action | No | Drives home hero |
| **Autopilot planning** | User selects autopilot mode | AutopilotEngine | Daily plan | Yes (mode selection) | Creates planning blocks |
| **Overload detection** | Plan generation | AutopilotEngine | Health state | No | Rebalance suggestion |
| **Recovery session generation** | Missed blocks detected | AutopilotEngine | Recovery sessions | No | Reschedules blocks |
| **Early completion detection** | Task completion | AutopilotEngine | Early completion opportunities | No | Suggests additional work |
| **Academic risk detection** | Risk factors present | AcademicIntelligenceEngine | Risk banners | No | Risk alerts on home |
| **Study recommendations** | User views study screen | AcademicIntelligenceEngine | Study recommendations | No | Drives study card |
| **Revision recommendations** | Revision due | AcademicIntelligenceEngine | Revision recommendations | No | Drives revision card |
| **Focus score calculation** | Session completes | FocusController | Score (max 100) | No | Awards XP, updates streak |
| **Focus → Study bridge** | Focus completes | StudyController | Study session recorded | No | Idempotent, prevents double XP |
| **Focus → Task completion** | Focus completes with linked task | TaskController | Task completed | No | Awards XP |
| **XP calculation** | Various completions | XPEngine | XP amount | No | Updates level, progress |
| **Level-up detection** | XP threshold reached | ProgressionController | Level up | No | LevelUpDialog |
| **Streak calculation** | Daily activity | StreakService | Current/best streak | No | Streak milestone XP |
| **Spaced repetition scheduling** | Revision outcome | RevisionController | Updated interval/ease factor | No | Reschedules revision |
| **Notification evaluation** | Various triggers | IntelligentNotificationEngine | Scheduled notifications | Partially (toggles) | Notifications delivered |
| **Notification reconciliation** | App launch | NotificationCoordinator | Cleaned schedule | No | Cancels outdated |
| **30-min burst** | Home screen | StudentOSIntelligenceEngine | Burst action | Yes (user chooses) | Starts focus |
| **Deep link OAuth** | App launch/callback | AppLinks plugin | Session exchange | No | Authenticates user |
| **Cache updates** | Data changes | StorageService | Local persistence | No | Offline support |
| **Supabase sync** | Network available | SupabaseService | Cloud sync | No | Cloud persistence |
| **Theme variant unlocking** | XP threshold | ThemeManager | Theme unlocked/locked | No | Cosmetic changes |
| **DailyOsCoordinator throttle** | Data changes | DailyOsCoordinator | Snapshot update | No | 15s throttle prevents excessive rebuilds |
| **Checkpoint system** | Focus timer | FocusController | Checkpoint bonus | No | Awards bonus at 15/30/45 min |
| **FocusGuard monitoring** | FocusGuard active | FocusGuardController | Blocked app detection | No | 1-second periodic check |
| **FocusGuard intervention** | Blocked app detected | FocusGuardService | Overlay or bring-to-foreground | No | Gentle vs strict mode |
| **Idempotent focus→study bridge** | Focus completes | StudyController | Study session recorded | No | Prevents double XP |
| **PlanningBlock status derivation** | Data changes | UniversalActionExecutor | Block display status | No | Automatic status computation |
| **Session restoration** | App launch | AuthIsolation | Restored session | No | Automatic |

---

## 10. UI REDESIGN PRESERVATION CHECKLIST

### MUST PRESERVE (Removing these would lose functionality)

**Authentication & Account:**
- [ ] Welcome screen
- [ ] Sign in (email/password + Google Sign-In)
- [ ] Sign up
- [ ] Forgot password
- [ ] Update password
- [ ] Verification pending
- [ ] Onboarding (education profile setup)
- [ ] Logout (clears memory, preserves storage)
- [ ] Session restoration
- [ ] Deep link OAuth callback handling

**Core Workflows:**
- [ ] Task creation (all fields: title, priority, estimatedMinutes, dates, subtasks, description, category, recurrence, reminder, links)
- [ ] Task editing
- [ ] Task deletion (with confirmation)
- [ ] Task completion
- [ ] Task filtering (all/uncompleted/completed)
- [ ] Task sorting
- [ ] Task searching
- [ ] Task scheduling (→ PlanningBlock)
- [ ] Task rescheduling
- [ ] Focus sessions: Timer mode, Stopwatch mode, FocusGuard mode
- [ ] Focus missions (objective + duration + style)
- [ ] Focus pause/resume/end/cancel
- [ ] Focus checkpoints
- [ ] Focus history
- [ ] Focus insights
- [ ] Focus distraction inbox
- [ ] FocusGuard settings (mode, permissions, blocked apps)
- [ ] Planning: Plan My Day, Rebalance, Recover, Skip, Unschedule
- [ ] PlanningBlock status display (upcoming/current/completed/missed/skipped)
- [ ] Study sessions (start/pause/resume/end)
- [ ] Study streak tracking
- [ ] Daily study target (120 min)

**Calendar & Schedule:**
- [ ] Calendar week/day/month views
- [ ] Today jump
- [ ] Add/edit/delete events
- [ ] Conflict detection and resolution
- [ ] Plan Around event
- [ ] View Day/Week
- [ ] Availability summary

**Knowledge & Practice:**
- [ ] Knowledge center (subject/topic browsing)
- [ ] Practice center
- [ ] Practice sessions (active recall)
- [ ] Practice results (scoring)
- [ ] Practice mode selection
- [ ] Revision queue with filters
- [ ] Active recall sessions
- [ ] Spaced repetition (outcome recording, interval updates)

**Notes & Resources:**
- [ ] Note creation/editing/viewing
- [ ] Note pinning, archiving, deleting
- [ ] Note focus/study/practice/revise/plan actions
- [ ] Resource browsing, search, open, download, favorite
- [ ] Resource creation

**Goals:**
- [ ] Goal creation, editing, deletion
- [ ] Goal planning
- [ ] Goal progress tracking

**Progress & Analytics:**
- [ ] Progress dashboard (level, XP)
- [ ] XP history
- [ ] Achievements viewing
- [ ] Leaderboard rankings
- [ ] Analytics (charts, trends, consistency, performance)

**Navigation:**
- [ ] Bottom tab navigation (Home, Plan, Study, More)
- [ ] Hamburger menu navigation
- [ ] AppRouter all navigation helpers
- [ ] Deep link handling
- [ ] Push/pop navigation

---

### IMPORTANT TO KEEP ACCESSIBLE

**Assistant:**
- [ ] StudentAssistantSheet (natural language input)
- [ ] All 34 intent types
- [ ] All 31 action types
- [ ] Clarification support
- [ ] Empty state guidance

**Creation:**
- [ ] GlobalAddSheet (7 creation options)
- [ ] UniversalActionLauncherSheet (7 action options)
- [ ] TaskCreationSheet
- [ ] SubjectCreationSheet
- [ ] ExamCreationSheet
- [ ] ResourceCreationSheet
- [ ] AddEditEventSheet
- [ ] DailyPlanSheet
- [ ] FocusModeSelectionSheet
- [ ] PracticeModeSelectionSheet
- [ ] NoteEditorScreen

**Settings & Preferences:**
- [ ] Theme mode (light/dark/system)
- [ ] Cosmetic theme variants
- [ ] Default focus duration
- [ ] Week start day
- [ ] Autopilot mode
- [ ] Notification toggles

**Gamification:**
- [ ] Streak display
- [ ] XP display
- [ ] Level indicator
- [ ] Achievements
- [ ] Leaderboard
- [ ] Rewards marketplace
- [ ] Reward redemption

**Notifications:**
- [ ] Notification center
- [ ] Notification filtering
- [ ] Notification tap → navigation

---

### CONTEXTUAL/SECONDARY

- [ ] Focus mode presets (sprint, pomodoro, deep focus, deep work)
- [ ] Quick start presets on FocusCenterScreen
- [ ] Day hint text (overload/recovery messages)
- [ ] Academic risk banners
- [ ] Missed session recovery banner
- [ ] Overload warning banner
- [ ] Early completion notification
- [ ] FocusGuard live status pill
- [ ] FocusGuard blocked app picker
- [ ] Revision self-evaluation (Knew It/Partly/Forgot)
- [ ] Practice question submission
- [ ] Conflict resolution dialog
- [ ] Delete confirmation dialogs
- [ ] Sign out confirmation
- [ ] Edit profile sheet

---

### SYSTEM / ACCOUNT

- [ ] Profile management
- [ ] Account data management
- [ ] Cloud sync (Supabase)
- [ ] Local persistence (StorageService/shared_preferences)
- [ ] Auth isolation
- [ ] Controller isolation
- [ ] Deep link handling
- [ ] Notification permission management
- [ ] FocusGuard permission management (Android)
- [ ] Session management
- [ ] Demo mode

---

### GAMIFICATION

- [ ] All XP earning sources (tasks, study, syllabus, exam, streak, consistency, revision)
- [ ] Level progression
- [ ] Streak tracking (current/best)
- [ ] Achievement unlocking
- [ ] Leaderboard rankings
- [ ] Level-up dialog
- [ ] XP spending (rewards)
- [ ] Streak milestones (3/7/14/30 days)
- [ ] Weekly consistency bonus
- [ ] Cosmetic theme unlocking via XP

---

### PREMIUM / ENTITLEMENT

- [ ] Premium subscription
- [ ] Trial management (7-day)
- [ ] Feature gating
- [ ] Entitlement management
- [ ] Discount computation
- [ ] Google Play billing integration
- [ ] Reward catalog browsing
- [ ] Redemption flow (atomic)
- [ ] Premium status display

---

## 11. SIMPLIFICATION OPPORTUNITIES

> These are OBSERVATIONS from the inventory about where the current UI exposes many things simultaneously. They are NOT recommendations — they are observations to guide the manual redesign.

### 11.1 HomeScreen — Most Dense Screen
The HomeScreen at 1760 lines contains 11 visible sections, 8+ action types, and depends on 13+ controllers. The student is presented with: header, hero card, plan card, schedule, risk alerts, quick actions, assistant bar, upcoming items, and progression footer — all simultaneously.

**Observation:** Consider whether some sections could be progressively disclosed (e.g., "Quick Actions" could be a single "Add" entry point; risk alerts could be summarized rather than shown as individual banners).

### 11.2 MoreScreen — 15+ Navigation Items
The MoreScreen contains 15+ navigation items across 2 groups. Every feature accessible from "More" could potentially be found from other places.

**Observation:** The More tab contains many features that are also accessible from other tabs (Goals from HomeScreen, Notifications from more places, etc.). Consider consolidating visually while preserving all access paths.

### 11.3 UniversalActionExecutor — 85+ Actions Across 10 Entity Types
Every entity type (Task, Subject, Topic, Exam, PlanningBlock, Resource, Goal, CalendarEvent, Focus, Note) has its own action set, totaling 85+ individual actions.

**Observation:** Consider a unified action pattern where similar actions follow the same interaction model (e.g., tap to view, long-press or swipe for more actions).

### 11.4 Focus — 11+ Entry Points
Focus is accessible from HomeScreen, FocusCenterScreen, StudyScreen, SubjectDetailScreen, TaskDetailScreen, PlanningScreen, NotesScreen, ExamDetailScreen, StudentAssistantSheet, UniversalActionLauncherSheet, GlobalAddSheet, and Notes action menu.

**Observation:** Many entry points lead to the same FocusModeSelectionSheet → FocusSessionScreen flow. A unified focus entry pattern could reduce visual duplication while preserving all access.

### 11.5 Settings — Scattered Preferences
Settings are split between SettingsScreen, UserPreferencesController, AppShellController, and ThemeManager.

**Observation:** Consider whether all settings could be consolidated into a single preferences flow.

### 11.6 Creation Flows — 10+ Creation Sheets
There are 10 different creation sheets/modals scattered throughout the app (TaskCreationSheet, SubjectCreationSheet, ExamCreationSheet, ResourceCreationSheet, AddEditEventSheet, DailyPlanSheet, FocusMissionSetupScreen, NoteEditorScreen, EditProfileSheet, PracticeModeSelectionSheet).

**Observation:** Many creation flows follow similar patterns (title input, save/cancel). A unified creation pattern could reduce cognitive load.

### 11.7 Intelligence — 24 Engines Behind the Scenes
The HomeScreen hero card, study recommendations, revision recommendations, risk alerts, and autopilot planning all come from different intelligence engines. Students see the results but not the engines.

**Observation:** The intelligence system is entirely backend/UI-agnostic. The redesign could present AI results through a simpler interface pattern.

### 11.8 Assistant — Hidden Power
The StudentAssistantSheet is accessible from multiple places but is primarily a text input that unlocks 34 intent types and 31 action types. Most students may not discover all capabilities.

**Observation:** The assistant is a powerful but potentially under-discovered feature. The redesign could make it more visible or keep it as a subtle entry point.

### 11.9 HamburgerMenu vs Bottom Navigation
The HamburgerMenu overlaps with the bottom tab navigation, providing navigation to Home, Plan & Study, Progress, Assistant, and Account.

**Observation:** There is some redundancy between the hamburger menu and the bottom tabs. The redesign could clarify the relationship between navigation systems.

### 11.10 Multiple Entry Points for Same Functionality
Many features have 3-11 entry points (see Section 6). While all must be preserved, visually presenting multiple entry points can feel overwhelming.

**Observation:** The redesign can consolidate visually while ensuring every function remains reachable from at least one clear path.

---

## 12. FINAL BLUEPRINT INPUT

### 12.1 Every Major Screen to Eventually Draw

**Authentication (10):**
WelcomeScreen, SignInScreen, SignUpScreen, ForgotPasswordScreen, UpdatePasswordScreen, VerificationPendingScreen, AuthLoadingScreen, AuthGate, AuthShell, OnboardingScreen

**Main Shell (4):**
HomeScreen, PlanningScreen, StudyScreen, MoreScreen

**Focus (8):**
FocusCenterScreen, FocusSessionScreen, FocusMissionSetupScreen, FocusHistoryScreen, FocusInsightsScreen, FocusDistractionInboxScreen, FocusGuardSettingsScreen, BlockedAppsPickerScreen

**Task (3):**
TasksScreen, TaskDetailScreen, TaskCreationSheet

**Subject (2):**
SubjectsScreen, SubjectDetailScreen

**Exam (2):**
ExamScreen, ExamDetailScreen

**Knowledge/Practice (4):**
KnowledgeCenterScreen, PracticeCenterScreen, PracticeSessionScreen, PracticeResultScreen

**Calendar (1 + widgets):**
CalendarScreen, AddEditEventSheet, ConflictDialog

**Revision (3):**
RevisionScreen, RevisionDetailScreen, RevisionSessionScreen

**Notes (2):**
NoteEditorScreen, NoteDetailScreen

**Resources (3):**
ResourcesScreen, ResourceDetailScreen, ResourceSearchScreen

**Progress/Analytics (5+):**
ProgressScreen, ProgressWorkspaceScreen, XpHistoryScreen, LeaderboardScreen, AchievementsScreen, AnalyticsScreen, AnalyticsDetailScreen

**Rewards (3):**
RewardsScreen, PremiumScreen, StreakScreen

**Goals (2):**
GoalsScreen, GoalDetailScreen

**Other (8):**
ProfileScreen, SettingsScreen, AccountDataScreen, NotificationCenterScreen, ModulePlaceholderScreen, AppShell, GlobalAddSheet, StudentAssistantSheet

### 12.2 Every Important Component/Action Each Screen Must Support

(See Section 2 for detailed breakdowns of each screen's actions, states, and information. Key patterns to remember:)

**Every list screen needs:** Add/Create button, Filter, Sort, Search, Tap to view detail
**Every detail screen needs:** Edit, Delete (with confirmation), Back navigation
**Every creation flow needs:** Title input, Save, Cancel
**Every session screen needs:** Pause, Resume, End controls
**Every modal sheet needs:** Scrollable content, Cancel/back, Transparent background

### 12.3 Every Cross-Screen Relationship to Remember

- **HomeScreen** is the hub that aggregates ALL data and drives the primary action
- **FocusModeSelectionSheet** is the universal bridge from any entity to a Focus session
- **UniversalActionExecutor** routes ALL entity actions consistently
- **AppRouter** owns ALL navigation — every screen transition goes through it
- **FocusController** bridges to TaskController, StudyController, ProgressionController, NotificationController, StreakService
- **StudentAssistantSheet** can reach ANY feature through 34 intents and 31 actions
- **GlobalAddSheet** is the universal creation entry point from HomeScreen
- **AutopilotEngine** drives PlanningScreen recommendations, recovery, and rebalancing
- **AcademicIntelligenceEngine** drives HomeScreen hero, StudyScreen recommendations, Calendar risk alerts

### 12.4 Every Functionality That Must Not Disappear

(See Section 10 — the complete preservation checklist. The core principle is:)

1. **Every functional action must be reachable** from the new UI, even if the visual path changes
2. **Every entity type must be manageable** (Task, Subject, Topic, Exam, PlanningBlock, Resource, Goal, CalendarEvent, Focus, Note)
3. **Every session type must be supported** (Timer, Stopwatch, FocusGuard)
4. **Every gamification feature must remain** (XP, levels, streaks, achievements, leaderboard, rewards)
5. **Every setting must be accessible** (theme, focus duration, autopilot, notifications)
6. **Every authentication flow must work** (sign in, sign up, Google, forgot password, verification, session restore, logout)
7. **Every notification type must be delivered** (8 categories, 12 triggers)
8. **Every permission must be requestable** (Usage Access, Overlay, Notifications)
9. **Every automation must continue** (daily briefing, autopilot, recommendations, recovery, notifications, XP, streaks)
10. **Every assistant intent must work** (34 types, 31 actions)
11. **Every modal sheet must be accessible** (15+ sheets)
12. **Every form must be completable** (40+ form types)

---

**END OF REDESIGN REFERENCE**

> This document is derived entirely from `docs/UI_FUNCTIONAL_INVENTORY.md`.
> No application source code was modified.
> All terminology matches the inventory.
> Anything unclear or not documented in the inventory is marked "NOT DOCUMENTED."
