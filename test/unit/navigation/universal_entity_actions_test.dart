import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/navigation/universal_action_executor.dart';
import 'package:student_os/features/planning/models/planning_block.dart';

PlanningBlock _block(DateTime start, DateTime end) {
  return PlanningBlock(
    id: 'pb_${start.millisecondsSinceEpoch}',
    userId: 'u1',
    subjectId: 's1',
    startAt: start,
    endAt: end,
  );
}

void main() {
  group('Universal entity actions (CODE 5)', () {
    test('Task actions: active exposes START/SCHEDULE/FOCUS/EDIT/COMPLETE/RESCHEDULE/VIEW', () {
      final actions = UniversalActionExecutor.taskActions(isCompleted: false);
      final ids = actions.map((a) => a.id).toSet();
      expect(
        ids,
        containsAll([
          UniversalTaskAction.start,
          UniversalTaskAction.schedule,
          UniversalTaskAction.focus,
          UniversalTaskAction.edit,
          UniversalTaskAction.complete,
          UniversalTaskAction.reschedule,
          UniversalTaskAction.view,
        ]),
      );
      expect(actions.length, equals(7));
    });

    test('Task actions: completed exposes VIEW only (no auto-mutate)', () {
      final actions = UniversalActionExecutor.taskActions(isCompleted: true);
      expect(actions.map((a) => a.id).toList(),
          equals([UniversalTaskAction.view]));
    });

    test('Subject actions expose STUDY/REVISE/FOCUS/TIMER/STOPWATCH/VIEW SYLLABUS', () {
      final ids =
          UniversalActionExecutor.subjectActions().map((a) => a.id).toSet();
      expect(
        ids,
        containsAll([
          UniversalSubjectAction.study,
          UniversalSubjectAction.revise,
          UniversalSubjectAction.focus,
          UniversalSubjectAction.timer,
          UniversalSubjectAction.stopwatch,
          UniversalSubjectAction.viewSyllabus,
        ]),
      );
    });

    test('Topic actions expose STUDY/REVISE/FOCUS/TIMER/STOPWATCH/VIEW', () {
      final ids =
          UniversalActionExecutor.topicActions().map((a) => a.id).toSet();
      expect(
        ids,
        containsAll([
          UniversalTopicAction.study,
          UniversalTopicAction.revise,
          UniversalTopicAction.focus,
          UniversalTopicAction.timer,
          UniversalTopicAction.stopwatch,
          UniversalTopicAction.view,
        ]),
      );
    });

    test('Exam actions expose STUDY/REVISE/PLAN/FOCUS/VIEW', () {
      final ids = UniversalActionExecutor.examActions().map((a) => a.id).toSet();
      expect(
        ids,
        containsAll([
          UniversalExamAction.study,
          UniversalExamAction.revise,
          UniversalExamAction.plan,
          UniversalExamAction.focus,
          UniversalExamAction.view,
        ]),
      );
    });

    test('PlanningBlock UPCOMING exposes START FOCUS/VIEW/RESCHEDULE/SKIP/UNSCHEDULE', () {
      final ids = UniversalActionExecutor.planningBlockActions(
        status: PlanningBlockStatus.upcoming,
      ).map((a) => a.id).toSet();
      expect(
        ids,
        containsAll([
          UniversalBlockAction.startFocus,
          UniversalBlockAction.view,
          UniversalBlockAction.reschedule,
          UniversalBlockAction.skip,
          UniversalBlockAction.unschedule,
        ]),
      );
    });

    test('PlanningBlock CURRENT exposes START FOCUS + VIEW only', () {
      final ids = UniversalActionExecutor.planningBlockActions(
        status: PlanningBlockStatus.current,
      ).map((a) => a.id).toList();
      expect(
        ids,
        equals([UniversalBlockAction.startFocus, UniversalBlockAction.view]),
      );
    });

    test('PlanningBlock COMPLETED exposes VIEW only', () {
      final ids = UniversalActionExecutor.planningBlockActions(
        status: PlanningBlockStatus.completed,
      ).map((a) => a.id).toList();
      expect(ids, equals([UniversalBlockAction.view]));
    });

    test('PlanningBlock MISSED exposes RECOVER/RESCHEDULE/VIEW', () {
      final ids = UniversalActionExecutor.planningBlockActions(
        status: PlanningBlockStatus.missed,
      ).map((a) => a.id).toSet();
      expect(
        ids,
        containsAll([
          UniversalBlockAction.recover,
          UniversalBlockAction.reschedule,
          UniversalBlockAction.view,
        ]),
      );
    });

    test('Resource actions adapt favorite label', () {
      final fav =
          UniversalActionExecutor.resourceActions(isFavorite: true);
      final notFav =
          UniversalActionExecutor.resourceActions(isFavorite: false);
      expect(fav.map((a) => a.id),
          contains(UniversalResourceAction.toggleFavorite));
      expect(fav.firstWhere((a) => a.id == UniversalResourceAction.toggleFavorite).label,
          equals('Unfavorite'));
      expect(notFav.firstWhere((a) => a.id == UniversalResourceAction.toggleFavorite).label,
          equals('Favorite'));
    });

    test('Goal actions expose VIEW/PLAN/PROGRESS', () {
      final ids = UniversalActionExecutor.goalActions().map((a) => a.id).toSet();
      expect(
        ids,
        containsAll([
          UniversalGoalAction.view,
          UniversalGoalAction.plan,
          UniversalGoalAction.progress,
        ]),
      );
    });

    test('Focus actions: no session exposes START only', () {
      final ids = UniversalActionExecutor.focusActions(
        hasActiveSession: false,
        isPaused: false,
      ).map((a) => a.id).toList();
      expect(ids, equals([UniversalFocusAction.start]));
    });

    test('Focus actions: active exposes CONTINUE/PAUSE/END', () {
      final actions = UniversalActionExecutor.focusActions(
        hasActiveSession: true,
        isPaused: false,
      );
      final ids = actions.map((a) => a.id).toSet();
      expect(
        ids,
        containsAll([
          UniversalFocusAction.continueSession,
          UniversalFocusAction.pauseResume,
          UniversalFocusAction.end,
        ]),
      );
      expect(
        actions
            .firstWhere((a) => a.id == UniversalFocusAction.pauseResume)
            .label,
        equals('Pause'),
      );
    });

    test('Focus actions: paused session shows Resume', () {
      final actions = UniversalActionExecutor.focusActions(
        hasActiveSession: true,
        isPaused: true,
      );
      expect(
        actions
            .firstWhere((a) => a.id == UniversalFocusAction.pauseResume)
            .label,
        equals('Resume'),
      );
    });

    group('derivePlanningBlockStatus', () {
      final ref = DateTime(2026, 9, 15, 12, 0);

      test('UPCOMING when now before start', () {
        final b = _block(
          DateTime(2026, 9, 15, 14, 0),
          DateTime(2026, 9, 15, 15, 0),
        );
        expect(
          UniversalActionExecutor.derivePlanningBlockStatus(b, referenceTime: ref),
          equals(PlanningBlockStatus.upcoming),
        );
      });

      test('CURRENT when now inside block', () {
        final b = _block(
          DateTime(2026, 9, 15, 11, 0),
          DateTime(2026, 9, 15, 13, 0),
        );
        expect(
          UniversalActionExecutor.derivePlanningBlockStatus(b, referenceTime: ref),
          equals(PlanningBlockStatus.current),
        );
      });

      test('COMPLETED when linked task completed', () {
        final b = _block(
          DateTime(2026, 9, 15, 6, 0),
          DateTime(2026, 9, 15, 7, 0),
        );
        expect(
          UniversalActionExecutor.derivePlanningBlockStatus(
            b,
            linkedTaskCompleted: true,
            referenceTime: ref,
          ),
          equals(PlanningBlockStatus.completed),
        );
      });

      test('MISSED when block ended and task incomplete', () {
        final b = _block(
          DateTime(2026, 9, 15, 6, 0),
          DateTime(2026, 9, 15, 7, 0),
        );
        expect(
          UniversalActionExecutor.derivePlanningBlockStatus(b, referenceTime: ref),
          equals(PlanningBlockStatus.missed),
        );
      });

      test('SKIPPED when explicitly skipped', () {
        final b = _block(
          DateTime(2026, 9, 15, 6, 0),
          DateTime(2026, 9, 15, 7, 0),
        );
        expect(
          UniversalActionExecutor.derivePlanningBlockStatus(
            b,
            isSkipped: true,
            referenceTime: ref,
          ),
          equals(PlanningBlockStatus.skipped),
        );
      });
    });
  });
}
