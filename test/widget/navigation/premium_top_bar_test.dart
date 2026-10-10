import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/app/app_shell.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/core/intelligence/daily_os_coordinator.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/time/app_clock.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/notifications/presentation/notification_center_screen.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/profile/profile_screen.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('top_bar_user');
    try {
      await StorageService.instance.clearUser(userId: 'top_bar_user');
    } catch (_) {}
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    StudyController.instance.clearData();
    SubjectController.instance.clearData();
    FocusController.instance.clearData();
    PlanningBlockController.instance.clearData();
    ProgressionController.instance.clearData();
    AcademicIntelligenceController.instance.clearData();
    DailyOsCoordinator.instance.clearOnLogout();
    await TaskController.instance.load();
    await ExamController.instance.load();
    await StudyController.instance.load();
    await SubjectController.instance.load();
    await FocusController.instance.load();
    await PlanningBlockController.instance.load();
    await ProgressionController.instance.load();
  });

  tearDown(() {
    AppClock.reset();
    FocusController.instance.clearData();
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    StudyController.instance.clearData();
    SubjectController.instance.clearData();
    PlanningBlockController.instance.clearData();
    ProgressionController.instance.clearData();
    AcademicIntelligenceController.instance.clearData();
    DailyOsCoordinator.instance.clearOnLogout();
    AuthIsolation.instance.clearSession();
  });

  Widget wrapWithApp({double width = 390}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 844)),
        child: AppScope(
          controller: AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: const AppShell(),
          ),
        ),
      ),
    );
  }

  Finder labelFinder(String label) => find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == label,
      );

  /// The shell header's action Row — anchored via its unique bell semantics so
  /// scoped finders never match identical icons inside the Home content.
  Finder headerRow() => find
      .ancestor(
        of: labelFinder('Notifications'),
        matching: find.byType(Row),
      )
      .first;

  Finder inHeader(Finder inner) =>
      find.descendant(of: headerRow(), matching: inner);

  Finder headerBolt() => inHeader(find.byIcon(Icons.bolt_rounded));
  Finder headerBell() =>
      inHeader(find.byIcon(Icons.notifications_outlined));
  Finder headerProfile() =>
      inHeader(find.byIcon(Icons.person_outline_rounded));

  group('Premium Top Bar — TOP BAR POLISH 1.0', () {
    testWidgets('Home renders hamburger + Student OS + premium action group '
        '(XP · Bell · Profile) with subordinate Quick Add', (tester) async {
      await tester.pumpWidget(wrapWithApp());
      await tester.pumpAndSettle();

      expect(find.text('Student OS'), findsOneWidget);
      expect(headerBell(), findsOneWidget);
      expect(labelFinder('Notifications'), findsOneWidget);
      // Premium XP status chip (bolt identity) and rightmost Profile action.
      expect(headerBolt(), findsOneWidget);
      expect(labelFinder('Profile'), findsOneWidget);
      expect(headerProfile(), findsOneWidget);
      // Subordinate Quick Add remains functional in the greeting row.
      expect(labelFinder('Add item'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('XP chip shows the live ProgressionController value',
        (tester) async {
      await tester.pumpWidget(wrapWithApp());
      await tester.pumpAndSettle();

      expect(inHeader(find.text('0 XP')), findsOneWidget);

      await ProgressionController.instance.recordEvent(
        XpEvent(
          id: 'top_bar_xp_1',
          type: XpEventType.taskCompleted,
          amount: 3,
          timestamp: DateTime.now(),
          reason: 'Top bar polish test',
        ),
      );
      await tester.pumpAndSettle();

      expect(inHeader(find.text('3 XP')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('XP, Bell and Profile share one vertical center (aligned group)',
        (tester) async {
      await tester.pumpWidget(wrapWithApp());
      await tester.pumpAndSettle();

      final xpY = tester.getCenter(headerBolt()).dy;
      final bellY = tester.getCenter(headerBell()).dy;
      final profileY = tester.getCenter(headerProfile()).dy;

      expect((xpY - bellY).abs(), lessThan(2));
      expect((bellY - profileY).abs(), lessThan(2));
      expect((xpY - profileY).abs(), lessThan(2));
    });

    testWidgets('Non-Home destinations keep a single bell (no XP/Profile)',
        (tester) async {
      await tester.pumpWidget(wrapWithApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Plan & Study'));
      await tester.pumpAndSettle();

      expect(headerBolt(), findsNothing);
      expect(labelFinder('Profile'), findsNothing);
      expect(headerProfile(), findsNothing);
      expect(headerBell(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Bell opens the Notification Center (no new system)',
        (tester) async {
      await tester.pumpWidget(wrapWithApp());
      await tester.pumpAndSettle();

      await tester.tap(headerBell());
      await tester.pumpAndSettle();

      expect(find.byType(NotificationCenterScreen), findsOneWidget);
    });

    testWidgets('Profile opens the Profile screen', (tester) async {
      await tester.pumpWidget(wrapWithApp());
      await tester.pumpAndSettle();

      await tester.tap(headerProfile());
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('Subordinate Quick Add opens the global add sheet',
        (tester) async {
      await tester.pumpWidget(wrapWithApp());
      await tester.pumpAndSettle();

      await tester.tap(labelFinder('Add item'));
      await tester.pumpAndSettle();

      expect(find.text('Add to Student OS'), findsOneWidget);
    });

    testWidgets('Hamburger still opens the navigation menu', (tester) async {
      await tester.pumpWidget(wrapWithApp());
      await tester.pumpAndSettle();

      await tester.tap(labelFinder('Open navigation'));
      await tester.pumpAndSettle();

      expect(labelFinder('Close navigation'), findsWidgets);
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('No overflow; Student OS/XP/Profile stay visible at '
        '320/360/390/412/430dp', (tester) async {
      for (final width in [320.0, 360.0, 390.0, 412.0, 430.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(width: width));
        await tester.pumpAndSettle();

        expect(find.text('Student OS'), findsOneWidget,
            reason: 'title visible at $width');
        expect(headerBolt(), findsOneWidget,
            reason: 'XP visible at $width');
        expect(headerBell(), findsOneWidget,
            reason: 'Bell visible at $width');
        expect(labelFinder('Profile'), findsOneWidget,
            reason: 'Profile visible at $width');
        final exc = tester.takeException();
        if (exc != null) {
          fail('overflow at $width: $exc');
        }
      }
    });
  });
}