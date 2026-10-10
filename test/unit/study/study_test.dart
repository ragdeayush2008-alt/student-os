import 'package:flutter_test/flutter_test.dart';

import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/features/study/study_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StudySession — model', () {
    test('creates with required and default fields', () {
      final session = StudySession(id: '1', subject: 'Mathematics');
      expect(session.id, '1');
      expect(session.subject, 'Mathematics');
      expect(session.taskId, isNull);
      expect(session.durationSec, 0);
      expect(session.completed, isTrue);
      expect(session.duration, Duration.zero);
    });

    test('date getter normalizes to calendar day', () {
      final started = DateTime(2026, 8, 28, 14, 30);
      final session = StudySession(
        id: '1',
        subject: 'Physics',
        startedAt: started,
      );
      expect(session.date, DateTime(2026, 8, 28));
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final session = StudySession(
        id: 's1',
        subject: 'Chemistry',
        taskId: 't1',
        startedAt: DateTime(2026, 8, 28, 9, 0),
        endedAt: DateTime(2026, 8, 28, 9, 45),
        durationSec: 2700,
        completed: true,
        note: 'review redox',
      );
      final json = session.toJson();
      final restored = StudySession.fromJson(json);
      expect(restored.id, session.id);
      expect(restored.subject, session.subject);
      expect(restored.taskId, session.taskId);
      expect(restored.durationSec, 2700);
      expect(restored.completed, isTrue);
      expect(restored.note, 'review redox');
      expect(restored.startedAt, session.startedAt);
    });

    test('copyWith changes only requested fields', () {
      final original = StudySession(
        id: '1',
        subject: 'Mathematics',
        durationSec: 600,
      );
      final updated = original.copyWith(durationSec: 1200);
      expect(updated.id, original.id);
      expect(updated.subject, original.subject);
      expect(updated.durationSec, 1200);
    });
  });

  group('StudyController — focus session flow', () {
    tearDown(() {
      StudyController.instance.cancelSession();
    });

    test('startSession begins a running session', () {
      final controller = StudyController.instance;
      controller.startSession(subject: 'Mathematics');
      expect(controller.hasActiveSession, isTrue);
      expect(controller.isRunning, isTrue);
      expect(controller.activeSubject, 'Mathematics');
    });

    test('pause and resume accumulate elapsed time', () async {
      final controller = StudyController.instance;
      controller.startSession(subject: 'Physics');
      // Simulate a short running window.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      controller.pauseSession();
      final pausedElapsed = controller.activeElapsed;
      expect(pausedElapsed, greaterThan(Duration.zero));
      expect(controller.isRunning, isFalse);

      // Elapsed should be frozen while paused.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.activeElapsed, equals(pausedElapsed));

      controller.resumeSession();
      expect(controller.isRunning, isTrue);
    });

    test('endSession produces a persisted completed session', () async {
      final controller = StudyController.instance;
      controller.startSession(subject: 'Chemistry');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final session = await controller.endSession();

      expect(session, isNotNull);
      expect(session!.isCompleted, isTrue);
      expect(session.subject, 'Chemistry');
      expect(controller.hasActiveSession, isFalse);
      expect(controller.sessions.contains(session), isTrue);
    });

    test('cancelSession discards without persisting', () {
      final controller = StudyController.instance;
      controller.startSession(subject: 'English');
      final before = controller.completedSessions.length;
      controller.cancelSession();
      expect(controller.hasActiveSession, isFalse);
      expect(controller.completedSessions.length, before);
    });
  });
}
