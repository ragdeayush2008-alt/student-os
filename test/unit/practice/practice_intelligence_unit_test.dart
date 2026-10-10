import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/academic_intelligence_engine.dart';
import 'package:student_os/core/intelligence/academic_knowledge_engine.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/data/models/topic_practice_attempt.dart';

void main() {
  group('Practice Intelligence Unit Tests', () {
    final now = DateTime(2026, 3, 15, 12, 0);

    test('1. assessTopicProgress derives accurate practice metrics', () {
      final topic = Topic(
        id: 'top_deprec',
        chapterId: 'ch_1',
        subjectId: 'sub_acc',
        title: 'Depreciation Methods',
      );

      final attempts = [
        TopicPracticeAttempt(
          id: 'p_1',
          topicId: 'top_deprec',
          durationSec: 600,
          totalQuestions: 10,
          correctAnswers: 8,
          startedAt: now.subtract(const Duration(days: 1)),
        ),
        TopicPracticeAttempt(
          id: 'p_2',
          topicId: 'top_deprec',
          durationSec: 900,
          totalQuestions: 10,
          correctAnswers: 9,
          startedAt: now.subtract(const Duration(days: 3)),
        ),
      ];

      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        practiceAttempts: attempts,
        referenceTime: now,
      );

      expect(progress.practiceAttemptsCount, 2);
      expect(progress.totalPracticeMinutes, 25);
      expect(progress.practiceAccuracyPercentage, 85); // 17 / 20 = 85%
      expect(progress.bestAccuracyPercentage, 90);
      expect(progress.recentAccuracyPercentage, 80);
      expect(progress.isWeakTopic, isFalse);
      expect(progress.masteryBreakdown!.practicePercentage, 67); // 2 of 3 targets
    });

    test('2. Weak topic detection flags low accuracy attempt (<65%)', () {
      final topic = Topic(
        id: 'top_partnership',
        chapterId: 'ch_1',
        subjectId: 'sub_acc',
        title: 'Partnership Accounts',
      );

      final attempts = [
        TopicPracticeAttempt(
          id: 'p_weak',
          topicId: 'top_partnership',
          durationSec: 600,
          totalQuestions: 10,
          correctAnswers: 4, // 40% accuracy
          startedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        practiceAttempts: attempts,
        referenceTime: now,
      );

      expect(progress.isWeakTopic, isTrue);
      expect(progress.weakTopicReason, contains('Practice accuracy is 40%'));
    });

    test('3. Weak topic detection flags declining score', () {
      final topic = Topic(
        id: 'top_calc',
        chapterId: 'ch_1',
        subjectId: 'sub_math',
        title: 'Calculus Derivatives',
      );

      final attempts = [
        TopicPracticeAttempt(
          id: 'p_recent',
          topicId: 'top_calc',
          durationSec: 600,
          totalQuestions: 10,
          correctAnswers: 6, // 60% recent
          startedAt: now.subtract(const Duration(hours: 2)),
        ),
        TopicPracticeAttempt(
          id: 'p_older',
          topicId: 'top_calc',
          durationSec: 600,
          totalQuestions: 10,
          correctAnswers: 9, // 90% best
          startedAt: now.subtract(const Duration(days: 4)),
        ),
      ];

      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        practiceAttempts: attempts,
        referenceTime: now,
      );

      expect(progress.isWeakTopic, isTrue);
      expect(progress.weakTopicReason, contains('fell to 60%'));
    });

    test('4. getWeakTopics returns prioritized list of weak topics', () {
      final topicStrong = Topic(
        id: 'top_strong',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        title: 'Strong Topic',
      );
      final topicWeak1 = Topic(
        id: 'top_weak_1',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        title: 'Weak Topic 1',
      );
      final topicWeak2 = Topic(
        id: 'top_weak_2',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        title: 'Weak Topic 2',
      );

      final attempts = [
        TopicPracticeAttempt(
          id: 'p_strong',
          topicId: 'top_strong',
          totalQuestions: 10,
          correctAnswers: 9,
          startedAt: now,
        ),
        TopicPracticeAttempt(
          id: 'p_w1',
          topicId: 'top_weak_1',
          totalQuestions: 10,
          correctAnswers: 3, // 30%
          startedAt: now,
        ),
        TopicPracticeAttempt(
          id: 'p_w2',
          topicId: 'top_weak_2',
          totalQuestions: 10,
          correctAnswers: 5, // 50%
          startedAt: now,
        ),
      ];

      final weakList = AcademicKnowledgeEngine.getWeakTopics(
        topics: [topicStrong, topicWeak1, topicWeak2],
        practiceAttempts: attempts,
        referenceTime: now,
      );

      expect(weakList.length, 2);
      expect(weakList.first.topic.id, 'top_weak_1'); // Lowest accuracy first (30%)
      expect(weakList.last.topic.id, 'top_weak_2');
    });

    test('5. generatePracticeRecommendations assigns higher score to weak topics', () {
      final subject = Subject(id: 'sub_fin', name: 'Finance');
      final topicWeak = Topic(
        id: 'top_bonds',
        chapterId: 'ch_1',
        subjectId: 'sub_fin',
        title: 'Bond Valuation',
      );
      final topicNormal = Topic(
        id: 'top_stocks',
        chapterId: 'ch_1',
        subjectId: 'sub_fin',
        title: 'Stock Valuation',
      );

      final attempts = [
        TopicPracticeAttempt(
          id: 'p_bond',
          topicId: 'top_bonds',
          totalQuestions: 10,
          correctAnswers: 4,
          startedAt: now,
        ),
        TopicPracticeAttempt(
          id: 'p_stock',
          topicId: 'top_stocks',
          totalQuestions: 10,
          correctAnswers: 9,
          startedAt: now,
        ),
      ];

      final recs = AcademicIntelligenceEngine.generatePracticeRecommendations(
        subjects: [subject],
        topics: [topicWeak, topicNormal],
        practiceAttempts: attempts,
        referenceTime: now,
      );

      expect(recs.first.topicId, 'top_bonds');
      expect(recs.first.isWeak, isTrue);
      expect(recs.first.score, greaterThan(recs.last.score));
    });
  });
}
