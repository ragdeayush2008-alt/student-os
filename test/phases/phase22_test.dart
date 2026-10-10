import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/analytics/revision_priority_engine.dart';
import 'package:student_os/core/analytics/performance_snapshot.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/study_session.dart';

void main() {
  group('Phase 22 — Revision, Practice & Weak-Area System', () {
    final engine = const RevisionPriorityEngine();

    test('Revision priority critical near exam with incomplete syllabus', () {
      final exam = StudentExam(
        id: 'e1',
        title: 'Law Exam',
        subject: 'Law',
        examDateTime: DateTime.now().add(const Duration(days: 3)),
        syllabusItems: List.generate(
          8,
          (i) => SyllabusItem(id: 's$i', title: 'T$i', completed: i < 2),
        ),
      );
      final result = engine.assessRevision(
        exam,
        PerformanceSnapshot(
          allSessions: [],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        ),
      );
      expect(result.priorityLabel, 'Critical');
      expect(result.needsRevision, isTrue);
      expect(result.remainingTopics, 6);
    });

    test('Revision priority medium with moderate time and some progress', () {
      final exam = StudentExam(
        id: 'e2',
        title: 'Midterm',
        subject: 'CS',
        examDateTime: DateTime.now().add(const Duration(days: 10)),
        syllabusItems: List.generate(
          5,
          (i) => SyllabusItem(id: 's$i', title: 'T$i', completed: i < 3),
        ),
      );
      final result = engine.assessRevision(
        exam,
        PerformanceSnapshot(
          allSessions: [],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        ),
      );
      expect(result.priorityLabel, 'Medium');
      expect(result.explanation, contains('10'));
    });

    test('Revision needs attention when topic incomplete and exam close', () {
      final exam = StudentExam(
        id: 'e3',
        title: 'Quiz',
        subject: 'Bio',
        examDateTime: DateTime.now().add(const Duration(days: 5)),
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'Topic', completed: false),
        ],
      );
      final result = engine.assessRevision(
        exam,
        PerformanceSnapshot(
          allSessions: [],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        ),
      );
      expect(result.needsRevision, isTrue);
      expect(result.recommendations, isNotEmpty);
    });

    test('Insufficient data produces safe explanation', () {
      final exam = StudentExam(
        id: 'e4',
        title: 'No Exam',
        examDateTime: null,
        syllabusItems: [],
      );
      final result = engine.assessRevision(
        exam,
        PerformanceSnapshot(
          allSessions: [],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        ),
      );
      expect(result.priorityLabel, anyOf('Scheduled', 'Medium'));
      expect(result.explanation, isNotEmpty);
    });

    test('Recent study reduces urgency when progress high', () {
      final now = DateTime.now();
      final exam = StudentExam(
        id: 'e5',
        title: 'Advanced',
        subject: 'Physics',
        examDateTime: now.add(const Duration(days: 14)),
        syllabusItems: List.generate(
          4,
          (i) => SyllabusItem(id: 's$i', title: 'T$i', completed: true),
        ),
      );
      final result = engine.assessRevision(
        exam,
        PerformanceSnapshot(
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
        ),
      );
      expect(result.priorityLabel, 'Scheduled');
      expect(result.needsRevision, isFalse);
    });
  });
}
