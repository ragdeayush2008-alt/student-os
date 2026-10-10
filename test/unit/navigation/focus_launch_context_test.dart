import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/navigation/focus_launch_context.dart';

void main() {
  group('FocusLaunchContext (CODE 5 context preservation)', () {
    test('empty context has no ids', () {
      const ctx = FocusLaunchContext();
      expect(ctx.hasSubject, isFalse);
      expect(ctx.hasTopic, isFalse);
      expect(ctx.hasTask, isFalse);
      expect(ctx.hasExam, isFalse);
      expect(ctx.hasPlanningBlock, isFalse);
    });

    test('Subject -> Topic -> Focus chain preserves all ids', () {
      const subject = FocusLaunchContext(subjectId: 'sub1', subjectName: 'Physics');
      final withTopic = subject.copyWith(
        topicId: 't1',
        topicName: 'Laws of Motion',
        chapterId: 'c1',
      );
      final forFocus = withTopic.copyWith(
        focusTitle: 'Study Partnership',
        duration: const Duration(minutes: 30),
      );

      expect(forFocus.subjectId, equals('sub1'));
      expect(forFocus.subjectName, equals('Physics'));
      expect(forFocus.topicId, equals('t1'));
      expect(forFocus.chapterId, equals('c1'));
      expect(forFocus.focusTitle, equals('Study Partnership'));
      expect(forFocus.duration, equals(const Duration(minutes: 30)));
    });

    test('Task -> Planning -> Focus preserves task + block ids', () {
      const task = FocusLaunchContext(taskId: 'task1', subjectId: 'sub2');
      final withBlock = task.copyWith(planningBlockId: 'pb1');
      expect(withBlock.taskId, equals('task1'));
      expect(withBlock.planningBlockId, equals('pb1'));
      expect(withBlock.hasPlanningBlock, isTrue);
    });

    test('Exam -> Revision -> Focus preserves exam + topic', () {
      const exam = FocusLaunchContext(examId: 'e1', examTitle: 'Boards');
      final merged = exam.merge(
        const FocusLaunchContext(
          subjectId: 'sub3',
          topicId: 't9',
          chapterId: 'c9',
        ),
      );
      expect(merged.examId, equals('e1'));
      expect(merged.subjectId, equals('sub3'));
      expect(merged.topicId, equals('t9'));
      expect(merged.chapterId, equals('c9'));
    });

    test('merge prefers incoming non-null values', () {
      const base = FocusLaunchContext(subjectId: 's1', taskId: 't1');
      const overlay = FocusLaunchContext(taskId: 't2', examId: 'e1');
      final merged = base.merge(overlay);
      expect(merged.subjectId, equals('s1'));
      expect(merged.taskId, equals('t2'));
      expect(merged.examId, equals('e1'));
    });

    test('json round-trip preserves planningBlockId', () {
      const ctx = FocusLaunchContext(
        subjectId: 's1',
        topicId: 't1',
        chapterId: 'c1',
        taskId: 'task1',
        examId: 'e1',
        planningBlockId: 'pb1',
        focusTitle: 'Focus',
        duration: Duration(minutes: 45),
      );
      final restored = FocusLaunchContext.fromJson(ctx.toJson());
      expect(restored, equals(ctx));
    });

    test('equality and toString', () {
      const a = FocusLaunchContext(subjectId: 's1');
      const b = FocusLaunchContext(subjectId: 's1');
      const c = FocusLaunchContext(subjectId: 's2');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.toString(), contains('s1'));
    });
  });
}
