import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/features/notes/student_note_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('reg_test_user');
    await StorageService.instance.clearUser(userId: 'reg_test_user');
    ControllerIsolation.instance.clearAllControllers();
    await StudentNoteController.instance.load();
    await TaskController.instance.load();
    await StudyController.instance.load();
  });

  tearDown(() async {
    await StorageService.instance.clearUser(userId: 'reg_test_user');
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  group('Notes Safety & Isolation Regression Tests', () {
    test('1. Unauthenticated state stays memory-only without shared demo fallback', () async {
      AuthIsolation.instance.clearSession();
      final nc = StudentNoteController.instance;
      nc.clearData();

      expect(nc.notes, isEmpty);

      // Attempting to create a note while logged out
      final note = await nc.createNote(
        title: 'Memory-Only Note',
        content: 'Should not write to any shared namespace.',
      );

      expect(note.userId, isNull);
      expect(nc.notes.length, 1);

      // Reloading from storage while unauthenticated restores nothing (no demo user fallback)
      nc.clearData();
      await nc.load();
      expect(nc.notes, isEmpty);
    });

    test('2. Subject reference clearing preserves note data intact', () async {
      final nc = StudentNoteController.instance;

      final note = await nc.createNote(
        title: 'Core Principles',
        content: 'Definitions and theorems.',
        subjectId: 'sub_temp',
        chapterId: 'ch_temp',
        topicId: 'top_temp',
      );

      await nc.clearSubjectReference('sub_temp');

      final current = nc.noteById(note.id);
      expect(current?.subjectId, isNull);
      expect(current?.chapterId, 'ch_temp');
      expect(current?.topicId, 'top_temp');
      expect(current?.title, 'Core Principles');
      expect(current?.content, 'Definitions and theorems.');
    });

    test('3. Chapter reference clearing preserves note data intact', () async {
      final nc = StudentNoteController.instance;

      final note = await nc.createNote(
        title: 'Theorem 1',
        content: 'Proof steps.',
        chapterId: 'ch_target',
      );

      await nc.clearChapterReference('ch_target');

      final current = nc.noteById(note.id);
      expect(current?.chapterId, isNull);
      expect(current?.title, 'Theorem 1');
    });

    test('4. Topic reference clearing preserves note data intact', () async {
      final nc = StudentNoteController.instance;

      final note = await nc.createNote(
        title: 'Topic Proof',
        content: 'Proof steps.',
        topicId: 'top_target',
      );

      await nc.clearTopicReference('top_target');

      final current = nc.noteById(note.id);
      expect(current?.topicId, isNull);
      expect(current?.title, 'Topic Proof');
    });

    test('5. Resource reference clearing removes reference without deleting note', () async {
      final nc = StudentNoteController.instance;

      final note = await nc.createNote(
        title: 'Referenced Note',
        content: 'Key takeaways.',
        resourceIds: const ['res_1', 'res_2'],
      );

      await nc.clearResourceReference('res_1');

      final current = nc.noteById(note.id);
      expect(current?.resourceIds, ['res_2']);
      expect(current?.content, 'Key takeaways.');
    });

    test('6. Creating or viewing notes never auto-completes tasks or study sessions', () async {
      final nc = StudentNoteController.instance;
      final tc = TaskController.instance;
      final sc = StudyController.instance;

      final task = await tc.createTask(title: 'Read chapter 3');
      expect(task.isCompleted, isFalse);
      expect(sc.sessions, isEmpty);

      // Create note
      final note = await nc.createNote(
        title: 'Chapter 3 Notes',
        content: 'Comprehensive summaries.',
      );

      // Mark viewed
      await nc.markViewed(note.id);

      // Assert zero side-effects on tasks or study sessions
      expect(tc.tasks.firstWhere((t) => t.id == task.id).isCompleted, isFalse);
      expect(sc.sessions, isEmpty);
    });

    test('7. Multiple updates to tags normalize and prevent duplicates', () async {
      final nc = StudentNoteController.instance;

      final note = await nc.createNote(
        title: 'Tag Test',
        tags: const ['math', '#Math', ' algebra '],
      );

      expect(note.tags, ['math', 'algebra']);

      await nc.updateNote(
        note.copyWith(tags: const ['math', '#geometry', 'geometry', 'MATH']),
      );

      final updated = nc.noteById(note.id);
      expect(updated?.tags, ['math', 'geometry']);
    });

    test('8. Pinned notes query respects active/archived state', () async {
      final nc = StudentNoteController.instance;

      final note1 = await nc.createNote(title: 'Pin 1', isPinned: true);
      final note2 = await nc.createNote(title: 'Pin 2', isPinned: true);

      expect(nc.pinnedNotes.length, 2);

      await nc.archiveNote(note1.id);
      // Archived pinned notes must not show in active pinned query
      expect(nc.pinnedNotes.length, 1);
      expect(nc.pinnedNotes.first.id, note2.id);

      await nc.restoreNote(note1.id);
      expect(nc.pinnedNotes.length, 2);
    });
  });
}
