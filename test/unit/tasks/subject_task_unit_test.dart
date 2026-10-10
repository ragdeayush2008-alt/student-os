import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/task.dart';

void main() {
  group('StudentTask subjectId — serialization', () {
    test('toJson/fromJson roundtrip preserves subjectId', () {
      final task = StudentTask(id: 't1', title: 'Revise', subjectId: 'sub_1');
      final restored = StudentTask.fromJson(task.toJson());
      expect(restored.subjectId, 'sub_1');
    });

    test('task JSON without subjectId deserializes to null', () {
      final oldJson = {
        'id': 'old_1',
        'title': 'Old task',
        'description': '',
        'priority': 'medium',
        'status': 'active',
        'category': '',
        'createdAt': '2024-01-15T10:00:00.000',
        'sortOrder': 1,
      };
      final task = StudentTask.fromJson(oldJson);
      expect(task.subjectId, isNull);
      expect(task.title, 'Old task');
    });

    test('copyWith(subjectId) updates the link', () {
      final task = StudentTask(id: 't1', title: 'Task');
      final linked = task.copyWith(subjectId: 'sub_9');
      expect(linked.subjectId, 'sub_9');
      expect(task.subjectId, isNull);
    });

    test('clearSubjectId() removes the link', () {
      final task = StudentTask(id: 't1', title: 'Task', subjectId: 'sub_1');
      final cleared = task.clearSubjectId();
      expect(cleared.subjectId, isNull);
    });

    test('copyWith(clearSubjectId: true) removes the link', () {
      final task = StudentTask(id: 't1', title: 'Task', subjectId: 'sub_1');
      expect(task.copyWith(clearSubjectId: true).subjectId, isNull);
    });

    test('task can have both subjectId and examId simultaneously', () {
      final task = StudentTask(
        id: 't1',
        title: 'Revision',
        subjectId: 'sub_1',
        examId: 'exam_1',
      );
      expect(task.subjectId, 'sub_1');
      expect(task.examId, 'exam_1');
    });
  });
}
