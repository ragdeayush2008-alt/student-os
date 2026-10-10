import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/calendar/academic_schedule_controller.dart';
import 'package:student_os/features/calendar/presentation/widgets/add_edit_event_sheet.dart';
import 'package:student_os/features/calendar/presentation/widgets/day_schedule_view.dart';
import 'package:student_os/features/calendar/presentation/widgets/home_today_agenda_card.dart';
import 'package:student_os/features/calendar/presentation/widgets/month_schedule_view.dart';
import 'package:student_os/features/calendar/presentation/widgets/week_schedule_view.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

Widget _buildTestApp(Widget child, {double width = 390, double height = 844}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: child,
      ),
    ),
  );
}

void main() {
  group('Day, Week, Month & Agenda Widgets Tests', () {
    final testDay = DateTime(2026, 9, 22);

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AuthIsolation.instance.setAuthenticatedUser('test_widgets_user');
      AcademicScheduleController.instance.clearData();
      ExamController.instance.clearData();
      TaskController.instance.clearData();
      PlanningBlockController.instance.clearData();
    });

    tearDown(() {
      AcademicScheduleController.instance.clearData();
      AuthIsolation.instance.clearSession();
    });

    testWidgets('1. DayScheduleView renders availability breakdown and empty state when clear', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        DayScheduleView(
          selectedDay: testDay,
          onDaySelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Committed'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('Free Time'), findsOneWidget);
      expect(find.text('Your schedule is clear'), findsOneWidget);
      expect(find.text('Add Commitment'), findsOneWidget);
    });

    testWidgets('2. DayScheduleView renders conflict alert and tapping opens dialog', (tester) async {
      // Fixed Class
      await AcademicScheduleController.instance.createEvent(
        title: 'Physics Class',
        startAt: DateTime(2026, 9, 22, 14, 0),
        endAt: DateTime(2026, 9, 22, 15, 0),
      );

      // Overlapping Study Block
      await PlanningBlockController.instance.scheduleBlock(
        null,
        DateTime(2026, 9, 22, 14, 0),
        DateTime(2026, 9, 22, 15, 0),
        customTitle: 'Study Chemistry',
      );

      await tester.pumpWidget(_buildTestApp(
        DayScheduleView(
          selectedDay: testDay,
          onDaySelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Schedule Conflict Detected'), findsOneWidget);

      // Tap on conflict banner to open dialog
      await tester.tap(find.textContaining('Schedule Conflict Detected'));
      await tester.pumpAndSettle();

      expect(find.text('Planned Study Overlaps Commitment'), findsOneWidget);
      expect(find.text('Reschedule Study'), findsOneWidget);
    });

    testWidgets('3. WeekScheduleView renders 7-day strip and summary bar', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WeekScheduleView(
          selectedDay: testDay,
          onDaySelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Committed'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('Free Time'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. MonthScheduleView renders month grid and selected day inspector', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MonthScheduleView(
          selectedDay: testDay,
          onDaySelected: (_) {},
          onSwitchToDayView: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('Day View'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. AddEditEventSheet validates empty title properly', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AddEditEventSheet(),
      ));
      await tester.pumpAndSettle();

      // Scroll to button and tap
      final btn = find.text('Add Commitment');
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter an event title'), findsOneWidget);
    });

    testWidgets('6. HomeTodayAgendaCard renders compact agenda signal on Home', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const HomeTodayAgendaCard(),
      ));
      await tester.pumpAndSettle();

      expect(find.text("Today's Schedule"), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
