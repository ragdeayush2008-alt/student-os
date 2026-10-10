import '../../data/models/academic_calendar_event.dart';
import '../../data/models/exam.dart';
import '../../data/models/revision_record.dart';
import '../../data/models/revision_schedule.dart';
import '../../data/models/student_note.dart';
import '../../data/models/study_session.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../data/models/topic.dart';
import '../../data/models/topic_practice_attempt.dart';
import '../../features/calendar/academic_schedule_controller.dart';
import '../../features/exams/exam_controller.dart';
import '../../features/knowledge/academic_knowledge_controller.dart';
import '../../features/knowledge/topic_practice_controller.dart';
import '../../features/notes/student_note_controller.dart';
import '../../features/revision/revision_controller.dart';
import '../../features/study/study_controller.dart';
import '../../features/subjects/subject_controller.dart';
import '../../features/tasks/task_controller.dart';
import 'package:meta/meta.dart';

/// Performance snapshot aggregating historical activity for analytics.
///
/// This provides the source of truth for historical analytics calculations.
@immutable
class PerformanceSnapshot {
  const PerformanceSnapshot({
    required this.allSessions,
    required this.allTasks,
    required this.allSubjects,
    required this.allExams,
    required this.studyDates,
    this.allTopics = const [],
    this.allPracticeAttempts = const [],
    this.allRevisionRecords = const [],
    this.allRevisionSchedules = const [],
    this.allCalendarEvents = const [],
    this.allNotes = const [],
  });

  final List<StudySession> allSessions;
  final List<StudentTask> allTasks;
  final List<Subject> allSubjects;
  final List<StudentExam> allExams;
  final Set<DateTime> studyDates;
  final List<Topic> allTopics;
  final List<TopicPracticeAttempt> allPracticeAttempts;
  final List<RevisionRecord> allRevisionRecords;
  final List<RevisionSchedule> allRevisionSchedules;
  final List<AcademicCalendarEvent> allCalendarEvents;
  final List<StudentNote> allNotes;

  factory PerformanceSnapshot.fromControllers() {
    final sc = StudyController.instance;
    final tc = TaskController.instance;
    final subc = SubjectController.instance;
    final ec = ExamController.instance;
    final kc = AcademicKnowledgeController.instance;
    final pc = TopicPracticeController.instance;
    final rc = RevisionController.instance;
    final cal = AcademicScheduleController.instance;
    final nc = StudentNoteController.instance;

    final allSessions = sc.sessions;
    final allTasks = tc.tasks;
    final allSubjects = subc.subjects;
    final allExams = ec.exams;
    final allTopics = kc.topics;
    final allPracticeAttempts = pc.attempts;
    final allRevisionRecords = rc.records;
    final allRevisionSchedules = rc.schedules;
    final allCalendarEvents = cal.events;
    final allNotes = nc.allActiveNotes;

    final studyDates = allSessions
        .where((s) => s.isCompleted)
        .map((s) => s.date)
        .toSet();

    return PerformanceSnapshot(
      allSessions: allSessions,
      allTasks: allTasks,
      allSubjects: allSubjects,
      allExams: allExams,
      studyDates: studyDates,
      allTopics: allTopics,
      allPracticeAttempts: allPracticeAttempts,
      allRevisionRecords: allRevisionRecords,
      allRevisionSchedules: allRevisionSchedules,
      allCalendarEvents: allCalendarEvents,
      allNotes: allNotes,
    );
  }
}
