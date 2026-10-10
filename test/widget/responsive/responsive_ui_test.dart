import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_shell.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/exams/exam_screen.dart';
import 'package:student_os/features/home/home_screen.dart';
import 'package:student_os/features/more/more_screen.dart';
import 'package:student_os/features/planning/planning_screen.dart';
import 'package:student_os/features/progress/progress_screen.dart';
import 'package:student_os/features/rewards/rewards_screen.dart';
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
import 'package:student_os/features/study/study_screen.dart';
import 'package:student_os/features/tasks/presentation/tasks_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapWithTheme(
    Widget child, {
    required double width,
    double height = 800,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: AppScope(
          controller: AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      ),
    );
  }

  const screenWidths = [320.0, 360.0, 390.0, 412.0];

  group('Responsive Layout Tests - No Overflow at 320/360/390/412dp', () {
    for (final width in screenWidths) {
      testWidgets('HomeScreen builds without overflow at ${width}dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithTheme(const HomeScreen(), width: width),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('PlanningScreen builds without overflow at ${width}dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithTheme(const PlanningScreen(), width: width),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PlanningScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('StudyScreen builds without overflow at ${width}dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithTheme(const StudyScreen(), width: width),
        );
        await tester.pumpAndSettle();

        expect(find.byType(StudyScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('FocusSessionScreen builds without overflow at ${width}dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithTheme(const FocusSessionScreen(), width: width),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FocusSessionScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('TasksScreen builds without overflow at ${width}dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithTheme(const TasksScreen(), width: width),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TasksScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('ExamScreen builds without overflow at ${width}dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithTheme(const ExamScreen(), width: width),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ExamScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('ProgressScreen builds without overflow at ${width}dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithTheme(const ProgressScreen(), width: width),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProgressScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('RewardsScreen builds without overflow at ${width}dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithTheme(const RewardsScreen(), width: width),
        );
        await tester.pumpAndSettle();

        expect(find.byType(RewardsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('MoreScreen builds without overflow at ${width}dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithTheme(const MoreScreen(), width: width),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MoreScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('AppShell builds without overflow at ${width}dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithTheme(const AppShell(), width: width));
        await tester.pumpAndSettle();

        expect(find.byType(AppShell), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
