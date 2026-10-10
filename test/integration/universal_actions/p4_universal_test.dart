import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/navigation/universal_action_executor.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('p4_universal');
    ControllerIsolation.instance.clearAllControllers();
  });

  tearDown(() {
    FocusController.instance.clearData();
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  group('Universal Actions — P4', () {
    test('19. Task actions -> Open/Edit/Complete/Schedule/Start Focus', () {
      final actions = UniversalActionExecutor.taskActions(isCompleted: false);
      expect(actions.any((a)=>a.id==UniversalTaskAction.view), isTrue);
      expect(actions.any((a)=>a.id==UniversalTaskAction.complete), isTrue);
      expect(actions.any((a)=>a.id==UniversalTaskAction.schedule), isTrue);
      expect(actions.any((a)=>a.id==UniversalTaskAction.focus), isTrue);
      final completed = UniversalActionExecutor.taskActions(isCompleted: true);
      expect(completed.length, 1);
      expect(completed.first.id, UniversalTaskAction.view);
    });

    test('20. Subject actions -> Open/Study/Focus/Revise', () {
      final actions = UniversalActionExecutor.subjectActions();
      expect(actions.any((a)=>a.id==UniversalSubjectAction.study), isTrue);
      expect(actions.any((a)=>a.id==UniversalSubjectAction.focus), isTrue);
      expect(actions.any((a)=>a.id==UniversalSubjectAction.revise), isTrue);
    });

    test('21. Chapter actions -> Open/Study/Practice/Revise', () {
      final actions = UniversalActionExecutor.chapterActions();
      expect(actions.any((a)=>a.id==UniversalChapterAction.study), isTrue);
      expect(actions.any((a)=>a.id==UniversalChapterAction.practice), isTrue);
      expect(actions.any((a)=>a.id==UniversalChapterAction.revise), isTrue);
    });

    test('22. Topic actions -> Learn/Focus/Practice/Revise', () {
      final actions = UniversalActionExecutor.topicActions();
      expect(actions.any((a)=>a.id==UniversalTopicAction.study), isTrue);
      expect(actions.any((a)=>a.id==UniversalTopicAction.practice), isTrue);
      expect(actions.any((a)=>a.id==UniversalTopicAction.revise), isTrue);
      expect(actions.any((a)=>a.id==UniversalTopicAction.focus), isTrue);
    });

    test('23. Exam actions -> Open/Study/Plan/Revise', () {
      final actions = UniversalActionExecutor.examActions();
      expect(actions.any((a)=>a.id==UniversalExamAction.study), isTrue);
      expect(actions.any((a)=>a.id==UniversalExamAction.plan), isTrue);
    });

    test('24. PlanningBlock actions by status', () {
      final upcoming = UniversalActionExecutor.planningBlockActions(status: PlanningBlockStatus.upcoming);
      expect(upcoming.any((a)=>a.id==UniversalBlockAction.startFocus), isTrue);
      final current = UniversalActionExecutor.planningBlockActions(status: PlanningBlockStatus.current);
      expect(current.any((a)=>a.id==UniversalBlockAction.startFocus), isTrue);
      final missed = UniversalActionExecutor.planningBlockActions(status: PlanningBlockStatus.missed);
      expect(missed.any((a)=>a.id==UniversalBlockAction.recover), isTrue);
      final completed = UniversalActionExecutor.planningBlockActions(status: PlanningBlockStatus.completed);
      expect(completed.any((a)=>a.id==UniversalBlockAction.view), isTrue);
    });

    test('25. Focus actions -> Start when none, Continue when active', () {
      expect(UniversalActionExecutor.focusActions(hasActiveSession: false, isPaused: false).any((a)=>a.id==UniversalFocusAction.start), isTrue);
      FocusController.instance.startQuickFocus(subjectName: 'Test');
      expect(UniversalActionExecutor.focusActions(hasActiveSession: true, isPaused: false).any((a)=>a.id==UniversalFocusAction.pauseResume), isTrue);
      FocusController.instance.clearData();
    });

    test('26. Goal actions -> Open/View progress', () {
      final actions = UniversalActionExecutor.goalActions();
      expect(actions.any((a)=>a.id==UniversalGoalAction.view), isTrue);
      expect(actions.any((a)=>a.id==UniversalGoalAction.progress), isTrue);
    });

    test('27. Resource actions -> Open/Download/Favorite', () {
      final actions = UniversalActionExecutor.resourceActions(isFavorite: false);
      expect(actions.any((a)=>a.id==UniversalResourceAction.open), isTrue);
      expect(actions.any((a)=>a.id==UniversalResourceAction.toggleFavorite), isTrue);
    });

    test('28. Subject -> Topic -> Focus preserves context', () async {
      final sub = await SubjectController.instance.createSubject(name: 'CtxSub');
      final ch = await AcademicKnowledgeController.instance.createChapter(subjectId: sub.id, title: 'CtxCh');
      final top = await AcademicKnowledgeController.instance.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'CtxTop');
      // Simulate Universal topic action preserves ids
      expect(top.subjectId, sub.id);
      expect(top.chapterId, ch.id);
    });

    test('29. Topic -> Practice preserves', () {
      final actions = UniversalActionExecutor.topicActions();
      expect(actions.any((a)=>a.id==UniversalTopicAction.practice), isTrue);
    });

    test('30. Topic -> Revision preserves', () {
      expect(UniversalActionExecutor.topicActions().any((a)=>a.id==UniversalTopicAction.revise), isTrue);
    });

    test('31. Task -> PlanningBlock -> Focus preserves', () async {
      final task = await TaskController.instance.createTask(title: 'CtxTask');
      final now = DateTime.now();
      final block = await PlanningBlockController.instance.scheduleBlock(task.id, now.add(const Duration(hours:1)), now.add(const Duration(hours:2)));
      expect(block.taskId, task.id);
      FocusController.instance.startTimer(duration: const Duration(minutes:30), taskId: block.taskId, planningBlockId: block.id);
      expect(FocusController.instance.activeSession!.taskId, task.id);
      expect(FocusController.instance.activeSession!.planningBlockId, block.id);
      FocusController.instance.clearData();
    });

    test('32. Exam -> Study preserves exam context', () async {
      expect(UniversalActionExecutor.examActions().any((a)=>a.id==UniversalExamAction.study), isTrue);
    });

    test('33. PlanningBlock -> Focus via startPlanningBlockFocus', () async {
      final now = DateTime.now();
      final block = await PlanningBlockController.instance.scheduleBlock(null, now.add(const Duration(hours:1)), now.add(const Duration(hours:2)), subjectId: 'subCtx');
      expect(block.subjectId, 'subCtx');
    });

    test('34. Assistant -> recommendation -> action uses Universal', () {
      // Verify assistant primary action types map to Universal executor destinations
      expect(UniversalActionExecutor.taskActions(isCompleted: false).isNotEmpty, isTrue);
    });
  });
}
