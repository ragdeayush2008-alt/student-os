import '../../features/planning/models/planning_block.dart';
import '../../features/preferences/user_preferences_controller.dart';
import '../../features/student_life/models/student_life_preferences.dart';
import '../../features/tasks/task_controller.dart';
import '../../features/exams/exam_controller.dart';
import '../../features/calendar/academic_schedule_controller.dart';
import 'notification_service.dart';

/// Coordinates notification scheduling across the app.
///
/// Handles reconciliation of task, study, planning, and exam reminders.
/// Called at startup and when relevant data changes.
class NotificationCoordinator {
  NotificationCoordinator._();

  static final NotificationCoordinator instance = NotificationCoordinator._();

  /// Reconciles all notifications based on current app state.
  ///
  /// Safe to call multiple times — uses deterministic IDs and
  /// cancel-before-reschedule for idempotency.
  Future<void> reconcileAll() async {
    if (!NotificationService.instance.hasPermission) return;

    await _reconcileStudyReminder();
    await _reconcilePlanningReminder();
    await _reconcileTaskReminders();
    await _reconcileExamReminders();
    await _reconcileCalendarEventReminders();
  }

  // ─── Academic Calendar Event Reminders ──────────────────────────────

  Future<void> _reconcileCalendarEventReminders() async {
    final now = DateTime.now();
    final events = AcademicScheduleController.instance
        .eventsForRange(now, now.add(const Duration(days: 7)));

    for (final event in events) {
      final notifId = NotificationIds.calendarEventReminder(event.id);
      await NotificationService.instance.cancel(notifId);

      if (event.reminderMinutesBefore != null && event.reminderMinutesBefore! > 0) {
        final reminderTime =
            event.startAt.subtract(Duration(minutes: event.reminderMinutesBefore!));
        if (reminderTime.isAfter(now)) {
          await NotificationService.instance.scheduleOneShot(
            id: notifId,
            title: '${event.title} starting soon',
            body: '${event.type.label} begins at ${event.startAt.hour.toString().padLeft(2, '0')}:${event.startAt.minute.toString().padLeft(2, '0')}',
            scheduledTime: reminderTime,
            payload: NotificationPayload(
              type: 'calendar_event',
              entityId: event.id,
            ).encode(),
          );
        }
      }
    }
  }

  // ─── Study reminder ─────────────────────────────────────────────────

  Future<void> _reconcileStudyReminder() async {
    final prefs = UserPreferencesController.instance;
    final id = NotificationIds.studyReminder();

    await NotificationService.instance.cancel(id);

    if (prefs.studyReminderEnabled) {
      await NotificationService.instance.scheduleDaily(
        id: id,
        title: 'Study Time',
        body: 'Time for your daily study session. Keep the momentum going!',
        hour: prefs.studyReminderTime.hour,
        minute: prefs.studyReminderTime.minute,
        payload: const NotificationPayload(type: 'study').encode(),
      );
    }
  }

  // ─── Planning reminder ──────────────────────────────────────────────

  Future<void> _reconcilePlanningReminder() async {
    final prefs = UserPreferencesController.instance;
    final id = NotificationIds.planningReminder();

    await NotificationService.instance.cancel(id);

    if (prefs.planningReminderEnabled) {
      await NotificationService.instance.scheduleDaily(
        id: id,
        title: 'Plan Your Day',
        body: 'Take a moment to plan your tasks and priorities for today.',
        hour: prefs.planningReminderTime.hour,
        minute: prefs.planningReminderTime.minute,
        payload: const NotificationPayload(type: 'planning').encode(),
      );
    }
  }

  // ─── Task reminders ─────────────────────────────────────────────────

  Future<void> _reconcileTaskReminders() async {
    final tasks = TaskController.instance.tasks;

    for (final task in tasks) {
      if (task.isCompleted || !task.reminderEnabled) {
        await NotificationService.instance.cancelForTask(task.id);
        continue;
      }

      if (task.reminderDateTime != null) {
        await NotificationService.instance.cancelForTask(task.id);

        if (task.reminderDateTime!.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleOneShot(
            id: NotificationIds.taskReminder(task.id),
            title: 'Task Reminder',
            body: 'Upcoming: ${task.title}',
            scheduledTime: task.reminderDateTime!,
            payload: NotificationPayload(
              type: 'task',
              entityId: task.id,
            ).encode(),
          );
        }
      }
    }
  }

  Future<void> scheduleTaskReminder(
    String taskId,
    String title,
    DateTime reminderTime,
  ) async {
    if (!NotificationService.instance.hasPermission) return;

    await NotificationService.instance.cancelForTask(taskId);

    if (reminderTime.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleOneShot(
        id: NotificationIds.taskReminder(taskId),
        title: 'Task Reminder',
        body: 'Upcoming: $title',
        scheduledTime: reminderTime,
        payload: NotificationPayload(type: 'task', entityId: taskId).encode(),
      );
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await NotificationService.instance.cancelForTask(taskId);
  }

  // ─── Exam reminders ─────────────────────────────────────────────────

  /// Reconciles all exam reminders for all upcoming exams.
  ///
  /// Cancel-before-reschedule ensures idempotency.
  Future<void> _reconcileExamReminders() async {
    final exams = ExamController.instance.exams;

    for (final exam in exams) {
      await reconcileExamReminders(exam);
    }
  }

  /// Reconciles reminders for a single exam.
  ///
  /// Safe to call multiple times — cancels all existing IDs first,
  /// then schedules only currently valid future reminders.
  Future<void> reconcileExamReminders(dynamic exam) async {
    // Cancel all possible reminder IDs for this exam first.
    await NotificationService.instance.cancelForExam(exam.id);

    // Don't schedule for completed/cancelled exams.
    if (!exam.isUpcoming) return;

    // Don't schedule if no exam date.
    if (exam.examDateTime == null) return;

    final now = DateTime.now();

    // Schedule 7-day reminder if enabled and future.
    if (exam.reminder7Days) {
      final reminderTime = exam.examDateTime!.subtract(const Duration(days: 7));
      if (reminderTime.isAfter(now)) {
        await NotificationService.instance.scheduleOneShot(
          id: NotificationIds.examReminder(exam.id, 7),
          title: 'Exam in 7 days',
          body: '${exam.title} — review your preparation plan.',
          scheduledTime: reminderTime,
          payload: NotificationPayload(
            type: 'exam',
            entityId: exam.id,
          ).encode(),
        );
      }
    }

    // Schedule 3-day reminder if enabled and future.
    if (exam.reminder3Days) {
      final reminderTime = exam.examDateTime!.subtract(const Duration(days: 3));
      if (reminderTime.isAfter(now)) {
        await NotificationService.instance.scheduleOneShot(
          id: NotificationIds.examReminder(exam.id, 3),
          title: 'Exam in 3 days',
          body: '${exam.title} is coming up soon.',
          scheduledTime: reminderTime,
          payload: NotificationPayload(
            type: 'exam',
            entityId: exam.id,
          ).encode(),
        );
      }
    }

    // Schedule 1-day reminder if enabled and future.
    if (exam.reminder1Day) {
      final reminderTime = exam.examDateTime!.subtract(const Duration(days: 1));
      if (reminderTime.isAfter(now)) {
        await NotificationService.instance.scheduleOneShot(
          id: NotificationIds.examReminder(exam.id, 1),
          title: 'Exam tomorrow',
          body: '${exam.title} — review your preparation plan.',
          scheduledTime: reminderTime,
          payload: NotificationPayload(
            type: 'exam',
            entityId: exam.id,
          ).encode(),
        );
      }
    }
  }

  /// Cancels all reminders for an exam.
  Future<void> cancelExamReminders(String examId) async {
    await NotificationService.instance.cancelForExam(examId);
  }

  // ─── Planning block transitions ──────────────────────────────────────

  Future<void> schedulePlanningBlockTransition({
    required String blockId,
    required String currentTitle,
    String? nextTitle,
    required DateTime transitionTime,
  }) async {
    if (!NotificationService.instance.hasPermission) return;
    await cancelPlanningBlockTransition(blockId);

    if (transitionTime.isAfter(DateTime.now())) {
      final body = nextTitle != null && nextTitle.isNotEmpty
          ? '$nextTitle starts now.'
          : 'Great job completing this session!';

      await NotificationService.instance.scheduleOneShot(
        id: NotificationIds.planningBlockEnd(blockId),
        title: '$currentTitle complete',
        body: body,
        scheduledTime: transitionTime,
        payload: NotificationPayload(type: 'planning', entityId: blockId).encode(),
      );
    }
  }

  Future<void> cancelPlanningBlockTransition(String blockId) async {
    await NotificationService.instance.cancel(NotificationIds.planningBlockEnd(blockId));
  }

  Future<void> reconcilePlanningNotifications(
    List<PlanningBlock> blocks, {
    required Map<String, String> blockTitles,
  }) async {
    if (!NotificationService.instance.hasPermission) return;
    final sorted = List<PlanningBlock>.from(blocks)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    for (int i = 0; i < sorted.length; i++) {
      final block = sorted[i];
      final currentTitle = blockTitles[block.id] ?? block.customTitle ?? 'Session';
      final nextTitle = i + 1 < sorted.length
          ? (blockTitles[sorted[i + 1].id] ?? sorted[i + 1].customTitle)
          : null;
      await schedulePlanningBlockTransition(
        blockId: block.id,
        currentTitle: currentTitle,
        nextTitle: nextTitle,
        transitionTime: block.endAt,
      );
    }
  }

  // ─── Preference change handlers ──────────────────────────────────────

  Future<void> onStudyReminderChanged() async {
    await _reconcileStudyReminder();
  }

  Future<void> onPlanningReminderChanged() async {
    await _reconcilePlanningReminder();
  }

  // ─── Student Life routine reminders ─────────────────────────────────

  static const List<String> _studentLifeKeys = [
    'hydration',
    'breakfast',
    'lunch',
    'dinner',
    'exercise',
    'wind_down',
    'bedtime',
    'nap',
    'study_break',
  ];

  /// Cancels every Student Life reminder. Used on sign-out and when the
  /// feature is disabled so no routine reminder can outlive its owner.
  Future<void> cancelStudentLifeNotifications() async {
    for (final key in _studentLifeKeys) {
      await NotificationService.instance.cancel(
        NotificationIds.studentLifeReminder(key),
      );
    }
  }

  /// Reconciles hydration, meal, exercise, nap, wind-down, and bedtime
  /// reminders against the current [StudentLifePreferences].
  ///
  /// Deterministic cancel-before-reschedule keeps this idempotent. Reminders
  /// that would fire inside the configured sleep window are skipped, and only
  /// one daily reminder per routine is scheduled (no spam).
  Future<void> reconcileStudentLifeNotifications({
    required StudentLifePreferences preferences,
  }) async {
    await cancelStudentLifeNotifications();

    if (!NotificationService.instance.hasPermission) return;
    if (!preferences.enabled || !preferences.notificationsEnabled) return;

    final sleepStart = preferences.targetBedtimeMinutes;
    final sleepEnd = preferences.targetWakeMinutes;

    Future<void> schedule({
      required String key,
      required String title,
      required String body,
      required int minutes,
    }) async {
      final normalised = ((minutes % 1440) + 1440) % 1440;
      if (isWithinSleepWindow(normalised, sleepStart, sleepEnd)) return;
      await NotificationService.instance.scheduleDaily(
        id: NotificationIds.studentLifeReminder(key),
        title: title,
        body: body,
        hour: normalised ~/ 60,
        minute: normalised % 60,
        payload: NotificationPayload(
          type: 'student_life',
          entityId: key,
        ).encode(),
      );
    }

    if (preferences.hydration != HydrationFrequency.off) {
      await schedule(
        key: 'hydration',
        title: 'Hydration',
        body: 'Take a short water break.',
        minutes: preferences.targetWakeMinutes + 180,
      );
    }

    if (preferences.mealRemindersEnabled) {
      await schedule(
        key: 'breakfast',
        title: 'Breakfast',
        body: 'Start the day with a meal.',
        minutes: preferences.breakfastMinutes,
      );
      await schedule(
        key: 'lunch',
        title: 'Lunch',
        body: 'Pause for lunch.',
        minutes: preferences.lunchMinutes,
      );
      await schedule(
        key: 'dinner',
        title: 'Dinner',
        body: 'Pause for dinner.',
        minutes: preferences.dinnerMinutes,
      );
    }

    if (preferences.exerciseEnabled && preferences.exerciseMinutes > 0) {
      await schedule(
        key: 'exercise',
        title: 'Move your body',
        body: 'A short ${preferences.exerciseMinutes} minute session.',
        minutes: preferences.exerciseAtMinutes,
      );
    }

    if (preferences.napEnabled && preferences.napDurationMinutes > 0) {
      await schedule(
        key: 'nap',
        title: 'Optional nap',
        body: 'Rest for ${preferences.napDurationMinutes} minutes if you need it.',
        minutes: 14 * 60,
      );
    }

    await schedule(
      key: 'wind_down',
      title: 'Wind down',
      body: 'Slow down and prepare for sleep.',
      minutes: preferences.targetBedtimeMinutes - preferences.windDownMinutes,
    );

    await schedule(
      key: 'bedtime',
      title: 'Bedtime',
      body: 'Time to rest for tomorrow.',
      minutes: preferences.targetBedtimeMinutes,
    );
  }

  /// True when [minutes] falls inside the sleep window defined by
  /// [sleepStart] and [sleepEnd] (both minutes-from-midnight).
  static bool isWithinSleepWindow(
    int minutes,
    int sleepStart,
    int sleepEnd,
  ) {
    if (sleepStart == sleepEnd) return false;
    if (sleepStart < sleepEnd) {
      return minutes >= sleepStart && minutes < sleepEnd;
    }
    return minutes >= sleepStart || minutes < sleepEnd;
  }
}
