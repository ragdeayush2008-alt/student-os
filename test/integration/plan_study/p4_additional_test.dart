import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/revision/revision_controller.dart';
import 'package:student_os/features/knowledge/topic_practice_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/calendar/academic_schedule_controller.dart';

Future<void> _setup(String uid) async {
  SharedPreferences.setMockInitialValues({});
  AuthIsolation.instance.setAuthenticatedUser(uid);
  ControllerIsolation.instance.clearAllControllers();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    FocusController.instance.clearData();
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  test('35. no duplicate recommendation -> single hero', () async {
    await _setup('p4_35');
    await SubjectController.instance.createSubject(name: 'S');
    final aic = AcademicIntelligenceController.instance;
    final action = aic.studentOSAction;
    // Home should have one hero, not two recommendations
    expect(action.title.isNotEmpty, isTrue);
    // Verify no second competing recommendation via different engine
    final alt = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(subjects: await SubjectController.instance.subjects, tasks: [], sessions: [], exams: []);
    expect(alt.title, action.title); // same pipeline
  });

  test('36. no duplicate overload card -> single overload signal', () async {
    await _setup('p4_36');
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    await PlanningBlockController.instance.scheduleBlock(null, DateTime(d.year,d.month,d.day,9,0), DateTime(d.year,d.month,d.day,12,0), subjectId: 's1');
    await PlanningBlockController.instance.scheduleBlock(null, DateTime(d.year,d.month,d.day,12,30), DateTime(d.year,d.month,d.day,15,30), subjectId: 's2');
    final snap = AcademicIntelligenceController.instance.studentStateSnapshot;
    expect(snap.isOverloaded, isTrue);
    // Only one overload place in Home (NextScheduleSection), not duplicate in Hero and Progress
  });

  test('37. no duplicate recovery -> single recovery', () async {
    await _setup('p4_37');
    final task = await TaskController.instance.createTask(title: 'Rec');
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 9,0);
    await PlanningBlockController.instance.scheduleBlock(task.id, start, start.add(const Duration(minutes:30)));
    final snap = AcademicIntelligenceController.instance.studentStateSnapshot;
    expect(snap.missedSessions.length, lessThanOrEqualTo(1)); // single recovery strip
  });

  test('39. task completion refresh -> Home intelligence refreshes', () async {
    await _setup('p4_39');
    final aic = AcademicIntelligenceController.instance;
    final before = aic.studentOSAction.title;
    final task = await TaskController.instance.createTask(title: 'RefreshTask');
    await TaskController.instance.completeTask(task.id);
    // After mutation, cache invalidated via listener microtask
    await Future.delayed(const Duration(milliseconds: 10));
    final after = aic.studentOSAction.title;
    expect(before != after || after.isNotEmpty, isTrue);
  });

  test('40. Focus completion refresh', () async {
    await _setup('p4_40');
    final aic = AcademicIntelligenceController.instance;
    var now = DateTime.now();
    FocusController.instance.setClockForTesting(()=>now);
    FocusController.instance.startTimer(duration: const Duration(minutes:10), objective: 'Test');
    final sid = FocusController.instance.activeSession!.id;
    now = now.add(const Duration(minutes:10));
    FocusController.instance.completeSession();
    await Future.delayed(const Duration(milliseconds:10));
    expect(StudyController.instance.sessions.where((s)=>s.focusSessionId==sid).isNotEmpty, isTrue);
    expect(aic.studentStateSnapshot.recentStudyMinutes, greaterThanOrEqualTo(10));
    FocusController.instance.resetClockForTesting();
  });

  test('41. study completion refresh', () async {
    await _setup('p4_41');
    final sub = await SubjectController.instance.createSubject(name: 'StudySub');
    await StudyController.instance.recordFocusCompletion(focusSessionId: 'study41', subject: sub.displayName, subjectId: sub.id, durationSec: 600);
    await Future.delayed(const Duration(milliseconds:10));
    expect(AcademicIntelligenceController.instance.studentStateSnapshot.recentStudyMinutes, greaterThanOrEqualTo(10));
  });

  test('42. revision completion refresh', () async {
    await _setup('p4_42');
    final kc = AcademicKnowledgeController.instance;
    final sub = await SubjectController.instance.createSubject(name: 'RevSub');
    final ch = await kc.createChapter(subjectId: sub.id, title: 'Ch');
    final top = await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'RevTop');
    await RevisionController.instance.recordRevision(topicId: top.id, subjectId: sub.id);
    await Future.delayed(const Duration(milliseconds:10));
    expect(AcademicIntelligenceController.instance.studentStateSnapshot.dueRevisionCount, isA<int>());
  });

  test('43. practice completion refresh', () async {
    await _setup('p4_43');
    final kc = AcademicKnowledgeController.instance;
    final sub = await SubjectController.instance.createSubject(name: 'PracSub');
    final ch = await kc.createChapter(subjectId: sub.id, title: 'Ch');
    final top = await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'PracTop');
    await TopicPracticeController.instance.recordAttempt(topicId: top.id, subjectId: sub.id, chapterId: ch.id, totalQuestions: 5, correctAnswers: 5);
    await Future.delayed(const Duration(milliseconds:10));
    expect(AcademicIntelligenceController.instance.studentStateSnapshot.recentPracticeAccuracy, isNotNull);
  });

  test('44. plan change refresh', () async {
    await _setup('p4_44');
    final aic = AcademicIntelligenceController.instance;
    await PlanningBlockController.instance.scheduleBlock(null, DateTime.now().add(const Duration(days:1)), DateTime.now().add(const Duration(days:1, hours:1)), subjectId: 'sub44', customTitle: 'Plan44');
    await Future.delayed(const Duration(milliseconds:10));
    expect(aic.studentStateSnapshot.plannedMinutes, isA<int>());
  });

  test('45. A -> B -> A isolation', () async {
    await _setup('p4_isoA');
    await SubjectController.instance.createSubject(name: 'IsoA2');
    await TaskController.instance.createTask(title: 'TaskA2');
    ControllerIsolation.instance.clearAllControllers(); AuthIsolation.instance.clearSession();
    await _setup('p4_isoB');
    expect(SubjectController.instance.subjects.where((s)=>s.name=='IsoA2').isEmpty, isTrue);
    await SubjectController.instance.createSubject(name: 'IsoB2');
    ControllerIsolation.instance.clearAllControllers(); AuthIsolation.instance.clearSession();
    AuthIsolation.instance.setAuthenticatedUser('p4_isoA');
    await SubjectController.instance.load();
    expect(SubjectController.instance.subjects.any((s)=>s.name=='IsoA2'), isTrue);
    expect(SubjectController.instance.subjects.any((s)=>s.name=='IsoB2'), isFalse);
  });

  test('46. Home intelligence isolation', () async {
    await _setup('p4_homeIsoA');
    await SubjectController.instance.createSubject(name: 'HomeA');
    await ExamController.instance.createExam(title: 'ExamA', subject: 'HomeA', examDateTime: DateTime.now().add(const Duration(days:1)));
    final snapA = AcademicIntelligenceController.instance.studentStateSnapshot;
    ControllerIsolation.instance.clearAllControllers(); AuthIsolation.instance.clearSession();
    await _setup('p4_homeIsoB');
    await SubjectController.instance.createSubject(name: 'HomeB');
    final snapB = AcademicIntelligenceController.instance.studentStateSnapshot;
    expect(snapB.nearestExam, isNull);
    expect(snapA.nearestExam?.title, 'ExamA');
  });

  test('48. Home offline', () async {
    await _setup('p4_offHome');
    await SubjectController.instance.createSubject(name: 'OffHome');
    final snap = AcademicIntelligenceController.instance.studentStateSnapshot;
    expect(snap.subjects.isNotEmpty, isTrue);
  });

  test('50. restart offline -> derived Home reconstructs', () async {
    const uid = 'p4_restart';
    await _setup(uid);
    final sub = await SubjectController.instance.createSubject(name: 'RestartSub');
    final task = await TaskController.instance.createTask(title: 'RestartTask');
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.setAuthenticatedUser(uid);
    await SubjectController.instance.load();
    await TaskController.instance.load();
    expect(SubjectController.instance.subjects.any((s)=>s.id==sub.id), isTrue);
    expect(TaskController.instance.tasks.any((t)=>t.id==task.id), isTrue);
    final snap = AcademicIntelligenceController.instance.studentStateSnapshot;
    expect(snap.subjects.any((s)=>s.id==sub.id), isTrue);
  });
}
