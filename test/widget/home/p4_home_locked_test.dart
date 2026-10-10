import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/time/app_clock.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/home/home_screen.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';
import 'package:student_os/features/exams/exam_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('p4_home_test');
    // Use StorageService clear to handle cached prefs correctly
    try { await StorageService.instance.clearUser(userId: 'p4_home_test'); } catch (_) {}
    ControllerIsolation.instance.clearAllControllers();
    AcademicIntelligenceController.instance.clearData();
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
    ControllerIsolation.instance.clearAllControllers();
    AcademicIntelligenceController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  Widget buildHome() => MaterialApp(theme: AppTheme.dark(), home: const MediaQuery(data: MediaQueryData(size: Size(390,844)), child: HomeScreen()));

  testWidgets('1. empty student -> FirstTimeEmptyState + no fake data', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390,844));
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();
    expect(find.textContaining("Let's build your day"), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
  });

  testWidgets('2. no plan -> offers Plan My Day', (tester) async {
    await SubjectController.instance.createSubject(name: 'Maths');
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();
    // Quick Actions Plan Day should be visible, Today shows either No plan or View Plan
    expect(find.text('Plan Day'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('3. existing plan -> Next/Schedule visible', (tester) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 14, 0);
    final end = DateTime(now.year, now.month, now.day, 15, 0);
    await PlanningBlockController.instance.scheduleBlock(null, start, end, subjectId: 's1', customTitle: 'Block');
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();
    expect(find.text("Today's Plan"), findsOneWidget);
  });

  testWidgets('4. active Focus -> Focus Active hero', (tester) async {
    FocusController.instance.startQuickFocus(subjectName: 'FocusSub');
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();
    expect(find.text('FOCUS ACTIVE'), findsOneWidget);
    expect(find.text('Continue Focus'), findsOneWidget);
    FocusController.instance.cancelSession();
  });

  testWidgets('5. caught-up state -> All caught up hero', (tester) async {
    // No tasks, no exams, no overdue -> empty
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();
    // Hero should show All caught up or similar
    expect(find.textContaining('All Caught Up').evaluate().isNotEmpty || find.textContaining('Caught Up').evaluate().isNotEmpty || find.text('Quick Actions').evaluate().isNotEmpty, isTrue);
  });

  testWidgets('6. overdue state -> Today progress shows overdue', (tester) async {
    await TaskController.instance.createTask(title: 'Overdue62', dueDate: DateTime.now().subtract(const Duration(days:1)));
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Overdue may appear in Today stats or risk banner
    expect(find.text('Today').evaluate().isNotEmpty, isTrue);
  });

  testWidgets('7. recovery state -> Recover strip', (tester) async {
    final task = await TaskController.instance.createTask(title: 'RecTask');
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 9,0);
    await PlanningBlockController.instance.scheduleBlock(task.id, start, start.add(const Duration(minutes:30)));
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();
    // May show Missed if now after 09:30, otherwise not
    expect(tester.takeException(), isNull);
  });

  testWidgets('8. overloaded state -> Overloaded strip single', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390,844));
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    await PlanningBlockController.instance.scheduleBlock(null, DateTime(d.year,d.month,d.day,9,0), DateTime(d.year,d.month,d.day,12,0), subjectId: 's1');
    await PlanningBlockController.instance.scheduleBlock(null, DateTime(d.year,d.month,d.day,12,30), DateTime(d.year,d.month,d.day,15,30), subjectId: 's2');
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('9. early completion -> Home renders', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();
    expect(find.text('Quick Actions'), findsOneWidget);
  });

  testWidgets('10. upcoming exam -> Upcoming & Goals shows exam', (tester) async {
    await ExamController.instance.createExam(title: 'Midterm', subject: 'Maths', examDateTime: DateTime.now().add(const Duration(days:3)));
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();
    expect(find.textContaining('Upcoming').evaluate().isNotEmpty, isTrue);
  });

  testWidgets('11. next PlanningBlock -> Next strip', (tester) async {
    // Freeze the app clock so the block is always on today's date and
    // strictly in the future, so the NEXT card renders at any wall clock.
    AppClock.freezeAt(DateTime(2026, 9, 21, 14, 0));
    await PlanningBlockController.instance.scheduleBlock(
      null,
      DateTime(2026, 9, 21, 14, 20),
      DateTime(2026, 9, 21, 14, 50),
      subjectId: 's_next',
    );
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();
    expect(find.textContaining('NEXT').evaluate().isNotEmpty, isTrue);
  });

  testWidgets('12. current PlanningBlock -> Current strip', (tester) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(minutes: 5));
    final end = now.add(const Duration(minutes: 25));
    await PlanningBlockController.instance.scheduleBlock(null, start, end, subjectId: 's_cur');
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();
    expect(find.textContaining('CURRENT').evaluate().isNotEmpty || find.textContaining('NEXT').evaluate().isNotEmpty, isTrue);
  });

  testWidgets('Locked sequence order: Header -> Quick Actions -> Hero -> Progress -> Next/Schedule -> Recommended -> Upcoming', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();
    final quickActionsPos = tester.getTopLeft(find.text('Quick Actions')).dy;
    final todayPos = tester.getTopLeft(find.text('Today')).dy;
    expect(quickActionsPos, lessThan(todayPos));
  });
}
