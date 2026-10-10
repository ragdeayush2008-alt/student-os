import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/exams/widgets/exam_detail_screen.dart';

/// Exam delete requires confirmation and removes only after it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
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

  testWidgets('delete asks first, cancels safely, deletes on confirm', (
    tester,
  ) async {
    final exam = await ExamController.instance.createExam(
      title: 'Delete Me Midterm',
      subject: 'Physics',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: ExamDetailScreen(examId: exam.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Delete exam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete exam'));
    await tester.pumpAndSettle();

    // Confirmation dialog appears; exam still present.
    expect(find.text('Delete "${exam.title}"?'), findsNothing);
    expect(find.textContaining('This cannot be undone'), findsOneWidget);
    expect(
      ExamController.instance.exams.map((e) => e.id),
      contains(exam.id),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      ExamController.instance.exams.map((e) => e.id),
      contains(exam.id),
    );

    // Confirm deletes.
    await tester.ensureVisible(find.text('Delete exam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete exam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(
      ExamController.instance.exams.map((e) => e.id),
      isNot(contains(exam.id)),
    );
  });
}
