import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/topic_practice_attempt.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/knowledge/topic_practice_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_test_practice');
    TopicPracticeController.instance.clearData();
    ProgressionController.instance.clearData();
  });

  tearDown(() {
    TopicPracticeController.instance.clearData();
    ProgressionController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  group('TopicPracticeAttempt Model Tests', () {
    test('1. Model creates with required and default fields', () {
      final attempt = TopicPracticeAttempt(
        id: 'prac_1',
        topicId: 'top_1',
      );

      expect(attempt.id, 'prac_1');
      expect(attempt.topicId, 'top_1');
      expect(attempt.durationSec, 0);
      expect(attempt.isCompleted, isFalse);
      expect(attempt.accuracyPercentage, isNull);
      expect(attempt.notes, isEmpty);
    });

    test('2. Accuracy percentage calculates correctly', () {
      final attempt1 = TopicPracticeAttempt(
        id: 'prac_1',
        topicId: 'top_1',
        totalQuestions: 10,
        correctAnswers: 8,
      );
      expect(attempt1.accuracyPercentage, 80);

      final attempt2 = TopicPracticeAttempt(
        id: 'prac_2',
        topicId: 'top_1',
        totalQuestions: 3,
        correctAnswers: 1,
      );
      expect(attempt2.accuracyPercentage, 33);

      final attempt3 = TopicPracticeAttempt(
        id: 'prac_3',
        topicId: 'top_1',
        totalQuestions: 0,
        correctAnswers: 0,
      );
      expect(attempt3.accuracyPercentage, isNull);
    });

    test('3. copyWith preserves unchanged fields and clears specified fields', () {
      final attempt = TopicPracticeAttempt(
        id: 'prac_1',
        topicId: 'top_1',
        subjectId: 'sub_1',
        chapterId: 'ch_1',
        durationSec: 1200,
        totalQuestions: 15,
        correctAnswers: 12,
        notes: 'Initial notes',
      );

      final updated = attempt.copyWith(
        durationSec: 1500,
        correctAnswers: 14,
      );

      expect(updated.id, 'prac_1');
      expect(updated.topicId, 'top_1');
      expect(updated.subjectId, 'sub_1');
      expect(updated.chapterId, 'ch_1');
      expect(updated.durationSec, 1500);
      expect(updated.totalQuestions, 15);
      expect(updated.correctAnswers, 14);
      expect(updated.notes, 'Initial notes');

      final cleared = attempt.copyWith(
        clearTotalQuestions: true,
        clearCorrectAnswers: true,
        clearNotes: true,
      );
      expect(cleared.totalQuestions, isNull);
      expect(cleared.correctAnswers, isNull);
      expect(cleared.notes, isEmpty);
    });

    test('4. JSON roundtrip serialization and deserialization', () {
      final now = DateTime(2026, 9, 15, 14, 30);
      final attempt = TopicPracticeAttempt(
        id: 'prac_json_1',
        userId: 'user_123',
        topicId: 'top_json',
        subjectId: 'sub_json',
        chapterId: 'ch_json',
        startedAt: now,
        completedAt: now.add(const Duration(minutes: 25)),
        durationSec: 1500,
        totalQuestions: 20,
        correctAnswers: 18,
        incorrectAnswers: 2,
        score: 90.0,
        notes: 'Solved all numericals correctly',
      );

      final json = attempt.toJson();
      final restored = TopicPracticeAttempt.fromJson(json);

      expect(restored.id, attempt.id);
      expect(restored.userId, attempt.userId);
      expect(restored.topicId, attempt.topicId);
      expect(restored.subjectId, attempt.subjectId);
      expect(restored.chapterId, attempt.chapterId);
      expect(restored.durationSec, attempt.durationSec);
      expect(restored.totalQuestions, attempt.totalQuestions);
      expect(restored.correctAnswers, attempt.correctAnswers);
      expect(restored.incorrectAnswers, attempt.incorrectAnswers);
      expect(restored.score, attempt.score);
      expect(restored.notes, attempt.notes);
      expect(restored.accuracyPercentage, 90);
    });

    test('5. Legacy JSON compatibility: missing optional fields load safely', () {
      final legacyJson = {
        'id': 'prac_legacy_1',
        'topicId': 'top_legacy',
        'startedAt': '2026-09-10T10:00:00.000',
        'durationSec': 600,
      };

      final restored = TopicPracticeAttempt.fromJson(legacyJson);
      expect(restored.id, 'prac_legacy_1');
      expect(restored.topicId, 'top_legacy');
      expect(restored.durationSec, 600);
      expect(restored.totalQuestions, isNull);
      expect(restored.correctAnswers, isNull);
      expect(restored.score, isNull);
      expect(restored.notes, isEmpty);
      expect(restored.userId, isNull);
    });
  });

  group('TopicPracticeController Tests', () {
    test('6. Record practice attempt persists and updates queries', () async {
      final controller = TopicPracticeController.instance;

      final attempt = await controller.recordAttempt(
        topicId: 'topic_depreciation',
        subjectId: 'sub_accounting',
        chapterId: 'ch_depreciation',
        durationSec: 1200,
        totalQuestions: 10,
        correctAnswers: 8,
        notes: 'Asset disposal methods',
      );

      expect(attempt.id, isNotEmpty);
      expect(controller.attempts.length, 1);
      expect(controller.attemptsForTopic('topic_depreciation').length, 1);
      expect(controller.attemptsForSubject('sub_accounting').length, 1);
      expect(controller.attemptsForChapter('ch_depreciation').length, 1);
      expect(controller.practiceMinutesForTopic('topic_depreciation'), 20);
      expect(controller.totalQuestionsAttemptedForTopic('topic_depreciation'), 10);
      expect(controller.totalCorrectAnswersForTopic('topic_depreciation'), 8);
      expect(controller.lastPracticedDateForTopic('topic_depreciation'), isNotNull);
    });

    test('7. Multiple attempts aggregate total practice minutes and questions', () async {
      final controller = TopicPracticeController.instance;

      await controller.recordAttempt(
        topicId: 'top_algebra',
        subjectId: 'sub_math',
        chapterId: 'ch_equations',
        durationSec: 900, // 15 min
        totalQuestions: 5,
        correctAnswers: 4,
      );

      await controller.recordAttempt(
        topicId: 'top_algebra',
        subjectId: 'sub_math',
        chapterId: 'ch_equations',
        durationSec: 1800, // 30 min
        totalQuestions: 15,
        correctAnswers: 13,
      );

      expect(controller.attemptsForTopic('top_algebra').length, 2);
      expect(controller.practiceMinutesForTopic('top_algebra'), 45);
      expect(controller.totalQuestionsAttemptedForTopic('top_algebra'), 20);
      expect(controller.totalCorrectAnswersForTopic('top_algebra'), 17);
    });

    test('8. Recording practice awards progression XP idempotently', () async {
      final controller = TopicPracticeController.instance;
      final progression = ProgressionController.instance;
      await progression.load();
      final initialXp = progression.totalXp;

      final attempt = await controller.recordAttempt(
        topicId: 'top_taxation',
        durationSec: 600,
      );

      final eventId = 'xp_practice_${attempt.id}';
      expect(progression.hasEvent(eventId), isTrue);
      expect(progression.totalXp, initialXp + 25);

      // Repeated event with same ID does NOT double-award XP
      final repeated = await progression.recordEvent(
        XpEvent(
          id: eventId,
          type: XpEventType.studySessionCompleted,
          amount: 25,
          reason: 'Duplicate practice test',
          timestamp: DateTime.now(),
        ),
      );
      expect(repeated, isFalse);
      expect(progression.totalXp, initialXp + 25);
    });

    test('9. User isolation: switching user clears memory and separates data', () async {
      final controller = TopicPracticeController.instance;

      // User A records attempt
      AuthIsolation.instance.setAuthenticatedUser('user_A');
      await controller.recordAttempt(
        topicId: 'top_a',
        durationSec: 1200,
        notes: 'User A practice',
      );
      expect(controller.attempts.length, 1);

      // User A logs out -> clear
      controller.clearData();
      expect(controller.attempts.isEmpty, isTrue);

      // User B logs in
      AuthIsolation.instance.setAuthenticatedUser('user_B');
      await controller.load();
      expect(controller.attempts.isEmpty, isTrue);

      await controller.recordAttempt(
        topicId: 'top_b',
        durationSec: 600,
        notes: 'User B practice',
      );
      expect(controller.attempts.length, 1);
      expect(controller.attempts.first.notes, 'User B practice');

      // User B logs out, User A logs back in
      controller.clearData();
      AuthIsolation.instance.setAuthenticatedUser('user_A');
      await controller.load();
      expect(controller.attempts.length, 1);
      expect(controller.attempts.first.notes, 'User A practice');
    });

    test('10. Deleting practice attempt updates state and persistence', () async {
      final controller = TopicPracticeController.instance;

      final a1 = await controller.recordAttempt(topicId: 'top_del', durationSec: 300);
      final a2 = await controller.recordAttempt(topicId: 'top_del', durationSec: 600);
      expect(controller.attempts.length, 2);

      await controller.deleteAttempt(a1.id);
      expect(controller.attempts.length, 1);
      expect(controller.attempts.first.id, a2.id);
    });
  });
}
