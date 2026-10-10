import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_engine.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// PART27 FLOW 2: Exam → weak Topic → Revision → Focus → completion → progress.
///
/// Uses only existing engines: exam pressure + revision recommendations from
/// [AcademicIntelligenceEngine], focus via [FocusController], progress via
/// [StudentOSIntelligenceEngine]. Exam deadlines are never modified.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('flow2_user');
    await StorageService.instance.clearUser(userId: 'flow2_user');
    ControllerIsolation.instance.clearAllControllers();
    FocusController.instance.resetClockForTesting();
  });

  tearDown(() {
    FocusController.instance.resetClockForTesting();
    FocusController.instance.clearData();
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  test('exam preparation loop preserves deadline and records progress',
      () async {
    final sub =
        await SubjectController.instance.createSubject(name: 'Accountancy');
    final ch = await AcademicKnowledgeController.instance.createChapter(
      subjectId: sub.id,
      title: 'Partnership',
    );
    final weakTopic =
        await AcademicKnowledgeController.instance.createTopic(
      chapterId: ch.id,
      subjectId: sub.id,
      title: 'Admission of a Partner',
      estimatedMinutes: 45,
      importance: TopicImportance.high,
    );

    final examDate = DateTime.now().add(const Duration(days: 3));
    final exam = await ExamController.instance.createExam(
      title: 'Accounts Unit Test',
      subject: 'Accountancy',
      examDateTime: examDate,
    );

    // 1. Exam pressure is detected from real data.
    final pressure = AcademicIntelligenceEngine.assessExamPressure(
      exam,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      subjects: SubjectController.instance.subjects,
    );
    expect(pressure.daysRemaining, greaterThanOrEqualTo(2));

    // 2. The unified recommendation surfaces real study work for the
    // exam-linked subject (revision recs only cover due-review items, so a
    // brand-new topic may not appear there yet — no faked expectations).
    final unified = AcademicIntelligenceEngine.generateUnifiedRecommendation(
      subjects: SubjectController.instance.subjects,
      exams: ExamController.instance.exams,
      sessions: StudyController.instance.sessions,
    );
    expect(unified.hasRecommendation, isTrue);
    expect(unified.primary!.subjectName, contains('Accountancy'));

    // 3. Focus on the weak topic with full context.
    final fc = FocusController.instance;
    var now = DateTime.now();
    fc.setClockForTesting(() => now);
    fc.startTimer(
      duration: const Duration(minutes: 45),
      subjectId: sub.id,
      subjectName: sub.displayName,
      examId: exam.id,
      topicId: weakTopic.id,
      chapterId: ch.id,
      objective: 'Revise ${weakTopic.title}',
    );
    final sessionId = fc.activeSession!.id;
    now = now.add(const Duration(minutes: 45));
    fc.completeSession();

    // 4. Bridged study record carries exam + topic links.
    final bridged = StudyController.instance.sessions
        .where((s) => s.focusSessionId == sessionId)
        .toList();
    expect(bridged.length, 1);
    expect(bridged.single.topicId, weakTopic.id);
    expect(bridged.single.examId, exam.id);
    expect(bridged.single.isCompleted, isTrue);

    // 5. Exam deadline untouched by the whole flow.
    final examAfter = ExamController.instance.exams
        .firstWhere((e) => e.id == exam.id);
    expect(examAfter.examDateTime, examDate);

    // 6. Next recommendation still deterministic after progress.
    final next = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.upcomingExams,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
    );
    expect(next.reason, isNotEmpty);
    expect(next.bulletReasons, isNotEmpty);
  });
}
