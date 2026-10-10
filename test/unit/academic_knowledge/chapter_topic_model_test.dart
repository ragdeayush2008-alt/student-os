import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/planning/models/planning_block.dart';

void main() {
  group('Chapter Model', () {
    test('instantiates with defaults and copyWith works', () {
      final ch = Chapter(
        id: 'ch_1',
        subjectId: 'sub_1',
        title: 'Partnership Accounts',
      );

      expect(ch.id, 'ch_1');
      expect(ch.subjectId, 'sub_1');
      expect(ch.title, 'Partnership Accounts');
      expect(ch.description, '');
      expect(ch.order, 0);
      expect(ch.estimatedMinutes, isNull);

      final updated = ch.copyWith(
        title: 'Advanced Partnership Accounts',
        description: 'Covers reconstitution and dissolution',
        order: 2,
        estimatedMinutes: 180,
      );

      expect(updated.id, 'ch_1');
      expect(updated.title, 'Advanced Partnership Accounts');
      expect(updated.description, 'Covers reconstitution and dissolution');
      expect(updated.order, 2);
      expect(updated.estimatedMinutes, 180);
    });

    test('serializes to and from JSON', () {
      final ch = Chapter(
        id: 'ch_2',
        subjectId: 'sub_2',
        title: 'Company Law',
        description: 'Incorporation and share capital',
        order: 1,
        estimatedMinutes: 120,
        userId: 'user_123',
      );

      final json = ch.toJson();
      final fromJson = Chapter.fromJson(json);

      expect(fromJson.id, ch.id);
      expect(fromJson.subjectId, ch.subjectId);
      expect(fromJson.title, ch.title);
      expect(fromJson.description, ch.description);
      expect(fromJson.order, ch.order);
      expect(fromJson.estimatedMinutes, ch.estimatedMinutes);
      expect(fromJson.userId, ch.userId);
      expect(fromJson, equals(ch));
    });
  });

  group('Topic Model', () {
    test('instantiates with defaults and copyWith works', () {
      final top = Topic(
        id: 'top_1',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        title: 'Admission of a Partner',
      );

      expect(top.id, 'top_1');
      expect(top.chapterId, 'ch_1');
      expect(top.subjectId, 'sub_1');
      expect(top.title, 'Admission of a Partner');
      expect(top.description, '');
      expect(top.order, 0);
      expect(top.estimatedMinutes, 35);
      expect(top.importance, TopicImportance.normal);

      final updated = top.copyWith(
        title: 'Retirement of a Partner',
        description: 'Settlement of capital and goodwill',
        order: 3,
        estimatedMinutes: 45,
        importance: TopicImportance.high,
      );

      expect(updated.id, 'top_1');
      expect(updated.title, 'Retirement of a Partner');
      expect(updated.description, 'Settlement of capital and goodwill');
      expect(updated.order, 3);
      expect(updated.estimatedMinutes, 45);
      expect(updated.importance, TopicImportance.high);
    });

    test('serializes to and from JSON with importance', () {
      final top = Topic(
        id: 'top_2',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        title: 'Death of a Partner',
        description: 'Executors account calculation',
        order: 4,
        estimatedMinutes: 40,
        importance: TopicImportance.critical,
        userId: 'user_456',
      );

      final json = top.toJson();
      final fromJson = Topic.fromJson(json);

      expect(fromJson.id, top.id);
      expect(fromJson.chapterId, top.chapterId);
      expect(fromJson.subjectId, top.subjectId);
      expect(fromJson.title, top.title);
      expect(fromJson.description, top.description);
      expect(fromJson.order, top.order);
      expect(fromJson.estimatedMinutes, top.estimatedMinutes);
      expect(fromJson.importance, TopicImportance.critical);
      expect(fromJson.userId, top.userId);
      expect(fromJson, equals(top));
    });
  });

  group('Backward Compatibility for Old Records', () {
    test('StudySession without topicId deserializes gracefully', () {
      final oldJson = {
        'id': 'session_legacy_1',
        'subject': 'Accountancy',
        'taskId': 'task_1',
        'startedAt': DateTime.now().toIso8601String(),
        'durationSec': 1800,
        'completed': true,
        'note': 'Old study session',
      };

      final session = StudySession.fromJson(oldJson);
      expect(session.id, 'session_legacy_1');
      expect(session.subject, 'Accountancy');
      expect(session.taskId, 'task_1');
      expect(session.topicId, isNull);
      expect(session.chapterId, isNull);
      expect(session.subjectId, isNull);
    });

    test('PlanningBlock without topicId deserializes gracefully', () {
      final oldJson = {
        'id': 'pb_legacy_1',
        'userId': 'user_1',
        'subjectId': 'sub_1',
        'startAt': DateTime.now().toIso8601String(),
        'endAt': DateTime.now().add(const Duration(minutes: 45)).toIso8601String(),
      };

      final block = PlanningBlock.fromJson(oldJson);
      expect(block.id, 'pb_legacy_1');
      expect(block.subjectId, 'sub_1');
      expect(block.topicId, isNull);
      expect(block.chapterId, isNull);
      expect(block.isSubjectBlock, isTrue);
      expect(block.isTopicBlock, isFalse);
    });

    test('FocusSession without topicId deserializes gracefully', () {
      final oldJson = {
        'id': 'fs_legacy_1',
        'subjectName': 'Economics',
        'mode': 'timer',
        'startedAt': DateTime.now().toIso8601String(),
        'durationSeconds': 1500,
        'status': 'completed',
        'outcome': 'completed',
      };

      final session = FocusSession.fromJson(oldJson);
      expect(session.id, 'fs_legacy_1');
      expect(session.subjectName, 'Economics');
      expect(session.topicId, isNull);
      expect(session.chapterId, isNull);
      expect(session.isComplete, isTrue);
    });
  });
}
