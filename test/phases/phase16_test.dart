import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/analytics/exam_preparation_engine.dart';
import 'package:student_os/core/analytics/performance_snapshot.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/task.dart';

void main() {
  group('Phase 16 — Academic Planning & Exam Mastery', () {
    final engine = const ExamPreparationEngine();

    test('Exam preparation calculates remaining work', () {
      final exam = StudentExam(
        id: 'e1',
        title: 'Law Final',
        subject: 'Law',
        examDateTime: DateTime.now().add(const Duration(days: 12)),
        syllabusItems: List.generate(
          10,
          (i) => SyllabusItem(id: 's$i', title: 'Topic $i', completed: i < 2),
        ),
      );
      final result = engine.assessExam(exam, _emptySnapshot());
      expect(result.remainingTopics, 8);
      expect(result.daysRemaining, 12);
      expect(result.urgencyLabel, isNotEmpty);
      expect(result.recommendations, isNotEmpty);
    });

    test('Critical urgency near exam with low progress', () {
      final exam = StudentExam(
        id: 'e2',
        title: 'Quick Quiz',
        subject: 'Math',
        examDateTime: DateTime.now().add(const Duration(days: 2)),
        syllabusItems: List.generate(
          5,
          (i) => SyllabusItem(id: 's$i', title: 'T$i', completed: false),
        ),
      );
      final result = engine.assessExam(exam, _emptySnapshot());
      expect(result.urgencyLabel, 'Critical');
    });

    test('Syllabus progression tracks completed vs remaining', () {
      final exam = StudentExam(
        id: 'e3',
        title: 'Midterm',
        subject: 'CS',
        examDateTime: DateTime.now().add(const Duration(days: 20)),
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'A', completed: true),
          SyllabusItem(id: 's2', title: 'B', completed: false),
        ],
      );
      final result = engine.assessExam(exam, _emptySnapshot());
      expect(result.syllabusCompleted, 1);
      expect(result.syllabusTotal, 2);
      expect(result.remainingTopics, 1);
    });

    test('Empty exam list produces safe result', () {
      final result = engine.assessExam(
        StudentExam(
          id: 'e0',
          title: 'None',
          examDateTime: null,
          syllabusItems: [],
        ),
        _emptySnapshot(),
      );
      expect(result.explanation, contains('No exam date'));
    });

    test('Linked task integration works', () {
      final exam = StudentExam(
        id: 'e4',
        title: 'Exam',
        subject: 'Bio',
        examDateTime: DateTime.now().add(const Duration(days: 14)),
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'Topic', completed: true),
        ],
      );
      final snapshot = PerformanceSnapshot(
        allSessions: [],
        allTasks: [
          StudentTask(
            id: 't1',
            title: 'Prep',
            examId: 'e4',
            status: TaskStatus.active,
          ),
        ],
        allSubjects: [],
        allExams: [],
        studyDates: {},
      );
      final result = engine.assessExam(exam, snapshot);
      expect(result.linkedTaskCount, 1);
      expect(result.uncompletedLinkedTasks, 1);
    });

    test('Recent study minutes reflected', () {
      final exam = StudentExam(
        id: 'e5',
        title: 'Study Exam',
        subject: 'Physics',
        examDateTime: DateTime.now().add(const Duration(days: 10)),
        syllabusItems: [],
      );
      final now = DateTime.now();
      final snapshot = PerformanceSnapshot(
        allSessions: [
          StudySession(
            id: 's1',
            subject: 'Physics',
            durationSec: 3600,
            startedAt: now.subtract(const Duration(days: 2)),
          ),
        ],
        allTasks: [],
        allSubjects: [],
        allExams: [],
        studyDates: {},
      );
      final result = engine.assessExam(exam, snapshot);
      expect(result.recentStudyMinutes, 60);
    });

    test('Recommended next action is deterministic', () {
      final exam = StudentExam(
        id: 'e6',
        title: 'Final',
        examDateTime: DateTime.now().add(const Duration(days: 5)),
        syllabusItems: [SyllabusItem(id: 's1', title: 'T', completed: false)],
      );
      final action = engine.recommendedNextAction(exam);
      expect(action, isNotEmpty);
      expect(action.contains('syllabus') || action.contains('study'), isTrue);
    });
  });
}

PerformanceSnapshot _emptySnapshot() => PerformanceSnapshot(
  allSessions: [],
  allTasks: [],
  allSubjects: [],
  allExams: [],
  studyDates: {},
);
