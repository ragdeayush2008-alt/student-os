import 'package:flutter/material.dart';

import '../core/constants/app_durations.dart';
import '../core/theme/app_scope.dart';
import '../core/theme/app_shell_controller.dart';
import '../core/theme/app_theme.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/auth/auth_gate.dart';
import '../features/auth/auth_scope.dart';
import '../features/auth/auth_service.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/auth/presentation/update_password_screen.dart';
import '../features/auth/presentation/verification_pending_screen.dart';
import '../features/exams/exam_screen.dart';
import '../features/focus/presentation/screens/focus_center_screen.dart';
import '../features/focus/presentation/screens/focus_distraction_inbox_screen.dart';
import '../features/focus/presentation/screens/focus_history_screen.dart';
import '../features/focus/presentation/screens/focus_insights_screen.dart';
import '../features/focus/presentation/screens/focus_mission_setup_screen.dart';
import '../features/focus/presentation/screens/focus_session_screen.dart';
import '../features/more/presentation/account_data_screen.dart';
import '../features/more/presentation/goals_screen.dart';
import '../features/notifications/presentation/notification_center_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/progression/leaderboard_screen.dart';
import '../features/progression/achievements_screen.dart';
import '../features/resources/resources_screen.dart';
import '../features/revision/revision_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';
import 'app_router.dart';
import 'app_shell.dart';

/// Root widget for Student OS.
///
/// Owns the theme, the shared [AppShellController] (theme + navigation state,
/// with local persistence), page transitions, and routing. The [AuthGate] is
/// the home widget: it decides whether to show the app shell directly (demo
/// mode or authenticated) or the authentication experience.
class StudentOsApp extends StatelessWidget {
  const StudentOsApp({super.key, required this.controller});

  final AppShellController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: AuthScope(
        authService: AuthService.instance,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return MaterialApp(
              title: 'Student OS',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.forVariant(
                Brightness.light,
                controller.activeThemeVariant,
              ),
              darkTheme: AppTheme.forVariant(
                Brightness.dark,
                controller.activeThemeVariant,
              ),
              themeMode: controller.effectiveThemeMode,
              themeAnimationDuration: AppDurations.themeTransition,
              themeAnimationCurve: AppCurves.standard,
              navigatorKey: AppRouter.navigatorKey,
              home: const AuthGate(),
              onGenerateRoute: (settings) => _route(settings),
            );
          },
        ),
      ),
    );
  }

  static Route<dynamic>? _route(RouteSettings settings) {
    switch (settings.name) {
      case AppRouter.profileRoute:
        return _page(settings, const ProfileScreen());
      case AppRouter.settingsRoute:
        return _page(settings, const SettingsScreen());
      case AppRouter.tasksRoute:
        return _page(settings, const TasksScreen());
      case AppRouter.goalsRoute:
        return _page(settings, const GoalsScreen());
      case AppRouter.leaderboardRoute:
        return _page(settings, const LeaderboardScreen());
      case AppRouter.achievementsRoute:
        return _page(settings, const AchievementsScreen());
      case AppRouter.accountDataRoute:
        return _page(settings, const AccountDataScreen());
      case AppRouter.examsRoute:
        return _page(settings, const ExamScreen());
      case AppRouter.focusSessionRoute:
        return _page(settings, const FocusSessionScreen());
      case AppRouter.focusCenterRoute:
        return _page(settings, const FocusCenterScreen());
      case AppRouter.focusMissionRoute:
        return _page(settings, const FocusMissionSetupScreen());
      case AppRouter.focusHistoryRoute:
        return _page(settings, const FocusHistoryScreen());
      case AppRouter.focusInsightsRoute:
        return _page(settings, const FocusInsightsScreen());
      case AppRouter.focusInboxRoute:
        return _page(settings, const FocusDistractionInboxScreen());
      case AppRouter.resourcesRoute:
        return _page(settings, const ResourcesScreen());
      case AppRouter.revisionRoute:
        return _page(settings, const RevisionScreen());
      case AppRouter.analyticsRoute:
        return _page(settings, const AnalyticsScreen());
      case AppRouter.notificationsRoute:
        return _page(settings, const NotificationCenterScreen());
      case AppRouter.authSignInRoute:
        return _page(settings, const SignInScreen());
      case AppRouter.authSignUpRoute:
        return _page(settings, const SignUpScreen());
      case AppRouter.authForgotPasswordRoute:
        return _page(settings, const ForgotPasswordScreen());
      case AppRouter.authUpdatePasswordRoute:
        return _page(settings, const UpdatePasswordScreen());
      case AppRouter.authVerificationPendingRoute:
        return _page(settings, const VerificationPendingScreen());
      default:
        return _page(settings, const AppShell());
    }
  }

  static MaterialPageRoute<dynamic> _page(
    RouteSettings settings,
    Widget child,
  ) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }
}
