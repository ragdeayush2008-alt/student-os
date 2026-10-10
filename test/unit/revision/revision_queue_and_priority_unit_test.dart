import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/academic_knowledge_engine.dart';
import 'package:student_os/data/models/academic_resource.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/revision_schedule.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/data/models/topic_practice_attempt.dart';

void main() {
  group('Revision Queue and Priority Unit Tests', () {
    final now = DateTime(2026, 3, 16, 12, 0);

    test('1. buildRevisionQueue orders overdue and due items first without duplicates', () {
      final subject = Subject(id: 'sub_acc', name: 'Accounting');

      final topicOverdue = Topic(
        id: 'top_overdue',
        chapterId: 'ch_1',
        subjectId: 'sub_acc',
        title: 'Overdue Topic',
      );
      final topicDue = Topic(
        id: 'top_due',
        chapterId: 'ch_1',
        subjectId: 'sub_acc',
        title: 'Due Topic',
      );
      final topicUpcoming = Topic(
        id: 'top_upcoming',
        chapterId: 'ch_1',
        subjectId: 'sub_acc',
        title: 'Upcoming Topic',
      );
      final topicUnstudied = Topic(
        id: 'top_unstudied',
        chapterId: 'ch_1',
        subjectId: 'sub_acc',
        title: 'Unstudied Topic',
      );

      final studyOverdue = StudySession(
        id: 's_overdue',
        topicId: 'top_overdue',
        subject: 'sub_acc',
        startedAt: now.subtract(const Duration(days: 10)),
        completed: true,
      );
      final studyDue = StudySession(
        id: 's_due',
        topicId: 'top_due',
        subject: 'sub_acc',
        startedAt: now.subtract(const Duration(days: 4)),
        completed: true,
      );
      final studyUpcoming = StudySession(
        id: 's_up',
        topicId: 'top_upcoming',
        subject: 'sub_acc',
        startedAt: now.subtract(const Duration(days: 1)),
        completed: true,
      );

      final queue = AcademicKnowledgeEngine.buildRevisionQueue(
        topics: [topicOverdue, topicDue, topicUpcoming, topicUnstudied],
        subjects: [subject],
        sessions: [studyOverdue, studyDue, studyUpcoming],
        referenceTime: now,
      );

      // Unstudied topic should NOT be in revision queue
      expect(queue.any((i) => i.topicId == 'top_unstudied'), isFalse);
      expect(queue.length, 3);

      // Verify no duplicates
      final ids = queue.map((i) => i.topicId).toSet();
      expect(ids.length, queue.length);

      // Verify overdue is first
      expect(queue.first.topicId, 'top_overdue');
      expect(queue.first.isOverdue, isTrue);
    });

    test('2. generateWhyReviseExplanation produces student-friendly evidence bullets', () {
      final topic = Topic(
        id: 'top_taxes',
        chapterId: 'ch_1',
        subjectId: 'sub_acc',
        title: 'Direct Taxation',
        importance: TopicImportance.critical,
      );

      final study = StudySession(
        id: 's_tax',
        topicId: 'top_taxes',
        subject: 'sub_acc',
        startedAt: now.subtract(const Duration(days: 6)),
        completed: true,
      );

      final practice = TopicPracticeAttempt(
        id: 'p_tax',
        topicId: 'top_taxes',
        totalQuestions: 10,
        correctAnswers: 5, // 50% accuracy
        startedAt: now.subtract(const Duration(days: 1)),
      );

      final exam = StudentExam(
        id: 'exam_tax',
        title: 'Taxation Final',
        subject: 'sub_acc',
        examDateTime: now.add(const Duration(days: 4)),
      );

      final reasons = AcademicKnowledgeEngine.generateWhyReviseExplanation(
        topic,
        sessions: [study],
        practiceAttempts: [practice],
        exams: [exam],
        referenceTime: now,
      );

      expect(reasons.length, greaterThanOrEqualTo(3));
      expect(reasons, anyElement(contains('Practice accuracy is 50%')));
      expect(reasons, anyElement(contains('Upcoming exam in 4 days')));
      expect(reasons, anyElement(contains('Critical syllabus topic')));
    });

    test('3. Revision-tagged resources are seamlessly integrated into queue', () {
      final resource = AcademicResource(
        id: 'res_rev_1',
        title: 'Formula Cheat Sheet',
        subjectId: 'sub_math',
        resourceType: ResourceType.revision,
        tags: ['revision', 'formulas'],
        lastAccessedAt: now.subtract(const Duration(days: 8)),
      );

      final queue = AcademicKnowledgeEngine.buildRevisionQueue(
        topics: [],
        resources: [resource],
        referenceTime: now,
      );

      expect(queue.length, 1);
      expect(queue.first.title, 'Formula Cheat Sheet');
      expect(queue.first.resource, isNotNull);
      expect(queue.first.dueCategory, RevisionDueCategory.dueToday);
    });
  });
}
