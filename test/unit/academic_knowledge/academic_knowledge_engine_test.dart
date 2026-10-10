import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/academic_knowledge_engine.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';

void main() {
  group('AcademicKnowledgeEngine - Topic Progress Derivation', () {
    final topic = Topic(
      id: 'top_test_1',
      chapterId: 'ch_1',
      subjectId: 'sub_1',
      title: 'Admission of a Partner',
      estimatedMinutes: 35,
    );

    test('derives notStarted when no study sessions exist', () {
      final now = DateTime(2026, 9, 12, 10, 0);
      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: const [],
        referenceTime: now,
      );

      expect(progress.status, TopicStatus.notStarted);
      expect(progress.mastery, TopicMasteryState.notStarted);
      expect(progress.totalStudyMinutes, 0);
      expect(progress.sessionsCount, 0);
      expect(progress.isRevisionDue, isFalse);
    });

    test('derives inProgress when short study session exists (<15m)', () {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sessions = [
        StudySession(
          id: 's_1',
          subject: 'Accountancy',
          topicId: topic.id,
          durationSec: 600, // 10 mins
          startedAt: now.subtract(const Duration(hours: 1)),
          completed: true,
        ),
      ];

      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: sessions,
        referenceTime: now,
      );

      expect(progress.status, TopicStatus.inProgress);
      expect(progress.mastery, TopicMasteryState.learning);
      expect(progress.totalStudyMinutes, 10);
      expect(progress.sessionsCount, 1);
    });

    test('derives studied when full session completed recently', () {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sessions = [
        StudySession(
          id: 's_1',
          subject: 'Accountancy',
          topicId: topic.id,
          durationSec: 2100, // 35 mins
          startedAt: now.subtract(const Duration(days: 1)),
          completed: true,
        ),
      ];

      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: sessions,
        referenceTime: now,
      );

      expect(progress.status, TopicStatus.studied);
      expect(progress.mastery, TopicMasteryState.familiar);
      expect(progress.totalStudyMinutes, 35);
      expect(progress.isRevisionDue, isFalse);
    });

    test('derives needsRevision when studied >= 4 days ago', () {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sessions = [
        StudySession(
          id: 's_1',
          subject: 'Accountancy',
          topicId: topic.id,
          durationSec: 2400, // 40 mins
          startedAt: now.subtract(const Duration(days: 6)),
          completed: true,
        ),
      ];

      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: sessions,
        referenceTime: now,
      );

      expect(progress.status, TopicStatus.needsRevision);
      expect(progress.isRevisionDue, isTrue);
      expect(progress.daysSinceStudied, 6);
    });

    test('derives mastered only with evidence of repeated sessions and sufficient time', () {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sessions = [
        StudySession(
          id: 's_1',
          subject: 'Accountancy',
          topicId: topic.id,
          durationSec: 1800, // 30 mins
          startedAt: now.subtract(const Duration(days: 10)),
          completed: true,
        ),
        StudySession(
          id: 's_2',
          subject: 'Accountancy',
          topicId: topic.id,
          durationSec: 1200, // 20 mins
          startedAt: now.subtract(const Duration(days: 5)),
          completed: true,
        ),
        StudySession(
          id: 's_3',
          subject: 'Accountancy',
          topicId: topic.id,
          durationSec: 1200, // 20 mins
          startedAt: now.subtract(const Duration(days: 1)),
          completed: true,
        ),
      ];

      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: sessions,
        referenceTime: now,
      );

      expect(progress.status, TopicStatus.mastered);
      expect(progress.mastery, TopicMasteryState.strong);
      expect(progress.totalStudyMinutes, 70);
      expect(progress.revisionCount, 2);
    });

    test('does NOT give false mastery on single session or opening topic', () {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sessions = [
        StudySession(
          id: 's_1',
          subject: 'Accountancy',
          topicId: topic.id,
          durationSec: 60, // 1 min accidental session
          startedAt: now.subtract(const Duration(minutes: 5)),
          completed: true,
        ),
      ];

      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: sessions,
        referenceTime: now,
      );

      expect(progress.status, isNot(TopicStatus.mastered));
      expect(progress.mastery, isNot(TopicMasteryState.strong));
    });
  });

  group('AcademicKnowledgeEngine - Chapter & Subject Progress', () {
    final chapter = Chapter(
      id: 'ch_1',
      subjectId: 'sub_acc',
      title: 'Partnership',
    );
    final top1 = Topic(
      id: 'top_1',
      chapterId: 'ch_1',
      subjectId: 'sub_acc',
      title: 'Admission',
    );
    final top2 = Topic(
      id: 'top_2',
      chapterId: 'ch_1',
      subjectId: 'sub_acc',
      title: 'Retirement',
    );

    test('assesses chapter progress from topics', () {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sessions = [
        StudySession(
          id: 's_1',
          subject: 'Accountancy',
          topicId: top1.id,
          chapterId: chapter.id,
          durationSec: 2100, // 35m
          startedAt: now.subtract(const Duration(days: 1)),
          completed: true,
        ),
      ];

      final chProgress = AcademicKnowledgeEngine.assessChapterProgress(
        chapter,
        [top1, top2],
        sessions: sessions,
        referenceTime: now,
      );

      expect(chProgress.totalTopics, 2);
      expect(chProgress.studiedTopics, 1);
      expect(chProgress.completionFraction, 0.5);
      expect(chProgress.completionPercentage, 50);
      expect(chProgress.totalStudyMinutes, 35);
    });

    test('assesses subject progress and health state', () {
      final now = DateTime(2026, 9, 12, 10, 0);
      final subject = Subject(
        id: 'sub_acc',
        name: 'Accountancy',
      );
      final exam = StudentExam(
        id: 'exam_1',
        title: 'Accountancy Board Exam',
        subject: 'Accountancy',
        examDateTime: now.add(const Duration(days: 3)),
      );

      final sessions = [
        StudySession(
          id: 's_1',
          subject: 'Accountancy',
          subjectId: subject.id,
          topicId: top1.id,
          chapterId: chapter.id,
          durationSec: 1800,
          startedAt: now.subtract(const Duration(days: 1)),
          completed: true,
        ),
      ];

      final subjectProgress = AcademicKnowledgeEngine.assessSubjectProgress(
        subject,
        chapters: [chapter],
        topics: [top1, top2],
        sessions: sessions,
        exams: [exam],
        referenceTime: now,
      );

      expect(subjectProgress.totalChapters, 1);
      expect(subjectProgress.totalTopics, 2);
      expect(subjectProgress.studiedTopics, 1);
      expect(subjectProgress.syllabusPercentage, 50);
      expect(subjectProgress.health, SubjectHealthState.atRisk); // 3 days to exam with incomplete topic
      expect(subjectProgress.learningDebtCount, 1);
    });

    test('hierarchical graceful degradation with zero topics', () {
      final subject = Subject(
        id: 'sub_general',
        name: 'General Studies',
      );

      final progress = AcademicKnowledgeEngine.assessSubjectProgress(
        subject,
        chapters: const [],
        topics: const [],
        sessions: const [],
      );

      expect(progress.hasSyllabus, isFalse);
      expect(progress.totalTopics, 0);
      expect(progress.syllabusPercentage, 0);
      expect(progress.health, SubjectHealthState.onTrack);
    });
  });

  group('AcademicKnowledgeEngine - Priority & Recommendations', () {
    final topic = Topic(
      id: 'top_prio',
      chapterId: 'ch_1',
      subjectId: 'sub_law',
      title: 'Company Formation',
      importance: TopicImportance.critical,
      estimatedMinutes: 40,
    );

    test('calculates critical priority when exam approaches and topic is unstudied', () {
      // Relative now: a fixed 2026 date becomes past as wall-clock advances,
      // which flips isUpcoming and drops the critical assessment.
      final now = DateTime.now();
      final exam = StudentExam(
        id: 'exam_law',
        title: 'Law Exam',
        subject: 'sub_law',
        examDateTime: now.add(const Duration(days: 2)),
      );

      final assessment = AcademicKnowledgeEngine.assessTopicPriority(
        topic,
        exams: [exam],
        sessions: const [],
        preference: SubjectPreference.high,
        referenceTime: now,
      );

      expect(assessment.level, AcademicPriorityLevel.critical);
      expect(assessment.score, greaterThan(65.0));
      expect(assessment.reasons.any((r) => r.contains('Critical')), isTrue);
      expect(assessment.reasons.any((r) => r.contains('Exam in 2 days')), isTrue);
    });

    test('remainingTopics and neglectedTopics filtering', () {
      final now = DateTime(2026, 9, 12, 10, 0);
      final topA = Topic(id: 't_a', chapterId: 'c_1', subjectId: 'sub_1', title: 'A');
      final topB = Topic(id: 't_b', chapterId: 'c_1', subjectId: 'sub_1', title: 'B');

      final sessions = [
        StudySession(
          id: 's_b',
          subject: 'Sub',
          topicId: topB.id,
          durationSec: 1800,
          startedAt: now.subtract(const Duration(days: 9)), // neglected
          completed: true,
        ),
      ];

      final remaining = AcademicKnowledgeEngine.remainingTopics(
        'sub_1',
        topics: [topA, topB],
        sessions: sessions,
        referenceTime: now,
      );
      expect(remaining.map((t) => t.id), contains('t_a'));
      expect(remaining.map((t) => t.id), isNot(contains('t_b')));

      final neglected = AcademicKnowledgeEngine.neglectedTopics(
        'sub_1',
        topics: [topA, topB],
        sessions: sessions,
        referenceTime: now,
      );
      expect(neglected.map((t) => t.id), contains('t_b'));
    });
  });
}
