import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/assistant/presentation/assistant_command_center_screen.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/focus/presentation/screens/focus_center_screen.dart';
import 'package:student_os/features/guides/guide_controller.dart';
import 'package:student_os/features/guides/guide_overlay.dart';
import 'package:student_os/features/guides/guide_progress_store.dart';
import 'package:student_os/features/guides/guide_targets.dart';
import 'package:student_os/features/guides/learn_screen.dart';
import 'package:student_os/features/home/home_screen.dart';
import 'package:student_os/features/more/more_screen.dart';
import 'package:student_os/features/planning/planning_screen.dart';
import 'package:student_os/features/sleep/presentation/sleep_schedule_screen.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';
import 'package:student_os/features/tools/presentation/tools_hub_screen.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';

/// Visual QA goldens: real screens, real pixels. Generate with
/// `flutter test test/widget/goldens --update-goldens`, then INSPECT the
/// PNGs in goldens/. They must read as one premium product.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('golden_user');
    SleepController.instance.clearData();
    StudentAssistantController.instance.clearData();
  });

  tearDown(() async {
    await StudentAssistantController.instance.clearConversation();
    StudentAssistantController.instance.clearData();
    SleepController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  Future<void> pumpScreen(WidgetTester tester, Widget screen,
      {double width = 390, double height = 844}) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routes: AppRouter.routes(),
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: AppScope(
            controller: AppShellController(),
            child: AuthScope(
              authService: AuthService.instance,
              child: Scaffold(body: screen),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('golden: home', (tester) async {
    await pumpScreen(tester, const HomeScreen());
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/app_home.png'),
    );
  });

  testWidgets('golden: planning', (tester) async {
    await pumpScreen(tester, const PlanningScreen());
    await expectLater(
      find.byType(PlanningScreen),
      matchesGoldenFile('goldens/app_planning.png'),
    );
  });

  testWidgets('golden: sprintx', (tester) async {
    await pumpScreen(tester, const FocusCenterScreen());
    await expectLater(
      find.byType(FocusCenterScreen),
      matchesGoldenFile('goldens/app_sprintx.png'),
    );
  });

  testWidgets('golden: tools', (tester) async {
    await pumpScreen(tester, const ToolsHubScreen());
    await expectLater(
      find.byType(ToolsHubScreen),
      matchesGoldenFile('goldens/app_tools.png'),
    );
  });

  testWidgets('golden: workspace', (tester) async {
    await pumpScreen(tester, const MoreScreen());
    await expectLater(
      find.byType(MoreScreen),
      matchesGoldenFile('goldens/app_workspace.png'),
    );
  });

  testWidgets('golden: assistant', (tester) async {
    await pumpScreen(tester, const AssistantCommandCenterScreen());
    await expectLater(
      find.byType(AssistantCommandCenterScreen),
      matchesGoldenFile('goldens/app_assistant.png'),
    );
  });

  testWidgets('golden: sleep', (tester) async {
    await pumpScreen(tester, const SleepScheduleScreen());
    await expectLater(
      find.byType(SleepScheduleScreen),
      matchesGoldenFile('goldens/app_sleep.png'),
    );
  });

  testWidgets('golden: learn', (tester) async {
    await pumpScreen(tester, const LearnScreen());
    await expectLater(
      find.byType(LearnScreen),
      matchesGoldenFile('goldens/app_learn.png'),
    );
  });

  testWidgets('golden: guide overlay with spotlight', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        navigatorKey: AppRouter.navigatorKey,
        routes: AppRouter.routes(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            body: Center(
              child: GuideTargetAnchor(
                id: 'home.hero',
                child: Container(
                  width: 200,
                  height: 120,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: const Text('Real control'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    GuideOverlayManager.ensureListening();
    await GuideController.instance.startGuide('home');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(GuideOverlayView),
      matchesGoldenFile('goldens/app_guide_overlay.png'),
    );
    await GuideController.instance.exitGuide();
    GuideProgressStore.instance.clearData();
  });
}
