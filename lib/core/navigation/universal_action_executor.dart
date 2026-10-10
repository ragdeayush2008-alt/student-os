import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../core/assistant/assistant_launch_context.dart';
import '../../core/intelligence/student_os_intelligence_engine.dart';
import '../../features/focus/controller/focus_controller.dart';
import '../../features/planning/controllers/planning_block_controller.dart';
import '../../features/planning/models/planning_block.dart';
import '../../features/planning/widgets/daily_plan_sheet.dart';
import '../../features/tasks/presentation/task_creation_sheet.dart';
import '../../features/tasks/task_controller.dart';
import '../../features/subjects/presentation/subject_creation_sheet.dart';
import '../../features/exams/widgets/exam_creation_sheet.dart';
import '../../features/knowledge/academic_knowledge_controller.dart';
import '../../features/knowledge/presentation/practice_mode_selection_sheet.dart';
import '../../features/resources/resource_controller.dart';
import '../../features/resources/resource_creation_sheet.dart';
import '../../data/models/academic_calendar_event.dart';
import '../../data/models/academic_resource.dart';
import '../../data/models/student_note.dart';
import '../../data/models/task.dart';
import '../../features/notes/student_note_controller.dart';
import '../../features/study/study_controller.dart';
import '../../features/subjects/subject_controller.dart';
import '../../features/calendar/academic_schedule_controller.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/calendar/presentation/widgets/add_edit_event_sheet.dart';

/// Centralized executor for all Student OS actions.
///
/// Ensures consistent routing and execution behavior without duplicating
/// navigation logic across widgets.
abstract final class UniversalActionExecutor {
  /// Executes a [StudentOSAction] with the appropriate context and routing.
  static void executeAction(BuildContext context, StudentOSAction action) {
    if (action.isFocusActive) {
      AppRouter.openActiveFocusSession(context);
      return;
    }

    if (action.isDoneForToday) {
      AppRouter.openProgress(context);
      return;
    }

    switch (action.type) {
      case StudentOSActionType.focusActive:
        AppRouter.openActiveFocusSession(context);
        break;

      case StudentOSActionType.completeTask:
        if (action.taskId != null) {
          AppRouter.openTaskDetail(context, action.taskId!);
        } else {
          AppRouter.openTasks(context);
        }
        break;

      case StudentOSActionType.examPrep:
        if (action.examId != null) {
          final dur = action.suggestedDurationMinutes > 0
              ? Duration(minutes: action.suggestedDurationMinutes)
              : const Duration(minutes: 30);
          AppRouter.startContextualFocus(
            context,
            duration: dur,
            examId: action.examId,
            subjectId: action.subjectId,
            subjectName: action.subjectName,
            topicId: action.topicId,
            chapterId: action.chapterId,
            focusTitle: action.title,
          );
        } else {
          AppRouter.openExams(context);
        }
        break;

      case StudentOSActionType.reviseTopic:
        final dur = action.suggestedDurationMinutes > 0
            ? Duration(minutes: action.suggestedDurationMinutes)
            : const Duration(minutes: 20);
        AppRouter.startContextualFocus(
          context,
          duration: dur,
          subjectId: action.subjectId,
          subjectName: action.subjectName,
          examId: action.examId,
          topicId: action.topicId,
          chapterId: action.chapterId,
          focusTitle: action.title,
        );
        break;

      case StudentOSActionType.studySubject:
        if (action.subjectId != null ||
            (action.subjectName != null && action.subjectName!.isNotEmpty)) {
          final dur = action.suggestedDurationMinutes > 0
              ? Duration(minutes: action.suggestedDurationMinutes)
              : const Duration(minutes: 35);
          AppRouter.startContextualFocus(
            context,
            duration: dur,
            subjectId: action.subjectId,
            subjectName: action.subjectName,
            taskId: action.taskId,
            examId: action.examId,
            topicId: action.topicId,
            chapterId: action.chapterId,
            focusTitle: action.title,
          );
        } else {
          AppRouter.openStudy(context);
        }
        break;

      case StudentOSActionType.scheduledBlock:
        if (action.suggestedDurationMinutes > 0) {
          AppRouter.startContextualFocus(
            context,
            duration: Duration(minutes: action.suggestedDurationMinutes),
            subjectId: action.subjectId,
            subjectName: action.subjectName,
            taskId: action.taskId,
            examId: action.examId,
            topicId: action.topicId,
            chapterId: action.chapterId,
            focusTitle: action.title,
          );
        } else if (action.taskId != null) {
          AppRouter.openTaskDetail(context, action.taskId!);
        } else {
          AppRouter.openPlan(context);
        }
        break;

      case StudentOSActionType.goalWork:
        AppRouter.openGoals(context);
        break;

      case StudentOSActionType.planDay:
        AppRouter.openPlan(context);
        break;

      case StudentOSActionType.doneForToday:
        AppRouter.openProgress(context);
        break;

      case StudentOSActionType.empty:
        AppRouter.openPlan(context);
        break;
    }
  }

  /// Starts a quick focus session with prefilled context.
  /// Preserves full navigation context (subject/topic/chapter/task/exam/block).
  /// If a session is already active, routes to it instead of starting another.
  static void startQuickFocus(
    BuildContext context, {
    String? subjectName,
    String? subjectId,
    String? taskId,
    String? examId,
    String? topicId,
    String? chapterId,
    String? planningBlockId,
    String? focusTitle,
    Duration duration = const Duration(minutes: 30),
  }) {
    if (FocusController.instance.hasActiveSession) {
      AppRouter.openActiveFocusSession(context);
      return;
    }

    AppRouter.startContextualFocus(
      context,
      duration: duration,
      subjectName: subjectName,
      subjectId: subjectId,
      taskId: taskId,
      examId: examId,
      topicId: topicId,
      chapterId: chapterId,
      planningBlockId: planningBlockId,
      focusTitle: focusTitle ?? '30m Burst Focus',
    );
  }

  /// Opens the Student OS personal assistant sheet.
  static void openAssistant(
    BuildContext context, {
    String? initialQuery,
    AssistantLaunchContext launchContext = AssistantLaunchContext.global,
  }) {
    AppRouter.openAssistant(
      context,
      initialQuery: initialQuery,
      launchContext: launchContext,
    );
  }

  /// Opens the global quick creation sheet.
  static void openGlobalAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GlobalAddSheet(),
    );
  }

  /// Opens the universal action launcher.
  static void openActionLauncher(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UniversalActionLauncherSheet(),
    );
  }

  /// Opens the plan daily sheet.
  static void openPlanMyDay(BuildContext context, {DateTime? targetDay}) {
    final day = targetDay ?? DateTime.now();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DailyPlanSheet(targetDay: day),
    );
  }

  /// Opens the knowledge center.
  static void openKnowledgeCenter(
    BuildContext context, {
    String? initialSubjectId,
    String? initialTag,
  }) {
    AppRouter.openKnowledgeCenter(
      context,
      initialSubjectId: initialSubjectId,
      initialTag: initialTag,
    );
  }

  /// Opens the note editor.
  static void openCreateNote(
    BuildContext context, {
    String? subjectId,
    String? chapterId,
    String? topicId,
    String? resourceId,
  }) {
    AppRouter.openNoteEditor(
      context,
      subjectId: subjectId,
      chapterId: chapterId,
      topicId: topicId,
      resourceId: resourceId,
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // CODE 5 — ENTITY-LEVEL UNIVERSAL ACTIONS
  //
  // Every major entity exposes a consistent, context-aware action set.
  // Pure descriptor functions (no BuildContext) are unit-testable; the
  // execute* methods perform routing via AppRouter + existing controllers.
  // No competing recommendation logic lives here.
  // ════════════════════════════════════════════════════════════════════════

  /// Task actions. Completed tasks expose VIEW only (never auto-mutate).
  static List<EntityActionDescriptor> taskActions({
    required bool isCompleted,
    bool isScheduled = false,
  }) {
    if (isCompleted) {
      return const [
        EntityActionDescriptor(
            id: UniversalTaskAction.view, label: 'View', icon: Icons.visibility_outlined),
      ];
    }
    return const [
      EntityActionDescriptor(
          id: UniversalTaskAction.start, label: 'Start', icon: Icons.play_arrow_rounded),
      EntityActionDescriptor(
          id: UniversalTaskAction.schedule, label: 'Schedule', icon: Icons.calendar_today_outlined),
      EntityActionDescriptor(
          id: UniversalTaskAction.focus, label: 'Focus', icon: Icons.timer_outlined),
      EntityActionDescriptor(
          id: UniversalTaskAction.edit, label: 'Edit', icon: Icons.edit_outlined),
      EntityActionDescriptor(
          id: UniversalTaskAction.complete, label: 'Complete', icon: Icons.check_circle_outline_rounded),
      EntityActionDescriptor(
          id: UniversalTaskAction.reschedule, label: 'Reschedule', icon: Icons.update_rounded),
      EntityActionDescriptor(
          id: UniversalTaskAction.view, label: 'View', icon: Icons.visibility_outlined),
    ];
  }

  /// Subject actions.
  static List<EntityActionDescriptor> subjectActions() {
    return const [
      EntityActionDescriptor(
          id: UniversalSubjectAction.study, label: 'Study', icon: Icons.menu_book_outlined),
      EntityActionDescriptor(
          id: UniversalSubjectAction.revise, label: 'Revise', icon: Icons.replay_rounded),
      EntityActionDescriptor(
          id: UniversalSubjectAction.focus, label: 'Focus', icon: Icons.timer_outlined),
      EntityActionDescriptor(
          id: UniversalSubjectAction.timer, label: 'Timer', icon: Icons.timer_rounded),
      EntityActionDescriptor(
          id: UniversalSubjectAction.stopwatch, label: 'Stopwatch', icon: Icons.av_timer_rounded),
      EntityActionDescriptor(
          id: UniversalSubjectAction.viewSyllabus, label: 'View Syllabus', icon: Icons.list_alt_rounded),
    ];
  }

  /// Chapter actions.
  static List<EntityActionDescriptor> chapterActions() {
    return const [
      EntityActionDescriptor(
          id: UniversalChapterAction.open, label: 'Open', icon: Icons.menu_book_outlined),
      EntityActionDescriptor(
          id: UniversalChapterAction.study, label: 'Study', icon: Icons.menu_book_outlined),
      EntityActionDescriptor(
          id: UniversalChapterAction.practice, label: 'Practice', icon: Icons.quiz_outlined),
      EntityActionDescriptor(
          id: UniversalChapterAction.revise, label: 'Revise', icon: Icons.replay_rounded),
      EntityActionDescriptor(
          id: UniversalChapterAction.schedule, label: 'Schedule', icon: Icons.calendar_today_outlined),
    ];
  }

  /// Topic actions.
  static List<EntityActionDescriptor> topicActions() {
    return const [
      EntityActionDescriptor(
          id: UniversalTopicAction.study, label: 'Study', icon: Icons.menu_book_outlined),
      EntityActionDescriptor(
          id: UniversalTopicAction.practice, label: 'Practice', icon: Icons.quiz_outlined),
      EntityActionDescriptor(
          id: UniversalTopicAction.revise, label: 'Revise', icon: Icons.replay_rounded),
      EntityActionDescriptor(
          id: UniversalTopicAction.focus, label: 'Focus', icon: Icons.timer_outlined),
      EntityActionDescriptor(
          id: UniversalTopicAction.timer, label: 'Timer', icon: Icons.timer_rounded),
      EntityActionDescriptor(
          id: UniversalTopicAction.stopwatch, label: 'Stopwatch', icon: Icons.av_timer_rounded),
      EntityActionDescriptor(
          id: UniversalTopicAction.view, label: 'View', icon: Icons.visibility_outlined),
    ];
  }

  /// Exam actions.
  static List<EntityActionDescriptor> examActions() {
    return const [
      EntityActionDescriptor(
          id: UniversalExamAction.study, label: 'Study', icon: Icons.menu_book_outlined),
      EntityActionDescriptor(
          id: UniversalExamAction.revise, label: 'Revise', icon: Icons.replay_rounded),
      EntityActionDescriptor(
          id: UniversalExamAction.plan, label: 'Plan', icon: Icons.calendar_month_outlined),
      EntityActionDescriptor(
          id: UniversalExamAction.focus, label: 'Focus', icon: Icons.timer_outlined),
      EntityActionDescriptor(
          id: UniversalExamAction.view, label: 'View', icon: Icons.visibility_outlined),
    ];
  }

  /// Planning-block actions, filtered by block status.
  static List<EntityActionDescriptor> planningBlockActions({
    required PlanningBlockStatus status,
  }) {
    switch (status) {
      case PlanningBlockStatus.upcoming:
        return const [
          EntityActionDescriptor(
              id: UniversalBlockAction.startFocus, label: 'Start Focus', icon: Icons.play_arrow_rounded),
          EntityActionDescriptor(
              id: UniversalBlockAction.view, label: 'View', icon: Icons.visibility_outlined),
          EntityActionDescriptor(
              id: UniversalBlockAction.reschedule, label: 'Reschedule', icon: Icons.update_rounded),
          EntityActionDescriptor(
              id: UniversalBlockAction.skip, label: 'Skip', icon: Icons.skip_next_outlined),
          EntityActionDescriptor(
              id: UniversalBlockAction.unschedule, label: 'Unschedule', icon: Icons.event_busy_outlined),
        ];
      case PlanningBlockStatus.current:
        return const [
          EntityActionDescriptor(
              id: UniversalBlockAction.startFocus, label: 'Start Focus', icon: Icons.play_arrow_rounded),
          EntityActionDescriptor(
              id: UniversalBlockAction.view, label: 'View', icon: Icons.visibility_outlined),
        ];
      case PlanningBlockStatus.completed:
        return const [
          EntityActionDescriptor(
              id: UniversalBlockAction.view, label: 'View', icon: Icons.visibility_outlined),
        ];
      case PlanningBlockStatus.missed:
        return const [
          EntityActionDescriptor(
              id: UniversalBlockAction.recover, label: 'Recover', icon: Icons.restart_alt_rounded),
          EntityActionDescriptor(
              id: UniversalBlockAction.reschedule, label: 'Reschedule', icon: Icons.update_rounded),
          EntityActionDescriptor(
              id: UniversalBlockAction.view, label: 'View', icon: Icons.visibility_outlined),
        ];
      case PlanningBlockStatus.skipped:
        return const [
          EntityActionDescriptor(
              id: UniversalBlockAction.view, label: 'View', icon: Icons.visibility_outlined),
          EntityActionDescriptor(
              id: UniversalBlockAction.reschedule, label: 'Reschedule', icon: Icons.update_rounded),
          EntityActionDescriptor(
              id: UniversalBlockAction.unschedule, label: 'Unschedule', icon: Icons.event_busy_outlined),
        ];
    }
  }

  /// Resource actions. Favorite label adapts to current state.
  static List<EntityActionDescriptor> resourceActions({required bool isFavorite}) {
    return [
      const EntityActionDescriptor(
          id: UniversalResourceAction.open, label: 'Open', icon: Icons.open_in_new_rounded),
      const EntityActionDescriptor(
          id: UniversalResourceAction.download, label: 'Download', icon: Icons.download_outlined),
      EntityActionDescriptor(
        id: UniversalResourceAction.toggleFavorite,
        label: isFavorite ? 'Unfavorite' : 'Favorite',
        icon: isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
      ),
    ];
  }

  /// Goal actions.
  static List<EntityActionDescriptor> goalActions() {
    return const [
      EntityActionDescriptor(
          id: UniversalGoalAction.view, label: 'View', icon: Icons.visibility_outlined),
      EntityActionDescriptor(
          id: UniversalGoalAction.plan, label: 'Plan', icon: Icons.calendar_month_outlined),
      EntityActionDescriptor(
          id: UniversalGoalAction.progress, label: 'Progress', icon: Icons.insights_outlined),
    ];
  }

  /// Academic calendar event actions.
  static List<EntityActionDescriptor> calendarEventActions({required bool isFixed}) {
    return const [
      EntityActionDescriptor(
          id: UniversalCalendarEventAction.view, label: 'View', icon: Icons.visibility_outlined),
      EntityActionDescriptor(
          id: UniversalCalendarEventAction.edit, label: 'Edit', icon: Icons.edit_outlined),
      EntityActionDescriptor(
          id: UniversalCalendarEventAction.planAround, label: 'Plan Around', icon: Icons.auto_awesome_rounded),
      EntityActionDescriptor(
          id: UniversalCalendarEventAction.viewDay, label: 'View Day', icon: Icons.view_agenda_rounded),
      EntityActionDescriptor(
          id: UniversalCalendarEventAction.delete, label: 'Delete', icon: Icons.delete_outline_rounded, isDestructive: true),
    ];
  }

  /// Focus actions, filtered by session state.
  static List<EntityActionDescriptor> focusActions({
    required bool hasActiveSession,
    required bool isPaused,
  }) {
    if (!hasActiveSession) {
      return const [
        EntityActionDescriptor(
            id: UniversalFocusAction.start, label: 'Start Focus', icon: Icons.play_arrow_rounded),
      ];
    }
    return [
      const EntityActionDescriptor(
          id: UniversalFocusAction.continueSession, label: 'Continue', icon: Icons.play_arrow_rounded),
      EntityActionDescriptor(
        id: UniversalFocusAction.pauseResume,
        label: isPaused ? 'Resume' : 'Pause',
        icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
      ),
      const EntityActionDescriptor(
          id: UniversalFocusAction.end, label: 'End', icon: Icons.stop_rounded),
    ];
  }

  /// Note actions.
  static List<EntityActionDescriptor> noteActions({
    required bool isPinned,
    required bool isArchived,
    bool hasTopic = false,
  }) {
    return [
      const EntityActionDescriptor(
        id: UniversalNoteAction.open,
        label: 'Open',
        icon: Icons.visibility_outlined,
      ),
      const EntityActionDescriptor(
        id: UniversalNoteAction.edit,
        label: 'Edit',
        icon: Icons.edit_outlined,
      ),
      const EntityActionDescriptor(
        id: UniversalNoteAction.focus,
        label: 'Focus',
        icon: Icons.timer_outlined,
      ),
      const EntityActionDescriptor(
        id: UniversalNoteAction.study,
        label: 'Study',
        icon: Icons.menu_book_outlined,
      ),
      if (hasTopic) ...[
        const EntityActionDescriptor(
          id: UniversalNoteAction.practice,
          label: 'Practice',
          icon: Icons.quiz_outlined,
        ),
        const EntityActionDescriptor(
          id: UniversalNoteAction.revise,
          label: 'Revise',
          icon: Icons.replay_rounded,
        ),
      ],
      const EntityActionDescriptor(
        id: UniversalNoteAction.plan,
        label: 'Plan',
        icon: Icons.calendar_today_outlined,
      ),
      EntityActionDescriptor(
        id: UniversalNoteAction.pin,
        label: isPinned ? 'Unpin' : 'Pin',
        icon: isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
      ),
      EntityActionDescriptor(
        id: UniversalNoteAction.archive,
        label: isArchived ? 'Restore' : 'Archive',
        icon: isArchived ? Icons.unarchive_rounded : Icons.archive_outlined,
      ),
      const EntityActionDescriptor(
        id: UniversalNoteAction.delete,
        label: 'Delete',
        icon: Icons.delete_outline_rounded,
      ),
    ];
  }

  /// Derives the display status of a planning block without mutating anything.
  static PlanningBlockStatus derivePlanningBlockStatus(
    PlanningBlock block, {
    bool linkedTaskCompleted = false,
    bool isSkipped = false,
    DateTime? referenceTime,
  }) {
    if (isSkipped) return PlanningBlockStatus.skipped;
    if (linkedTaskCompleted) return PlanningBlockStatus.completed;
    final now = referenceTime ?? DateTime.now();
    if (now.isBefore(block.startAt)) return PlanningBlockStatus.upcoming;
    if (!now.isBefore(block.startAt) && now.isBefore(block.endAt)) {
      return PlanningBlockStatus.current;
    }
    return PlanningBlockStatus.missed;
  }

  // ── Entity executors (routing only, via existing AppRouter/controllers) ──

  static void executeTaskAction(
    BuildContext context,
    String actionId,
    StudentTask task,
  ) {
    switch (actionId) {
      case UniversalTaskAction.start:
      case UniversalTaskAction.view:
      case UniversalTaskAction.edit:
        AppRouter.openTaskDetail(context, task.id);
        break;
      case UniversalTaskAction.schedule:
        openPlanMyDay(context);
        break;
      case UniversalTaskAction.reschedule:
        AppRouter.openPlan(context);
        break;
      case UniversalTaskAction.focus:
        AppRouter.openFocusModeSelection(
          context,
          subjectId: task.subjectId,
          taskId: task.id,
          taskTitle: task.title,
          examId: task.examId,
          focusTitle: task.title,
          suggestedDuration: Duration(
            minutes: task.estimatedMinutes > 0 ? task.estimatedMinutes : 25,
          ),
        );
        break;
      case UniversalTaskAction.complete:
        TaskController.instance.completeTask(task.id);
        break;
    }
  }

  static void executeSubjectAction(
    BuildContext context,
    String actionId, {
    required String subjectId,
    String? subjectName,
  }) {
    switch (actionId) {
      case UniversalSubjectAction.study:
      case UniversalSubjectAction.viewSyllabus:
        AppRouter.openSubjectDetail(context, subjectId);
        break;
      case UniversalSubjectAction.revise:
        AppRouter.openRevision(context);
        break;
      case UniversalSubjectAction.focus:
        AppRouter.openFocusModeSelection(
          context,
          subjectId: subjectId,
          subjectName: subjectName,
          focusTitle: subjectName,
        );
        break;
      case UniversalSubjectAction.timer:
        AppRouter.startContextualFocus(
          context,
          duration: const Duration(minutes: 25),
          subjectId: subjectId,
          subjectName: subjectName,
          focusTitle: subjectName,
        );
        break;
      case UniversalSubjectAction.stopwatch:
        final fc = FocusController.instance;
        if (fc.hasActiveSession) {
          AppRouter.openActiveFocusSession(context);
          return;
        }
        fc.startStopwatch(
          subjectId: subjectId,
          subjectName: subjectName,
          objective: subjectName ?? 'Focus Session',
        );
        AppRouter.openActiveFocusSession(context);
        break;
    }
  }

  static void executeTopicAction(
    BuildContext context,
    String actionId, {
    String? subjectId,
    String? subjectName,
    String? topicId,
    String? topicName,
    String? chapterId,
  }) {
    switch (actionId) {
      case UniversalTopicAction.study:
        if (subjectId != null) {
          AppRouter.openSubjectDetail(context, subjectId);
        } else {
          AppRouter.openStudy(context);
        }
        break;
      case UniversalTopicAction.practice:
        if (topicId != null) {
          final topic =
              AcademicKnowledgeController.instance.topicById(topicId);
          if (topic != null) {
            PracticeModeSelectionSheet.show(context, topic: topic);
          } else {
            AppRouter.openPracticeCenter(context);
          }
        } else {
          AppRouter.openPracticeCenter(context);
        }
        break;
      case UniversalTopicAction.revise:
        AppRouter.openRevision(context);
        break;
      case UniversalTopicAction.view:
        if (subjectId != null) {
          AppRouter.openSubjectDetail(context, subjectId);
        } else {
          AppRouter.openStudy(context);
        }
        break;
      case UniversalTopicAction.focus:
        AppRouter.openFocusModeSelection(
          context,
          subjectId: subjectId,
          subjectName: subjectName,
          topicId: topicId,
          topicName: topicName,
          chapterId: chapterId,
          focusTitle: topicName,
        );
        break;
      case UniversalTopicAction.timer:
        AppRouter.startContextualFocus(
          context,
          duration: const Duration(minutes: 25),
          subjectId: subjectId,
          subjectName: subjectName,
          topicId: topicId,
          chapterId: chapterId,
          focusTitle: topicName,
        );
        break;
      case UniversalTopicAction.stopwatch:
        final fc = FocusController.instance;
        if (fc.hasActiveSession) {
          AppRouter.openActiveFocusSession(context);
          return;
        }
        fc.startStopwatch(
          subjectId: subjectId,
          subjectName: subjectName,
          topicId: topicId,
          chapterId: chapterId,
          objective: topicName ?? subjectName ?? 'Focus Session',
        );
        AppRouter.openActiveFocusSession(context);
        break;
    }
  }

  static void executeChapterAction(
    BuildContext context,
    String actionId, {
    required String chapterId,
    String? subjectId,
    String? subjectName,
    String? chapterTitle,
  }) {
    switch (actionId) {
      case UniversalChapterAction.open:
      case UniversalChapterAction.study:
        if (subjectId != null) {
          AppRouter.openSubjectDetail(context, subjectId);
        } else {
          AppRouter.openStudy(context);
        }
        break;
      case UniversalChapterAction.practice:
        AppRouter.openPracticeCenter(context);
        break;
      case UniversalChapterAction.revise:
        AppRouter.openRevision(context);
        break;
      case UniversalChapterAction.schedule:
        UniversalActionExecutor.openPlanMyDay(context);
        break;
    }
  }

  static void executeExamAction(
    BuildContext context,
    String actionId, {
    required String examId,
    String? examTitle,
    String? subjectId,
    String? subjectName,
  }) {
    switch (actionId) {
      case UniversalExamAction.study:
      case UniversalExamAction.view:
        AppRouter.openExamDetail(context, examId);
        break;
      case UniversalExamAction.revise:
        AppRouter.openRevision(context);
        break;
      case UniversalExamAction.plan:
        AppRouter.openPlan(context);
        break;
      case UniversalExamAction.focus:
        AppRouter.openFocusModeSelection(
          context,
          subjectId: subjectId,
          subjectName: subjectName,
          examId: examId,
          examTitle: examTitle,
          focusTitle: examTitle,
        );
        break;
    }
  }

  static Future<void> executePlanningBlockAction(
    BuildContext context,
    String actionId,
    PlanningBlock block,
  ) async {
    switch (actionId) {
      case UniversalBlockAction.startFocus:
        AppRouter.startPlanningBlockFocus(context, block);
        break;
      case UniversalBlockAction.view:
        AppRouter.openPlan(context);
        break;
      case UniversalBlockAction.reschedule:
        AppRouter.openPlan(context);
        break;
      case UniversalBlockAction.recover:
        final duration = block.endAt.difference(block.startAt);
        final newStart = DateTime.now().add(const Duration(minutes: 15));
        await PlanningBlockController.instance.rescheduleBlock(
          block.id,
          newStart,
          newStart.add(duration),
        );
        break;
      case UniversalBlockAction.skip:
      case UniversalBlockAction.unschedule:
        await PlanningBlockController.instance.unscheduleBlock(block.id);
        break;
    }
  }

  static void executeResourceAction(
    BuildContext context,
    String actionId,
    AcademicResource resource,
  ) {
    switch (actionId) {
      case UniversalResourceAction.open:
      case UniversalResourceAction.download:
        AppRouter.openResourceDetail(context, resource.id);
        break;
      case UniversalResourceAction.toggleFavorite:
        ResourceController.instance.toggleFavorite(resource.id);
        break;
    }
  }

  static void executeGoalAction(BuildContext context, String actionId) {
    switch (actionId) {
      case UniversalGoalAction.view:
        AppRouter.openGoals(context);
        break;
      case UniversalGoalAction.plan:
        AppRouter.openPlan(context);
        break;
      case UniversalGoalAction.progress:
        AppRouter.openProgress(context);
        break;
    }
  }

  static void executeFocusAction(BuildContext context, String actionId) {
    final fc = FocusController.instance;
    switch (actionId) {
      case UniversalFocusAction.start:
        AppRouter.openFocusCenter(context);
        break;
      case UniversalFocusAction.continueSession:
        AppRouter.openActiveFocusSession(context);
        break;
      case UniversalFocusAction.pauseResume:
        if (fc.activeSession?.isPaused == true) {
          fc.resumeSession();
        } else {
          fc.pauseSession();
        }
        AppRouter.openActiveFocusSession(context);
        break;
      case UniversalFocusAction.end:
        fc.endSessionEarly();
        break;
    }
  }

  static void executeNoteAction(
    BuildContext context,
    String actionId,
    StudentNote note,
  ) {
    switch (actionId) {
      case UniversalNoteAction.open:
        AppRouter.openNoteDetail(context, note.id);
        break;
      case UniversalNoteAction.edit:
        AppRouter.openNoteEditor(context, noteId: note.id);
        break;
      case UniversalNoteAction.focus:
        AppRouter.startContextualFocus(
          context,
          duration: Duration(minutes: (note.estimatedReadMinutes * 2).clamp(15, 60)),
          subjectId: note.subjectId,
          topicId: note.topicId,
          chapterId: note.chapterId,
          focusTitle: 'Note: ${note.title}',
        );
        break;
      case UniversalNoteAction.study:
        if (note.hasSubject) {
          final subject = SubjectController.instance.subjectById(note.subjectId!);
          StudyController.instance.startSession(
            subject: subject?.displayName ?? 'General',
            subjectId: note.subjectId,
            chapterId: note.chapterId,
            topicId: note.topicId,
          );
        }
        AppRouter.openStudy(context);
        break;
      case UniversalNoteAction.practice:
        AppRouter.openPracticeCenter(context);
        break;
      case UniversalNoteAction.revise:
        AppRouter.openRevision(context);
        break;
      case UniversalNoteAction.plan:
        openPlanMyDay(context);
        break;
      case UniversalNoteAction.pin:
        StudentNoteController.instance.togglePinned(note.id);
        break;
      case UniversalNoteAction.archive:
        if (note.isArchived) {
          StudentNoteController.instance.restoreNote(note.id);
        } else {
          StudentNoteController.instance.archiveNote(note.id);
        }
        break;
      case UniversalNoteAction.delete:
        StudentNoteController.instance.deleteNote(note.id);
        break;
    }
  }

  /// Shows a consistent bottom-sheet action menu for any entity.
  static Future<void> showEntityActions(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<EntityActionDescriptor> actions,
    required ValueChanged<String> onSelect,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => EntityActionSheet(
        title: title,
        subtitle: subtitle,
        actions: actions,
        onSelect: (id) {
          Navigator.of(sheetContext).pop();
          onSelect(id);
        },
      ),
    );
  }

  static void executeCalendarEventAction(
    BuildContext context,
    String actionId,
    AcademicCalendarEvent event,
  ) {
    switch (actionId) {
      case UniversalCalendarEventAction.view:
      case UniversalCalendarEventAction.edit:
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddEditEventSheet(initialEvent: event),
        );
        break;
      case UniversalCalendarEventAction.planAround:
        openPlanMyDay(context, targetDay: event.startAt);
        break;
      case UniversalCalendarEventAction.viewDay:
        AppRouter.openCalendar(
          context,
          initialDate: event.startAt,
          initialMode: CalendarViewMode.day,
        );
        break;
      case UniversalCalendarEventAction.viewWeek:
        AppRouter.openCalendar(
          context,
          initialDate: event.startAt,
          initialMode: CalendarViewMode.week,
        );
        break;
      case UniversalCalendarEventAction.delete:
        AcademicScheduleController.instance.deleteEvent(event.id);
        break;
    }
  }
}

/// Modal sheet offering standardized global creation options.
class GlobalAddSheet extends StatelessWidget {
  const GlobalAddSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add to Student OS',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            _AddTile(
              icon: Icons.calendar_month_rounded,
              title: 'New Commitment / Class',
              subtitle: 'Add a class, lecture, lab, or fixed event',
              color: const Color(0xFF4A90E2),
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddEditEventSheet(),
                );
              },
            ),
            _AddTile(
              icon: Icons.checklist_rounded,
              title: 'New Task',
              subtitle: 'Create a homework, assignment, or study task',
              color: const Color(0xFF285C4D),
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const TaskCreationSheet(),
                );
              },
            ),
            _AddTile(
              icon: Icons.school_rounded,
              title: 'New Exam',
              subtitle: 'Track upcoming test, exam, or quiz',
              color: const Color(0xFF1F5C44),
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const ExamCreationSheet(),
                );
              },
            ),
            _AddTile(
              icon: Icons.auto_stories_rounded,
              title: 'New Subject',
              subtitle: 'Add an academic subject or course',
              color: const Color(0xFF2E7D5B),
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const SubjectCreationSheet(),
                );
              },
            ),
            _AddTile(
              icon: Icons.description_outlined,
              title: 'New Note',
              subtitle: 'Write notes with subject and topic context',
              color: const Color(0xFF4F7D68),
              onTap: () {
                Navigator.of(context).pop();
                AppRouter.openNoteEditor(context);
              },
            ),
            _AddTile(
              icon: Icons.sticky_note_2_rounded,
              title: 'New Resource',
              subtitle: 'Save reference links, documents, or study material',
              color: const Color(0xFF6F967F),
              onTap: () {
                Navigator.of(context).pop();
                ResourceCreationSheet.show(context, ResourceType.link);
              },
            ),
            _AddTile(
              icon: Icons.auto_awesome_rounded,
              title: 'Plan My Day',
              subtitle: 'Generate an automatic schedule for today',
              color: const Color(0xFF1F5C44),
              onTap: () {
                Navigator.of(context).pop();
                UniversalActionExecutor.openPlanMyDay(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight Universal Action Launcher Sheet.
class UniversalActionLauncherSheet extends StatelessWidget {
  const UniversalActionLauncherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'What do you want to do?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            _AddTile(
              icon: Icons.auto_awesome_rounded,
              title: 'Ask Student OS',
              subtitle: 'State available time, ask what to study or revise',
              color: const Color(0xFF4F7D68),
              onTap: () {
                Navigator.of(context).pop();
                UniversalActionExecutor.openAssistant(context);
              },
            ),
            _AddTile(
              icon: Icons.timer_rounded,
              title: 'Start Focus Session',
              subtitle: 'Timer, mission objective & Focus Guard',
              color: const Color(0xFF285C4D),
              onTap: () {
                Navigator.of(context).pop();
                AppRouter.openFocusCenter(context);
              },
            ),
            _AddTile(
              icon: Icons.auto_awesome_rounded,
              title: 'Plan My Day',
              subtitle: 'Automated study & task distribution',
              color: const Color(0xFF1F5C44),
              onTap: () {
                Navigator.of(context).pop();
                UniversalActionExecutor.openPlanMyDay(context);
              },
            ),
            _AddTile(
              icon: Icons.checklist_rounded,
              title: 'Manage Tasks',
              subtitle: 'Organize homework, subtasks & deadlines',
              color: const Color(0xFF2E7D5B),
              onTap: () {
                Navigator.of(context).pop();
                AppRouter.openTasks(context);
              },
            ),
            _AddTile(
              icon: Icons.school_rounded,
              title: 'Review Upcoming Exams',
              subtitle: 'Countdowns, syllabus & pressure signals',
              color: const Color(0xFF1F5C44),
              onTap: () {
                Navigator.of(context).pop();
                AppRouter.openExams(context);
              },
            ),
            _AddTile(
              icon: Icons.replay_rounded,
              title: 'Revise Materials',
              subtitle: 'Syllabus topics & review backlog',
              color: const Color(0xFF4F7D68),
              onTap: () {
                Navigator.of(context).pop();
                AppRouter.openRevision(context);
              },
            ),
            _AddTile(
              icon: Icons.quiz_outlined,
              title: 'Practice & Quizzes',
              subtitle: 'Interactive questions, weak topic solving & history',
              color: const Color(0xFF2E7D5B),
              onTap: () {
                Navigator.of(context).pop();
                AppRouter.openPracticeCenter(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CODE 5 — Universal entity action descriptors & status
// ════════════════════════════════════════════════════════════════════════════

/// Display status of a planning block (derived, never persisted).
enum PlanningBlockStatus {
  upcoming('Upcoming'),
  current('Current'),
  completed('Completed'),
  missed('Missed'),
  skipped('Skipped');

  const PlanningBlockStatus(this.label);
  final String label;
}

/// A single consistent entity action shown in bottom sheets / menus.
@immutable
class EntityActionDescriptor {
  const EntityActionDescriptor({
    required this.id,
    required this.label,
    required this.icon,
    this.isDestructive = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool isDestructive;
}

/// Task action ids.
abstract final class UniversalTaskAction {
  static const start = 'task_start';
  static const schedule = 'task_schedule';
  static const focus = 'task_focus';
  static const edit = 'task_edit';
  static const complete = 'task_complete';
  static const reschedule = 'task_reschedule';
  static const view = 'task_view';
}

/// Subject action ids.
abstract final class UniversalSubjectAction {
  static const study = 'subject_study';
  static const revise = 'subject_revise';
  static const focus = 'subject_focus';
  static const timer = 'subject_timer';
  static const stopwatch = 'subject_stopwatch';
  static const viewSyllabus = 'subject_view_syllabus';
}

/// Chapter action ids.
abstract final class UniversalChapterAction {
  static const open = 'chapter_open';
  static const study = 'chapter_study';
  static const practice = 'chapter_practice';
  static const revise = 'chapter_revise';
  static const schedule = 'chapter_schedule';
}

/// Topic action ids.
abstract final class UniversalTopicAction {
  static const study = 'topic_study';
  static const practice = 'topic_practice';
  static const revise = 'topic_revise';
  static const focus = 'topic_focus';
  static const timer = 'topic_timer';
  static const stopwatch = 'topic_stopwatch';
  static const view = 'topic_view';
}

/// Exam action ids.
abstract final class UniversalExamAction {
  static const study = 'exam_study';
  static const revise = 'exam_revise';
  static const plan = 'exam_plan';
  static const focus = 'exam_focus';
  static const view = 'exam_view';
}

/// Planning-block action ids.
abstract final class UniversalBlockAction {
  static const startFocus = 'block_start_focus';
  static const view = 'block_view';
  static const reschedule = 'block_reschedule';
  static const skip = 'block_skip';
  static const unschedule = 'block_unschedule';
  static const recover = 'block_recover';
}

/// Resource action ids.
abstract final class UniversalResourceAction {
  static const open = 'resource_open';
  static const download = 'resource_download';
  static const toggleFavorite = 'resource_toggle_favorite';
}

/// Goal action ids.
abstract final class UniversalGoalAction {
  static const view = 'goal_view';
  static const plan = 'goal_plan';
  static const progress = 'goal_progress';
}

/// Academic calendar event action ids.
abstract final class UniversalCalendarEventAction {
  static const view = 'calendar_event_view';
  static const edit = 'calendar_event_edit';
  static const delete = 'calendar_event_delete';
  static const planAround = 'calendar_event_plan_around';
  static const viewDay = 'calendar_event_view_day';
  static const viewWeek = 'calendar_event_view_week';
}

/// Focus action ids.
abstract final class UniversalFocusAction {
  static const start = 'focus_start';
  static const continueSession = 'focus_continue';
  static const pauseResume = 'focus_pause_resume';
  static const end = 'focus_end';
}

/// Note action ids.
abstract final class UniversalNoteAction {
  static const open = 'note_open';
  static const edit = 'note_edit';
  static const focus = 'note_focus';
  static const study = 'note_study';
  static const practice = 'note_practice';
  static const revise = 'note_revise';
  static const plan = 'note_plan';
  static const pin = 'note_pin';
  static const archive = 'note_archive';
  static const delete = 'note_delete';
}

/// Consistent bottom-sheet menu for entity universal actions.
class EntityActionSheet extends StatelessWidget {
  const EntityActionSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.actions,
    required this.onSelect,
  });

  final String title;
  final String? subtitle;
  final List<EntityActionDescriptor> actions;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final action in actions)
                      _EntityActionTile(
                        action: action,
                        onTap: () => onSelect(action.id),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntityActionTile extends StatelessWidget {
  const _EntityActionTile({required this.action, required this.onTap});

  final EntityActionDescriptor action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = action.isDestructive ? Colors.red : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Icon(action.icon, size: 20, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  action.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
