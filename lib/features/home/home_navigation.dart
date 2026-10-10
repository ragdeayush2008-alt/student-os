import 'package:flutter/material.dart' hide PrioritizedAction;

import '../../app/app_router.dart';
import '../../core/intelligence/adaptive_priority_engine.dart';
import '../../features/exams/exam_controller.dart';
import '../../features/subjects/subject_controller.dart';
import '../../features/tasks/task_controller.dart';

/// Where a Home Daily OS action leads.
///
/// Deterministic and testable: [HomeNavigation.resolveDestination] is pure
/// (reads only controller registries for validity guards) and
/// [HomeNavigation.openAction] always delegates to existing [AppRouter]
/// helpers — never back to Home.
enum HomeActionDestination {
  taskDetail,
  examDetail,
  subjectDetail,
  study,
  focusSession,
  focusCenter,
}

/// Resolves NOW/NEXT [PrioritizedAction] routing for the Home command center.
///
/// Guards against stale recommendations (deleted task/exam/subject) and
/// preserves taskId / subjectId / examId / focus context across navigation.
abstract final class HomeNavigation {
  /// Pure, deterministic destination for [action].
  ///
  /// Same controller state → same destination. Returns null only when the
  /// action references an entity that no longer exists.
  static HomeActionDestination? resolveDestination(PrioritizedAction action) {
    if (action.taskId != null) {
      final exists = TaskController.instance.tasks.any(
        (t) => t.id == action.taskId,
      );
      if (!exists) return null;
      return HomeActionDestination.taskDetail;
    }
    if (action.examId != null) {
      final exists = ExamController.instance.exams.any(
        (e) => e.id == action.examId,
      );
      if (!exists) return null;
      return HomeActionDestination.examDetail;
    }
    if (action.subjectId != null) {
      final subject = SubjectController.instance.subjectById(action.subjectId!);
      if (subject == null) return null;
      return HomeActionDestination.subjectDetail;
    }
    return HomeActionDestination.study;
  }

  /// Human-readable primary button label for [action].
  static String primaryLabel(PrioritizedAction action) {
    final dest = resolveDestination(action);
    return switch (dest) {
      HomeActionDestination.taskDetail => 'Open task',
      HomeActionDestination.examDetail => 'View exam',
      HomeActionDestination.subjectDetail => 'Open subject',
      HomeActionDestination.study => 'Open study',
      _ => 'Open study',
    };
  }

  /// Opens [action] at its real destination. Never routes back to Home.
  ///
  /// Returns false when the action is stale (deleted entity) so callers can
  /// show a truthful fallback instead of navigating nowhere.
  static bool openAction(BuildContext context, PrioritizedAction action) {
    final dest = resolveDestination(action);
    switch (dest) {
      case HomeActionDestination.taskDetail:
        AppRouter.openTaskDetail(context, action.taskId!);
        return true;
      case HomeActionDestination.examDetail:
        AppRouter.openExamDetail(context, action.examId!);
        return true;
      case HomeActionDestination.subjectDetail:
        AppRouter.openSubjectDetail(context, action.subjectId!);
        return true;
      case HomeActionDestination.study:
        AppRouter.openStudy(context);
        return true;
      case null:
        return false;
      case HomeActionDestination.focusSession:
      case HomeActionDestination.focusCenter:
        AppRouter.openFocusCenter(context);
        return true;
    }
  }

  /// Starts a real 25-minute focus session and opens the live session
  /// screen. Never routes to the Focus landing page.
  ///
  /// Uses a [FocusMission] (not a bare quick focus) so the session retains
  /// taskId / subjectId / examId context for completion handling and display.
  static void startQuickFocusAndOpen(
    BuildContext context, {
    String? subjectName,
    String? subjectId,
    String? taskId,
    String? examId,
  }) {
    final cleanSubject = (subjectName ?? '').trim();
    AppRouter.openFocusCenter(
      context,
      subjectName: cleanSubject.isNotEmpty ? cleanSubject : null,
      subjectId: subjectId,
      taskId: taskId,
      examId: examId,
      focusTitle: cleanSubject.isNotEmpty ? cleanSubject : null,
    );
  }

  /// Continues the currently active focus session, preserving its context.
  static void continueActiveFocus(BuildContext context) {
    AppRouter.openActiveFocusSession(context);
  }
}
