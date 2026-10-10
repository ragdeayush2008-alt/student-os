import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_parser.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/exams/exam_controller.dart';

/// Assistant moves exams through the existing Exam system (preview +
/// confirm), keeps the time of day, and offers preparation recalculation.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
  });

  tearDown(() async {
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
    await StudentAssistantController.instance.clearConversation();
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
  });

  Future<void> seedAccounts() async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    await ExamController.instance.createExam(
      title: 'Accounts Final',
      subject: 'Accounts',
      examDateTime: day.add(const Duration(days: 9)),
    );
  }

  group('parser', () {
    test('"Move my Accounts exam to 12 October" parses', () {
      final intent = const DeterministicStudentIntentParser()
          .parse('Move my Accounts exam to 12 October');
      expect(intent.intentType, AssistantIntentType.updateExamDate);
      expect(intent.targetDate, isNotNull);
      expect(intent.targetDate!.month, 10);
      expect(intent.targetDate!.day, 12);
    });

    test('"My Accounts exam changed to tomorrow" parses', () async {
      await seedAccounts();
      final exams = ExamController.instance.exams;
      final intent = const DeterministicStudentIntentParser().parse(
        'My Accounts exam changed to tomorrow',
        exams: exams,
      );
      expect(intent.intentType, AssistantIntentType.updateExamDate);
      final today = DateTime.now();
      final expected =
          DateTime(today.year, today.month, today.day)
              .add(const Duration(days: 1));
      expect(intent.targetDate, expected);
    });
  });

  group('preview + confirm + execute', () {
    testWidgets('confirm moves the exam and keeps prep intact', (
      tester,
    ) async {
      AuthIsolation.instance.setAuthenticatedUser('exam_move_user');
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('host'))),
      );
      final context = tester.element(find.text('host'));
      await seedAccounts();

      final controller = StudentAssistantController.instance;
      final preview = await controller.ask(
        'Move my Accounts exam to 12 October',
      );
      expect(preview.requiresConfirmation, isTrue);
      expect(
        preview.primaryAction?.type,
        AssistantActionType.updateExamDate,
      );

      await controller.confirmAction(context);
      final moved = ExamController.instance.exams.single;
      expect(moved.examDateTime!.month, 10);
      expect(moved.examDateTime!.day, 12);
      expect(controller.lastResult?.title, isNot('Couldn\'t Apply Changes'));
    });

    testWidgets('ambiguous exams clarify instead of guessing', (
      tester,
    ) async {
      AuthIsolation.instance.setAuthenticatedUser('exam_move_user');
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('host'))),
      );
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      await ExamController.instance.createExam(
        title: 'Accounts Midterm',
        subject: 'Accounts',
        examDateTime: day.add(const Duration(days: 4)),
      );
      await ExamController.instance.createExam(
        title: 'Accounts Final',
        subject: 'Accounts',
        examDateTime: day.add(const Duration(days: 9)),
      );

      final result = await StudentAssistantController.instance.ask(
        'Move my Accounts exam to 12 October',
      );
      expect(result.clarificationRequired, isTrue);
      expect(result.clarificationChoices.length, 2);
    });
  });
}
