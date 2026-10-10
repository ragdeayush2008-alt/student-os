import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/student_note.dart';
import 'package:student_os/features/notes/student_note_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_user_notes');
    StudentNoteController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    StudentNoteController.instance.clearData();
  });

  group('StudentNoteController Unit Tests', () {
    test('1. Creates a note and persists locally', () async {
      final ctrl = StudentNoteController.instance;

      final note = await ctrl.createNote(
        title: 'Trial Balance Notes',
        content: 'Debit balances equal credit balances.',
        subjectId: 'sub_acc',
        chapterId: 'ch_trial',
        topicId: 'top_rules',
        tags: const ['accounting', 'trial_balance'],
        isPinned: true,
      );

      expect(ctrl.notes.length, 1);
      expect(ctrl.notes.first.id, note.id);
      expect(ctrl.notes.first.title, 'Trial Balance Notes');
      expect(ctrl.notes.first.isPinned, isTrue);
      expect(ctrl.notes.first.userId, 'test_user_notes');

      // Verify re-loading from local storage
      ctrl.clearData();
      expect(ctrl.notes, isEmpty);

      await ctrl.load();
      expect(ctrl.notes.length, 1);
      expect(ctrl.notes.first.title, 'Trial Balance Notes');
    });

    test('2. Updates a note safely', () async {
      final ctrl = StudentNoteController.instance;

      final note = await ctrl.createNote(
        title: 'Draft Note',
        content: 'Initial text',
      );

      final updated = note.copyWith(
        title: 'Finalized Note',
        content: 'Polished explanation with formulas.',
        tags: const ['final'],
      );

      await ctrl.updateNote(updated);

      expect(ctrl.notes.first.title, 'Finalized Note');
      expect(ctrl.notes.first.content, 'Polished explanation with formulas.');
      expect(ctrl.notes.first.tags, ['final']);
    });

    test('3. Deletes a note', () async {
      final ctrl = StudentNoteController.instance;

      final note = await ctrl.createNote(
        title: 'Temporary Note',
        content: 'Delete me',
      );

      expect(ctrl.notes.length, 1);
      await ctrl.deleteNote(note.id);
      expect(ctrl.notes, isEmpty);
    });

    test('4. Archives and restores notes', () async {
      final ctrl = StudentNoteController.instance;

      final note = await ctrl.createNote(
        title: 'Old Syllabus Note',
        content: '2024 syllabus',
      );

      expect(ctrl.allActiveNotes.length, 1);
      expect(ctrl.archivedNotes, isEmpty);

      await ctrl.archiveNote(note.id);
      expect(ctrl.allActiveNotes, isEmpty);
      expect(ctrl.archivedNotes.length, 1);

      await ctrl.restoreNote(note.id);
      expect(ctrl.allActiveNotes.length, 1);
      expect(ctrl.archivedNotes, isEmpty);
    });

    test('5. Toggles pin and marks viewed', () async {
      final ctrl = StudentNoteController.instance;

      final note = await ctrl.createNote(title: 'Key Summary');
      expect(ctrl.pinnedNotes, isEmpty);

      await ctrl.togglePinned(note.id);
      expect(ctrl.pinnedNotes.length, 1);
      expect(ctrl.pinnedNotes.first.isPinned, isTrue);

      expect(ctrl.notes.first.lastViewedAt, isNull);
      await ctrl.markViewed(note.id);
      expect(ctrl.notes.first.lastViewedAt, isNotNull);
    });

    test('6. Attaches and detaches academic resources', () async {
      final ctrl = StudentNoteController.instance;

      final note = await ctrl.createNote(title: 'Calculus Notes');
      expect(note.resourceIds, isEmpty);

      await ctrl.attachResource(note.id, 'res_pdf_limits');
      expect(ctrl.notes.first.resourceIds, ['res_pdf_limits']);

      // Attaching duplicate is idempotent
      await ctrl.attachResource(note.id, 'res_pdf_limits');
      expect(ctrl.notes.first.resourceIds, ['res_pdf_limits']);

      await ctrl.attachResource(note.id, 'res_video_derivatives');
      expect(ctrl.notes.first.resourceIds.length, 2);

      await ctrl.detachResource(note.id, 'res_pdf_limits');
      expect(ctrl.notes.first.resourceIds, ['res_video_derivatives']);
    });

    test('7. Safe unlinking preserves note content when Subject, Chapter, Topic, or Resource is deleted', () async {
      final ctrl = StudentNoteController.instance;

      await ctrl.createNote(
        title: 'Master Study Note',
        content: 'Critical student authored notes.',
        subjectId: 'sub_math',
        chapterId: 'ch_calc',
        topicId: 'top_int',
        resourceIds: const ['res_formula_sheet'],
      );

      // Subject deleted
      await ctrl.clearSubjectReference('sub_math');
      expect(ctrl.notes.first.subjectId, isNull);
      expect(ctrl.notes.first.content, 'Critical student authored notes.');

      // Chapter deleted
      await ctrl.clearChapterReference('ch_calc');
      expect(ctrl.notes.first.chapterId, isNull);

      // Topic deleted
      await ctrl.clearTopicReference('top_int');
      expect(ctrl.notes.first.topicId, isNull);

      // Resource deleted
      await ctrl.clearResourceReference('res_formula_sheet');
      expect(ctrl.notes.first.resourceIds, isEmpty);

      // Note survives completely intact
      expect(ctrl.notes.first.title, 'Master Study Note');
      expect(ctrl.notes.first.content, 'Critical student authored notes.');
    });

    test('8. Query filtering across subject, chapter, topic, and tags', () async {
      final ctrl = StudentNoteController.instance;

      await ctrl.createNote(
        title: 'Subject A Note 1',
        subjectId: 'sub_a',
        chapterId: 'ch_1',
        topicId: 'top_1',
        tags: const ['important'],
      );

      await ctrl.createNote(
        title: 'Subject A Note 2',
        subjectId: 'sub_a',
        chapterId: 'ch_2',
        topicId: 'top_2',
        tags: const ['review'],
      );

      await ctrl.createNote(
        title: 'Subject B Note 1',
        subjectId: 'sub_b',
        tags: const ['important'],
      );

      expect(ctrl.notesForSubject('sub_a').length, 2);
      expect(ctrl.notesForSubject('sub_b').length, 1);
      expect(ctrl.notesForChapter('ch_1').length, 1);
      expect(ctrl.notesForTopic('top_1').length, 1);
      expect(ctrl.notesByTag('important').length, 2);
      expect(ctrl.notesByTag('review').length, 1);
      expect(ctrl.allTags, {'important', 'review'});
    });

    test('9. Stress query performance on 1,000 notes', () async {
      final ctrl = StudentNoteController.instance;

      final notesList = List.generate(1000, (i) {
        return StudentNote(
          id: 'note_$i',
          userId: 'test_user_notes',
          title: 'Academic Note $i on Chemistry and Physics',
          content: 'Detailed formula and explanation for concept $i in organic chemistry.',
          subjectId: 'sub_${i % 10}',
          chapterId: 'ch_${i % 50}',
          topicId: 'top_${i % 200}',
          tags: ['chemistry', 'physics', 'tag_$i'],
          isPinned: i % 20 == 0,
          updatedAt: DateTime.now().subtract(Duration(minutes: i)),
        );
      });

      for (final note in notesList) {
        await ctrl.createNote(
          title: note.title,
          content: note.content,
          subjectId: note.subjectId,
          chapterId: note.chapterId,
          topicId: note.topicId,
          tags: note.tags,
          isPinned: note.isPinned,
        );
      }

      final stopwatch = Stopwatch()..start();
      final searchResults = ctrl.searchNotes('Chemistry');
      final elapsedSearch = stopwatch.elapsedMilliseconds;

      expect(searchResults.length, 1000);
      expect(elapsedSearch, lessThan(250), reason: 'Search across 1000 notes must complete in under 250ms');

      final subjectNotes = ctrl.notesForSubject('sub_0');
      expect(subjectNotes.length, 100);
    });
  });
}
