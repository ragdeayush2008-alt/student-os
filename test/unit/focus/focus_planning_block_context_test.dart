import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';

void main() {
  group('FocusSession planningBlockId (CODE 5, backward compatible)', () {
    test('new sessions carry planningBlockId through JSON', () {
      final session = FocusSession(
        id: 'fs1',
        startedAt: DateTime(2026, 9, 15, 10, 0),
        subjectId: 's1',
        taskId: 't1',
        topicId: 'topic1',
        chapterId: 'ch1',
        planningBlockId: 'pb1',
        objective: 'Physics',
      );
      final json = session.toJson();
      expect(json['planningBlockId'], equals('pb1'));

      final restored = FocusSession.fromJson(json);
      expect(restored.planningBlockId, equals('pb1'));
      expect(restored.subjectId, equals('s1'));
      expect(restored.taskId, equals('t1'));
      expect(restored.topicId, equals('topic1'));
      expect(restored.chapterId, equals('ch1'));
    });

    test('legacy JSON without planningBlockId restores as null', () {
      final session = FocusSession(
        id: 'fs_legacy',
        startedAt: DateTime(2026, 9, 15, 10, 0),
        objective: 'Legacy',
      );
      final json = Map<String, dynamic>.from(session.toJson())
        ..remove('planningBlockId');
      expect(json.containsKey('planningBlockId'), isFalse);

      final restored = FocusSession.fromJson(json);
      expect(restored.planningBlockId, isNull);
      expect(restored.objective, equals('Legacy'));
    });
  });
}
