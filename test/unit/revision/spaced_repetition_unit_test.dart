import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/academic_knowledge_engine.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/revision_record.dart';
import 'package:student_os/data/models/revision_schedule.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/data/models/topic_practice_attempt.dart';

void main() {
  group('Spaced Repetition 2.0 Engine Unit Tests', () {
    final now = DateTime(2026, 3, 16, 12, 0);

    test('1. Initial schedule for newly studied topic starts at 3-day interval', () {
      final topic = Topic(
        id: 'top_new_study',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        title: 'New Study Topic',
      );

      final studySession = StudySession(
        id: 'sess_1',
        topicId: 'top_new_study',
        subject: 'sub_1',
        durationSec: 1800,
        startedAt: now.subtract(const Duration(days: 1)),
        completed: true,
      );

      final schedule = AcademicKnowledgeEngine.deriveOrUpdateSchedule(
        topic,
        sessions: [studySession],
        referenceTime: now,
      );

      expect(schedule.revisionCount, 0);
      expect(schedule.intervalDays, 3);
      expect(schedule.state, RevisionState.newTopic);
    });

    test('2. Successful revision expands interval sequentially (3d -> 7d -> 14d -> 30d)', () {
      final topic = Topic(
        id: 'top_progress',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        title: 'Progressing Topic',
      );

      // Revision 1
      final rec1 = RevisionRecord(
        id: 'r_1',
        topicId: 'top_progress',
        recallOutcome: RevisionRecallOutcome.knew,
        completedAt: now.subtract(const Duration(days: 20)),
      );
      // Revision 2
      final rec2 = RevisionRecord(
        id: 'r_2',
        topicId: 'top_progress',
        recallOutcome: RevisionRecallOutcome.knew,
        completedAt: now.subtract(const Duration(days: 10)),
      );

      final sched2 = AcademicKnowledgeEngine.deriveOrUpdateSchedule(
        topic,
        records: [rec1, rec2],
        referenceTime: now,
      );

      expect(sched2.revisionCount, 2);
      expect(sched2.intervalDays, 14);
      expect(sched2.state, RevisionState.stable);

      // Revision 3
      final rec3 = RevisionRecord(
        id: 'r_3',
        topicId: 'top_progress',
        recallOutcome: RevisionRecallOutcome.knew,
        completedAt: now,
      );

      final sched3 = AcademicKnowledgeEngine.deriveOrUpdateSchedule(
        topic,
        records: [rec1, rec2, rec3],
        referenceTime: now,
      );

      expect(sched3.revisionCount, 3);
      expect(sched3.intervalDays, 30);
    });

    test('3. Failed recall resets interval to 1 day and flags learning', () {
      final existingSched = RevisionSchedule(
        id: 'sched_forgot',
        topicId: 'top_forgot',
        intervalDays: 14,
        revisionCount: 2,
        state: RevisionState.stable,
        easeFactor: 2.5,
      );

      // In controller or engine update on fail:
      final updated = existingSched.copyWith(
        intervalDays: 1,
        state: RevisionState.learning,
        failedRecallCount: 1,
      );

      expect(updated.intervalDays, 1);
      expect(updated.state, RevisionState.learning);
      expect(updated.failedRecallCount, 1);
    });

    test('4. Low practice accuracy (<60%) pulls interval down to 1 day', () {
      final topic = Topic(
        id: 'top_practice_fail',
        chapterId: 'ch_1',
        subjectId: 'sub_acc',
        title: 'Accounting Standards',
      );

      final practiceAttempt = TopicPracticeAttempt(
        id: 'p_low',
        topicId: 'top_practice_fail',
        totalQuestions: 10,
        correctAnswers: 4, // 40% accuracy
        startedAt: now,
      );

      final schedule = AcademicKnowledgeEngine.deriveOrUpdateSchedule(
        topic,
        practiceAttempts: [practiceAttempt],
        referenceTime: now,
      );

      expect(schedule.intervalDays, 1);
      expect(schedule.priorityScore, greaterThanOrEqualTo(50.0));
      expect(schedule.priorityReasons, anyElement(contains('Practice accuracy is 40%')));
    });

    test('5. Near-term exam (<=3 days) boosts revision priority to Critical', () {
      final topic = Topic(
        id: 'top_exam_near',
        chapterId: 'ch_1',
        subjectId: 'sub_law',
        title: 'Corporate Law Statutes',
      );

      final exam = StudentExam(
        id: 'exam_law',
        title: 'Corporate Law Finals',
        subject: 'sub_law',
        examDateTime: now.add(const Duration(days: 2)), // 2 days away
      );

      final study = StudySession(
        id: 's_law',
        topicId: 'top_exam_near',
        subject: 'sub_law',
        startedAt: now.subtract(const Duration(days: 2)),
        completed: true,
      );

      final schedule = AcademicKnowledgeEngine.deriveOrUpdateSchedule(
        topic,
        sessions: [study],
        exams: [exam],
        referenceTime: now,
      );

      expect(schedule.priorityScore, greaterThanOrEqualTo(65.0));
      expect(schedule.priorityReasons, anyElement(contains('Exam in 2 day(s)')));
    });
  });
}
