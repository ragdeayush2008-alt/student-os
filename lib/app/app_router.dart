import 'package:flutter/material.dart';

import 'student_os_page_route.dart';
import '../core/services/notification_service.dart';
import '../core/theme/app_scope.dart';
import '../core/navigation/shell_destinations.dart';
import '../core/widgets/module_placeholder_screen.dart';
import '../data/mock/app_module.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/exams/widgets/exam_detail_screen.dart';
import '../features/exams/widgets/exam_creation_sheet.dart';
import '../features/exams/exam_controller.dart';
import '../features/auth/auth_service.dart';
import '../features/tasks/presentation/task_creation_sheet.dart';
import '../features/widgets/widget_deep_links.dart';
import '../features/home/home_screen.dart';
import '../features/more/more_screen.dart';
import '../data/models/topic.dart';
import '../features/planning/planning_screen.dart';
import '../features/planning/widgets/topic_plan_sheet.dart';
import '../features/progress/progress_screen.dart';
import '../features/resources/resource_detail_screen.dart';
import '../features/resources/resources_screen.dart';
import '../features/resources/search_screen.dart';
import '../features/rewards/rewards_screen.dart';
import '../features/premium/services/entitlement_service.dart';
import '../features/premium/presentation/membership_screen.dart';
import '../features/premium/presentation/premium_benefits_screen.dart';
import '../features/premium/presentation/premium_purchase_screen.dart';
import '../features/widgets/presentation/widgets_screen.dart';
import '../features/revision/revision_screen.dart';
import '../features/study/study_screen.dart';
import '../features/subjects/subject_controller.dart';
import '../features/subjects/subject_detail_screen.dart';
import '../features/subjects/subjects_screen.dart';
import '../features/tasks/presentation/task_detail_screen.dart';
import '../features/focus/controller/focus_controller.dart';
import '../features/focus/presentation/screens/focus_center_screen.dart';
import '../features/focus/presentation/screens/focus_session_screen.dart';
import '../features/focus/presentation/screens/focus_mission_setup_screen.dart';
import '../features/focus/presentation/screens/focus_history_screen.dart';
import '../features/focus/presentation/screens/focus_insights_screen.dart';
import '../features/focus/presentation/screens/focus_distraction_inbox_screen.dart';
import '../features/focus/presentation/widgets/focus_mode_selection_sheet.dart';
import '../features/streak/presentation/streak_screen.dart';
import '../features/progression/leaderboard_screen.dart';
import '../features/progression/achievements_screen.dart';
import '../features/notifications/presentation/notification_center_screen.dart';
import '../features/knowledge/presentation/practice_center_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/sleep/presentation/sleep_schedule_screen.dart';
import '../core/assistant/assistant_launch_context.dart';
import '../core/assistant/presentation/assistant_command_center_screen.dart';
import '../core/assistant/student_assistant_controller.dart';
import '../features/calendar/presentation/widgets/add_edit_event_sheet.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/planning/models/planning_block.dart';
import '../features/tasks/task_controller.dart';
import '../core/widgets/hamburger_menu.dart';
import '../features/knowledge/presentation/knowledge_center_screen.dart';
import '../features/notes/presentation/note_detail_screen.dart';
import '../features/notes/presentation/note_editor_screen.dart';
import '../features/tools/presentation/tools_hub_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';
import '../features/exams/exam_screen.dart';
import '../features/more/presentation/goals_screen.dart';
import '../features/more/presentation/account_data_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/calculator/presentation/calculator_screen.dart';
import '../features/checklist/presentation/checklist_screen.dart';
import '../features/guides/learn_screen.dart';
import '../features/habits/presentation/habits_screen.dart';
import '../features/notes/presentation/quick_notes_screen.dart';
import '../features/wellness/presentation/wellness_screen.dart';
import '../features/student_life/presentation/student_life_screen.dart';
import '../features/catalog/presentation/course_selection_screen.dart';

/// Application router: owns the named routes for the Student OS shell and
/// provides helpers to open feature placeholder screens.
///
/// Phase 3 uses a lightweight approach: the shell swaps between top-level
/// destinations and pushes placeholder routes for future modules. The router
/// is the single place to grow navigation in later phases without touching
/// every screen.
abstract final class AppRouter {
  /// Global navigator key so notification taps can navigate without a
  /// BuildContext. Attached to the root [Navigator] in the app shell.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Handles navigation triggered by a home-screen widget tap.
  ///
  /// Deep links look like `studentos://widget/tasks` (see WidgetCatalog).
  /// Authentication is never bypassed: logged-out taps park as
  /// [pendingWidgetLink] and open Home (login); the link is consumed after
  /// authentication via [consumePendingWidgetLink]. Premium-locked taps
  /// route through the existing paywall; exam ids are verified against the
  /// authenticated user's exams before opening.
  static String? pendingWidgetLink;

  static void handleWidgetDeepLink(String raw) {
    final link = WidgetDeepLinks.parse(raw);
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    if (!link.isKnown) {
      openHome(navigator.context);
      return;
    }
    if (!AuthService.instance.isAuthenticated) {
      pendingWidgetLink = raw;
      openHome(navigator.context);
      return;
    }
    _openWidgetLink(navigator.context, link);
  }

  /// Opens a parked widget link after login. No-op when there is none.
  static void consumePendingWidgetLink() {
    final raw = pendingWidgetLink;
    if (raw == null) return;
    pendingWidgetLink = null;
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    if (!AuthService.instance.isAuthenticated) return;
    final link = WidgetDeepLinks.parse(raw);
    if (!link.isKnown) return;
    _openWidgetLink(navigator.context, link);
  }

  static void _openWidgetLink(BuildContext context, WidgetDeepLink link) {
    switch (link.target) {
      case WidgetDeepLinkTarget.home:
        openHome(context);
      case WidgetDeepLinkTarget.assistant:
        openAssistantCommandCenter(context);
      case WidgetDeepLinkTarget.tasks:
        openTasks(context);
      case WidgetDeepLinkTarget.planning:
        openPlan(context);
      case WidgetDeepLinkTarget.focus:
        openFocusCenter(context);
      case WidgetDeepLinkTarget.exam:
        if (link.id != null) {
          final exists = ExamController.instance.exams.any(
            (e) => e.id == link.id,
          );
          if (exists) {
            openExamDetail(context, link.id!);
            return;
          }
        }
        openExams(context);
      case WidgetDeepLinkTarget.sleep:
        openSleepSchedule(context);
      case WidgetDeepLinkTarget.progress:
        openProgress(context);
      case WidgetDeepLinkTarget.addTask:
        openAddTask(context);
      case WidgetDeepLinkTarget.addExam:
        openAddExam(context);
      case WidgetDeepLinkTarget.customFocus:
        openFocusModeSelection(
          context,
          suggestedDuration: Duration(minutes: link.minutes ?? 25),
        );
      case WidgetDeepLinkTarget.premium:
        openPremiumPage(context, sourceFeatureId: link.feature);
      case WidgetDeepLinkTarget.unknown:
        openHome(context);
    }
  }

  /// Handles navigation triggered by a notification tap.
  ///
  /// Uses the global navigator key so it works in foreground, background, and
  /// terminated launch states. Renders no-op if the navigator isn't ready.
  static void handleNotificationPayload(NotificationPayload payload) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (payload.isTask && payload.entityId != null) {
      Navigator.of(navigator.context).push(
        MaterialPageRoute<void>(
          builder: (_) => TaskDetailScreen(taskId: payload.entityId!),
        ),
      );
    } else if (payload.isExam && payload.entityId != null) {
      Navigator.of(navigator.context).push(
        MaterialPageRoute<void>(
          builder: (_) => ExamDetailScreen(examId: payload.entityId!),
        ),
      );
    } else if (payload.isStudyReminder) {
      openStudy(navigator.context);
    } else if (payload.isPlanningReminder) {
      openPlan(navigator.context);
    } else if (payload.isStudentLife) {
      openStudentLife(navigator.context);
    } else if (payload.isSleepSchedule) {
      openSleepSchedule(navigator.context);
    } else if (payload.isBriefing || payload.isReview) {
      openAssistantCommandCenter(navigator.context);
    } else if (payload.isExam) {
      Navigator.of(navigator.context).pushNamed(examsRoute);
    } else if (payload.isRewardUnlocked || payload.isRewardAvailable) {
      openRewards(navigator.context);
    }
  }

  static const homeRoute = '/home';
  static const planRoute = '/plan';
  static const studyRoute = '/study';
  static const focusCenterRoute = '/focus-center';
  static const focusMissionRoute = '/focus-mission';
  static const focusSessionRoute = '/focus-session';
  static const focusHistoryRoute = '/focus-history';
  static const focusInsightsRoute = '/focus-insights';
  static const focusInboxRoute = '/focus-inbox';
  static const toolsRoute = '/tools';
  static const toolsHubRoute = '/tools-hub';
  static const workspaceRoute = '/workspace';
  static const progressRoute = '/progress';
  static const moreRoute = '/more';
  static const profileRoute = '/profile';
  static const settingsRoute = '/settings';
  static const tasksRoute = '/tasks';
  static const goalsRoute = '/goals';
  static const accountDataRoute = '/account-data';
  static const examsRoute = '/exams';
  static const resourcesRoute = '/resources';
  static const revisionRoute = '/revision';
  static const rewardsRoute = '/rewards';
  static const premiumRoute = '/premium';
  static const premiumBenefitsRoute = '/premium-benefits';
  static const membershipRoute = '/membership';
  static const widgetsRoute = '/widgets';
  static const subjectDetailRoute = '/subject-detail';
  static const subjectsRoute = '/subjects';
  static const analyticsRoute = '/analytics';
  static const leaderboardRoute = '/leaderboard';
  static const achievementsRoute = '/achievements';
  static const notificationsRoute = '/notifications';
  static const practiceCenterRoute = '/practice-center';
  static const calendarRoute = '/calendar';
  static const knowledgeRoute = '/knowledge';
  static const knowledgeCenterRoute = '/knowledge-center';
  static const noteEditorRoute = '/note-editor';
  static const quickNotesRoute = '/quick-notes';
  static const calculatorRoute = '/calculator';
  static const wellnessRoute = '/wellness';
  static const studentLifeRoute = '/student-life';
  static const sleepRoute = '/sleep';
  static const assistantRoute = '/assistant';
  static const checklistRoute = '/checklist';
  static const habitsRoute = '/habits';
  static const distractionBoxRoute = '/distraction-box';
  static const courseSelectionRoute = '/course-selection';
  static const learnRoute = '/learn';

  // Auth routes (handled by the auth experience navigator in AuthGate)
  static const authSignInRoute = '/sign-in';
  static const authSignUpRoute = '/sign-up';
  static const authForgotPasswordRoute = '/forgot-password';
  static const authUpdatePasswordRoute = '/update-password';
  static const authVerificationPendingRoute = '/verification-pending';

  /// Named routes reachable from the shell / placeholder helper.
  static Map<String, WidgetBuilder> routes() => {
    homeRoute: (_) => const HomeScreen(),
    planRoute: (_) => const PlanningScreen(),
    studyRoute: (_) => const StudyScreen(),
    focusCenterRoute: (_) => const FocusCenterScreen(),
    focusMissionRoute: (_) => const FocusMissionSetupScreen(),
    focusSessionRoute: (_) => const FocusSessionScreen(),
    focusHistoryRoute: (_) => const FocusHistoryScreen(),
    focusInsightsRoute: (_) => const FocusInsightsScreen(),
    focusInboxRoute: (_) => const FocusDistractionInboxScreen(),
    toolsRoute: (_) => const ToolsHubScreen(),
    toolsHubRoute: (_) => const ToolsHubScreen(),
    workspaceRoute: (_) => const MoreScreen(),
    progressRoute: (_) => const ProgressScreen(),
    moreRoute: (_) => const MoreScreen(),
    resourcesRoute: (_) => const ResourcesScreen(),
    revisionRoute: (_) => const RevisionScreen(),
    analyticsRoute: (_) => const AnalyticsScreen(),
    leaderboardRoute: (_) => const LeaderboardScreen(),
    achievementsRoute: (_) => const AchievementsScreen(),
    notificationsRoute: (_) => const NotificationCenterScreen(),
    practiceCenterRoute: (_) => const PracticeCenterScreen(),
    calendarRoute: (_) => const CalendarScreen(),
    knowledgeRoute: (_) => const KnowledgeCenterScreen(),
    knowledgeCenterRoute: (_) => const KnowledgeCenterScreen(),
    noteEditorRoute: (_) => const NoteEditorScreen(),
    quickNotesRoute: (_) => const QuickNotesScreen(),
    calculatorRoute: (_) => const CalculatorScreen(),
    wellnessRoute: (_) => const WellnessScreen(),
    studentLifeRoute: (_) => const StudentLifeScreen(),
    sleepRoute: (_) => const SleepScheduleScreen(),
    assistantRoute: (_) => const AssistantCommandCenterScreen(),
    checklistRoute: (_) => const ChecklistScreen(),
    habitsRoute: (_) => const HabitsScreen(),
    distractionBoxRoute: (_) => const FocusDistractionInboxScreen(),
    tasksRoute: (_) => const TasksScreen(),
    learnRoute: (_) => const LearnScreen(),
    examsRoute: (_) => const ExamScreen(),
    goalsRoute: (_) => const GoalsScreen(),
    accountDataRoute: (_) => const AccountDataScreen(),
    settingsRoute: (_) => const SettingsScreen(),
    profileRoute: (_) => const ProfileScreen(),
    rewardsRoute: (_) => const RewardsScreen(),
    premiumRoute: (_) => const PremiumPurchaseScreen(),
    premiumBenefitsRoute: (_) => const PremiumBenefitsScreen(),
    membershipRoute: (_) => const MembershipScreen(),
    widgetsRoute: (_) => const WidgetsScreen(),
    subjectsRoute: (_) => const SubjectsScreen(),
    courseSelectionRoute: (_) => const CourseSelectionScreen(),
  };

  // ---- Navigation helpers used from within screens ----

  /// Opens a polished, generic "coming soon" module placeholder.
  static void showComingSoon(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModulePlaceholderScreen(
          title: title,
          icon: Icons.auto_awesome_outlined,
          description:
              '$title will be available in a future phase of '
              'Student OS. This is a visual foundation only.',
          capabilities: const [
            'Premium, consistent module experience',
            'Reusable components & states',
            'Connected to the Student OS navigation shell',
          ],
        ),
      ),
    );
  }

  /// Pushes a dedicated module placeholder screen for a known [AppModule].
  static void openModule(BuildContext context, AppModule module) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModulePlaceholderScreen(
          title: module.title,
          icon: module.icon,
          description: module.subtitle,
          capabilities: const [
            'Organized, intuitive module experience',
            'Reusable premium components & states',
            'Deep integration with the Student OS shell',
          ],
        ),
      ),
    );
  }

  static void openProfile(BuildContext context) {
    Navigator.of(context).push(StudentOSPageRoute(builder: (_) => const ProfileScreen()));
  }

  /// Opens the Course / Exam selection and goal management screen.
  static void openCourseSelection(BuildContext context, {String? categoryId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CourseSelectionScreen(initialCategoryId: categoryId),
      ),
    );
  }

  /// Returns to the Home tab of the shell (CODE 5 drawer IA).
  static void openHome(BuildContext context) => _switchTab(context, homeRoute);

  /// Opens the education profile / course catalog setup screen in edit mode.
  static void openEducationSetup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OnboardingScreen(isEditMode: true),
      ),
    );
  }

  static void openSettings(BuildContext context) {
    Navigator.of(context).push(StudentOSPageRoute(builder: (_) => const SettingsScreen()));
  }

  /// Switches the shell to the Plan tab.
  static void openPlan(BuildContext context) => _switchTab(context, planRoute);

  /// Opens the shared Topic → Plan scheduling sheet for [topic].
  ///
  /// Used by the Assistant so topic scheduling always flows through
  /// `PlanningBlockController`, never a second schedule.
  static Future<String?> openTopicPlan(BuildContext context, Topic topic) {
    return TopicPlanSheet.show(context, topic: topic);
  }

  /// Switches the shell to the Study tab (Plan & Study).
  static void openStudy(BuildContext context) =>
      _switchTab(context, planRoute);

  /// Switches the shell to the Focus tab.
  static void openFocusTab(BuildContext context) =>
      _switchTab(context, focusCenterRoute);

  /// Switches the shell to the Tools tab.
  static void openTools(BuildContext context) =>
      _switchTab(context, toolsRoute);

  /// Switches the shell to the Workspace tab.
  static void openWorkspace(BuildContext context) =>
      _switchTab(context, moreRoute);

  /// Switches the shell to the More tab.
  static void openMore(BuildContext context) =>
      _switchTab(context, moreRoute);

  static int _indexForRoute(String route) {
    if (route == studyRoute) return 1; // Map legacy study to Plan & Study tab
    if (route == '/workspace') return 4;
    if (route == toolsHubRoute) return 3;
    if (route == '/focus') return 2;
    return ShellDestinations.all.indexWhere((d) => d.route == route);
  }

  static void _switchTab(BuildContext context, String route) {
    final index = _indexForRoute(route);
    if (index >= 0) {
      AppScope.of(context).setSelectedIndex(index);
    }
  }

  static void openProgress(BuildContext context) {
    Navigator.of(context).pushNamed(progressRoute);
  }

  static void openLeaderboard(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LeaderboardScreen()));
  }

  static void openAchievements(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()));
  }

  static void openCalendar(
    BuildContext context, {
    DateTime? initialDate,
    CalendarViewMode? initialMode,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CalendarScreen(
          initialDate: initialDate,
          initialMode: initialMode ?? CalendarViewMode.week,
        ),
      ),
    );
  }

  static void openAddCalendarEvent(
    BuildContext context, {
    DateTime? initialDate,
    TimeOfDay? initialStartTime,
  }) {    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditEventSheet(
        initialDate: initialDate,
        initialStartTime: initialStartTime,
      ),
    );
  }

  static void openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationCenterScreen(),
      ),
    );
  }

  static void openAnalytics(BuildContext context) {
    // Advanced Analytics is Pro; basic Progress stays free elsewhere.
    if (!EntitlementService.instance
        .hasFeatureAccess('premium.analytics.advanced')) {
      openPremiumPage(context, sourceFeatureId: 'premium.analytics.advanced');
      return;
    }
    Navigator.of(context).pushNamed(analyticsRoute);
  }

  static void openTasks(BuildContext context) {
    Navigator.of(context).push(StudentOSPageRoute(builder: (_) => const TasksScreen()));
  }

  static void openTaskDetail(BuildContext context, String taskId) {
    Navigator.of(context).push(
      StudentOSPageRoute(builder: (_) => TaskDetailScreen(taskId: taskId)),
    );
  }

  static void openGoals(BuildContext context) {
    Navigator.of(context).push(StudentOSPageRoute(builder: (_) => const GoalsScreen()));
  }

  static void openAccountData(BuildContext context) {
    Navigator.of(context).push(StudentOSPageRoute(builder: (_) => const AccountDataScreen()));
  }

  static void openExams(BuildContext context) {
    Navigator.of(context).pushNamed(examsRoute);
  }
  static void openExamDetail(BuildContext context, String examId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ExamDetailScreen(examId: examId)),
    );
  }

  /// Opens the Add Exam sheet directly (used by Home empty state).
  static void openAddExam(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExamCreationSheet(),
    );
  }

  /// Opens the canonical Add Task sheet (used by widget quick entry).
  static void openAddTask(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TaskCreationSheet(),
    );
  }

  static void openQuickNotes(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const QuickNotesScreen()),
    );
  }

  static void openCalculator(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CalculatorScreen()),
    );
  }

  static void openWellness(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WellnessScreen()),
    );
  }

  static void openStudentLife(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const StudentLifeScreen()),
    );
  }

  /// Opens the P1 Sleep schedule screen (planned bedtime/wake window).
  static void openSleepSchedule(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SleepScheduleScreen(),
      ),
    );
  }

  /// Opens the Assistant Command Center as a full screen.
  ///
  /// Canonical Assistant entry: every caller lands on the same screen/state;
  /// only [launchContext] (origin feature) varies for contextual suggestions.
  static void openAssistantCommandCenter(
    BuildContext context, {
    AssistantLaunchContext launchContext = AssistantLaunchContext.global,
    String? initialQuery,
  }) {
    StudentAssistantController.instance.setLaunchContext(launchContext);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AssistantCommandCenterScreen(initialQuery: initialQuery),
      ),
    );
  }

  static void openChecklist(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ChecklistScreen()),
    );
  }

  static void openHabits(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HabitsScreen()),
    );
  }

  static void openDistractionBox(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FocusDistractionInboxScreen(),
      ),
    );
  }

  static void openResources(BuildContext context) {
    Navigator.of(context).pushNamed(resourcesRoute);
  }

  static void openRevision(BuildContext context) {
    Navigator.of(context).pushNamed(revisionRoute);
  }

  static void openPracticeCenter(BuildContext context) {
    Navigator.of(context).pushNamed(practiceCenterRoute);
  }

  static void openKnowledgeCenter(
    BuildContext context, {
    String? initialSubjectId,
    String? initialTag,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KnowledgeCenterScreen(
          initialSubjectId: initialSubjectId,
          initialTag: initialTag,
        ),
      ),
    );
  }

  static void openNoteDetail(BuildContext context, String noteId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteDetailScreen(noteId: noteId),
      ),
    );
  }

  static void openNoteEditor(
    BuildContext context, {
    String? noteId,
    String? subjectId,
    String? chapterId,
    String? topicId,
    String? resourceId,
    String? initialTitle,
    String? initialContent,
    List<String>? initialTags,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditorScreen(
          noteId: noteId,
          initialSubjectId: subjectId,
          initialChapterId: chapterId,
          initialTopicId: topicId,
          initialResourceId: resourceId,
          initialTitle: initialTitle,
          initialContent: initialContent,
          initialTags: initialTags,
        ),
      ),
    );
  }

  static void openResourceDetail(BuildContext context, String resourceId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResourceDetailScreen(resourceId: resourceId),
      ),
    );
  }

  static void openResourceSearch(BuildContext context, {String? initialTag}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResourceSearchScreen(initialTag: initialTag),
      ),
    );
  }

  static void openSubjectList(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SubjectsScreen()));
  }

  static void openSubjectDetail(BuildContext context, String subjectId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubjectDetailScreen(subjectId: subjectId),
      ),
    );
  }

  static void openSubjectResources(BuildContext context, String subjectId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResourcesScreen(initialSubjectId: subjectId),
      ),
    );
  }

  static void openRewards(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RewardsScreen()));
  }

  /// Opens the permanent Learn Student OS center (interactive guides).
  static void openLearnCenter(BuildContext context) {
    Navigator.of(context).pushNamed(learnRoute);
  }

  /// Central Premium entry: every paywall redirect lands here with the
  /// source feature for a contextual header. Uses the existing navigator.
  static void openPremiumPage(BuildContext context, {String? sourceFeatureId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PremiumPurchaseScreen(
          sourceFeatureId: sourceFeatureId,
        ),
      ),
    );
  }

  static void openPremiumBenefits(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PremiumBenefitsScreen(),
      ),
    );
  }

  static void openMembership(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MembershipScreen()),
    );
  }

  /// Opens the in-app home-screen widget catalog.
  static void openWidgets(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WidgetsScreen()),
    );
  }

  /// Opens the hamburger command menu.
  static void openHamburger(BuildContext context) {
    openHamburgerMenu(context);
  }

  /// Opens the streak detail screen.
  static void openStreak(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const StreakScreen()));
  }

  /// Opens the canonical Student OS Assistant experience.
  ///
  /// ONE surface for every entry point (Home, Plan & Study, Tools Hub,
  /// Workspace, Tasks, Exams, SprintX, Sleep, …): the Assistant Command
  /// Center. Only [launchContext] varies, tuning the contextual subtitle
  /// and catalog suggestions. An optional [initialQuery] is asked
  /// automatically on open.
  static void openAssistant(
    BuildContext context, {
    String? initialQuery,
    AssistantLaunchContext launchContext = AssistantLaunchContext.global,
  }) {
    openAssistantCommandCenter(
      context,
      launchContext: launchContext,
      initialQuery: initialQuery,
    );
  }

  /// Opens the context-aware Focus Mode Selection sheet for Subject, Topic, Task, or Exam.
  /// If a session is already active, routes safely to the active session.
  /// Context (subject/topic/chapter/task/exam/planningBlock) is preserved.
  static void openFocusModeSelection(
    BuildContext context, {
    String? subjectId,
    String? subjectName,
    String? chapterId,
    String? topicId,
    String? topicName,
    String? taskId,
    String? taskTitle,
    String? examId,
    String? examTitle,
    String? planningBlockId,
    String? focusTitle,
    Duration suggestedDuration = const Duration(minutes: 25),
  }) {
    final fc = FocusController.instance;
    if (fc.hasActiveSession) {
      openActiveFocusSession(context);
      return;
    }

    FocusModeSelectionSheet.show(
      context,
      subjectId: subjectId,
      subjectName: subjectName,
      chapterId: chapterId,
      topicId: topicId,
      topicName: topicName,
      taskId: taskId,
      taskTitle: taskTitle,
      examId: examId,
      examTitle: examTitle,
      focusTitle: focusTitle,
      suggestedDuration: suggestedDuration,
    );
  }

  /// Opens the Focus Center home screen.
  static void openFocusCenter(
    BuildContext context, {
    String? subjectName,
    String? subjectId,
    String? taskId,
    String? examId,
    String? focusTitle,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FocusCenterScreen(
          taskId: taskId,
          focusTitle: focusTitle,
          subjectName: subjectName,
          subjectId: subjectId,
          examId: examId,
        ),
      ),
    );
  }

  /// Opens the Focus Mission setup screen.
  static void openFocusMission(BuildContext context) {
    Navigator.of(context).pushNamed(focusMissionRoute);
  }

  /// Opens the focus session screen (for active sessions).
  static void openActiveFocusSession(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: focusSessionRoute),
        builder: (_) => const FocusSessionScreen(),
      ),
    );
  }

  /// Opens the Focus History screen.
  static void openFocusHistory(BuildContext context) {
    Navigator.of(context).pushNamed(focusHistoryRoute);
  }

  /// Opens the Focus Insights screen.
  static void openFocusInsights(BuildContext context) {
    Navigator.of(context).pushNamed(focusInsightsRoute);
  }

  /// Opens the Distraction Inbox screen.
  static void openFocusInbox(BuildContext context) {
    Navigator.of(context).pushNamed(focusInboxRoute);
  }

  /// Opens the mode-selection flow for a planned session, carrying the block's
  /// assigned duration (remaining where applicable) and full context. The user
  /// picks Focus / Timer (uses the planned duration directly, never re-asks) or
  /// Stopwatch (open-ended). If a session is already active, routes to the
  /// active session without clobbering it.
  static void startPlanningBlockFocus(
    BuildContext context,
    PlanningBlock block,
  ) {
    final fc = FocusController.instance;
    if (fc.hasActiveSession) {
      openActiveFocusSession(context);
      return;
    }

    final now = DateTime.now();
    final totalDuration = block.endAt.difference(block.startAt);
    Duration duration = totalDuration;
    if (now.isAfter(block.startAt) && now.isBefore(block.endAt)) {
      // Late start: use remaining planned duration
      duration = block.endAt.difference(now);
    } else if (now.isAfter(block.endAt)) {
      // Expired block: safe action - use full assigned duration
      duration = totalDuration;
    }
    if (duration.inMinutes < 1) {
      duration = const Duration(minutes: 1);
    }

    final subject = block.subjectId != null
        ? SubjectController.instance.subjectById(block.subjectId!)
        : null;
    final task = block.taskId != null
        ? TaskController.instance.tasks
            .where((t) => t.id == block.taskId)
            .firstOrNull
        : null;
    final title = block.customTitle ??
        task?.title ??
        subject?.displayName ??
        'Focus Session';

    FocusModeSelectionSheet.show(
      context,
      subjectId: block.subjectId ?? task?.subjectId,
      subjectName: subject?.displayName ?? block.customTitle,
      taskId: block.taskId,
      taskTitle: task?.title ?? block.customTitle,
      examId: task?.examId,
      topicId: block.topicId,
      chapterId: block.chapterId,
      planningBlockId: block.id,
      focusTitle: title,
      suggestedDuration: duration,
      fixedDuration: duration,
    );
  }

  /// Starts a contextual Focus session directly with an explicit duration and context.
  /// If a session is already active, routes to the active session.
  /// Preserves subject/topic/chapter/task/exam/planningBlock context.
  static void startContextualFocus(
    BuildContext context, {
    required Duration duration,
    String? subjectId,
    String? subjectName,
    String? taskId,
    String? examId,
    String? topicId,
    String? chapterId,
    String? planningBlockId,
    String? focusTitle,
  }) {
    final fc = FocusController.instance;
    if (fc.hasActiveSession) {
      openActiveFocusSession(context);
      return;
    }

    fc.startTimer(
      duration: duration > Duration.zero
          ? duration
          : const Duration(minutes: 25),
      subjectId: subjectId,
      subjectName: subjectName,
      taskId: taskId,
      examId: examId,
      topicId: topicId,
      chapterId: chapterId,
      planningBlockId: planningBlockId,
      objective: focusTitle ??
          (subjectName != null && subjectName.isNotEmpty
              ? subjectName
              : 'Focus Session'),
    );

    openActiveFocusSession(context);
  }

  /// Opens the focus-session experience with context preservation.
  static void openFocusSessionLegacy(
    BuildContext context, {
    String? subject,
    String? taskId,
    String? focusTitle,
    String? subjectId,
    String? examId,
    String? topicId,
    String? chapterId,
  }) {
    final fc = FocusController.instance;
    if (!fc.hasActiveSession) {
      fc.startTimer(
        duration: const Duration(minutes: 25),
        subjectName: subject,
        subjectId: subjectId,
        taskId: taskId,
        examId: examId,
        topicId: topicId,
        chapterId: chapterId,
        objective: focusTitle ?? (subject != null && subject.isNotEmpty ? subject : 'Focus Session'),
      );
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FocusSessionScreen(
          taskId: taskId,
          focusTitle: focusTitle,
          subjectName: subject,
          subjectId: subjectId,
          examId: examId,
        ),
      ),
    );
  }
}
