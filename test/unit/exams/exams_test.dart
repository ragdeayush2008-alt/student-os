import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/services/notification_service.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';

void main() {
  group('StudentExam model', () {
    test('fromJson/toJson roundtrip preserves all fields', () {
      final exam = StudentExam(
        id: 'exam_1',
        title: 'Math Final',
        subject: 'Mathematics',
        examDateTime: DateTime(2025, 6, 15, 10, 0),
        notes: 'Bring calculator',
        status: ExamStatus.upcoming,
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'Chapter 1', completed: true),
          SyllabusItem(id: 's2', title: 'Chapter 2', completed: false),
        ],
        reminder7Days: true,
        reminder3Days: true,
        reminder1Day: false,
      );
      final json = exam.toJson();
      final restored = StudentExam.fromJson(json);

      expect(restored.id, exam.id);
      expect(restored.title, exam.title);
      expect(restored.subject, exam.subject);
      expect(restored.examDateTime, exam.examDateTime);
      expect(restored.notes, exam.notes);
      expect(restored.syllabusItems.length, 2);
      expect(restored.syllabusItems[0].completed, true);
      expect(restored.reminder7Days, true);
      expect(restored.reminder1Day, false);
    });

    test('fromJson with missing fields uses defaults', () {
      final json = {'id': 'exam_2', 'title': 'Science Quiz'};
      final exam = StudentExam.fromJson(json);
      expect(exam.subject, '');
      expect(exam.examDateTime, isNull);
      expect(exam.status, ExamStatus.upcoming);
      expect(exam.syllabusItems, isEmpty);
      expect(exam.reminder7Days, false);
    });

    test('daysUntilExam calculates correctly', () {
      final futureExam = StudentExam(
        id: 'e1',
        title: 'Future',
        examDateTime: DateTime.now().add(const Duration(days: 5)),
      );
      expect(futureExam.daysUntilExam, 5);

      final todayExam = StudentExam(
        id: 'e2',
        title: 'Today',
        examDateTime: DateTime.now(),
      );
      expect(todayExam.daysUntilExam, 0);
    });

    test('countdown formats correctly', () {
      final tomorrow = StudentExam(
        id: 'e1',
        title: 'Tomorrow',
        examDateTime: DateTime.now().add(const Duration(days: 1)),
      );
      expect(tomorrow.countdown, 'Tomorrow');

      final weekExam = StudentExam(
        id: 'e2',
        title: 'Week',
        examDateTime: DateTime.now().add(const Duration(days: 7)),
      );
      expect(weekExam.countdown, '1 week');
    });

    test('syllabusProgress calculates correctly', () {
      final exam = StudentExam(
        id: 'e1',
        title: 'Test',
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'S1', completed: true),
          SyllabusItem(id: 's2', title: 'S2', completed: true),
          SyllabusItem(id: 's3', title: 'S3', completed: false),
          SyllabusItem(id: 's4', title: 'S4', completed: false),
        ],
      );
      expect(exam.syllabusProgress, 0.5);
      expect(exam.syllabusCompleted, 2);
      expect(exam.syllabusTotal, 4);
      expect(exam.allSyllabusComplete, false);
    });

    test('copyWith preserves existing fields', () {
      final exam = StudentExam(
        id: 'e1',
        title: 'Original',
        subject: 'Math',
        syllabusItems: [SyllabusItem(id: 's1', title: 'Topic')],
        reminder7Days: true,
      );
      final updated = exam.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.subject, 'Math');
      expect(updated.syllabusItems.length, 1);
      expect(updated.reminder7Days, true);
    });

    test('copyWith clearExamDateTime works', () {
      final exam = StudentExam(
        id: 'e1',
        title: 'Test',
        examDateTime: DateTime(2025, 6, 15),
      );
      final cleared = exam.copyWith(clearExamDateTime: true);
      expect(cleared.examDateTime, isNull);
    });
  });

  group('SyllabusItem', () {
    test('copyWith toggles completion', () {
      final item = SyllabusItem(id: 's1', title: 'Test');
      expect(item.completed, false);
      final completed = item.copyWith(
        completed: true,
        completedAt: DateTime.now(),
      );
      expect(completed.completed, true);
      expect(completed.completedAt, isNotNull);
    });

    test('fromJson/toJson roundtrip', () {
      final item = SyllabusItem(
        id: 's1',
        title: 'Chapter 1',
        completed: true,
        completedAt: DateTime(2025, 3, 1),
      );
      final json = item.toJson();
      final restored = SyllabusItem.fromJson(json);
      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.completed, true);
      expect(restored.completedAt, isNotNull);
    });
  });

  group('NotificationIds', () {
    test('deterministic IDs for same input', () {
      expect(
        NotificationIds.taskReminder('task_1'),
        NotificationIds.taskReminder('task_1'),
      );
    });

    test('different IDs for different inputs', () {
      expect(
        NotificationIds.taskReminder('task_1'),
        isNot(NotificationIds.taskReminder('task_2')),
      );
    });

    test('exam reminder IDs are deterministic per offset', () {
      final id1 = NotificationIds.examReminder('exam_1', 7);
      final id2 = NotificationIds.examReminder('exam_1', 7);
      expect(id1, id2);
      expect(
        NotificationIds.examReminder('exam_1', 7),
        isNot(NotificationIds.examReminder('exam_1', 3)),
      );
    });

    test('all IDs fit in 31 bits', () {
      final ids = [
        NotificationIds.taskReminder('any_task_id'),
        NotificationIds.studyReminder(),
        NotificationIds.planningReminder(),
        NotificationIds.examReminder('exam_123', 7),
      ];
      for (final id in ids) {
        expect(id, greaterThan(0));
        expect(id, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });
  });

  group('NotificationPayload', () {
    test('task payload encodes and decodes', () {
      const payload = NotificationPayload(type: 'task', entityId: 't1');
      final encoded = payload.encode();
      expect(encoded, 'task:t1');
      final decoded = NotificationPayload.decode(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.isTask, true);
      expect(decoded.entityId, 't1');
    });

    test('exam payload encodes and decodes', () {
      const payload = NotificationPayload(type: 'exam', entityId: 'e9');
      final decoded = NotificationPayload.decode(payload.encode());
      expect(decoded!.isExam, true);
      expect(decoded.entityId, 'e9');
    });

    test('study and planning payloads have no entity id', () {
      const study = NotificationPayload(type: 'study');
      final decodedStudy = NotificationPayload.decode(study.encode());
      expect(decodedStudy!.isStudyReminder, true);
      expect(decodedStudy.entityId, isNull);

      const planning = NotificationPayload(type: 'planning');
      final decodedPlanning = NotificationPayload.decode(planning.encode());
      expect(decodedPlanning!.isPlanningReminder, true);
      expect(decodedPlanning.entityId, isNull);
    });

    test('malformed payload safely decoded', () {
      expect(NotificationPayload.decode(null), isNull);
      expect(NotificationPayload.decode(''), isNull);
      // Colon with empty type wraps type only, does not crash.
      final decoded = NotificationPayload.decode(':id');
      expect(decoded, isNotNull);
    });

    test('decode preserves unknown types', () {
      final decoded = NotificationPayload.decode('custom_something');
      expect(decoded!.type, 'custom_something');
      expect(decoded.entityId, isNull);
    });
  });

  group('StudentTask examId serialization', () {
    test('task with examId serializes and deserializes', () {
      final task = StudentTask(
        id: 't1',
        title: 'Review chapter 3',
        examId: 'exam_1',
      );
      final json = task.toJson();
      expect(json['examId'], 'exam_1');
      final restored = StudentTask.fromJson(json);
      expect(restored.examId, 'exam_1');
    });

    test('old task JSON without examId defaults to null', () {
      final oldJson = {
        'id': 't2',
        'title': 'Old task',
        'description': '',
        'priority': 'medium',
        'status': 'active',
        'category': '',
        'createdAt': '2024-01-15T10:00:00.000',
        'sortOrder': 1,
      };
      final task = StudentTask.fromJson(oldJson);
      expect(task.examId, isNull);
      expect(task.title, 'Old task');
    });

    test('copyWith clearExamId removes link', () {
      final task = StudentTask(id: 't1', title: 'Task', examId: 'exam_1');
      final unlinked = task.copyWith(clearExamId: true);
      expect(unlinked.examId, isNull);
    });
  });

  group('ExamReadiness engine', () {
    test('combined progress averages both signals when both present', () {
      final combined = ExamReadiness.combinedProgress(
        syllabus: 0.8,
        linkedTasks: 0.6,
      );
      expect(combined, closeTo(0.7, 0.001));
    });

    test('combined progress uses syllabus alone when no linked tasks', () {
      final combined = ExamReadiness.combinedProgress(
        syllabus: 0.5,
        linkedTasks: 0,
      );
      expect(combined, closeTo(0.5, 0.001));
    });

    test('combined progress uses linked tasks alone when no syllabus', () {
      final combined = ExamReadiness.combinedProgress(
        syllabus: 0,
        linkedTasks: 0.4,
      );
      expect(combined, closeTo(0.4, 0.001));
    });

    test('no data yields zero', () {
      final combined = ExamReadiness.combinedProgress(
        syllabus: 0,
        linkedTasks: 0,
      );
      expect(combined, 0);
    });
  });

  group('Exam readiness labels', () {
    // Controllers are singletons; guard against cross-test contamination by
    // testing only the no-task, deterministic path and pure helpers.

    test('no syllabus and no linked tasks → No preparation', () {
      // TaskController is a singleton; these exam ids are not used by any
      // other test so no linked tasks exist for them.
      final exam = StudentExam(id: 'readiness_empty', title: 'Test');
      final result = ExamController.instance.readiness(exam);
      expect(result.label, 'No preparation');
    });

    test('fully completed syllabus → On track with reasons', () {
      final exam = StudentExam(
        id: 'readiness_full',
        title: 'Math',
        examDateTime: DateTime.now().add(const Duration(days: 10)),
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'A', completed: true),
          SyllabusItem(id: 's2', title: 'B', completed: true),
        ],
      );
      final result = ExamController.instance.readiness(exam);
      expect(result.label, 'On track');
      expect(result.reasons, isNotEmpty);
    });

    test('close exam + incomplete work → Needs attention', () {
      final exam = StudentExam(
        id: 'readiness_close',
        title: 'Quiz',
        examDateTime: DateTime.now().add(const Duration(days: 2)),
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'A', completed: false),
          SyllabusItem(id: 's2', title: 'B', completed: false),
        ],
      );
      final result = ExamController.instance.readiness(exam);
      expect(result.label, 'Needs attention');
    });
  });
}
