import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/data/models/academic_calendar_event.dart';
import 'package:student_os/features/calendar/academic_schedule_controller.dart';
import 'package:student_os/features/calendar/presentation/calendar_screen.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

Widget _buildTestApp(Widget child, {double width = 390, double height = 844}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, height)),
      child: child,
    ),
  );
}

void main() {
  group('CalendarScreen Widget & Responsive Layout Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AuthIsolation.instance.setAuthenticatedUser('test_widget_user');
      AcademicScheduleController.instance.clearData();
      ExamController.instance.clearData();
      TaskController.instance.clearData();
      PlanningBlockController.instance.clearData();
    });

    tearDown(() {
      AcademicScheduleController.instance.clearData();
      AuthIsolation.instance.clearSession();
    });

    testWidgets('1. CalendarScreen renders with Week view by default', (tester) async {
      await tester.pumpWidget(_buildTestApp(const CalendarScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Academic Schedule'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.byTooltip('Add Commitment'), findsOneWidget);
    });

    testWidgets('2. Segmented button switches between Week, Day, and Month views', (tester) async {
      await tester.pumpWidget(_buildTestApp(const CalendarScreen()));
      await tester.pumpAndSettle();

      // Switch to Day view
      await tester.tap(find.text('Day'));
      await tester.pumpAndSettle();
      expect(find.text('Committed'), findsOneWidget);
      expect(find.text('Free Time'), findsOneWidget);

      // Switch to Month view
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsWidgets);
      expect(find.text('Day View'), findsOneWidget);

      // Switch back to Week view
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.text('Committed'), findsOneWidget);
    });

    testWidgets('3. Add commitment button opens AddEditEventSheet modal', (tester) async {
      await tester.pumpWidget(_buildTestApp(const CalendarScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add Commitment'));
      await tester.pumpAndSettle();

      expect(find.text('Add Academic Commitment'), findsOneWidget);
      expect(find.text('Title *'), findsOneWidget);
      expect(find.text('Class'), findsOneWidget);
      expect(find.text('Lecture'), findsOneWidget);
      expect(find.text('Lab'), findsOneWidget);
      expect(find.text('All Day'), findsOneWidget);
    });

    testWidgets('4. Responsive UI verification: 320dp (compact phone) builds with zero overflow', (tester) async {
      await tester.pumpWidget(_buildTestApp(const CalendarScreen(), width: 320, height: 600));
      await tester.pumpAndSettle();

      expect(find.text('Academic Schedule'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Responsive UI verification: 360dp, 412dp, 430dp builds cleanly with zero overflow', (tester) async {
      for (final width in [360.0, 412.0, 430.0]) {
        await tester.pumpWidget(_buildTestApp(const CalendarScreen(), width: width, height: 900));
        await tester.pumpAndSettle();

        expect(find.text('Academic Schedule'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('6. Day view displays event cards and action buttons', (tester) async {
      final date = DateTime(2026, 9, 22);
      await AcademicScheduleController.instance.createEvent(
        title: 'Economics Lecture',
        type: AcademicEventType.lecture,
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 30),
        location: 'Room 201',
      );

      await tester.pumpWidget(_buildTestApp(
        CalendarScreen(
          initialDate: date,
          initialMode: CalendarViewMode.day,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Economics Lecture'), findsOneWidget);
      expect(find.text('Room 201'), findsOneWidget);
      expect(find.text('Lecture'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
