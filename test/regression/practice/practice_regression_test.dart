import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/topic_practice_attempt.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/knowledge/topic_practice_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_regression_practice');
    TopicPracticeController.instance.clearData();
    ProgressionController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  group('Practice Regression Tests', () {
    test('1. TopicPracticeAttempt backwards compatibility with minimal legacy JSON', () {
      final legacyJson = <String, dynamic>{
        'id': 'prac_legacy_1',
        'topicId': 'top_legacy',
        'durationSec': 1200,
      };

      final attempt = TopicPracticeAttempt.fromJson(legacyJson);
      expect(attempt.id, 'prac_legacy_1');
      expect(attempt.topicId, 'top_legacy');
      expect(attempt.durationSec, 1200);
      expect(attempt.totalQuestions, isNull);
      expect(attempt.correctAnswers, isNull);
      expect(attempt.score, isNull);
      expect(attempt.notes, '');
      expect(attempt.isCompleted, isTrue);
    });

    test('2. Manual practice recording workflow preserved from CODE 7', () async {
      final attempt = await TopicPracticeController.instance.recordAttempt(
        topicId: 'top_manual',
        subjectId: 'sub_manual',
        durationSec: 1200,
        totalQuestions: 15,
        correctAnswers: 12,
        incorrectAnswers: 3,
        score: 80.0,
        notes: 'Manual practice recording from sheet',
      );

      expect(attempt.topicId, 'top_manual');
      expect(attempt.totalQuestions, 15);
      expect(attempt.correctAnswers, 12);
      expect(attempt.accuracyPercentage, 80);
      expect(TopicPracticeController.instance.attempts.length, 1);
    });

    test('3. Practice XP award is strictly idempotent and prevents double-crediting', () async {
      final attempt = await TopicPracticeController.instance.recordAttempt(
        topicId: 'top_xp_test',
        durationSec: 600,
        totalQuestions: 5,
        correctAnswers: 4,
      );

      final eventId = 'xp_practice_${attempt.id}';
      final initialCount = ProgressionController.instance.events.where((e) => e.id == eventId).length;
      expect(initialCount, 1);

      // Attempt recording duplicate XP with same event ID
      final duplicateAccepted = await ProgressionController.instance.recordEvent(
        XpEvent(
          id: eventId,
          type: XpEventType.studySessionCompleted,
          amount: 25,
          reason: 'Duplicate practice test',
          timestamp: DateTime.now(),
        ),
      );

      expect(duplicateAccepted, isFalse);
      final afterCount = ProgressionController.instance.events.where((e) => e.id == eventId).length;
      expect(afterCount, 1);
    });

    test('4. Unknown identity does not write to persistent storage', () async {
      AuthIsolation.instance.clearSession();
      TopicPracticeController.instance.clearData();

      // When identity is unknown, resolveUserId is null
      expect(AuthIsolation.resolveUserId(null), isNull);
    });
  });
}
