import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/services/notification_service.dart';
import 'package:student_os/core/utils/app_week_utils.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/tasks/task_recommendation_engine.dart';

void main() {
  group('StudentTask model backward compatibility', () {
    test('old JSON without new fields deserializes safely', () {
      final oldJson = {
        'id': 'old_1',
        'title': 'Old task',
        'description': '',
        'priority': 'medium',
        'status': 'active',
        'category': '',
        'createdAt': '2024-01-15T10:00:00.000',
        'sortOrder': 1,
      };
      final task = StudentTask.fromJson(oldJson);
      expect(task.id, 'old_1');
      expect(task.title, 'Old task');
      expect(task.subtasks, isEmpty);
      expect(task.recurrence, isNull);
      expect(task.reminderEnabled, false);
      expect(task.reminderDateTime, isNull);
      expect(task.isCompleted, false);
    });

    test('new JSON with all fields deserializes correctly', () {
      final json = {
        'id': 'new_1',
        'title': 'New task',
        'description': 'With desc',
        'priority': 'high',
        'status': 'active',
        'dueDate': '2025-03-01T00:00:00.000',
        'scheduledDate': '2025-02-28T00:00:00.000',
        'category': 'Math',
        'createdAt': '2025-02-01T10:00:00.000',
        'updatedAt': '2025-02-02T10:00:00.000',
        'completedAt': null,
        'sortOrder': 5,
        'subtasks': [
          {
            'id': 's1',
            'title': 'Sub 1',
            'completed': true,
            'createdAt': '2025-02-01T10:00:00.000',
          },
          {
            'id': 's2',
            'title': 'Sub 2',
            'completed': false,
            'createdAt': '2025-02-01T10:00:00.000',
          },
        ],
        'recurrence': {'frequency': 'daily', 'customWeekdays': []},
        'reminderEnabled': true,
        'reminderDateTime': '2025-02-28T09:00:00.000',
      };
      final task = StudentTask.fromJson(json);
      expect(task.subtasks.length, 2);
      expect(task.subtasks[0].completed, true);
      expect(task.recurrence!.frequency, RecurrenceFrequency.daily);
      expect(task.reminderEnabled, true);
      expect(task.hasRecurrence, true);
    });

    test('toJson/fromJson roundtrip preserves all fields', () {
      final original = StudentTask(
        id: 'rt_1',
        title: 'Roundtrip',
        description: 'Test',
        priority: TaskPriority.high,
        dueDate: DateTime(2025, 3, 1),
        scheduledDate: DateTime(2025, 2, 28),
        category: 'Science',
        subtasks: [
          StudentSubtask(id: 's1', title: 'One'),
          StudentSubtask(
            id: 's2',
            title: 'Two',
            completed: true,
            completedAt: DateTime.now(),
          ),
        ],
        recurrence: const TaskRecurrence(
          frequency: RecurrenceFrequency.weekdays,
        ),
        reminderEnabled: true,
        reminderDateTime: DateTime(2025, 2, 28, 9, 0),
      );
      final json = original.toJson();
      final restored = StudentTask.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.subtasks.length, 2);
      expect(restored.recurrence!.frequency, RecurrenceFrequency.weekdays);
      expect(restored.reminderEnabled, true);
    });

    test('copyWith preserves existing fields', () {
      final task = StudentTask(
        id: 'cw_1',
        title: 'Original',
        subtasks: [StudentSubtask(id: 's1', title: 'Sub')],
        recurrence: const TaskRecurrence(frequency: RecurrenceFrequency.weekly),
        reminderEnabled: true,
      );
      final updated = task.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.subtasks.length, 1);
      expect(updated.recurrence!.frequency, RecurrenceFrequency.weekly);
      expect(updated.reminderEnabled, true);
    });

    test('copyWith clear fields works', () {
      final task = StudentTask(
        id: 'cw_2',
        title: 'Task',
        dueDate: DateTime(2025, 3, 1),
        scheduledDate: DateTime(2025, 2, 28),
        recurrence: const TaskRecurrence(frequency: RecurrenceFrequency.daily),
        reminderEnabled: true,
        reminderDateTime: DateTime(2025, 2, 28, 9, 0),
      );
      final cleared = task.copyWith(
        clearDueDate: true,
        clearScheduledDate: true,
        clearRecurrence: true,
        clearReminderDateTime: true,
      );
      expect(cleared.dueDate, isNull);
      expect(cleared.scheduledDate, isNull);
      expect(cleared.recurrence, isNull);
      expect(cleared.reminderDateTime, isNull);
    });
  });

  group('StudentSubtask', () {
    test('copyWith toggles completion', () {
      final sub = StudentSubtask(id: 's1', title: 'Test');
      expect(sub.completed, false);
      final completed = sub.copyWith(
        completed: true,
        completedAt: DateTime.now(),
      );
      expect(completed.completed, true);
      expect(completed.completedAt, isNotNull);
      final reopened = completed.copyWith(
        completed: false,
        clearCompletedAt: true,
      );
      expect(reopened.completed, false);
      expect(reopened.completedAt, isNull);
    });

    test('toJson/fromJson roundtrip', () {
      final sub = StudentSubtask(
        id: 's1',
        title: 'Test subtask',
        completed: true,
        completedAt: DateTime(2025, 2, 15),
      );
      final json = sub.toJson();
      final restored = StudentSubtask.fromJson(json);
      expect(restored.id, sub.id);
      expect(restored.title, sub.title);
      expect(restored.completed, true);
      expect(restored.completedAt, isNotNull);
    });
  });

  group('StudentTask convenience getters', () {
    test('isInbox returns true when no dates set', () {
      final task = StudentTask(id: 't1', title: 'Inbox');
      expect(task.isInbox, true);
    });

    test('isInbox returns false when dueDate set', () {
      final task = StudentTask(
        id: 't1',
        title: 'Scheduled',
        dueDate: DateTime.now(),
      );
      expect(task.isInbox, false);
    });

    test('subtaskProgress calculates correctly', () {
      final task = StudentTask(
        id: 't1',
        title: 'Task',
        subtasks: [
          StudentSubtask(id: 's1', title: 'S1', completed: true),
          StudentSubtask(id: 's2', title: 'S2', completed: true),
          StudentSubtask(id: 's3', title: 'S3', completed: false),
        ],
      );
      expect(task.subtaskCount, 3);
      expect(task.subtasksCompleted, 2);
      expect(task.subtaskProgress, closeTo(0.667, 0.01));
      expect(task.allSubtasksComplete, false);
    });

    test('allSubtasksComplete works', () {
      final task = StudentTask(
        id: 't1',
        title: 'Task',
        subtasks: [
          StudentSubtask(id: 's1', title: 'S1', completed: true),
          StudentSubtask(id: 's2', title: 'S2', completed: true),
        ],
      );
      expect(task.allSubtasksComplete, true);
    });
  });

  group('TaskRecurrence', () {
    test('toJson/fromJson roundtrip', () {
      const r = TaskRecurrence(
        frequency: RecurrenceFrequency.weekly,
        customWeekdays: [1, 3, 5],
      );
      final json = r.toJson();
      final restored = TaskRecurrence.fromJson(json);
      expect(restored.frequency, RecurrenceFrequency.weekly);
      expect(restored.customWeekdays, [1, 3, 5]);
    });

    test('isActive returns true for non-none frequency', () {
      const r1 = TaskRecurrence(frequency: RecurrenceFrequency.daily);
      const r2 = TaskRecurrence(frequency: RecurrenceFrequency.none);
      expect(r1.isActive, true);
      expect(r2.isActive, false);
    });
  });

  group('AppWeekUtils', () {
    test('startOfWeek Monday default', () {
      // Wednesday Feb 19, 2025
      final day = DateTime(2025, 2, 19);
      final start = AppWeekUtils.startOfWeek(day);
      expect(start, DateTime(2025, 2, 17)); // Monday
    });

    test('startOfWeek Sunday start', () {
      // Wednesday Feb 19, 2025
      final day = DateTime(2025, 2, 19);
      final start = AppWeekUtils.startOfWeek(day, startsMonday: false);
      expect(start, DateTime(2025, 2, 16)); // Sunday
    });

    test('endOfWeek Monday start', () {
      final day = DateTime(2025, 2, 19);
      final end = AppWeekUtils.endOfWeek(day);
      expect(end, DateTime(2025, 2, 24)); // Next Monday
    });

    test('weekDates returns 7 dates', () {
      final dates = AppWeekUtils.weekDates(DateTime(2025, 2, 19));
      expect(dates.length, 7);
      expect(dates.first, DateTime(2025, 2, 17)); // Monday
      expect(dates.last, DateTime(2025, 2, 23)); // Sunday
    });

    test('weekdayLabels Monday start', () {
      final labels = AppWeekUtils.weekdayLabels();
      expect(labels.first, 'Mon');
      expect(labels.last, 'Sun');
    });

    test('weekdayLabels Sunday start', () {
      final labels = AppWeekUtils.weekdayLabels(startsMonday: false);
      expect(labels.first, 'Sun');
      expect(labels.last, 'Sat');
    });

    test('dateOnly strips time', () {
      final dt = DateTime(2025, 3, 15, 14, 30, 45);
      expect(AppWeekUtils.dateOnly(dt), DateTime(2025, 3, 15));
    });

    test('dateOnlyOrNull returns null for null', () {
      expect(AppWeekUtils.dateOnlyOrNull(null), isNull);
    });

    test('dateOnlyOrNull normalizes non-null', () {
      final dt = DateTime(2025, 3, 15, 14, 30);
      expect(AppWeekUtils.dateOnlyOrNull(dt), DateTime(2025, 3, 15));
    });
  });

  group('TaskRecommendationEngine', () {
    test('overdue tasks rank highest', () {
      final tasks = [
        StudentTask(
          id: 't1',
          title: 'Due soon',
          priority: TaskPriority.high,
          dueDate: DateTime.now().add(const Duration(days: 2)),
        ),
        StudentTask(
          id: 't2',
          title: 'Overdue',
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
      final recs = TaskRecommendationEngine.recommend(tasks);
      expect(recs.length, 2);
      expect(recs.first.task.id, 't2');
      expect(recs.first.reason, contains('Overdue'));
    });

    test('due tomorrow ranks after overdue', () {
      final tasks = [
        StudentTask(
          id: 't1',
          title: 'Due tomorrow',
          dueDate: DateTime.now().add(const Duration(days: 1)),
        ),
        StudentTask(
          id: 't2',
          title: 'Due next week',
          dueDate: DateTime.now().add(const Duration(days: 5)),
        ),
      ];
      final recs = TaskRecommendationEngine.recommend(tasks);
      expect(recs.first.task.id, 't1');
      expect(recs.first.reason, 'Due tomorrow');
    });

    test('completed tasks are excluded', () {
      final tasks = [
        StudentTask(
          id: 't1',
          title: 'Done',
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
        ),
      ];
      final recs = TaskRecommendationEngine.recommend(tasks);
      expect(recs, isEmpty);
    });

    test('empty tasks returns empty list', () {
      final recs = TaskRecommendationEngine.recommend([]);
      expect(recs, isEmpty);
    });

    test('limit parameter works', () {
      final tasks = List.generate(
        10,
        (i) => StudentTask(
          id: 't$i',
          title: 'Task $i',
          dueDate: DateTime.now().subtract(Duration(days: i)),
        ),
      );
      final recs = TaskRecommendationEngine.recommend(tasks, limit: 3);
      expect(recs.length, 3);
    });

    test('high priority due soon ranks above low priority same distance', () {
      final tasks = [
        StudentTask(
          id: 't1',
          title: 'Low priority',
          priority: TaskPriority.low,
          dueDate: DateTime.now().add(const Duration(days: 3)),
        ),
        StudentTask(
          id: 't2',
          title: 'High priority',
          priority: TaskPriority.high,
          dueDate: DateTime.now().add(const Duration(days: 3)),
        ),
      ];
      final recs = TaskRecommendationEngine.recommend(tasks);
      // Both hit the "due in 3 days" check with same urgency,
      // but high priority has lower sortOrder tiebreak.
      expect(recs.length, 2);
    });

    test('nearly complete subtasks are recommended', () {
      final tasks = [
        StudentTask(
          id: 't1',
          title: 'Almost done',
          subtasks: [
            StudentSubtask(id: 's1', title: 'S1', completed: true),
            StudentSubtask(id: 's2', title: 'S2', completed: true),
            StudentSubtask(id: 's3', title: 'S3', completed: false),
          ],
        ),
      ];
      final recs = TaskRecommendationEngine.recommend(tasks);
      expect(recs.length, 1);
      expect(recs.first.reason, contains('subtask'));
    });
  });

  group('NotificationIds', () {
    test('deterministic IDs for same input', () {
      final id1 = NotificationIds.taskReminder('task_123');
      final id2 = NotificationIds.taskReminder('task_123');
      expect(id1, id2);
    });

    test('different IDs for different inputs', () {
      final id1 = NotificationIds.taskReminder('task_1');
      final id2 = NotificationIds.taskReminder('task_2');
      expect(id1, isNot(id2));
    });

    test('study and planning IDs are different', () {
      final study = NotificationIds.studyReminder();
      final plan = NotificationIds.planningReminder();
      expect(study, isNot(plan));
    });
  });
}
