import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/academic_knowledge_engine.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/data/models/topic_practice_attempt.dart';

void main() {
  final now = DateTime(2026, 9, 15, 10, 0);

  group('AcademicKnowledgeEngine — Learning Experience 2.0 Engine Tests', () {
    test('1. Topic with 0 study sessions is notStarted and has clean breakdown', () {
      final topic = Topic(
        id: 'top_1',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        title: 'Depreciation Basics',
        estimatedMinutes: 45,
      );

      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: [],
        practiceAttempts: [],
        referenceTime: now,
      );

      expect(progress.status, TopicStatus.notStarted);
      expect(progress.mastery, TopicMasteryState.notStarted);
      expect(progress.totalStudyMinutes, 0);
      expect(progress.sessionsCount, 0);
      expect(progress.daysSinceStudied, 999);
      expect(progress.isRevisionDue, isFalse);
      expect(progress.recommendedActionLabel, 'Start Learning');
      expect(progress.masteryBreakdown, isNotNull);
      expect(progress.masteryBreakdown!.learningPercentage, 0);
      expect(progress.masteryBreakdown!.practicePercentage, 0);
      expect(progress.recommendationReason, contains('Not yet studied'));
    });

    test('2. Topic with single short study session is inProgress', () {
      final topic = Topic(
        id: 'top_1',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        title: 'Depreciation Basics',
        estimatedMinutes: 45,
      );

      final session = StudySession(
        id: 's_1',
        subject: 'Accounting',
        topicId: 'top_1',
        startedAt: now.subtract(const Duration(minutes: 10)),
        endedAt: now,
        durationSec: 600, // 10 min
        completed: true,
      );

      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: [session],
        referenceTime: now,
      );

      expect(progress.status, TopicStatus.inProgress);
      expect(progress.mastery, TopicMasteryState.learning);
      expect(progress.totalStudyMinutes, 10);
      expect(progress.sessionsCount, 1);
      expect(progress.daysSinceStudied, 0);
      expect(progress.isRevisionDue, isFalse);
      expect(progress.recommendedActionLabel, 'Continue Learning');
      expect(progress.recommendationReason, contains('In progress'));
    });

    test('3. Topic with study > 4 days ago is needsRevision with explainable reason', () {
      final topic = Topic(
        id: 'top_1',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        title: 'Depreciation Basics',
        estimatedMinutes: 45,
      );

      final session = StudySession(
        id: 's_1',
        subject: 'Accounting',
        topicId: 'top_1',
        startedAt: now.subtract(const Duration(days: 5)),
        endedAt: now.subtract(const Duration(days: 5, minutes: -30)),
        durationSec: 1800, // 30 min
        completed: true,
      );

      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: [session],
        referenceTime: now,
      );

      expect(progress.status, TopicStatus.needsRevision);
      expect(progress.isRevisionDue, isTrue);
      expect(progress.daysSinceStudied, 5);
      expect(progress.recommendedActionLabel, 'Revise Now');
      expect(progress.recommendationReason, contains('Revision is due because you last studied this 5 days ago'));
    });

    test('4. Topic with multiple revisions & practice attempts advances to mastered & strong', () {
      final topic = Topic(
        id: 'top_1',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        title: 'Depreciation Methods',
        estimatedMinutes: 45,
      );

      final sessions = [
        StudySession(
          id: 's_1',
          subject: 'Accounting',
          topicId: 'top_1',
          startedAt: now.subtract(const Duration(days: 10)),
          durationSec: 1800,
          completed: true,
        ),
        StudySession(
          id: 's_2',
          subject: 'Accounting',
          topicId: 'top_1',
          startedAt: now.subtract(const Duration(days: 6)),
          durationSec: 1200,
          completed: true,
        ),
        StudySession(
          id: 's_3',
          subject: 'Accounting',
          topicId: 'top_1',
          startedAt: now.subtract(const Duration(days: 1)),
          durationSec: 1200,
          completed: true,
        ),
      ];

      final practices = [
        TopicPracticeAttempt(
          id: 'prac_1',
          topicId: 'top_1',
          startedAt: now.subtract(const Duration(days: 1)),
          durationSec: 900,
          totalQuestions: 10,
          correctAnswers: 9,
        ),
        TopicPracticeAttempt(
          id: 'prac_2',
          topicId: 'top_1',
          startedAt: now.subtract(const Duration(hours: 3)),
          durationSec: 900,
          totalQuestions: 10,
          correctAnswers: 10,
        ),
      ];

      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: sessions,
        practiceAttempts: practices,
        referenceTime: now,
      );

      expect(progress.status, TopicStatus.mastered);
      expect(progress.mastery, TopicMasteryState.strong);
      expect(progress.revisionCount, 2);
      expect(progress.practiceAttemptsCount, 2);
      expect(progress.totalPracticeMinutes, 30);
      expect(progress.practiceAccuracyPercentage, 95);
      expect(progress.recommendedActionLabel, 'Practice');
      expect(progress.masteryBreakdown!.learningPercentage, 100);
      expect(progress.masteryBreakdown!.revisionPercentage, 100);
    });

    test('5. assessChapterProgress calculates topic counters and fraction correctly', () {
      final chapter = Chapter(id: 'ch_1', subjectId: 'sub_1', title: 'Chapter 1: Foundations');
      final topics = [
        Topic(id: 't_1', chapterId: 'ch_1', subjectId: 'sub_1', title: 'Basics'),
        Topic(id: 't_2', chapterId: 'ch_1', subjectId: 'sub_1', title: 'Principles'),
        Topic(id: 't_3', chapterId: 'ch_1', subjectId: 'sub_1', title: 'Applications'),
        Topic(id: 't_4', chapterId: 'ch_1', subjectId: 'sub_1', title: 'Summary'),
      ];

      final sessions = [
        StudySession(
          id: 's_1',
          subject: 'Test',
          topicId: 't_1',
          startedAt: now.subtract(const Duration(days: 1)),
          durationSec: 1800,
          completed: true,
        ),
        StudySession(
          id: 's_2',
          subject: 'Test',
          topicId: 't_2',
          startedAt: now.subtract(const Duration(days: 5)),
          durationSec: 1800,
          completed: true,
        ),
      ];

      final prog = AcademicKnowledgeEngine.assessChapterProgress(
        chapter,
        topics,
        sessions: sessions,
        referenceTime: now,
      );

      expect(prog.totalTopics, 4);
      expect(prog.studiedTopics, 2);
      expect(prog.needsRevisionTopics, 1); // t_2 is 5 days ago
      expect(prog.completionFraction, 0.5);
      expect(prog.completionPercentage, 50);
      expect(prog.totalStudyMinutes, 60);
    });

    test('6. assessSubjectProgress handles empty topic subject honestly', () {
      final subject = Subject(id: 'sub_empty', name: 'Philosophy');

      final prog = AcademicKnowledgeEngine.assessSubjectProgress(
        subject,
        chapters: [],
        topics: [],
        sessions: [],
        referenceTime: now,
      );

      expect(prog.totalChapters, 0);
      expect(prog.totalTopics, 0);
      expect(prog.studiedTopics, 0);
      expect(prog.needsRevisionTopics, 0);
      expect(prog.totalStudyMinutes, 0);
      expect(prog.syllabusFraction, 0.0);
      expect(prog.hasSyllabus, isFalse);
      expect(prog.health, SubjectHealthState.onTrack);
    });

    test('7. getRecommendedTopicForSubject picks highest priority topic', () {
      final subject = Subject(id: 'sub_acc', name: 'Accountancy', preference: SubjectPreference.high);
      final chapters = [Chapter(id: 'ch_1', subjectId: 'sub_acc', title: 'Chapter 1')];
      final topics = [
        Topic(id: 't_1', chapterId: 'ch_1', subjectId: 'sub_acc', title: 'Basics', importance: TopicImportance.normal),
        Topic(id: 't_2', chapterId: 'ch_1', subjectId: 'sub_acc', title: 'Depreciation Critical', importance: TopicImportance.critical),
      ];

      final recommended = AcademicKnowledgeEngine.getRecommendedTopicForSubject(
        subject,
        chapters: chapters,
        topics: topics,
        sessions: [],
        referenceTime: now,
      );

      expect(recommended, isNotNull);
      expect(recommended!.id, 't_2');
      expect(recommended.title, 'Depreciation Critical');
    });

    test('8. getRecommendedTopicForChapter returns next unstudied topic in chapter order', () {
      final chapter = Chapter(id: 'ch_1', subjectId: 'sub_acc', title: 'Chapter 1');
      final topics = [
        Topic(id: 't_1', chapterId: 'ch_1', subjectId: 'sub_acc', title: 'Topic 1', order: 0),
        Topic(id: 't_2', chapterId: 'ch_1', subjectId: 'sub_acc', title: 'Topic 2', order: 1),
      ];

      // t_1 is studied
      final sessions = [
        StudySession(
          id: 's_1',
          subject: 'Accountancy',
          topicId: 't_1',
          startedAt: now.subtract(const Duration(hours: 2)),
          durationSec: 2400,
          completed: true,
        ),
      ];

      final nextInChapter = AcademicKnowledgeEngine.getRecommendedTopicForChapter(
        chapter,
        topics: topics,
        sessions: sessions,
        referenceTime: now,
      );

      expect(nextInChapter, isNotNull);
      expect(nextInChapter!.id, 't_2');
    });

    test('9. getNeedsAttentionTopics returns topics needing revision or in progress', () {
      final topics = [
        Topic(id: 't_1', chapterId: 'ch_1', subjectId: 'sub_1', title: 'Fresh Topic'),
        Topic(id: 't_2', chapterId: 'ch_1', subjectId: 'sub_1', title: 'Neglected Topic'),
      ];

      final sessions = [
        StudySession(
          id: 's_1',
          subject: 'Sub',
          topicId: 't_1',
          startedAt: now.subtract(const Duration(hours: 1)),
          durationSec: 1800,
          completed: true,
        ),
        StudySession(
          id: 's_2',
          subject: 'Sub',
          topicId: 't_2',
          startedAt: now.subtract(const Duration(days: 6)),
          durationSec: 1800,
          completed: true,
        ),
      ];

      final attention = AcademicKnowledgeEngine.getNeedsAttentionTopics(
        'sub_1',
        topics: topics,
        sessions: sessions,
        referenceTime: now,
      );

      expect(attention.length, 1);
      expect(attention.first.topic.id, 't_2');
      expect(attention.first.isRevisionDue, isTrue);
    });
  });
}
