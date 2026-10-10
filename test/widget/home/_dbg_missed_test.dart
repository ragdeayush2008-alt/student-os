import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/core/intelligence/daily_os_coordinator.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/time/app_clock.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/home/home_screen.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('dbg_missed2');
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    StudyController.instance.clearData();
    SubjectController.instance.clearData();
    FocusController.instance.clearData();
    PlanningBlockController.instance.clearData();
    AcademicIntelligenceController.instance.clearData();
    DailyOsCoordinator.instance.clearOnLogout();
    await TaskController.instance.load();
    await ExamController.instance.load();
    await StudyController.instance.load();
    await SubjectController.instance.load();
    await FocusController.instance.load();
    await PlanningBlockController.instance.load();
  });

  tearDown(() {
    AppClock.reset();
    FocusController.instance.clearData();
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    StudyController.instance.clearData();
    SubjectController.instance.clearData();
    PlanningBlockController.instance.clearData();
    AcademicIntelligenceController.instance.clearData();
    DailyOsCoordinator.instance.clearOnLogout();
    AuthIsolation.instance.clearSession();
  });

  testWidgets('DEBUG missed frozen dump', (tester) async {
    AppClock.freezeAt(DateTime(2026, 9, 21, 14, 0));
    final sub = await SubjectController.instance.createSubject(name: 'History');
    final now = AppClock.current;
    final midnight = DateTime(now.year, now.month, now.day);
    var end = now.subtract(const Duration(minutes: 5));
    var start = end.subtract(const Duration(minutes: 30));
    if (start.isBefore(midnight)) {
      start = midnight;
      end = midnight.add(const Duration(minutes: 2));
    }
    final block = await PlanningBlockController.instance.scheduleSubjectBlock(
      sub.id,
      start,
      end,
      customTitle: 'Morning Review',
    );
    debugPrint('DBG clock=${AppClock.current} start=${block.startAt} end=${block.endAt}');

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: AppScope(
          controller: AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: const Scaffold(body: HomeScreen()),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().join(' | ');
    debugPrint('DBG TEXTS: $texts');
  });
}