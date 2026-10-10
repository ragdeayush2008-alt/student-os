# Student OS — Complete UI/UX Functional Inventory

> **Audit Type:** Forensic Complete
> **Scope:** All application source code
> **Purpose:** Reference document for manual UI/UX redesign
> **Constraint:** NO source code modified
> **Generated:** 2026-09-19

---

## 0. EXECUTIVE SUMMARY

**Student OS** is a comprehensive Flutter application with:
- **65+ screen files** across **30 feature modules**
- **4 bottom-tab shell destinations** (Home, Plan, Study, More)
- **30+ controllers** (ChangeNotifier singletons)
- **16+ core services** (Supabase, Storage, Notifications, etc.)
- **26+ data models**
- **34 assistant intent types**
- **31 assistant action types**
- **8 entity types** in UniversalActionExecutor with **85+ individual actions**
- **8 Focus screens** dedicated to the Focus module
- **24 intelligence engines/controllers**
- **Deep link support** (Android OAuth, custom schemes, localhost fallback)
- **Supabase backend** with cloud sync
- **Google Sign-In** authentication
- **Android-specific FocusGuard** with MethodChannel
- **15+ bottom sheets/modals/dialogs**
- **40+ form input types**

---

## 1. MASTER SCREEN INVENTORY

### Category A: Authentication & Onboarding (10 screens)

| # | SCREEN ID | SCREEN NAME | FILE PATH | FEATURE | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|---------|-------------|-----------------|
| 1 | AUTH_WELCOME | WelcomeScreen | `lib/features/auth/presentation/welcome_screen.dart` | auth | App launch, unauthenticated | First impression, sign-in prompt |
| 2 | AUTH_SIGN_IN | SignInScreen | `lib/features/auth/presentation/sign_in_screen.dart` | auth | AuthGate when unauthenticated | Email/password + Google sign-in |
| 3 | AUTH_SIGN_UP | SignUpScreen | `lib/features/auth/presentation/sign_up_screen.dart` | auth | AuthGate when unauthenticated | Create new account |
| 4 | AUTH_FORGOT | ForgotPasswordScreen | `lib/features/auth/presentation/forgot_password_screen.dart` | auth | From SignInScreen | Password recovery |
| 5 | AUTH_UPDATE_PW | UpdatePasswordScreen | `lib/features/auth/presentation/update_password_screen.dart` | auth | Auth flow | Update existing password |
| 6 | AUTH_VERIFY | VerificationPendingScreen | `lib/features/auth/presentation/verification_pending_screen.dart` | auth | After sign-up | Email verification waiting |
| 7 | AUTH_LOADING | AuthLoadingScreen | `lib/features/auth/widgets/auth_loading_screen.dart` | auth | During auth check | Loading state |
| 8 | AUTH_GATE | AuthGate | `lib/features/auth/auth_gate.dart` | auth | Root before AppShell | Determines auth state |
| 9 | ONBOARDING | OnboardingScreen | `lib/features/onboarding/presentation/onboarding_screen.dart` | onboarding | First launch or edit mode | Education profile setup |
| 10 | AUTH_SHELL | AuthShell | `lib/features/auth/widgets/auth_shell.dart` | auth | Wrapper for auth flow | Auth experience navigation |

### Category B: Main Shell Tab Destinations (4 screens)

| # | SCREEN ID | SCREEN NAME | FILE PATH | FEATURE | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|---------|-------------|-----------------|
| 11 | HOME | HomeScreen | `lib/features/home/home_screen.dart` | home | Bottom nav tab 1 | Intelligent dashboard |
| 12 | PLAN | PlanningScreen | `lib/features/planning/planning_screen.dart` | planning | Bottom nav tab 2 | Daily planning |
| 13 | STUDY | StudyScreen | `lib/features/study/study_screen.dart` | study | Bottom nav tab 3 | Study execution hub |
| 14 | MORE | MoreScreen | `lib/features/more/more_screen.dart` | more | Bottom nav tab 4 | Settings, profile, features |

### Category C: Focus Module (8 screens)

| # | SCREEN ID | SCREEN NAME | FILE PATH | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|-------------|-----------------|
| 15 | FOCUS_CENTER | FocusCenterScreen | `lib/features/focus/presentation/screens/focus_center_screen.dart` | AppRouter.openFocusCenter, multiple entry points | Focus hub |
| 16 | FOCUS_SESSION | FocusSessionScreen | `lib/features/focus/presentation/screens/focus_session_screen.dart` | AppRouter.openActiveFocusSession, startPlanningBlockFocus, startContextualFocus, openFocusSessionLegacy | Active focus session |
| 17 | FOCUS_MISSION | FocusMissionSetupScreen | `lib/features/focus/presentation/screens/focus_mission_setup_screen.dart` | AppRouter.openFocusMission, FocusCenterScreen | Mission setup |
| 18 | FOCUS_HISTORY | FocusHistoryScreen | `lib/features/focus/presentation/screens/focus_history_screen.dart` | AppRouter.openFocusHistory, FocusCenterScreen | Session history |
| 19 | FOCUS_INSIGHTS | FocusInsightsScreen | `lib/features/focus/presentation/screens/focus_insights_screen.dart` | AppRouter.openFocusInsights, FocusCenterScreen | Focus analytics |
| 20 | FOCUS_INBOX | FocusDistractionInboxScreen | `lib/features/focus/presentation/screens/focus_distraction_inbox_screen.dart` | AppRouter.openFocusInbox, FocusCenterScreen | Distraction review |
| 21 | FOCUS_GUARD_SETTINGS | FocusGuardSettingsScreen | `lib/features/focus/presentation/screens/focus_guard_settings_screen.dart` | FocusCenterScreen, More | FocusGuard configuration |
| 22 | BLOCKED_APPS | BlockedAppsPickerScreen | `lib/features/focus/presentation/screens/blocked_apps_picker_screen.dart` | FocusGuardSettingsScreen | Select blocked apps |

### Category D: Task Module (3 screens)

| # | SCREEN ID | SCREEN NAME | FILE PATH | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|-------------|-----------------|
| 23 | TASKS | TasksScreen | `lib/features/tasks/presentation/tasks_screen.dart` | AppRouter.openTasks, More | Task list |
| 24 | TASK_DETAIL | TaskDetailScreen | `lib/features/tasks/presentation/task_detail_screen.dart` | AppRouter.openTaskDetail, UniversalActionExecutor | Task detail |
| 25 | TASK_CREATION | TaskCreationSheet | `lib/features/tasks/presentation/task_creation_sheet.dart` | HomeScreen, GlobalAddSheet, UniversalActionExecutor | Create task |

### Category E: Subject Module (2 screens)

| # | SCREEN ID | SCREEN NAME | FILE PATH | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|-------------|-----------------|
| 26 | SUBJECTS | SubjectsScreen | `lib/features/subjects/subjects_screen.dart` | AppRouter.openSubjectList, More | Subject list |
| 27 | SUBJECT_DETAIL | SubjectDetailScreen | `lib/features/subjects/subject_detail_screen.dart` | AppRouter.openSubjectDetail, UniversalActionExecutor | Subject detail |

### Category F: Exam Module (1 screen + 1 detail widget)

| # | SCREEN ID | SCREEN NAME | FILE PATH | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|-------------|-----------------|
| 28 | EXAMS | ExamScreen | `lib/features/exams/exam_screen.dart` | AppRouter.openExams, More, UniversalActionExecutor | Exam list |
| 29 | EXAM_DETAIL | ExamDetailScreen | `lib/features/exams/widgets/exam_detail_screen.dart` | AppRouter.openExamDetail, UniversalActionExecutor | Exam detail |

### Category G: Knowledge/Practice Module (4 screens)

| # | SCREEN ID | SCREEN NAME | FILE PATH | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|-------------|-----------------|
| 30 | KNOWLEDGE_CENTER | KnowledgeCenterScreen | `lib/features/knowledge/presentation/knowledge_center_screen.dart` | AppRouter.openKnowledgeCenter, UniversalActionExecutor | Subject/topic browsing |
| 31 | PRACTICE_CENTER | PracticeCenterScreen | `lib/features/knowledge/presentation/practice_center_screen.dart` | AppRouter.openPracticeCenter, UniversalActionExecutor | Practice center |
| 32 | PRACTICE_SESSION | PracticeSessionScreen | `lib/features/knowledge/presentation/practice_session_screen.dart` | PracticeModeSelectionSheet | Active practice |
| 33 | PRACTICE_RESULT | PracticeResultScreen | `lib/features/knowledge/presentation/practice_result_screen.dart` | PracticeSessionScreen | Results |

### Category H: Calendar Module (1 screen + widgets)

| # | SCREEN ID | SCREEN NAME | FILE PATH | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|-------------|-----------------|
| 34 | CALENDAR | CalendarScreen | `lib/features/calendar/presentation/calendar_screen.dart` | AppRouter.openCalendar, More | Calendar view |

### Category I: Revision Module (3 screens)

| # | SCREEN ID | SCREEN NAME | FILE PATH | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|-------------|-----------------|
| 35 | REVISION | RevisionScreen | `lib/features/revision/revision_screen.dart` | AppRouter.openRevision, UniversalActionExecutor | Revision queue |
| 36 | REVISION_DETAIL | RevisionDetailScreen | `lib/features/revision/revision_detail_screen.dart` | RevisionScreen | Revision detail |
| 37 | REVISION_SESSION | RevisionSessionScreen | `lib/features/revision/presentation/revision_session_screen.dart` | RevisionScreen | Active recall |

### Category J: Notes Module (2 screens)

| # | SCREEN ID | SCREEN NAME | FILE PATH | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|-------------|-----------------|
| 38 | NOTE_EDITOR | NoteEditorScreen | `lib/features/notes/presentation/note_editor_screen.dart` | AppRouter.openNoteEditor, GlobalAddSheet, UniversalActionExecutor | Create/edit notes |
| 39 | NOTE_DETAIL | NoteDetailScreen | `lib/features/notes/presentation/note_detail_screen.dart` | AppRouter.openNoteDetail, UniversalActionExecutor | View note |

### Category K: Resources Module (3 screens)

| # | SCREEN ID | SCREEN NAME | FILE PATH | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|-------------|-----------------|
| 40 | RESOURCES | ResourcesScreen | `lib/features/resources/resources_screen.dart` | AppRouter.openResources, More, UniversalActionExecutor | Resource library |
| 41 | RESOURCE_DETAIL | ResourceDetailScreen | `lib/features/resources/resource_detail_screen.dart` | AppRouter.openResourceDetail, UniversalActionExecutor | Resource detail |
| 42 | RESOURCE_SEARCH | ResourceSearchScreen | `lib/features/resources/search_screen.dart` | AppRouter.openResourceSearch, UniversalActionExecutor | Search resources |

### Category L: Progress/Analytics (5 screens)

| # | SCREEN ID | SCREEN NAME | FILE PATH | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|-------------|-----------------|
| 43 | PROGRESS | ProgressScreen | `lib/features/progress/progress_screen.dart` | AppRouter.openProgress, UniversalActionExecutor, HomeScreen | Progress dashboard |
| 44 | PROGRESS_WORKSPACE | ProgressWorkspaceScreen | `lib/features/progression/progress_workspace_screen.dart` | ProgressScreen | Detailed workspace |
| 45 | LEADERBOARD | LeaderboardScreen | `lib/features/progression/leaderboard_screen.dart` | AppRouter.openLeaderboard, More | Rankings |
| 46 | ACHIEVEMENTS | AchievementsScreen | `lib/features/progression/achievements_screen.dart` | AppRouter.openAchievements, More | Achievements |
| 47 | ANALYTICS | AnalyticsScreen | `lib/features/analytics/analytics_screen.dart` | More tab | Academic analytics |
| 48 | ANALYTICS_DETAIL | AnalyticsDetailScreen | `lib/features/analytics/analytics_detail_screen.dart` | AnalyticsScreen | Detailed analytics |
| 49 | XP_HISTORY | XpHistoryScreen | `lib/features/progression/widgets/xp_history_screen.dart` | ProgressScreen | XP history |

### Category M: Rewards/Streak (3 screens)

| # | SCREEN ID | SCREEN NAME | FILE PATH | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|-------------|-----------------|
| 50 | REWARDS | RewardsScreen | `lib/features/rewards/rewards_screen.dart` | AppRouter.openRewards, More | Reward marketplace |
| 51 | PREMIUM | PremiumScreen | `lib/features/rewards/premium_screen.dart` | More tab, Profile | Premium subscription |
| 52 | STREAK | StreakScreen | `lib/features/streak/presentation/streak_screen.dart` | More tab, AppRouter.openStreak | Streak details |

### Category N: Other Feature Screens (8 screens)

| # | SCREEN ID | SCREEN NAME | FILE PATH | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|-------------|-----------------|
| 53 | GOALS | GoalsScreen | `lib/features/goals/goal_screen.dart` | AppRouter.openGoals, More | Goal list |
| 54 | GOAL_DETAIL | GoalDetailScreen | `lib/features/goals/goal_detail_screen.dart` | GoalsScreen | Goal detail |
| 55 | PROFILE | ProfileScreen | `lib/features/profile/profile_screen.dart` | AppRouter.openProfile, More | User profile |
| 56 | SETTINGS | SettingsScreen | `lib/features/settings/settings_screen.dart` | AppRouter.openSettings, More | App settings |
| 57 | ACCOUNT_DATA | AccountDataScreen | `lib/features/more/presentation/account_data_screen.dart` | More tab | Account data |
| 58 | GOALS_MORE | GoalsScreen (More tab) | `lib/features/more/presentation/goals_screen.dart` | More tab Goals | Goals (alt entry) |
| 59 | NOTIFICATIONS | NotificationCenterScreen | `lib/features/notifications/presentation/notification_center_screen.dart` | AppRouter.openNotifications, More | Notifications |
| 60 | MODULE_PLACEHOLDER | ModulePlaceholderScreen | `lib/core/widgets/module_placeholder_screen.dart` | AppRouter.showComingSoon, AppRouter.openModule | Future module placeholder |

### Category O: Shared/System Widgets (4)

| # | SCREEN ID | SCREEN NAME | FILE PATH | HOW TO OPEN | PRIMARY PURPOSE |
|---|-----------|-------------|-----------|-------------|-----------------|
| 61 | APP_SHELL | AppShell | `lib/app/app_shell.dart` | Authenticated users | Bottom-tab shell |
| 62 | GLOBAL_ADD_SHEET | GlobalAddSheet | `lib/core/navigation/universal_action_executor.dart` | UniversalActionExecutor.openGlobalAdd | Global creation menu |
| 63 | UNIVERSAL_LAUNCHER | UniversalActionLauncherSheet | `lib/core/navigation/universal_action_executor.dart` | UniversalActionExecutor.openActionLauncher | Action launcher |
| 64 | ENTITY_ACTION_SHEET | EntityActionSheet | `lib/core/navigation/universal_action_executor.dart` | UniversalActionExecutor.showEntityActions | Entity action menu |

---

## 2. MASTER NAVIGATION MAP

```
STUDENT OS
│
├── Auth Experience (unauthenticated)
│   ├── WelcomeScreen
│   ├── SignInScreen → ForgotPasswordScreen, SignUpScreen
│   ├── SignUpScreen → VerificationPendingScreen
│   ├── ForgotPasswordScreen
│   ├── UpdatePasswordScreen
│   ├── VerificationPendingScreen
│   ├── OnboardingScreen (initial or edit mode)
│   └── AuthGate (routes based on auth state)
│
├── AppShell (authenticated) — Bottom Tab Navigation
│   │
│   ├── Home (tab 1)
│   │   ├── Hero Action → UniversalActionExecutor.executeAction()
│   │   ├── 30-min Burst → startQuickFocus()
│   │   ├── Add Task → TaskCreationSheet (modal)
│   │   ├── Global Add → GlobalAddSheet (modal)
│   │   ├── Assistant → StudentAssistantSheet (modal)
│   │   ├── Risk Banner → ExamDetailScreen / SubjectDetailScreen / TasksScreen
│   │   ├── Quick Actions → Various screens
│   │   ├── Progress Footer → ProgressScreen
│   │   └── Profile → ProfileScreen
│   │
│   ├── Plan (tab 2)
│   │   ├── Plan My Day → DailyPlanSheet (modal)
│   │   ├── Rebalance → AcademicIntelligenceController.rebalanceDay()
│   │   ├── Recover → AcademicIntelligenceController.recoverMissedSession()
│   │   ├── Planning Blocks → FocusModeSelectionSheet / FocusCenterScreen
│   │   ├── Calendar → CalendarScreen
│   │   ├── Add Event → AddEditEventSheet (modal)
│   │   └── Tasks → TasksScreen
│   │
│   ├── Study (tab 3)
│   │   ├── Active Focus → FocusSessionScreen
│   │   ├── Recommendation → FocusCenterScreen / KnowledgeCenterScreen / RevisionScreen
│   │   ├── Study Subject → SubjectDetailScreen
│   │   ├── Practice Topic → PracticeModeSelectionSheet → PracticeSessionScreen
│   │   ├── Revise Topic → RevisionScreen
│   │   ├── Focus Subject → FocusModeSelectionSheet
│   │   ├── Exams → ExamScreen
│   │   └── Recent Activity → StudyController.recentSessions
│   │
│   └── More (tab 4)
│       ├── Goals → GoalsScreen / GoalDetailScreen
│       ├── Profile → ProfileScreen
│       ├── Settings → SettingsScreen
│       ├── Notifications → NotificationCenterScreen
│       ├── Account Data → AccountDataScreen
│       ├── Achievements → AchievementsScreen
│       ├── Leaderboard → LeaderboardScreen
│       ├── Rewards → RewardsScreen
│       ├── Premium → PremiumScreen
│       ├── Streak → StreakScreen
│       ├── Academic Schedule → CalendarScreen
│       ├── Knowledge Base → KnowledgeCenterScreen
│       ├── Study Resources → ResourcesScreen
│       ├── Subjects → SubjectsScreen
│       └── Assistant → StudentAssistantSheet
│
├── Focus Module (pushed routes)
│   ├── FocusCenterScreen → FocusMissionSetupScreen, FocusHistoryScreen,
│   │   FocusInsightsScreen, FocusDistractionInboxScreen,
│   │   FocusGuardSettingsScreen, BlockedAppsPickerScreen,
│   │   FocusModeSelectionSheet (entity-contextual)
│   ├── FocusSessionScreen (active session)
│   ├── FocusMissionSetupScreen
│   ├── FocusHistoryScreen
│   ├── FocusInsightsScreen
│   ├── FocusDistractionInboxScreen
│   ├── FocusGuardSettingsScreen
│   └── BlockedAppsPickerScreen
│
├── Task Module
│   ├── TasksScreen → TaskDetailScreen
│   └── TaskCreationSheet (modal)
│
├── Subject Module
│   ├── SubjectsScreen → SubjectDetailScreen
│   └── SubjectCreationSheet (modal)
│
├── Exam Module
│   ├── ExamScreen → ExamDetailScreen
│   └── ExamCreationSheet (modal)
│
├── Knowledge Module
│   ├── KnowledgeCenterScreen → PracticeCenterScreen, RevisionScreen
│   ├── PracticeCenterScreen → PracticeSessionScreen → PracticeResultScreen
│   └── PracticeModeSelectionSheet (modal)
│
├── Calendar Module
│   └── CalendarScreen → AddEditEventSheet (modal), Conflict Dialog (modal)
│
├── Revision Module
│   ├── RevisionScreen → RevisionSessionScreen
│   └── RevisionDetailScreen
│
├── Notes Module
│   ├── NoteEditorScreen (pushed)
│   └── NoteDetailScreen (pushed)
│
├── Resources Module
│   ├── ResourcesScreen → ResourceDetailScreen
│   └── ResourceSearchScreen
│
├── Progress/Analytics Module
│   ├── ProgressScreen → ProgressWorkspaceScreen, XpHistoryScreen
│   ├── LeaderboardScreen
│   ├── AchievementsScreen
│   ├── AnalyticsScreen → AnalyticsDetailScreen
│   └── LevelUpDialog (automatic, via AppShell)
│
├── Rewards Module
│   ├── RewardsScreen → Redemption flow
│   ├── PremiumScreen
│   └── Reward catalog/browsing
│
├── Goals Module
│   ├── GoalsScreen → GoalDetailScreen
│   └── GoalsScreen (More tab duplicate)
│
├── Notification System
│   └── NotificationCenterScreen
│
├── Assistant System
│   └── StudentAssistantSheet (modal)
│
└── Deep Links
    ├── OAuth Callback (com.ragdetechnologies.studentos://login-callback)
    ├── Legacy OAuth (com.ragdetechnologies.student_os://login-callback)
    ├── Localhost Fallback (http://localhost:3000)
    └── Notification Tap → TaskDetailScreen / ExamDetailScreen / StudyScreen / PlanningScreen / RewardsScreen
```

**Key Navigation Routes:**
- Shell Tab Routes: `/home`, `/plan`, `/study`, `/more`
- Feature Routes: `/profile`, `/settings`, `/tasks`, `/goals`, `/account-data`, `/exams`, `/resources`, `/revision`, `/analytics`, `/notifications`, `/practice-center`, `/calendar`, `/knowledge`, `/knowledge-center`, `/note-editor`, `/focus-center`, `/focus-mission`, `/focus-session`, `/focus-history`, `/focus-insights`, `/focus-inbox`, `/leaderboard`, `/achievements`, `/subject-detail`, `/subjects`, `/rewards`, `/progress`
- Auth Routes: `/sign-in`, `/sign-up`, `/forgot-password`, `/update-password`, `/verification-pending`

---

## 3. COMPLETE FEATURE INVENTORY

### 3.1 Home Ecosystem
- **FEATURE:** Intelligent Home Dashboard
- **MODULE:** home
- **CONTROLLERS:** DailyOsCoordinator, AcademicIntelligenceController, TaskController, ExamController, StudyController, SubjectController, StudentService, GoalController, ResourceController, PlanningBlockController, FocusController, AcademicScheduleController, ProgressionController, StreakService
- **SUBFEATURES:** Daily briefing snapshot, Primary hero (contextual action card), First-time empty state, Today's overview (workload/recovery/early completion), Today's plan (PlanningBlocks), Today's schedule (agenda), Academic risk alerts, Quick actions grid (7 actions), Assistant entry bar, Upcoming & goals preview, Progression footer bar, Level-up toast
- **AUTOMATION:** DailyOsCoordinator snapshot, AcademicIntelligence recommendations, AutopilotEngine, risk detection, 30-minute burst

### 3.2 Planning Ecosystem
- **FEATURE:** Daily Planning & Scheduling
- **MODULE:** planning
- **CONTROLLERS:** PlanController, PlanningBlockController, PlanningEngine, AcademicScheduleController
- **SUBFEATURES:** DailyPlanSheet, PlanningBlock management, Rebalance day, Recover missed session, Skip block, Unschedule block, Budget management (default 180 min), Autopilot mode, Schedule-aware planning, Missed session recovery, Overload detection, PlanningBlock status derivation

### 3.3 Study Ecosystem
- **FEATURE:** Study Session Management
- **MODULE:** study
- **CONTROLLERS:** StudyController, TaskController, FocusController, ExamController, SubjectController, AcademicKnowledgeController, AcademicIntelligenceController, TodayPlanEngine
- **SUBFEATURES:** Active session tracking, Study streak tracking, Daily focus target (120 min), Study recommendations, Revision recommendations, Study consistency analytics, Focus completion bridge

### 3.4 Focus Ecosystem
- **FEATURE:** Focus Sessions
- **MODULE:** focus
- **CONTROLLERS:** FocusController, FocusGuardController
- **SERVICES:** FocusGuardService (MethodChannel), FocusGuardPermissionService
- **SUBFEATURES:** Focus modes (Timer/Stopwatch/FocusGuard), Focus missions, Focus sessions lifecycle, Focus checkpoints (15/30/45 min), Focus score calculation, Focus history, Focus insights, Focus distraction inbox, Focus Guard (app blocking), FocusGuard permissions (Usage Access, Overlay), FocusGuard modes (gentle/standard/strict), FocusGuard safe packages (12 Android apps), FocusGuard overlay intervention, Focus launch context preservation, Focus XP award, Focus → Study bridge, Focus → Task completion bridge, Focus → Streak update, Quick start presets, 30-minute burst, Contextual focus

### 3.5 Task Ecosystem
- **FEATURE:** Task Management
- **MODULE:** tasks
- **CONTROLLERS:** TaskController
- **SUBFEATURES:** Task creation, Task filtering, Task sorting, Task searching, Task editing, Task completion, Task deletion (with confirmation), Task scheduling, Task rescheduling, Task linking, Subtask management, Priority levels, Due date management, Recurrence, Reminder, Overdue detection

### 3.6 Subject Ecosystem
- **FEATURE:** Subject Management
- **MODULE:** subjects
- **CONTROLLERS:** SubjectController, AcademicKnowledgeController
- **SUBFEATURES:** Subject list, Subject detail with chapters/topics, Subject syllabus, Subject study/revision/focus actions, Subject creation, Catalog course data

### 3.7 Exam Ecosystem
- **FEATURE:** Exam Tracking
- **MODULE:** exams
- **CONTROLLERS:** ExamController
- **SUBFEATURES:** Exam list with countdown timers, Exam detail with syllabus, Exam creation/editing/deletion, Exam study/revision/focus/plan actions, Exam pressure assessment

### 3.8 Knowledge/Practice Ecosystem
- **FEATURE:** Knowledge & Practice
- **MODULE:** knowledge
- **CONTROLLERS:** AcademicKnowledgeController, PracticeQuestionController, TopicPracticeController
- **SUBFEATURES:** Knowledge center, Practice center, Practice sessions, Practice results, Practice mode selection, Topic practice attempts, Weak area identification, Practice history

### 3.9 Calendar Ecosystem
- **FEATURE:** Academic Calendar
- **MODULE:** calendar
- **CONTROLLERS:** AcademicScheduleController
- **SUBFEATURES:** Week/day/month view modes, Today jump, Add commitment, Event editing/deletion, Conflict detection, Availability summary, Planning block integration, Day schedule view, Agenda timeline, Plan Around event, View Day/Week

### 3.10 Revision Ecosystem
- **FEATURE:** Revision & Spaced Repetition
- **MODULE:** revision
- **CONTROLLERS:** RevisionController, AcademicKnowledgeController
- **SUBFEATURES:** Revision queue (4 filters), Momentum cards, Hero recommendation, Active recall sessions, Spaced repetition intervals (learning/stable/strong/mastered), Ease factors (1.3-3.0), Outcome recording (forgot/partial/knew), Revision scheduling, Revision practice, Revision history, XP award (15/25), Cloud sync via Supabase

### 3.11 Notes/Knowledge Ecosystem
- **FEATURE:** Notes & Knowledge Management
- **MODULE:** notes
- **CONTROLLERS:** StudentNoteController
- **SUBFEATURES:** Note creation/editing/viewing, Note pinning, Note archiving/unarchiving, Note deletion, Note focus, Note study, Note practice, Note revise, Note plan, Note search, Note listing (pinned, recent, archived)

### 3.12 Resources Ecosystem
- **FEATURE:** Resource Library
- **MODULE:** resources
- **CONTROLLERS:** ResourceController
- **SUBFEATURES:** Resource list/browsing, Resource search by tag, Resource detail with actions, Resource creation, Resource favoriting, Resource download, Resource filtering

### 3.13 Progress/Analytics Ecosystem
- **FEATURE:** Progress & Analytics
- **MODULE:** progress/analytics
- **CONTROLLERS:** ProgressionController, AchievementController, LeaderboardController, AcademicAnalyticsController, XPEngine, StreakService, RankingEngine
- **SUBFEATURES:** Overall progress dashboard, Progress workspace, XP history, Level indicator, Achievements, Leaderboard rankings, Academic analytics, Consistency analysis, Task performance analysis, Subject performance analysis, Exam readiness, Level-up dialog, XP earning/spending, Streak tracking

### 3.14 Rewards Ecosystem
- **FEATURE:** Rewards & Premium
- **MODULE:** rewards
- **CONTROLLERS:** RedemptionController, ThemeManager, PremiumEntitlement, EntitlementManager, FeatureGate
- **SERVICES:** SubscriptionProvider, GooglePlaySubscriptionProvider
- **SUBFEATURES:** Reward marketplace, Category filtering, Reward catalog (15 rewards, pricing tiers), Redemption flow (atomic), Entitlement management, Premium subscription, Trial management (7-day), Discount computation, Feature gating, Google Play billing, Reward history

### 3.15 Gamification Ecosystem
- **FEATURE:** Gamification System
- **MODULE:** progression/gamification
- **CONTROLLERS:** ProgressionController, AchievementController, LeaderboardController, StreakService, XPEngine, RankingEngine
- **SUBFEATURES:** XP earning, Level progression, Streak tracking, Achievement unlocking, Leaderboard rankings, Rank movement notifications, Level-up dialog, XP spending, Reward transactions, Entitlement management, Feature gating, Cosmetic theme unlocking, Streak milestones, Weekly consistency bonus

### 3.16 Assistant Ecosystem
- **FEATURE:** Student OS Assistant
- **MODULE:** assistant
- **CONTROLLERS:** StudentAssistantController, StudentAssistantEngine, StudentAssistantParser
- **SUBFEATURES:** 34 intent types, 31 action types, Natural language parsing, Deterministic intent parser, Context-aware responses, Clarification support, Confidence scoring, Command confirmation, Assistant sheet (modal bottom sheet)

### 3.17 Intelligence Ecosystem
- **FEATURE:** Academic Intelligence
- **MODULE:** intelligence
- **CONTROLLERS:** AcademicIntelligenceController, DailyOsCoordinator, and 22+ engine/controller files
- **SUBFEATURES:** (24 total) StudentOSIntelligenceEngine, AutopilotEngine, DailyOsCoordinator, AcademicIntelligenceEngine, TodayIntelligenceEngine, TodayPlanEngine, PlanningIntelligenceEngine, SmartRecommendationEngine, WeeklyPlanEngine, AdaptivePriorityEngine, IntelligentNotificationEngine, AcademicCommandCenter, AcademicAnalyticsEngine, RevisionPriorityEngine, ExamReadinessAnalyzer, ExamPreparationEngine, ConsistencyAnalyzer, TaskPerformanceAnalyzer, PerformanceTrendAnalyzer, SubjectPerformanceAnalyzer, AnalyticsInsightEngine, PerformanceSnapshot, StudentBehaviorProfile, AcademicContext, AcademicInsights
- **AUTOMATION:** Daily briefing, recommendation computation, risk detection, autopilot planning, overload detection, recovery session generation, notification evaluation

### 3.18 Notification Ecosystem
- **FEATURE:** Notifications
- **MODULE:** notifications
- **CONTROLLERS:** NotificationController, NotificationService, NotificationCoordinator
- **SUBFEATURES:** Notification center (list/filter/mark read), Local notification scheduling, 8 notification categories, 4 notification priorities, 12 evaluation triggers, Notification reconciliation, Deep link notification handling, Permission management, Scheduled notifications, Duplicate prevention

### 3.19 Settings/Preferences Ecosystem
- **FEATURE:** Application Settings
- **MODULE:** settings/preferences
- **CONTROLLERS:** UserPreferencesController, AppShellController, ThemeManager
- **SUBFEATURES:** Theme mode (light/dark/system), Cosmetic theme variants, Default focus duration, Week start day, Autopilot mode, Notification toggles (6 categories)

### 3.20 Account/Authentication Ecosystem
- **FEATURE:** Authentication & Account Management
- **MODULE:** auth/account
- **CONTROLLERS:** AuthService, StudentService
- **SERVICES:** SupabaseService, GoogleSignIn, AuthIsolation, ControllerIsolation
- **SUBFEATURES:** Welcome, Email/password sign-in, Google Sign-In (OAuth), Sign up, Forgot password, Update password, Email verification, Auth state restoration, Session isolation, Controller isolation, Logout, Deep link OAuth callback handling, Session reconciliation, User switching/isolation, Profile management, Account data management, Demo mode

---

## 4. SUBFEATURE INVENTORY

### FOCUS — 30 subfeatures
1. Focus session lifecycle (active/paused/completed/cancelled/interrupted)
2. Timer mode (configurable duration countdown)
3. Stopwatch mode (unlimited elapsed time)
4. FocusGuard mode (app blocking)
5. Focus missions (objective + duration + style)
6. Focus checkpoints (at 15/30/45 minutes)
7. Focus score calculation (duration/minute ratios + completion bonus + checkpoint bonus - distraction penalty, max 100)
8. Focus history (past sessions with scores, outcomes)
9. Focus insights (analytics, trends, patterns)
10. Focus distraction inbox (captured distractions during sessions)
11. Focus Guard settings (mode: gentle/standard/strict)
12. Focus Guard permissions (Usage Access, Overlay)
13. Focus Guard safe packages (12 pre-defined Android apps)
14. Focus Guard overlay (intervention display)
15. Focus Guard blocked app detection (1-second periodic monitoring)
16. Focus Guard intervention (gentle = bring-to-foreground, strict = overlay)
17. Focus launch context preservation (subject/topic/chapter/task/exam/block)
18. Focus → Study completion bridge (idempotent, links focusSessionId)
19. Focus → Task completion bridge (auto-completes linked task)
20. Focus → XP award
21. Focus → Streak update
22. Focus → Notification update
23. Focus → Progression level-up detection
24. Quick start presets (sprint/pomodoro/deepFocus/deepWork)
25. 30-minute burst focus
26. Contextual focus (from subject/topic/task/exam/planning block)
27. Resume existing session vs start new
28. End session early
29. Cancel session
30. Pause/resume with state preservation

### TASKS — 17 subfeatures
1. Task creation (title, priority, estimated effort, dates, subtasks, description, category, recurrence, reminder, exam link, subject link, goal link)
2. Task editing
3. Task completion
4. Task deletion (with confirmation dialog)
5. Task filtering (all/uncompleted/completed)
6. Task sorting
7. Task searching
8. Task scheduling (→ PlanningBlock)
9. Task rescheduling
10. Task linking (subject, exam, goal)
11. Subtask management with progress bar
12. Priority levels (critical/high/medium/low)
13. Due date management
14. Recurrence rules
15. Reminder time setting
16. Overdue detection and display
17. Task completion → XP award, PlanningBlock status update

### PLANNING — 16 subfeatures
1. Daily plan generation (PlanningEngine)
2. Plan my day (bottom sheet with budget presets)
3. Planning block creation
4. Planning block management
5. Rebalance day (overload correction)
6. Recover missed session
7. Skip block
8. Unschedule block
9. Schedule-aware planning
10. Overload detection
11. Early completion detection
12. Recovery session generation
13. Budget management (default 180 min)
14. PlanningBlock status derivation (upcoming/current/completed/missed/skipped)
15. Autopilot mode (suggest/autopilot/manual)
16. Plan transition notifications

### STUDY — 13 subfeatures
1. Study session management (start/pause/resume/end/cancel)
2. Study streak tracking
3. Daily focus target (120 min)
4. Study recommendations (AI-powered)
5. Revision recommendations
6. Study consistency analytics
7. Strongest day identification
8. Study session history
9. Today sessions tracking
10. Study progress vs target
11. Week durations tracking
12. Study streak days calculation
13. Focus completion → study recording (idempotent)

### INTELLIGENCE — 24 subfeatures
1. Daily briefing generation, 2. What should I do now, 3. Daily academic snapshot, 4. Academic risk detection, 5. Goal intelligence assessment, 6. Autopilot planning, 7. Health state computation (clear/onTrack/busy/overloaded/recoveryNeeded), 8. Next action determination, 9. Start my day action, 10. Continue my day action, 11. Recovery session generation, 12. Early completion detection, 13. 30-minute burst recommendation, 14. Exam pressure assessment, 15. Study/revision recommendations, 16. Unified recommendations, 17. Study time allocation with breaks, 18. Weekly plan generation, 19. Adaptive priority, 20. Smart resource recommendations, 21. Focus items derivation, 22. Notification evaluation (8 categories), 23. Performance snapshot, 24. Consistency analysis

### GAMIFICATION — 14 subfeatures
1. XP earning (tasks, study, syllabus, exam, streak, consistency, revision), 2. Level progression, 3. Streak tracking (current, best), 4. Achievement unlocking, 5. Leaderboard rankings, 6. Rank movement notifications, 7. Level-up dialog, 8. XP spending (reward redemption), 9. Reward transactions, 10. Entitlement management, 11. Feature gating, 12. Cosmetic theme unlocking, 13. Streak milestones (3/7/14/30 days), 14. Weekly consistency bonus

### NOTIFICATIONS — 12 subfeatures
1. Notification list (200-item cap), 2. Filter (all/unread/tasks/exams/focus/progression), 3. Local notification scheduling, 4. One-shot notifications, 5. Daily notifications, 6. Notification cancellation (before rescheduling for idempotency), 7. Notification tap → navigation, 8. Deep link notification handling, 9. Permission management, 10. Evaluation triggers (12 types), 11. Duplicate prevention, 12. Notification reconciliation

### SETTINGS — 7 subfeatures
1. Theme mode (light/dark/system), 2. Cosmetic theme variants, 3. Default focus duration, 4. Week start day, 5. Autopilot mode (suggest/autopilot/manual), 6. Notification toggles (6 categories), 7. User preferences persistence

### REWARDS — 11 subfeatures
1. Reward catalog browsing, 2. Category filtering, 3. Reward redemption (atomic), 4. Entitlement query, 5. Premium subscription, 6. Trial management (7-day), 7. Discount computation (level-based 5-20% + redeemed, capped 50%), 8. Feature gating, 9. Google Play billing, 10. Reward history, 11. Unlock notifications

---

## 5. COMPLETE BUTTON/ACTION INVENTORY

### 5.1 UniversalActionExecutor Entity Actions (Complete)

**Task Actions:** View (completed tasks only), Start, Schedule, Focus, Edit, Complete, Reschedule

**Subject Actions:** Study, Revise, Focus, Timer, Stopwatch, View Syllabus

**Topic Actions:** Study, Practice, Revise, Focus, Timer, Stopwatch, View

**Exam Actions:** Study, Revise, Plan, Focus, View

**PlanningBlock Actions (status-dependent):**
- Upcoming: Start Focus, View, Reschedule, Skip, Unschedule
- Current: Start Focus, View
- Completed: View
- Missed: Recover, Reschedule, View
- Skipped: View, Reschedule, Unschedule

**Resource Actions:** Open, Download, Toggle Favorite

**Goal Actions:** View, Plan, Progress

**CalendarEvent Actions:** View, Edit, Plan Around, View Day, View Week, Delete

**Focus Actions (session-state-dependent):**
- No session: Start Focus
- Active: Continue, Pause/Resume, End

**Note Actions:** Open, Edit, Focus, Study, Practice, Revise, Plan, Pin, Archive, Delete

### 5.2 Complete Action Inventory (by screen)

**HomeScreen:** Global Add (FAB), Profile avatar, 30-min Burst, Rebalance, Recover, Toggle Done Today, Quick Actions (Add Task), Assistant bar, Risk Banner actions, Progress Footer

**TasksScreen:** Add Task, filter, sort, search; TaskDetailScreen: Start Focus, Complete, Edit, Delete, Schedule, Reschedule, View

**FocusCenterScreen:** Timer, Stopwatch, FocusGuard buttons, Start Focus, Open Focus Mission, View History/Insights/Inbox/Guard Settings/Blocked Apps

**FocusSessionScreen:** Pause, Resume, End

**FocusMissionSetupScreen:** Duration chips, Style chips, Protection selector, Start, Connect entity

**PlanningScreen:** Plan My Day, Rebalance, Recover, Start Focus (block), View, Reschedule, Skip, Unschedule, Recover (block)

**CalendarScreen:** Today, Day/Week/Month switch, Add Commitment (FAB), Edit event, Delete event, Plan Around, View Day/Week, Resolve conflict

**KnowledgeCenterScreen:** Study, Practice, Revise (per topic)

**PracticeCenterScreen:** Start Practice, View history

**PracticeSessionScreen:** Submit answer, Complete

**RevisionScreen:** Start, Practice, Schedule, Filter; RevisionSessionScreen: Reveal notes, Self-evaluate (Knew It/Partly/Forgot), Complete

**NotesScreen:** Save, Edit, Focus, Study, Practice, Revise, Plan, Pin, Archive, Delete, Search

**ResourcesScreen:** Add Resource, filter, search; ResourceDetailScreen: Open, Download, Toggle Favorite, Edit, Delete

**GoalsScreen:** Create Goal, View Goal, Plan, Track Progress

**ProfileScreen:** Edit profile, Navigate to Achievements/Rewards/Tasks/Settings, Sign Out

**SettingsScreen:** Theme mode selector, Cosmetic theme selector, Focus duration picker, Week start day selector, Autopilot mode selector, Notification toggles

**HamburgerMenu:** Home, Plan, Study, Progress, Assistant, Account, Sign Out

**GlobalAddSheet:** New Commitment/Class, New Task, New Exam, New Subject, New Note, New Resource, Plan My Day

**UniversalActionLauncherSheet:** Ask Student OS, Start Focus Session, Plan My Day, Manage Tasks, Review Exams, Revise Materials, Practice & Quizzes

**MoreScreen:** Academic Schedule, Goals & Targets, Rewards Marketplace, Achievements & Badges, Leaderboard, Progress & Analytics, Knowledge Base & Notes, Study Resources, Subjects, Settings, Account & Data

---

## 6. EVERY MODAL/BOTTOM SHEET/DIALOG

### 6.1 TaskCreationSheet
- **FILE:** `lib/features/tasks/presentation/task_creation_sheet.dart`
- **OPENED FROM:** HomeScreen, GlobalAddSheet, UniversalActionExecutor.openGlobalAdd
- **FIELDS:** title, priority, estimatedMinutes, dueDate, scheduledDate, subtasks, description, category, recurrence, reminderTime, examId, subjectId, goalId
- **BUTTONS:** Save, Cancel
- **CONFIRMATION:** No

### 6.2 AddEditEventSheet
- **FILE:** `lib/features/calendar/presentation/widgets/add_edit_event_sheet.dart`
- **OPENED FROM:** CalendarScreen, AppRouter.openAddCalendarEvent, GlobalAddSheet
- **FIELDS:** title, type, date, startTime, endTime, location, recurrence, reminder
- **BUTTONS:** Save, Cancel, Delete (for existing events)
- **CONFIRMATION:** Delete requires confirmation

### 6.3 DailyPlanSheet
- **FILE:** `lib/features/planning/widgets/daily_plan_sheet.dart`
- **OPENED FROM:** UniversalActionExecutor.openPlanMyDay, GlobalAddSheet
- **FIELDS:** budgetMinutes (presets: 15/30/60/120/180/240/300 or custom), items with duration adjustment
- **BUTTONS:** Apply Plan, Cancel

### 6.4 FocusModeSelectionSheet
- **FILE:** `lib/features/focus/presentation/widgets/focus_mode_selection_sheet.dart`
- **OPENED FROM:** AppRouter.openFocusModeSelection (TaskDetailScreen, SubjectDetailScreen, ExamDetailScreen, UniversalActionExecutor)
- **FIELDS:** Subject/topic/task/exam context, duration, focus style
- **SPECIAL:** If active session exists, routes to FocusSessionScreen instead

### 6.5 StudentAssistantSheet
- **FILE:** `lib/core/assistant/presentation/student_assistant_sheet.dart`
- **OPENED FROM:** HomeScreen, More tab, UniversalActionLauncherSheet, AppRouter.openAssistant, GlobalAddSheet
- **FIELDS:** Text input, message history
- **BUTTONS:** Send, Close
- **HEIGHT:** 85% max height

### 6.6 GlobalAddSheet
- **FILE:** `lib/core/navigation/universal_action_executor.dart`
- **OPTIONS:** 7 creation items (event, task, exam, subject, note, resource, plan)

### 6.7 UniversalActionLauncherSheet
- **FILE:** `lib/core/navigation/universal_action_executor.dart`
- **OPTIONS:** 7 action items (ask assistant, focus, plan, tasks, exams, revision, practice)

### 6.8 EntityActionSheet
- **FILE:** `lib/core/navigation/universal_action_executor.dart`
- **OPENED FROM:** UniversalActionExecutor.showEntityActions, all entity detail screens
- **OPTIONS:** Varies by entity type (85+ actions across 10 entity types)

### 6.9 LevelUpDialog
- **FILE:** `lib/features/progression/widgets/level_up_dialog.dart`
- **OPENED FROM:** AppShell (automatic on level up)

### 6.10 Conflict Dialog (Calendar)
- **FILE:** Calendar day_schedule_view.dart
- **BUTTONS:** Resolve, Dismiss

### 6.11 FocusGuard Permission Dialogs
- **FILE:** `lib/features/focus/services/focus_guard_permission_service.dart`
- **PERMISSIONS:** Android Usage Access, Overlay permission
- **PLATFORM:** Android only

### 6.12 Delete Confirmation Dialogs
- **Where:** TaskDetailScreen, Calendar, Notes
- **CONFIRMATION:** YES required

### 6.13 Sign Out Confirmation
- **FILE:** `lib/core/widgets/hamburger_menu.dart`
- **CONFIRMATION:** YES

### 6.14 PracticeModeSelectionSheet
- **FILE:** `lib/features/knowledge/presentation/practice_mode_selection_sheet.dart`
- **NAVIGATION:** → PracticeSessionScreen

### 6.15 Edit Profile Sheet
- **FILE:** `lib/features/more/more_screen.dart`
- **OPENED FROM:** MoreScreen (_openEditProfile)

### 6.16 SubjectCreationSheet, 6.17 ExamCreationSheet, 6.18 ResourceCreationSheet
- **All modal bottom sheets with transparent background, scrollable**

### 6.19 Reward Redemption Flow
- **Atomic redemption:** validate eligibility → deduct XP → grant entitlement → persist → notify. Rollback on failure.

---

## 7. EVERY FORM/INPUT

| FORM | SCREEN | FIELDS | VALIDATION | PERSISTENCE |
|------|--------|--------|------------|-------------|
| Task Creation | TaskCreationSheet | title (required), priority, estimatedMinutes, dates, subtasks, description, category, recurrence, reminder, links | Title required | TaskController → StorageService → Supabase |
| Calendar Event | AddEditEventSheet | title (required), type, date, startTime, endTime, location, recurrence, reminder | Title required, end > start | AcademicScheduleController → Supabase |
| Note Editor | NoteEditorScreen | title (required), content (required), subjectId, chapterId, topicId, resourceId, tags | Title required | StudentNoteController → Supabase |
| Goal Creation | GoalsScreen/GoalDetailScreen | title (required), description, target, deadline, progress | Title required | GoalController → Supabase |
| Focus Mission | FocusMissionSetupScreen | objective (required), duration, focusStyle, protectionLevel, linked entities | Objective required, duration > 0 | FocusController → Supabase |
| Daily Plan | DailyPlanSheet | budgetMinutes, items with durations | Budget > 0 | PlanController → Supabase |
| Settings | SettingsScreen | themeMode, cosmeticVariant, focusDuration, weekStartDay, autopilotMode, notificationToggles | None required | UserPreferencesController → StorageService |
| Assistant Input | StudentAssistantSheet | query (required) | Non-empty | Session only |
| Focus Session Config | FocusSessionScreen | duration, subjectId, subjectName, taskId, examId, topicId, chapterId, planningBlockId, objective | - | FocusController → Supabase |
| Study Session Config | StudyScreen | subject, subjectId, chapterId, topicId | - | StudyController → Supabase |
| Revision Evaluation | RevisionSessionScreen | outcome (required), notes (optional) | Outcome required | RevisionController → Supabase |
| Practice Answer | PracticeSessionScreen | selectedOption, questionId | Option must be selected | TopicPracticeController → Supabase |
| Profile Edit | ProfileScreen | displayName, email (read-only), education, course/institution | - | StudentService → Supabase |
| Blocked Apps Picker | BlockedAppsPickerScreen | blockedApps (package names) | - | FocusGuardController |
| FocusGuard Settings | FocusGuardSettingsScreen | mode, usageAccessEnabled, overlayEnabled, safePackages | - | FocusGuardController |

---

## 8. STATE INVENTORY

### 8.1 HomeScreen States: First Launch, Loading, Error, Empty, Populated, Offline, Overloaded, Recovery Needed, Done For Today, Focus Active

### 8.2 Task States: Loading, Empty, Populated, Error, Offline, Task Detail - Active/Completed/Overdue

### 8.3 Focus States: Idle, Active (Timer/Stopwatch/FocusGuard), Paused, Completed, Interrupted, FocusGuard notReady/usageAccessRequired/overlayRequired/ready/unsupported

### 8.4 FocusGuard Permission States: notReady, usageAccessRequired, overlayRequired, ready, unsupported

### 8.5 Planning States: Loading, Empty, Populated, Overloaded, Recovery Needed, Block Upcoming/Current/Completed/Missed/Skipped

### 8.6 Calendar States: Loading, Week/Day/Month View, Conflict detected

### 8.7 Notification States: Loading, Empty, Populated, Error

### 8.8 Auth States: Checking, Authenticated, Unauthenticated, Signing In, Sign Up, Forgot Password, Verification Pending, Password Update, Session Restored, Session Expired

### 8.9 Premium States: Free, Active Trial, Subscribed, Trial Expired, Feature Locked

### 8.10 Level-Up State: Level Up Detected → LevelUpDialog

---

## 9. EMPTY STATES

| SCREEN | EMPTY CONDITION | MESSAGE | PRIMARY ACTION | CAN CREATE DATA |
|--------|----------------|---------|---------------|-----------------|
| HomeScreen | First time (no data) | Guided setup | Complete onboarding | Yes |
| TasksScreen | No tasks | "No tasks yet" | Add task | Yes |
| SubjectDetailScreen | No chapters/topics | Subject info shown | Add subjects | Yes |
| ExamScreen | No exams | No exams | Add exam | Yes |
| KnowledgeCenterScreen | No subjects | No knowledge data | Add subjects | Yes |
| FocusHistoryScreen | No sessions | No history | Start focus | Yes |
| FocusInsightsScreen | No data | No insights | Start focus | Yes |
| FocusDistractionInboxScreen | No distractions | No distractions | None | No |
| RevisionScreen | No revision due | No revision due | Schedule revision | Yes |
| NotificationCenterScreen | No notifications | No notifications | None | No |
| LeaderboardScreen | No entries | No rankings | None | No |
| AchievementsScreen | No achievements | No achievements | None | No |
| RewardsScreen | No unlockable | No unlockables | Browse catalog | Yes |
| GoalsScreen | No goals | No goals | Create goal | Yes |
| PracticeCenterScreen | No practice data | No practice | Select topic | Yes |
| CalendarScreen | No events | No commitments | Add commitment | Yes |
| ResourceSearchScreen | No results | No results | Search different | Yes |

---

## 10. ERROR STATES

| ERROR | TRIGGER | MESSAGE | RECOVERY | OFFLINE BEHAVIOR |
|-------|---------|---------|----------|-----------------|
| Supabase init timeout | Main initialization | Logged (debug only) | Retry on next launch | App may not function |
| Auth init timeout | Main initialization | Logged (debug only) | Retry | Auth may fail |
| User data load timeout | Controller loading | Logged (debug only) | Per-controller 8s timeout | Cached data shown |
| Snapshot load failure | DailyOsCoordinator | "Couldn't load your day" | Retry button | Cached data shown |
| FocusGuard permission denied | FocusGuardController | Permission request | Open settings | N/A |
| Google Sign-In failure | SignInScreen | Error message | Retry | N/A |
| OAuth callback error | Deep link | Logged (debug only) | Retry authentication | N/A |
| Supabase session null | Deep link | Logged (debug only) | Manual code exchange | N/A |
| Notification permission denied | NotificationService | System prompt | Open settings | N/A |
| Form validation error | Task/Note/Event creation | Inline error | Fix field | N/A |
| FocusGuard unsupported | FocusGuardService | Unsupported message | N/A | N/A (Android only) |
| PlanningEngine failure | Plan generation | Error state | Retry | N/A |
| AcademicIntelligence failure | Recommendation | Error state | Retry | N/A |
| Leaderboard error | LeaderboardScreen | Error message | Retry | N/A |

---

## 11. AUTOMATION INVENTORY

| AUTOMATION | TRIGGER | OUTPUT | USER CONTROL | CAN DISABLE | SIDE EFFECTS |
|-----------|---------|--------|-------------|-------------|-------------|
| Daily briefing | App launch, periodic | DailyAcademicSnapshot | No | No | Updates home screen |
| What should I do now | User views home | Recommended action | No | No | Drives home hero |
| Autopilot planning | User selects autopilot mode | Daily plan | Yes (mode selection) | Yes | Creates planning blocks |
| Overload detection | Plan generation | Health state | No | No | Rebalance suggestion |
| Recovery session generation | Missed blocks detected | Recovery sessions | No | No | Reschedules blocks |
| Early completion detection | Task completion | Early completion opportunities | No | No | Suggests additional work |
| Academic risk detection | Risk factors present | Risk banners | No | No | Risk alerts on home |
| Study recommendations | User views study screen | Study recommendations | No | No | Drives study card |
| Revision recommendations | Revision due | Revision recommendations | No | No | Drives revision card |
| Focus score calculation | Session completes | Score (max 100) | No | No | Awards XP, updates streak |
| Focus → Study bridge | Focus completes | Study session recorded | No | No | Idempotent, prevents double XP |
| Focus → Task completion | Focus completes with linked task | Task completed | No | No | Awards XP |
| XP calculation | Various completions | XP amount | No | No | Updates level, progress |
| Level-up detection | XP threshold reached | Level up | No | No | LevelUpDialog |
| Streak calculation | Daily activity | Current/best streak | No | No | Streak milestone XP |
| Spaced repetition scheduling | Revision outcome | Updated interval/ease factor | No | No | Reschedules revision |
| Notification evaluation | Various triggers | Scheduled notifications | Partially (toggles) | Yes | Notifications delivered |
| Notification reconciliation | App launch | Cleaned schedule | No | No | Cancels outdated |
| 30-min burst recommendation | Home screen | Burst action | Yes (user chooses) | No | Starts focus |
| Deep link OAuth handling | App launch, OAuth callback | Session exchange | No | No | Authenticates user |
| Cache updates | Data changes | Local persistence | No | No | Offline support |
| Theme variant unlocking | XP threshold | Theme unlocked/locked | No | No | Cosmetic changes |
| DailyOsCoordinator throttle | Data changes | Snapshot update | No | No | 15s throttle |

---

## 12. PERMISSION INVENTORY

| PERMISSION | PLATFORM | WHY NEEDED | WHERE REQUESTED | IF DENIED | HOW ENABLE | RELATED FEATURES |
|-----------|----------|-----------|-----------------|-----------|------------|-----------------|
| Android Usage Access | Android | Detect foreground apps for FocusGuard | FocusGuardSettingsScreen, FocusGuardController | FocusGuard limited mode | Android Settings → Apps → Usage access | FocusGuard |
| Overlay Permission | Android | Display focus overlay | FocusGuardSettingsScreen, FocusGuardController | FocusGuard limited mode | Android Settings → Display → Overlay | FocusGuard |
| Local Notifications | All | Schedule local notifications | NotificationService.initialize() | No notifications | System Settings → Notifications | All notifications |
| Google Sign-In | All | OAuth authentication | SignInScreen | Email/password still works | Google account selection | Auth |
| Deep Links | Android | OAuth callback handling | App links plugin | Auth via email/password still works | App configuration | Auth |
| Storage/Files | Android/iOS | Local JSON persistence | StorageService | App may not function | System permissions | All data persistence |

---

## 13. AUTHENTICATION/ACCOUNT FLOW

```
FIRST OPEN → AuthGate checks auth state
  ├── Authenticated → AppShell → HomeScreen
  │   ├── AuthIsolation.setAuthenticatedUser(userId)
  │   ├── ControllerIsolation.reloadAllControllers(userId)
  │   ├── StudentService.initializeFromAuth()
  │   ├── _loadUserScopedData() (19 controllers, 8s timeout each)
  │   ├── NotificationCoordinator.reconcileAll()
  │   └── HomeScreen
  └── Unauthenticated → AuthExperience → WelcomeScreen/SignInScreen

LOGOUT → HamburgerMenu → Sign Out (with confirmation)
  ├── ControllerIsolation.clearAllControllers() (memory only)
  ├── AuthIsolation.clearSession()
  └── AuthGate → WelcomeScreen/SignInScreen
  NOTE: Persistent storage is NOT deleted on logout

SESSION RESTORE → App launch → AuthService listener → AuthGate
  ├── If session exists → AppShell
  └── If no session → AuthExperience

DEEP LINK AUTH → OAuth callback → _handleRawDeepLink → _exchangeCodeForSession
  ├── Supabase auth.exchangeCodeForSession(code)
  └── Session established → AppShell
```

---

## 14. CROSS-MODULE RELATIONSHIP MAP

```
TASK → PlanningBlock → PlanningScreen → PlanController
  ↓ (start focus) → FocusModeSelectionSheet → FocusController → FocusSessionScreen
  ↓ (completes) → TaskController.completeTask() → XP award → ProgressionController
  ↓ → StudyController.recordFocusCompletion() → Study streak
  ↓ → NotificationController.onTaskCompleted()

SUBJECT → Chapter → Topic
  ↓ (study/practice/revise) → KnowledgeCenterScreen → AcademicKnowledgeController
  ↓ (practice) → PracticeCenterScreen → PracticeQuestionController → TopicPracticeController
  ↓ (revision) → RevisionScreen → RevisionController
  ↓ (focus) → FocusModeSelectionSheet → FocusController

EXAM → linked to Subject
  ↓ (study/revise/plan/focus) → ExamDetailScreen / RevisionScreen / PlanningScreen / FocusModeSelectionSheet
  ↓ (upcoming) → AcademicIntelligenceEngine → Risk banner
  ↓ → NotificationController.evaluateUpcomingExams()

CALENDAR EVENT → integrated with PlanningBlock
  ↓ (plan around) → PlanningScreen → PlanController
  ↓ (conflicts) → Conflict dialog → AcademicScheduleController

FOCUS SESSION → completes → FocusController → ProgressionController (XP)
  ↓ → StudyController (study recording, idempotent)
  ↓ → TaskController (task completion)
  ↓ → NotificationController (notifications)
  ↓ → StreakService (streak update)

NOTES → linked to Subject/Chapter/Topic
  ↓ (from note) → FocusModeSelectionSheet → FocusController
  ↓ (from note) → StudyController.startSession()
  ↓ (from note) → PracticeCenterScreen / RevisionScreen / PlanningScreen

ASSISTANT → StudentAssistantEngine → StudentAssistantIntent → StudentAssistantAction
  ↓ → AppRouter → Screen/Controller → UniversalActionExecutor → FocusController/TaskController/etc.
```

---

## 15. DUPLICATE ENTRY-POINT INVENTORY

| FUNCTION | ENTRY POINTS | CONTEXT DIFFERENCE |
|----------|-------------|-------------------|
| **Focus** | HomeScreen hero, FocusCenterScreen, StudyScreen, SubjectDetailScreen, TaskDetailScreen, PlanningScreen (blocks), NotesScreen, ExamDetailScreen, Assistant, UniversalActionLauncherSheet, GlobalAddSheet | Context varies: subject/topic/task/exam/block/note context, or plain focus center |
| **Tasks** | HomeScreen, TasksScreen directly, More tab → GoalsScreen, Assistant, GlobalAddSheet | HomeScreen creates task via sheet; TasksScreen manages all tasks |
| **Calendar** | Plan tab, More tab, Assistant, UniversalActionLauncherSheet, HomeScreen | More tab shows schedule; Plan tab shows planning |
| **Goals** | GoalsScreen, More tab → Goals, HomeScreen preview | GoalsScreen is full management; More tab is alternate entry |
| **Achievements** | AchievementsScreen, More tab → Achievements, ProfileScreen → Achievements | Same screen, different entry |
| **Leaderboard** | LeaderboardScreen, More tab → Leaderboard | Same screen, different entry |
| **Rewards** | RewardsScreen, More tab → Rewards, ProfileScreen → Rewards | Same screen, different entry |
| **Settings** | SettingsScreen, More tab → Settings, ProfileScreen → Settings | Same screen, different entry |
| **Notifications** | NotificationCenterScreen, More tab → Notifications | Same screen, different entry |
| **Knowledge** | KnowledgeCenterScreen, More tab → Knowledge Base, StudyScreen, SubjectDetailScreen | Knowledge center is main browse; More tab is alternate entry |
| **Resources** | ResourcesScreen, More tab → Study Resources, GlobalAddSheet, Assistant | Main list vs alternate entry |
| **Subjects** | SubjectsScreen, More tab → Subjects, GlobalAddSheet | Main list vs alternate entry |
| **Practice** | PracticeCenterScreen, KnowledgeCenterScreen, SubjectDetailScreen, Notes actions, StudyScreen, Assistant | Multiple entry points depending on context |
| **Revision** | RevisionScreen, SubjectDetailScreen, Topic actions, Notes actions, StudyScreen, Assistant | Multiple entry points depending on context |
| **Planning** | Plan tab, HomeScreen (today's plan), GlobalAddSheet, Assistant, CalendarScreen | Plan tab is full planning; HomeScreen shows today's plan preview |

---

## 16. HIDDEN FEATURES

| FEATURE | WHERE FOUND | HOW USER ACCESSES IT | WHAT IT DOES |
|---------|------------|---------------------|-------------|
| FocusGuard overlay | FocusGuardService, FocusController | Automatic when FocusGuard mode active | Blocks apps during focus, shows overlay intervention |
| FocusGuard blocked app detection | FocusGuardController | Automatic 1-second monitoring | Detects blocked app usage, records distraction |
| Focus checkpoints | FocusController | Automatic at 15/30/45 min | Awards checkpoint bonus to focus score |
| Focus distraction capture | FocusController | Automatic during FocusGuard sessions | Captures distractions during focus |
| Focus insights | FocusInsightsScreen | From FocusCenterScreen | Analytics and patterns from focus data |
| Focus distraction inbox | FocusDistractionInboxScreen | From FocusCenterScreen | Review captured distractions |
| PlanningBlock status derivation | UniversalActionExecutor.derivePlanningBlockStatus() | Automatic | Computes block display status |
| Missed session recovery | AcademicIntelligenceController.recoverMissedSession() | From HomeScreen Today card | Reschedules missed work |
| Day rebalancing | AcademicIntelligenceController.rebalanceDay() | From HomeScreen Today card | Rebalances overloaded schedule |
| 30-minute burst | StudentOSIntelligenceEngine.thirtyMinuteBurstAction | From HomeScreen hero | Quick focus burst recommendation |
| Autopilot mode | UserPreferencesController | SettingsScreen | Automatic planning mode |
| Smart recommendations | AcademicIntelligenceEngine | HomeScreen, StudyScreen | AI-powered suggestions |
| Daily briefing | DailyOsCoordinator | HomeScreen | Automated daily state summary |
| Academic risk detection | AcademicIntelligenceEngine | HomeScreen risk banners | Contextual alerts |
| Notification reconciliation | NotificationCoordinator | Automatic on app launch | Cleans outdated notifications |
| Deep link OAuth | AppLinks plugin | App launch | Handles OAuth callbacks |
| Session restoration | AuthIsolation | App launch | Restores previous session |
| Theme variant unlocking | ThemeManager | RewardsScreen | Unlock cosmetic themes with XP |
| Feature gating | FeatureGate | Throughout app | Controls feature availability |
| Focus launch context | FocusLaunchContext | Navigation | Preserves context across entity-to-focus flows |
| Idempotent focus→study bridge | StudyController.recordFocusCompletion() | Automatic | Prevents double XP on focus completion |
| Edit profile | _EditProfileSheet | From MoreScreen | Edits profile information |
| Conflict resolution | Calendar conflict dialog | From CalendarScreen | Resolves schedule conflicts |
| Notification evaluation | IntelligentNotificationEngine | Automatic | Evaluates and schedules notifications |
| Practice mode selection | PracticeModeSelectionSheet | From KnowledgeCenterScreen | Selects practice mode before starting |

---

## 17. SETTINGS INVENTORY

| SETTING | LOCATION | OPTIONS | DEFAULT | EFFECT | RELATED MODULE |
|---------|----------|---------|---------|--------|----------------|
| Theme mode | SettingsScreen → Appearance Mode | light, dark, system | system | Changes app theme | AppShellController |
| Cosmetic theme variant | SettingsScreen → Cosmetic Themes | Default, Focus Dark, Academic Light, Midnight Scholar (+ locked) | Default | Changes color variant | ThemeManager |
| Default focus duration | SettingsScreen | Duration picker | 25 min | Pre-selects when opening focus | FocusController |
| Week start day | SettingsScreen | 0-6 (Sun-Sat) | 0 (Sunday) | Week-boundary calculations | Calendar, Planning |
| Autopilot mode | SettingsScreen | suggest, autopilot, manual | suggest | Planning behavior | PlanningEngine |
| Study/planning reminders | SettingsScreen → Notification toggles | On/Off per category | On | Enables/disables notifications | NotificationController |
| Task/exam/focus notifications | SettingsScreen → Notification toggles | On/Off per category | On | Enables/disables notifications | NotificationController |
| Achievement/streak/leaderboard notifications | SettingsScreen → Notification toggles | On/Off per category | On | Enables/disables notifications | NotificationController |

---

## 18. NOTIFICATION INVENTORY

| NOTIFICATION | TRIGGER | ACTION WHEN TAPPED | CAN DISABLE | RELATED FEATURE |
|-------------|---------|-------------------|-------------|-----------------|
| examApproaching | Exam date approaching | Opens ExamScreen | Yes | Exams |
| preparationGap | Preparation gap detected | Opens StudyScreen | Yes | Study |
| todayPlan | Daily plan ready | Opens PlanningScreen | Yes | Planning |
| overdueTask | Task overdue | Opens TasksScreen | Yes | Tasks |
| studySession | Study session reminder | Opens StudyScreen | Yes | Study |
| revisionDue | Revision due | Opens RevisionScreen | Yes | Revision |
| progressSummary | Progress milestone | Opens ProgressScreen | Yes | Progress |
| rewardMilestone | Reward unlocked | Opens RewardsScreen | Yes | Rewards |
| Task completed | Task completed | Opens TaskDetailScreen | Yes | Tasks |
| Study completed | Study completed | Opens StudyScreen | Yes | Study |
| Focus completed | Focus completed | Opens FocusCenterScreen | Yes | Focus |
| Achievement unlocked | Achievement earned | Opens AchievementsScreen | Yes | Achievements |
| Level up | Level gained | Opens ProgressScreen | Yes | Progression |
| Streak milestone | Streak milestone | Opens StreakScreen | Yes | Streak |
| Leaderboard rank changed | Rank changed | Opens LeaderboardScreen | Yes | Leaderboard |
| Reward unlocked | Reward earned | Opens RewardsScreen | Yes | Rewards |
| Daily plan ready | Plan generated | Opens PlanningScreen | Yes | Planning |

---

## 19. DATA ENTITY INVENTORY

| ENTITY | FILE | KEY FIELDS | CONTROLLER | PERSISTENCE | RELATIONSHIPS |
|--------|------|-----------|------------|-------------|---------------|
| StudentTask | `lib/data/models/task.dart` | id, title, priority, estimatedMinutes, dueDate, scheduledDate, subjectId, examId, goalId, subtasks, isCompleted | TaskController | StorageService → Supabase | Subject, Exam, Goal, PlanningBlock |
| PlanningBlock | `lib/data/models/planning_block.dart` | id, startAt, endAt, subjectId, taskId, examId, topicId, chapterId, customTitle, status | PlanningBlockController | StorageService → Supabase | Subject, Task, Exam, Topic, Chapter |
| Subject | `lib/data/models/subject.dart` | id, displayName, syllabus, chapters, topics | SubjectController | StorageService → Supabase | Chapter, Topic, Task, Exam |
| Chapter | `lib/data/models/subject.dart` | id, title, topics | Subject | StorageService | Subject, Topic |
| Topic | `lib/data/models/subject.dart` | id, title, chapters, subjectId | Subject | StorageService | Subject, Chapter, Practice, Revision |
| Exam | `lib/data/models/exam.dart` | id, title, date, syllabus, subjectId | ExamController | StorageService → Supabase | Subject, Task, PlanningBlock |
| StudentNote | `lib/data/models/student_note.dart` | id, title, content, subjectId, chapterId, topicId, resourceId, tags, isPinned, isArchived | StudentNoteController | StorageService → Supabase | Subject, Chapter, Topic, Resource |
| StudentProfile | `lib/data/models/student_profile.dart` | id, displayName, email, course, institution, educationLevel | StudentService | StorageService → Supabase | AuthService |
| PracticeSession | `lib/data/models/practice_session.dart` | id, topicId, questions, score, result | TopicPracticeController | StorageService → Supabase | Topic, PracticeQuestion |
| PracticeSet | `lib/data/models/practice_set.dart` | id, topicId, questions | PracticeQuestionController | StorageService | Topic, PracticeQuestion |
| TopicPracticeAttempt | `lib/data/models/topic_practice_attempt.dart` | id, topicId, score, correctCount | TopicPracticeController | StorageService | Topic, PracticeQuestion |
| RevisionRecord | `lib/data/models/revision_record.dart` | id, topicId, outcome, easeFactor, interval | RevisionController | StorageService → Supabase | Topic |
| RevisionSchedule | `lib/data/models/revision_schedule.dart` | id, topicId, nextReview, interval, easeFactor | RevisionController | StorageService → Supabase | Topic |
| RevisionQueueItem | `lib/data/models/revision_queue_item.dart` | id, topicId, category, priority | RevisionController | StorageService | Topic |
| AcademicCalendarEvent | `lib/data/models/academic_calendar_event.dart` | id, title, type, startAt, endAt, location, recurrence | AcademicScheduleController | StorageService → Supabase | PlanningBlock |
| AcademicResource | `lib/data/models/academic_resource.dart` | id, title, type, url, isFavorite | ResourceController | StorageService → Supabase | Subject, Note |
| Achievement | `lib/data/models/achievement.dart` | id, title, description, isUnlocked | AchievementController | StorageService | ProgressionController |
| Level | `lib/data/models/level.dart` | level, xp | ProgressionController | StorageService | XPEvent |
| XPEvent | `lib/data/models/xp_event.dart` | id, amount, source, timestamp | XPEngine | StorageService | ProgressionController |
| Reward | `lib/data/models/reward.dart` | id, title, price, category, entitlementId | RedemptionController | StorageService → Supabase | Entitlement, RewardTransaction |
| RewardTransaction | `lib/data/models/reward_transaction.dart` | id, rewardId, xpSpent, timestamp | RedemptionController | StorageService → Supabase | Reward, Entitlement |
| Entitlement | `lib/data/models/entitlement.dart` | id, feature, isActive | PremiumEntitlement | StorageService → Supabase | Reward, FeatureGate |
| LeaderboardEntry | `lib/data/models/leaderboard_entry.dart` | id, rank, xp, userId | LeaderboardController | StorageService → Supabase | ProgressionController |
| AppNotification | `lib/data/models/app_notification.dart` | id, title, body, type, isRead | NotificationController | StorageService → Supabase | Various |
| FocusSession | focus/data/models/ | id, duration, subjectId, taskId, examId, score, outcome | FocusController | StorageService | Task, Subject, Exam, Topic |
| FocusMission | focus/data/models/focus_mission.dart | id, objective, duration, focusStyle | FocusController | StorageService | Subject, Task, Exam |
| FocusDistraction | focus/data/models/ | id, appName, timestamp | FocusController | StorageService | FocusSession |
| StudySession | `lib/data/models/study_session.dart` | id, subject, duration, date | StudyController | StorageService | Subject, FocusSession |
| CatalogCourse | `lib/data/catalog/` | id, title, subjects | CourseCatalogService | - | CatalogSubject |
| CatalogSubject | `lib/data/catalog/` | id, title, curriculum | CourseCatalogService | - | CatalogCurriculum |
| CatalogCurriculum | `lib/data/catalog/` | id, nodes | CourseCatalogService | - | CatalogNode |
| CatalogNode | `lib/data/catalog/` | id, type, content | CourseCatalogService | - | CatalogCurriculum |
| SyllabusState | `lib/data/models/` | id, subjectId, state | AcademicKnowledgeController | StorageService | Subject |

---

## 20. MOBILE/WEB/PLATFORM DIFFERENCES

| FEATURE | ANDROID | iOS | WEB |
|---------|---------|-----|-----|
| FocusGuard | Full (MethodChannel, Usage Access, Overlay) | Not available | Not available |
| FocusGuard permissions | Android Settings → Usage Access/Overlay | N/A | N/A |
| FocusGuard safe packages | 12 pre-defined Android system apps | N/A | N/A |
| FocusGuard monitoring | 1-second timer via MethodChannel | N/A | N/A |
| FocusGuard overlay | `showFocusOverlay()` / `bringAppToForeground()` | N/A | N/A |
| Focus active session | Floating timer shown/hidden on lifecycle change | N/A | N/A |
| Google Sign-In | Supported | Supported | Supported |
| Deep links | Valid scheme, legacy underscore scheme, localhost fallback | Same | Same |
| Notifications | `flutter_local_notifications` with Android init | Same plugin, iOS-specific | Browser notifications |
| Subscription | `GooglePlaySubscriptionProvider` | App Store | Web payment |
| App lifecycle | `AppLifecycleState` observed | Same | N/A |

---

## 21. RESPONSIVE UI INVENTORY

- **Navigation:** Mobile: Bottom tab navigation (4 destinations). Tablet/Web: Likely same with expanded content.
- **Modals:** Bottom sheets with scroll control and transparent background throughout
- **Dialogs:** Full-screen or modal dialogs depending on content
- **AssistantSheet:** Bottom sheet (85% height) on mobile; likely side panel on web
- **GlobalAddSheet/EntityActionSheet:** Bottom sheet pattern on mobile; likely side panel on web

---

## 22. PREMIUM/ENTITLEMENT INVENTORY

| FEATURE | TYPE | DESCRIPTION | LOCKED IF | UNLOCK VIA |
|---------|------|-------------|-----------|------------|
| Cosmetic theme variants | Entitlement | Theme variants | Locked (default) | Redeem XP in Marketplace |
| Premium subscription | Subscription | Full premium access | Free/Trial expired | Google Play subscription |
| Trial | Entitlement | 7-day premium trial | After trial expires | Upgrade to subscription |
| Feature gating | System | Controls feature availability | Feature not unlocked | Entitlement check |
| Discount computation | System | Level-based 5-20% + redeemed, capped 50% | N/A | Automatic |

**Premium States:** `free`, `activeTrial`, `subscribed`, `trialExpired`
**Marketplace:** 15 rewards, pricing tiers: starter/progress/advanced/premium/elite, categories: All/For You/Featured/Cosmetic/Academic/Premium/Feature/Badge
**Redemption:** Atomic (validate → deduct XP → grant entitlement → persist → notify). Rollback on failure.

---

## 23. GAMIFICATION INVENTORY

### XP System
| SOURCE | BASE XP | BONUS | MAX |
|--------|---------|-------|-----|
| Task completion | 10 | Priority bonus | - |
| Study session | 15 | Per 30min | 50 |
| Syllabus | 25 | - | - |
| Exam | 50 | - | - |
| Streak milestone 3 days | 20 | - | - |
| Streak milestone 7 days | 40 | - | - |
| Streak milestone 14 days | 60 | - | - |
| Streak milestone 30 days | 100 | - | - |
| Weekly consistency | 30 | - | - |
| Revision (forgot) | 15 | - | - |
| Revision (partial/knew) | 25 | - | - |

### Other Gamification
- **Level System:** Based on total XP, LevelUpDialog shown automatically via AppShell
- **Streak System:** From completed tasks + study sessions, milestones at 3/7/14/30 days
- **Achievement System:** Unlocked via NotificationController.onAchievementUnlocked()
- **Leaderboard System:** Rankings with rank movement notifications

---

## 24. ASSISTANT COMMAND INVENTORY

### 34 Intent Types (abbreviated)
Greeting, Help, WhatShouldIDo, WhatShouldIStudy, WhatShouldIRevise, StartMyDay, ContinueMyDay, PlanTime, AvailableTime, StartFocus, StudySubject, StudyTopic, ReviseTopic, FocusSubject, FocusTopic, ShowTasks, StartTask, CompleteTask, ShowTodayPlan, ShowExams, ShowGoals, ShowProgress, ShowWeakAreas, ShowOverdue, Reschedule, RecoverMissedSession, RebalanceDay, PracticeTopic, PracticeWeakest, ShowPracticeHistory, ShowScheduleToday/Tomorrow/Week, ShowNextClass, CheckFreeTime, ShowScheduleConflicts, ShowBusiestDay, ShowNotes, SearchNotes, OpenNote, ShowPinnedNotes, ShowRecentNotes, CreateNote

### 31 Action Types
Navigation actions: OpenHome, OpenPlan, OpenStudy, OpenFocus, OpenTasks, OpenExams, OpenGoals, OpenProgress, OpenRevision, OpenCalendar, OpenPractice, OpenKnowledge, OpenNote, SearchNotes

Action execution: StartFocus, StartPlanningBlock, StartTopic, StartTask, StartRevision, StartPlan, ApplyPlan, Reschedule, Recover, Rebalance, CompleteTask, StartPractice, ResolveConflict, CreateNote

---

## 25. UNIVERSAL ACTION INVENTORY

### Entity Types and Actions

**Task** (UniversalTaskAction): `start`, `schedule`, `focus`, `edit`, `complete`, `reschedule`, `view`

**Subject** (UniversalSubjectAction): `study`, `revise`, `focus`, `timer`, `stopwatch`, `viewSyllabus`

**Topic** (UniversalTopicAction): `study`, `practice`, `revise`, `focus`, `timer`, `stopwatch`, `view`

**Exam** (UniversalExamAction): `study`, `revise`, `plan`, `focus`, `view`

**PlanningBlock** (UniversalBlockAction): `startFocus`, `view`, `reschedule`, `skip`, `unschedule`, `recover` (status-dependent)

**Resource** (UniversalResourceAction): `open`, `download`, `toggleFavorite`

**Goal** (UniversalGoalAction): `view`, `plan`, `progress`

**CalendarEvent** (UniversalCalendarEventAction): `view`, `edit`, `planAround`, `viewDay`, `viewWeek`, `delete`

**Focus** (UniversalFocusAction): `start`, `continueSession`, `pauseResume`, `end` (session-state-dependent)

**Note** (UniversalNoteAction): `open`, `edit`, `focus`, `study`, `practice`, `revise`, `plan`, `pin`, `archive`, `delete`

---

## 26. FUNCTIONAL PRIORITY CLASSIFICATION

### CORE (Required for primary workflow)
1. Task management (create, edit, complete, delete)
2. Focus sessions (Timer, Stopwatch, FocusGuard)
3. Planning (Plan My Day, planning blocks, rebalance, recover)
4. Study sessions (start, pause, resume, end)
5. Subject management
6. Authentication (sign in, sign up, Google, session restore)
7. Home dashboard (daily briefing, recommendations)
8. Navigation (bottom tab, AppRouter, deep links)
9. State management (controllers, auth isolation, controller isolation)
10. Data persistence (StorageService, Supabase)

### SUPPORTING (Supports core workflows)
1. Calendar (events, conflicts, scheduling)
2. Revision (spaced repetition, active recall)
3. Knowledge (subject/topic browsing, syllabus)
4. Practice (questions, attempts, results)
5. Notes (create, edit, organize)
6. Resources (store, search, manage)
7. Goals (create, track, plan)
8. Intelligence (recommendations, autopilot, risk detection)
9. Assistant (natural language commands)
10. Notifications (evaluation, scheduling, delivery)

### UTILITY (Useful standalone capability)
1. Focus history and insights
2. Focus distraction inbox
3. FocusGuard settings and permissions
4. Blocked apps picker
5. Achievement viewing
6. Leaderboard rankings
7. Streak tracking
8. XP history
9. Resource search
10. Note search and filtering

### SYSTEM (Authentication, settings, permissions, sync)
1. Auth flow (welcome, sign in, sign up, forgot password, verification)
2. Profile management
3. Settings (theme, autopilot, notifications, focus duration)
4. Account data management
5. Preferences
6. Permission management
7. Supabase sync
8. Deep link handling
9. Auth isolation and controller isolation
10. Notification permission

### DISCOVERY (Navigation/search/assistant entry points)
1. Student Assistant (natural language interface)
2. UniversalActionLauncherSheet ("What do you want to do?")
3. GlobalAddSheet ("Add to Student OS")
4. Hamburger menu (slide-over navigation)
5. Search (resources, notes)
6. Assistant intents (34 command types)
7. Module placeholder screens

### GAMIFICATION (XP, badges, leaderboard, rewards)
1. XP earning and tracking
2. Level progression
3. Streak tracking
4. Achievement unlocking
5. Leaderboard rankings
6. Reward marketplace
7. Reward redemption
8. Entitlement management
9. Premium subscription
10. Cosmetic theme unlocking

### PREMIUM (Entitlement-related)
1. Premium subscription
2. Trial management
3. Feature gating
4. Google Play billing
5. Discount computation
6. Entitlement queries

---

## 27. BLUEPRINT-SAFE FUNCTIONAL REQUIREMENTS

### FUNCTIONAL CAPABILITIES THE NEW UI MUST PRESERVE

**Task Management:**
- Create task (with all fields)
- Edit task
- Delete task (with confirmation)
- Complete task
- Filter tasks (all/uncompleted/completed)
- Sort tasks
- Search tasks
- Schedule task
- Reschedule task
- Link task to subject/exam/goal
- Manage subtasks

**Focus:**
- Start focus session (Timer mode)
- Start focus session (Stopwatch mode)
- Start focus session (FocusGuard mode)
- Start focus mission
- Pause/resume focus session
- End focus session early
- Cancel focus session
- View focus history
- View focus insights
- Review focus distractions
- Configure FocusGuard (mode, permissions, blocked apps)

**Planning:**
- Plan My Day
- Rebalance day
- Recover missed session
- Skip block
- Unschedule block
- View planning blocks
- Start Focus from planning block

**Study:**
- Start study session
- Pause/resume/end study session
- View study recommendations
- View study streak
- View study progress vs target

**Calendar:**
- Add/edit/delete events
- Switch between week/day/month views
- Jump to today
- View conflicts
- Plan around events
- View day/week

**Revision:**
- Start revision session
- Practice topic
- Schedule revision
- Filter revision queue
- Record outcome (forgot/partial/knew)
- View revision history

**Notes:**
- Create/edit/delete notes
- Pin/unpin notes
- Archive/restore notes
- Focus from note
- Study from note
- Practice from note
- Revise from note
- Plan from note
- Search notes
- View pinned/recent notes

**Resources:**
- Browse resources
- Search resources by tag
- Open/download resources
- Toggle favorite
- Create resources
- Filter resources

**Goals:**
- Create goals
- Edit goals
- Delete goals
- Plan goals
- Track goal progress

**Profile:**
- View profile
- Edit profile
- Sign out
- View achievements
- View rewards

**Settings:**
- Change theme mode
- Change cosmetic theme variant
- Set default focus duration
- Set week start day
- Set autopilot mode
- Toggle notifications

**Assistant:**
- Natural language input
- All 34 intent types
- All 31 action types

**Gamification:**
- Earn XP
- Track level
- Track streaks
- View achievements
- View leaderboard
- Redeem rewards
- View premium status

---

## 28. UI-ONLY VS FUNCTIONAL ELEMENTS

### A. FUNCTIONAL ELEMENTS (removal would remove functionality)
All controllers, services, models, action executors, navigation logic, state management, data persistence, authentication, notification scheduling, focus timer/stopwatch logic, FocusGuard MethodChannel calls, planning engine, intelligence engines, assistant parser/engine, XP engine, streak service, revision engine, deep link handling, session management

### B. PRESENTATIONAL ELEMENTS (can freely change)
- Cards (AppCard, TaskTile, StatCard, etc.)
- Colors (AppTheme, AppPalette, MonoPalette, ThemeVariants)
- Spacing (AppSpacing, AppRadius, AppElevation)
- Typography (AppTextTheme)
- Decorative icons, gradients, borders
- Animations (AnimatedEntrance, AppPageTransitions, FadeThroughPage)
- Visual hierarchy
- Hero illustrations
- Background patterns

### C. NAVIGATION ELEMENTS (provide access to functionality)
- Bottom tab bar (FuturisticShellNav)
- AppRouter navigation helpers
- UniversalActionExecutor routing
- Hamburger menu
- Modal bottom sheets (as navigation vehicles)
- Deep link handlers

### D. SYSTEM STATES (communicate status)
- Loading indicators
- Error states with retry
- Empty states with CTAs
- Offline indicators
- Permission denial states
- Authentication states
- FocusGuard permission states
- Focus session states (active/paused/completed)
- Planning block status (upcoming/current/completed/missed/skipped)
- Level-up dialog
- Notification badges
- Streak badges
- XP indicators

---

## 29. SCREEN-BY-SCREEN BLUEPRINT DATA SHEETS

(See Section 1 for complete screen details. Each screen follows this compact format below.)

### SCREEN: HomeScreen (11)
**PURPOSE:** Intelligent dashboard answering "What should I do now?"

**USER CAN:**
1. Execute recommended action (start focus, plan, study, etc.)
2. Start 30-minute burst focus
3. Add task (via FAB or Quick Actions)
4. Open GlobalAddSheet for any creation
5. Ask Student OS Assistant
6. Rebalance day
7. Recover missed session
8. Toggle Done Today
9. View academic risks
10. View progress

**MUST DISPLAY:**
1. Greeting with user name and date
2. Streak and XP
3. Primary hero (contextual action card)
4. Today's overview (workload, recovery, early completion)
5. Today's plan (PlanningBlocks list)
6. Today's schedule (agenda)
7. Academic risk alerts (if applicable)
8. Quick actions grid (7 actions)
9. Assistant entry bar
10. Upcoming exams and goals preview
11. Progression footer bar

**OPTIONAL/CONTEXTUAL:**
1. First-time empty state (guided setup)
2. Day hint text (overload/recovery)
3. Level-up toast

**ACTIONS:** Execute action, 30-min burst, Rebalance, Recover, Add task, Start focus, View plan, View schedule, Toggle done today, Open assistant, Open profile

**NAVIGATION:** From: AppShell → To: Various screens based on action

**MODAL/SHEETS:** TaskCreationSheet, GlobalAddSheet

**STATES:** First Launch, Loading, Error, Empty, Populated, Offline, Overloaded, Recovery Needed, Done For Today, Focus Active

**DATA:** Greeting, streak, XP, focus minutes today, planning blocks, next block, academic risks, exams, goals, study recommendations

**DEPENDENCIES:** DailyOsCoordinator, AcademicIntelligenceController, TaskController, ExamController, StudyController, SubjectController, StudentService, GoalController, ResourceController, PlanningBlockController, FocusController, AcademicScheduleController, ProgressionController, StreakService

**PERMISSIONS:** None directly

**AUTOMATIONS:** Daily briefing, recommendations, autopilot, risk detection, 30-min burst

**IMPORTANT RELATIONSHIPS:** Aggregates data from 13+ controllers; drives all major workflows via hero action; assistant entry point

### SCREEN: PlanningScreen (12)
**PURPOSE:** Daily planning and schedule management

**USER CAN:** Plan my day, rebalance, recover, start focus from block, view blocks, reschedule, skip, unschedule, recover block, open calendar

**MUST DISPLAY:** Today's plan (PlanningBlocks list), day budget, block status indicators, calendar integration

**ACTIONS:** Plan My Day, Rebalance, Recover, Start Focus (block), View, Reschedule, Skip, Unschedule, Recover (block), Add event

**MODAL/SHEETS:** DailyPlanSheet, AddEditEventSheet

**STATES:** Loading, Empty, Populated, Overloaded, Recovery Needed, Block Upcoming/Current/Completed/Missed/Skipped

### SCREEN: StudyScreen (13)
**PURPOSE:** Academic execution hub with recommendations

**USER CAN:** Start focus with subject, study topic, practice topic, revise topic, continue active session, view recommendations, view recent activity

**MUST DISPLAY:** Active focus card (if in progress), What Should I Study? recommendation, alternative recommendations, revision recommendations, upcoming exams preview, recent study activity, Start Study/Focus actions

**ACTIONS:** Start Focus, Study subject, Practice topic, Revise topic, Continue session

**NAVIGATION:** → FocusCenterScreen, KnowledgeCenterScreen, RevisionScreen, ExamDetailScreen, SubjectDetailScreen, PracticeCenterScreen

**STATES:** Loading, Empty, Populated, Focus Active

### SCREEN: FocusCenterScreen (15)
**PURPOSE:** Focus hub and mode selection

**USER CAN:** Start Timer/Stopwatch/FocusGuard, open focus mission, view history/insights/inbox/settings, select quick start presets, start 30-min burst

**MUST DISPLAY:** Streak stats, weekly minutes, ready-to-focus hero, quick start presets, mode buttons, FocusGuard live status pill, recent session history

**ACTIONS:** Start Timer, Start Stopwatch, Start FocusGuard, Open Focus Mission, View History, View Insights, View Inbox, View Guard Settings, View Blocked Apps

**MODAL/SHEETS:** FocusModeSelectionSheet

**STATES:** Idle, Active (Timer/Stopwatch/FocusGuard), Paused, Completed, Interrupted

### SCREEN: FocusSessionScreen (16)
**PURPOSE:** Active focus timer/stopwatch/FocusGuard session

**USER CAN:** Pause, Resume, End session

**MUST DISPLAY:** Timer/stopwatch display, session objective, subject/topic context, progress bar, checkpoint indicators, pause/resume/end controls, FocusGuard overlay (when active)

**ACTIONS:** Pause, Resume, End

**STATES:** Focusing, Paused, Completed, Interrupted

**MODES:** Timer, Stopwatch, FocusGuard

**AUTOMATIONS:** Checkpoint system (15/30/45 min), score calculation, XP award, streak update, task completion bridge, FocusGuard monitoring (Android)

### SCREEN: TasksScreen (23)
**PURPOSE:** Task list management

**USER CAN:** Add task, filter (all/uncompleted/completed), sort, search, tap to view, complete, edit, delete

**MUST DISPLAY:** Task list, filter controls, sort controls, search

**ACTIONS:** Add Task, filter, sort, search, tap task

**MODAL/SHEETS:** TaskCreationSheet

**STATES:** Loading, Empty, Populated, Error, Offline

### SCREEN: TaskDetailScreen (24)
**PURPOSE:** Task detail with actions

**USER CAN:** Start Focus, Complete, Edit, Delete, Schedule, Reschedule, View

**MUST DISPLAY:** Task title, description, priority, estimated effort, due date, scheduled blocks, subtasks, linked subject/exam/goal, completion status banners

**ACTIONS:** Start Focus, Complete, Edit, Delete, Schedule, Reschedule, View

**MODAL/SHEETS:** Confirmation dialog for delete

**STATES:** Active, Completed, Overdue

### SCREEN: CalendarScreen (34)
**PURPOSE:** Academic calendar view

**USER CAN:** Add commitment, edit event, delete event, plan around event, view day/week, jump to today, resolve conflicts

**MUST DISPLAY:** View mode selector (week/day/month), Today jump, Add Commitment button, day schedule view, conflicts banner, availability summary, agenda timeline

**ACTIONS:** Add Commitment, Jump to Today, Switch view mode, Edit event, Delete event, Plan Around, View Day, View Week, Resolve conflict

**MODAL/SHEETS:** AddEditEventSheet, Conflict dialog

**STATES:** Loading, Week/Day/Month View, Conflict detected

### SCREEN: RewardsScreen (50)
**PURPOSE:** Reward marketplace

**USER CAN:** Browse rewards, filter by category, redeem rewards, view next unlock

**MUST DISPLAY:** Marketplace summary, next unlock preview, affordable carousel, category filters

**ACTIONS:** Browse, Redeem, View next unlock

**MODAL/SHEETS:** Redemption flow

**STATES:** Free, Active Trial, Subscribed, Trial Expired

### SCREEN: SettingsScreen (56)
**PURPOSE:** Application settings

**USER CAN:** Change theme mode, select cosmetic theme, set focus duration, set week start day, set autopilot mode, toggle notifications

**MUST DISPLAY:** Appearance Mode section, Cosmetic Themes section, Focus Duration, Week Start Day, Autopilot Mode, Notification toggles

**ACTIONS:** Toggle theme mode, Select cosmetic variant, Set focus duration, Set week start day, Set autopilot mode, Toggle notifications

**STATES:** All settings are user-configurable

### SCREEN: ProfileScreen (55)
**PURPOSE:** User profile and identity

**USER CAN:** Edit profile, view achievements/rewards/tasks/settings, sign out

**MUST DISPLAY:** Identity card (avatar, name, journey), premium badge, academic summary, goals wrap, links to all features, sign out

**ACTIONS:** Edit profile, Navigate to features, Sign Out

**STATES:** Authenticated, Demo mode

### SCREEN: NotificationCenterScreen (59)
**PURPOSE:** Notification center

**USER CAN:** Filter notifications, tap to navigate, mark as read

**MUST DISPLAY:** Notification list, filter controls, unread count

**ACTIONS:** Filter, tap to navigate, mark as read

**STATES:** Loading, Empty, Populated, Error

### SCREEN: StudentAssistantSheet (assistant)
**PURPOSE:** AI assistant with natural language input

**USER CAN:** Type query, receive response, execute recommended actions

**MUST DISPLAY:** Input field, message history, suggested commands

**ACTIONS:** Send query, Close

**STATES:** Loading, Has result, Empty, Error

### SCREEN: MoreScreen (14)
**PURPOSE:** Settings, profile, additional features

**USER CAN:** Navigate to all More tab features, edit profile, view academic schedule, goals, rewards, achievements, leaderboard, progress, knowledge, resources, subjects, settings, account data

**MUST DISPLAY:** Profile hero card, Academic & Goals section, App Configuration section, footer

**ACTIONS:** Navigate to all listed features, edit profile

---

## 30. COMPLETE APP MAP

```
STUDENT OS
│
├── Authentication
│   ├── WelcomeScreen
│   ├── SignInScreen
│   ├── SignUpScreen
│   ├── ForgotPasswordScreen
│   ├── UpdatePasswordScreen
│   ├── VerificationPendingScreen
│   ├── AuthLoadingScreen
│   ├── AuthGate
│   ├── AuthShell
│   └── OnboardingScreen
│
├── Home
│   ├── HomeScreen (1760 lines)
│   ├── _HomeHeader
│   ├── _HomeLoadingState
│   ├── _FirstTimeEmptyState
│   ├── _TodayOverviewCard
│   ├── _TodayPlanSection
│   ├── _HomeTodayAgendaCard
│   ├── _QuickActionsSection
│   ├── _HomeAssistantBar
│   ├── _UpcomingAndGoalsSection
│   └── _ProgressionBar
│
├── Plan
│   ├── PlanningScreen (1475 lines)
│   ├── DailyPlanSheet
│   └── PlanningBlock management
│
├── Study
│   ├── StudyScreen (1622 lines)
│   ├── _StudyHeader
│   ├── _ActiveFocusCard
│   ├── _WhatShouldIStudyCard
│   ├── _StudySubjectCard
│   └── study_subjects/
│
├── More
│   ├── MoreScreen (724 lines)
│   ├── _ProfileHeroCard
│   ├── _EditProfileSheet
│   ├── _SettingsGroup
│   ├── goals_screen.dart (More tab)
│   ├── account_data_screen.dart
│   └── navigation to:
│       ├── GoalsScreen, ProfileScreen, SettingsScreen
│       ├── NotificationCenterScreen, AccountDataScreen
│       ├── StreakScreen, AchievementsScreen
│       ├── LeaderboardScreen, RewardsScreen, PremiumScreen
│       ├── CalendarScreen, KnowledgeCenterScreen
│       ├── ResourcesScreen, SubjectsScreen
│       └── StudentAssistantSheet
│
├── Focus (8 screens)
│   ├── FocusCenterScreen (1402 lines)
│   ├── FocusSessionScreen
│   ├── FocusMissionSetupScreen
│   ├── FocusHistoryScreen
│   ├── FocusInsightsScreen
│   ├── FocusDistractionInboxScreen
│   ├── FocusGuardSettingsScreen
│   └── BlockedAppsPickerScreen
│
├── Tasks (3 screens)
│   ├── TasksScreen
│   ├── TaskDetailScreen
│   └── TaskCreationSheet
│
├── Subjects (2 screens)
│   ├── SubjectsScreen
│   └── SubjectDetailScreen
│
├── Exams (2 screens)
│   ├── ExamScreen
│   └── ExamDetailScreen
│
├── Knowledge/Practice (4 screens)
│   ├── KnowledgeCenterScreen
│   ├── PracticeCenterScreen
│   ├── PracticeSessionScreen
│   └── PracticeResultScreen
│
├── Calendar (1 screen + widgets)
│   ├── CalendarScreen
│   ├── AddEditEventSheet
│   ├── DayScheduleView
│   ├── WeekScheduleView
│   ├── MonthScheduleView
│   └── Conflict dialog
│
├── Revision (3 screens)
│   ├── RevisionScreen
│   ├── RevisionDetailScreen
│   └── RevisionSessionScreen
│
├── Notes (2 screens)
│   ├── NoteEditorScreen
│   └── NoteDetailScreen
│
├── Resources (3 screens)
│   ├── ResourcesScreen
│   ├── ResourceDetailScreen
│   └── ResourceSearchScreen
│
├── Progress/Analytics (5+ screens)
│   ├── ProgressScreen
│   ├── ProgressWorkspaceScreen
│   ├── LeaderboardScreen
│   ├── AchievementsScreen
│   ├── AnalyticsScreen
│   ├── AnalyticsDetailScreen
│   └── XpHistoryScreen
│
├── Rewards (3 screens)
│   ├── RewardsScreen
│   ├── PremiumScreen
│   └── StreakScreen
│
├── Goals (2 screens)
│   ├── GoalsScreen
│   └── GoalDetailScreen
│
├── Notifications (1 screen)
│   └── NotificationCenterScreen
│
├── Assistant (1 sheet)
│   └── StudentAssistantSheet
│
├── Profile
│   └── ProfileScreen
│
├── Settings
│   └── SettingsScreen
│
├── Intelligence (24 engines)
│   ├── StudentOSIntelligenceEngine
│   ├── AutopilotEngine
│   ├── DailyOsCoordinator
│   ├── AcademicIntelligenceEngine
│   ├── TodayIntelligenceEngine
│   ├── TodayPlanEngine
│   ├── PlanningIntelligenceEngine
│   ├── SmartRecommendationEngine
│   ├── WeeklyPlanEngine
│   ├── AdaptivePriorityEngine
│   ├── IntelligentNotificationEngine
│   └── 12 more engine files
│
├── Gamification (6 controllers)
│   ├── ProgressionController
│   ├── AchievementController
│   ├── LeaderboardController
│   ├── StreakService
│   ├── XPEngine
│   └── RankingEngine
│
└── Navigation/System
    ├── AppRouter
    ├── UniversalActionExecutor
    ├── AppShell
    ├── FuturisticShellNav
    ├── HamburgerMenu
    ├── ShellDestinations
    ├── FocusLaunchContext
    ├── GlobalAddSheet
    ├── UniversalActionLauncherSheet
    ├── EntityActionSheet
    └── ModulePlaceholderScreen
```

---

## 31. FINAL STATISTICS

| METRIC | COUNT |
|--------|-------|
| **TOTAL SCREENS** | 65 |
| **TOTAL MAJOR FEATURES** | 20 (auth, home, planning, study, focus, tasks, subjects, exams, knowledge, calendar, revision, notes, resources, progress, analytics, rewards, streak, goals, notifications, settings, profile, intelligence) |
| **TOTAL SUBFEATURES** | 150+ (across all features) |
| **TOTAL FUNCTIONAL ACTIONS** | 200+ (including all entity actions, screen-specific actions, hamburger menu actions, sheet actions) |
| **TOTAL MODALS/SHEETS** | 15+ (TaskCreationSheet, AddEditEventSheet, DailyPlanSheet, FocusModeSelectionSheet, StudentAssistantSheet, GlobalAddSheet, UniversalActionLauncherSheet, EntityActionSheet, LevelUpDialog, Conflict Dialog, FocusGuard Permissions, Delete Confirmations, Sign Out, PracticeModeSelection, EditProfile, SubjectCreation, ExamCreation, ResourceCreation, Reward Redemption, Notification Filter) |
| **TOTAL FORMS** | 15+ (task creation, calendar event, note editor, goal, focus mission, daily plan, settings, assistant input, focus session config, study session config, revision evaluation, practice answer, profile edit, blocked apps, focusguard settings) |
| **TOTAL ASSISTANT INTENTS** | 34 |
| **TOTAL ASSISTANT ACTIONS** | 31 |
| **TOTAL UNIVERSAL ACTION ENTITY TYPES** | 10 (Task, Subject, Topic, Exam, PlanningBlock, Resource, Goal, CalendarEvent, Focus, Note) |
| **TOTAL UNIVERSAL ACTIONS** | 85+ |
| **TOTAL NOTIFICATION TYPES** | 17 |
| **TOTAL PERMISSIONS** | 6 (Android Usage Access, Overlay, Local Notifications, Google Sign-In, Deep Links, Storage) |
| **TOTAL IMPORTANT DATA ENTITIES** | 30+ |
| **TOTAL MAJOR CROSS-MODULE RELATIONSHIPS** | 15+ |
| **TOTAL INTELLIGENCE ENGINES** | 24 |
| **TOTAL CONTROLLERS** | 30+ |
| **TOTAL CORE SERVICES** | 16+ |

### MOST DENSE SCREENS (objectively large numbers of controls/features)

1. **HomeScreen** (1760 lines) — 11 visible sections, 8+ action types, 13+ controller dependencies
2. **StudyScreen** (1622 lines) — Multiple recommendation sections, active focus tracking, study/study actions
3. **PlanningScreen** (1475 lines) — Planning blocks, day budget, rebalance/recover, calendar integration
4. **FocusCenterScreen** (1402 lines) — Focus modes, missions, history, insights, guard settings, presets
5. **MoreScreen** (724 lines) — Profile hero, 2+ section groups with 15+ navigation items
6. **SettingsScreen** (632 lines) — Theme modes, cosmetic themes, focus duration, autopilot, notifications
7. **UniversalActionExecutor** (1514 lines) — Entity actions for 10 entity types, 3+ modal sheets

### MULTIPLE ENTRY-POINT FUNCTIONS

- **Focus** — 11+ entry points (HomeScreen, FocusCenterScreen, StudyScreen, SubjectDetailScreen, TaskDetailScreen, PlanningScreen, NotesScreen, ExamDetailScreen, Assistant, UniversalActionLauncherSheet, GlobalAddSheet)
- **Tasks** — 5+ entry points
- **Calendar** — 5+ entry points
- **Practice** — 6+ entry points
- **Revision** — 6+ entry points
- **Goals** — 3+ entry points

### HIDDEN / EASY-TO-MISS FUNCTIONS

- FocusGuard overlay and blocked app detection (automatic, Android-only)
- Focus checkpoints (automatic, 15/30/45 min)
- Missed session recovery (from HomeScreen Today card)
- Day rebalancing (from HomeScreen Today card)
- 30-minute burst (from HomeScreen hero)
- Autopilot mode (SettingsScreen)
- Edit profile sheet (MoreScreen, not obvious)
- Conflict resolution dialog (CalendarScreen)
- Focus launch context preservation (automatic navigation feature)
- Idempotent focus→study bridge (automatic)
- Theme variant unlocking via XP (RewardsScreen)
- Notification reconciliation (automatic on app launch)
- Deep link OAuth handling (automatic)

### UI REDESIGN PRESERVATION CHECKLIST

All capabilities listed in Section 27 "Blueprint-Safe Functional Requirements" must be preserved. The key principle is that every functional action must remain reachable from the new UI, even if the visual navigation path changes.

### ARCHITECTURE / FUNCTIONAL DEPENDENCIES

The new UI must call rather than reimplement:
- **FocusController** — All focus session management, timer/stopwatch/FocusGuard
- **TaskController** — Task CRUD, completion
- **PlanningBlockController/PlanningEngine** — Schedule management, rebalance, recover
- **StudyController** — Study sessions, streak tracking
- **AcademicIntelligenceController/DailyOsCoordinator** — Daily briefing, recommendations
- **AutopilotEngine** — Autopilot planning, overload detection
- **StudentAssistantController/Engine/Parser** — AI assistant
- **UniversalActionExecutor** — Entity action routing
- **AppRouter** — All navigation
- **NotificationController/Service/Coordinator** — Notification evaluation and delivery
- **ProgressionController/XPEngine/StreakService** — XP, levels, streaks
- **RevisionController** — Spaced repetition
- **AcademicKnowledgeController/PracticeQuestionController/TopicPracticeController** — Knowledge and practice
- **ResourceController** — Resource management
- **StudentNoteController** — Notes
- **AcademicScheduleController** — Calendar events
- **ExamController** — Exams
- **SubjectController** — Subjects
- **GoalController** — Goals
- **RedemptionController** — Rewards
- **PremiumEntitlement/EntitlementManager/FeatureGate** — Entitlements
- **UserPreferencesController** — Settings
- **ThemeManager** — Themes
- **AuthService** — Authentication
- **StudentService** — Profile
- **SupabaseService** — Cloud sync
- **StorageService** — Local persistence
- **FocusGuardController/Service/PermissionService** — FocusGuard (Android)
- **GooglePlaySubscriptionProvider/SubscriptionProvider** — Premium billing

---

## 32. FINAL SUMMARY

**UI FUNCTIONAL INVENTORY COMPLETE — NO APPLICATION SOURCE CODE MODIFIED.**

This document provides a complete forensic audit of the Student OS application covering:
- 65 screens across 20+ feature modules
- 200+ functional actions
- 15+ modal sheets and dialogs
- 15+ form types
- 34 assistant intent types
- 31 assistant action types
- 10 entity types with 85+ universal actions
- 17 notification types
- 6 permissions
- 30+ data entities
- 24 intelligence engines
- 30+ controllers
- 16+ core services
- Complete navigation maps, cross-module relationships, duplicate entry points, hidden features, settings, gamification systems, premium/entitlement system, and platform-specific differences

Every functional capability is documented for the future manual UI redesign to preserve. The repository remains completely unchanged.
