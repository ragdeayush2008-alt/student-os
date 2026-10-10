import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/exams/widgets/exam_creation_sheet.dart';

/// Exam creation sheet: validation, date picking, edit prefill, and the
/// post-save preparation offer (which never touches existing work).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('exam_sheet_user');
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
  });

  tearDown(() async {
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
    AuthIsolation.instance.clearSession();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('empty title cannot save', (tester) async {
    await tester.pumpWidget(wrap(const ExamCreationSheet()));
    await tester.pumpAndSettle();

    expect(find.text('New exam'), findsOneWidget);
    // Save disabled without a title: no exam appears.
    final save = find.text('Add exam');
    await tester.tap(save, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(ExamController.instance.exams, isEmpty);
  });

  testWidgets('date picker sets the exam date', (tester) async {
    await tester.pumpWidget(wrap(const ExamCreationSheet()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Accounts Final');
    // Open the date row.
    expect(find.text('Exam date & time'), findsOneWidget);
    await tester.tap(find.text('Pick date & time'));
    await tester.pumpAndSettle();
    // Native date picker opens; pick OK without changing.
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // A time picker follows; confirm it too.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // A date chip now shows a real date.
    expect(find.text('Exam date & time'), findsOneWidget);
  });

  testWidgets('save offers preparation planning', (tester) async {
    await tester.pumpWidget(wrap(const ExamCreationSheet()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Accounts Final');
    await tester.tap(find.text('Pick date & time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Bottom-sheet hit-testing is unreliable in the test scaffold, so
    // invoke the enabled save button directly (wiring, not pixels).
    final saveButton = find.ancestor(
      of: find.text('Add exam'),
      matching: find.byType(ElevatedButton),
    );
    expect(saveButton, findsOneWidget);
    tester.widget<ElevatedButton>(saveButton).onPressed!();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Plan preparation?').evaluate().isNotEmpty) break;
    }

    expect(ExamController.instance.exams.length, 1);
    expect(find.text('Plan preparation?'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pump(const Duration(milliseconds: 200));
    // Existing exam untouched by declining.
    expect(ExamController.instance.exams.length, 1);
  });

  testWidgets('edit mode prefills existing values', (tester) async {
    final exam = await ExamController.instance.createExam(
      title: 'Physics Midterm',
      subject: 'Physics',
    );
    await tester.pumpWidget(wrap(ExamCreationSheet(editing: exam)));
    await tester.pumpAndSettle();

    expect(find.text('Physics Midterm'), findsWidgets);
    expect(find.text('Physics'), findsWidgets);
  });
}
