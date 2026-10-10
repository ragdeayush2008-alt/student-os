import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/app_notification.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/planning/models/planning_block.dart';

/// PART27 FLOW 12: legacy JSON (written before Code 5/6 fields existed)
/// deserializes safely, preserves all existing data, and leaves new
/// nullable fields absent (null) — no destructive migration.
void main() {
  group('Legacy JSON compatibility', () {
    test('FocusSession without planningBlockId restores as null', () {
      final restored = FocusSession.fromJson({
        'id': 'fs_legacy',
        'objective': 'Old session',
        'mode': 'timer',
        'status': 'completed',
        'startedAt': '2026-01-05T10:00:00.000',
        'endedAt': '2026-01-05T10:25:00.000',
        'phase': 'completed',
        'focusDuration': 1500,
        'outcome': 'completed',
      });
      expect(restored.id, 'fs_legacy');
      expect(restored.planningBlockId, isNull);
      expect(restored.objective, 'Old session');
      expect(restored.isComplete, isTrue);
    });

    test('StudySession without focusSessionId restores as null', () {
      final restored = StudySession.fromJson({
        'id': 's_legacy',
        'subject': 'Physics',
        'startedAt': '2026-02-01T09:00:00.000',
        'durationSec': 1800,
        'completed': true,
      });
      expect(restored.subject, 'Physics');
      expect(restored.focusSessionId, isNull);
      expect(restored.isCompleted, isTrue);
      expect(restored.durationSec, 1800);
    });

    test('StudySession round-trips the new focusSessionId', () {
      final session = StudySession(
        id: 's_new',
        subject: 'Chemistry',
        focusSessionId: 'fs_123',
        durationSec: 1200,
      );
      final restored = StudySession.fromJson(session.toJson());
      expect(restored.focusSessionId, 'fs_123');
    });

    test('PlanningBlock legacy payload parses with full context', () {
      final restored = PlanningBlock.fromJson({
        'id': 'pb_legacy',
        'userId': 'user_x',
        'taskId': 't1',
        'subjectId': 's1',
        'topicId': 't9',
        'chapterId': 'c2',
        'startAt': '2026-03-01T10:00:00.000',
        'endAt': '2026-03-01T11:00:00.000',
      });
      expect(restored.taskId, 't1');
      expect(restored.topicId, 't9');
      expect(restored.chapterId, 'c2');
      expect(restored.endAt.difference(restored.startAt).inMinutes, 60);
    });

    test('Task / Subject / Exam legacy payloads preserve data', () {
      final task = StudentTask.fromJson({'id': 't1', 'title': 'Legacy task'});
      expect(task.title, 'Legacy task');
      expect(task.isCompleted, isFalse);

      final subject = Subject.fromJson({'id': 's1', 'name': 'Legacy'});
      expect(subject.displayName, 'Legacy');

      final exam = StudentExam.fromJson({'id': 'e1', 'title': 'Legacy exam'});
      expect(exam.title, 'Legacy exam');
    });

    test('Chapter / Topic legacy payloads keep nullable userId', () {
      final ch = Chapter.fromJson({'id': 'c1', 'title': 'Ch'});
      expect(ch.title, 'Ch');
      expect(ch.userId, isNull);

      final topic = Topic.fromJson({'id': 't1', 'title': 'Top'});
      expect(topic.title, 'Top');
      expect(topic.userId, isNull);
    });

    test('XpEvent and AppNotification legacy payloads parse', () {
      final event = XpEvent.fromJson({
        'id': 'xp1',
        'type': 'taskCompleted',
        'amount': 25,
        'timestamp': '2026-04-01T12:00:00.000',
        'reason': 'done',
      });
      expect(event.amount, 25);

      final notif = AppNotification.fromJson({
        'id': 'n1',
        'type': 'taskCompleted',
        'title': 'T',
        'body': 'B',
        'createdAt': '2026-04-01T12:00:00.000',
      });
      expect(notif.title, 'T');
    });
  });
}
