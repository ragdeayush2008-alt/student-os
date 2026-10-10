import 'package:flutter_test/flutter_test.dart';

import 'package:student_os/data/models/student_profile.dart';
import 'package:student_os/data/models/task.dart';

void main() {
  group('StudentTask — model', () {
    test('creates with required fields', () {
      final task = StudentTask(id: '1', title: 'Test task');
      expect(task.id, '1');
      expect(task.title, 'Test task');
      expect(task.description, '');
      expect(task.priority, TaskPriority.medium);
      expect(task.status, TaskStatus.active);
      expect(task.isCompleted, isFalse);
    });

    test('isOverdue returns true for past due date', () {
      final task = StudentTask(
        id: '1',
        title: 'Overdue',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(task.isOverdue, isTrue);
    });

    test('isDueToday returns true when due today', () {
      final now = DateTime.now();
      final task = StudentTask(
        id: '1',
        title: 'Today',
        dueDate: DateTime(now.year, now.month, now.day, 23, 59),
      );
      expect(task.isDueToday, isTrue);
    });

    test('copyWith creates new instance with changes', () {
      final original = StudentTask(id: '1', title: 'Original');
      final updated = original.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(original.title, 'Original');
      expect(updated.id, original.id);
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final task = StudentTask(
        id: 'test_1',
        title: 'Test task',
        description: 'A description',
        priority: TaskPriority.high,
        category: 'Math',
      );
      final json = task.toJson();
      final restored = StudentTask.fromJson(json);
      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.description, task.description);
      expect(restored.priority, TaskPriority.high);
      expect(restored.category, 'Math');
    });

    test('completed task has completedAt timestamp', () {
      final task = StudentTask(id: '1', title: 'Done');
      final completed = task.copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
      );
      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, isNotNull);
    });
  });

  group('StudentProfile — model', () {
    test('creates with defaults', () {
      final profile = StudentProfile();
      expect(profile.id, 'demo');
      expect(profile.displayName, '');
      expect(profile.isOnboardingComplete, isFalse);
      expect(profile.initials, '?');
    });

    test('displayLabel uses name when available', () {
      final profile = StudentProfile(displayName: 'Alex');
      expect(profile.displayLabel, 'Alex');
    });

    test('displayLabel falls back to email prefix', () {
      final profile = StudentProfile(email: 'alex@test.com');
      expect(profile.displayLabel, 'alex');
    });

    test('academicSummary combines context fields', () {
      final profile = StudentProfile(
        course: 'Computer Science',
        institution: 'MIT',
        currentYear: '3rd Year',
      );
      expect(profile.academicSummary, contains('Computer Science'));
      expect(profile.academicSummary, contains('MIT'));
      expect(profile.academicSummary, contains('3rd Year'));
    });

    test('toJson/fromJson roundtrip preserves all fields', () {
      final profile = StudentProfile(
        id: 'user_1',
        displayName: 'Test Student',
        email: 'test@test.com',
        educationLevel: EducationLevel.undergraduate,
        institution: 'Test University',
        course: 'Engineering',
        currentYear: '2nd Year',
        goals: [StudentGoal.academicExcellence, StudentGoal.consistency],
        academicFocus: AcademicFocus.examPrep,
        onboardingState: OnboardingState.complete,
      );
      final json = profile.toJson();
      final restored = StudentProfile.fromJson(json);
      expect(restored.id, profile.id);
      expect(restored.displayName, profile.displayName);
      expect(restored.educationLevel, EducationLevel.undergraduate);
      expect(restored.goals.length, 2);
      expect(restored.academicFocus, AcademicFocus.examPrep);
      expect(restored.isOnboardingComplete, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      final profile = StudentProfile(
        id: '1',
        displayName: 'Original',
        course: 'CS',
      );
      final updated = profile.copyWith(displayName: 'Updated');
      expect(updated.displayName, 'Updated');
      expect(updated.course, 'CS');
      expect(updated.id, profile.id);
    });
  });

  group('TaskPriority — properties', () {
    test('has correct labels', () {
      expect(TaskPriority.low.label, 'Low');
      expect(TaskPriority.critical.label, 'Critical');
    });

    test('has correct colors', () {
      expect(TaskPriority.high.color, isNotNull);
      expect(TaskPriority.medium.color, isNotNull);
    });
  });

  group('EducationLevel — labels', () {
    test('all levels have labels', () {
      for (final level in EducationLevel.values) {
        expect(level.label.isNotEmpty, isTrue);
      }
    });
  });

  group('StudentGoal — properties', () {
    test('all goals have labels and icons', () {
      for (final goal in StudentGoal.values) {
        expect(goal.label.isNotEmpty, isTrue);
        expect(goal.icon, isNotNull);
      }
    });
  });
}
