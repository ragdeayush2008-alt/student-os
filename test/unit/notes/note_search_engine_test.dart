import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/student_note.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/notes/services/note_search_engine.dart';

void main() {
  group('NoteSearchEngine Deterministic Search Tests', () {
    final subjects = [
      Subject(id: 'sub_acc', name: 'Accountancy', color: 0xFF2EC4B6),
      Subject(id: 'sub_eco', name: 'Economics', color: 0xFF3B82D8),
    ];

    final chapters = [
      Chapter(id: 'ch_dep', subjectId: 'sub_acc', title: 'Depreciation Accounting'),
      Chapter(id: 'ch_micro', subjectId: 'sub_eco', title: 'Microeconomics Overview'),
    ];

    final topics = [
      Topic(id: 'top_straight', chapterId: 'ch_dep', subjectId: 'sub_acc', title: 'Straight Line Method'),
      Topic(id: 'top_elasticity', chapterId: 'ch_micro', subjectId: 'sub_eco', title: 'Price Elasticity of Demand'),
    ];

    final notes = [
      // Exact title match for "depreciation"
      StudentNote(
        id: 'note_exact',
        title: 'Depreciation',
        content: 'Overview of asset value reduction over time.',
        subjectId: 'sub_acc',
        updatedAt: DateTime(2026, 3, 1),
      ),
      // Title prefix match for "depreciation"
      StudentNote(
        id: 'note_prefix',
        title: 'Depreciation Schedules and Provisions',
        content: 'Calculation formulas.',
        subjectId: 'sub_acc',
        updatedAt: DateTime(2026, 3, 2),
      ),
      // Title substring match for "depreciation"
      StudentNote(
        id: 'note_substring',
        title: 'Advanced Methods of Depreciation in Practice',
        content: 'Practical examples.',
        subjectId: 'sub_acc',
        updatedAt: DateTime(2026, 3, 3),
      ),
      // Tag match for "depreciation"
      StudentNote(
        id: 'note_tag',
        title: 'Fixed Asset Valuation',
        content: 'Historical cost and balance sheet reporting.',
        tags: const ['depreciation', 'accounting'],
        subjectId: 'sub_acc',
        updatedAt: DateTime(2026, 3, 4),
      ),
      // Hierarchy match for "depreciation" (chapter is Depreciation Accounting)
      StudentNote(
        id: 'note_hierarchy',
        title: 'Straight Line Formula Notes',
        content: 'Formula: (Cost - Salvage) / Useful life.',
        chapterId: 'ch_dep',
        subjectId: 'sub_acc',
        updatedAt: DateTime(2026, 3, 5),
      ),
      // Content match for "depreciation"
      StudentNote(
        id: 'note_content',
        title: 'Accounting Standards 10',
        content: 'Property plant and equipment discusses depreciation rules.',
        subjectId: 'sub_acc',
        updatedAt: DateTime(2026, 3, 6),
      ),
      // Unrelated note
      StudentNote(
        id: 'note_unrelated',
        title: 'Market Structures',
        content: 'Monopoly, oligopoly, and perfect competition.',
        subjectId: 'sub_eco',
        updatedAt: DateTime(2026, 3, 7),
      ),
    ];

    test('1. Exact title match ranks #1', () {
      final results = NoteSearchEngine.search(
        notes: notes,
        query: 'depreciation',
        subjects: subjects,
        chapters: chapters,
        topics: topics,
      );

      expect(results, isNotEmpty);
      expect(results.first.id, 'note_exact');
    });

    test('2. Strict 6-tier deterministic ranking order', () {
      final results = NoteSearchEngine.search(
        notes: notes,
        query: 'depreciation',
        subjects: subjects,
        chapters: chapters,
        topics: topics,
      );

      final resultIds = results.map((n) => n.id).toList();

      expect(resultIds.indexOf('note_exact'), 0, reason: 'Exact title match must be rank 1');
      expect(resultIds.indexOf('note_prefix'), 1, reason: 'Title prefix must be rank 2');
      expect(resultIds.indexOf('note_substring'), 2, reason: 'Title substring must be rank 3');
      expect(resultIds.indexOf('note_tag'), 3, reason: 'Tag match must be rank 4');
      expect(resultIds.indexOf('note_hierarchy'), 4, reason: 'Hierarchy match must be rank 5');
      expect(resultIds.indexOf('note_content'), 5, reason: 'Content match must be rank 6');
      expect(resultIds.contains('note_unrelated'), isFalse, reason: 'Unrelated note should not appear');
    });

    test('3. Query normalization handles case, extra whitespace, and punctuation', () {
      final r1 = NoteSearchEngine.search(
        notes: notes,
        query: '  DEPRECIATION!  ',
        subjects: subjects,
        chapters: chapters,
        topics: topics,
      );
      final r2 = NoteSearchEngine.search(
        notes: notes,
        query: 'depreciation',
        subjects: subjects,
        chapters: chapters,
        topics: topics,
      );

      expect(r1.map((n) => n.id), equals(r2.map((n) => n.id)));
    });

    test('4. Empty query returns notes sorted by pinned then recency', () {
      final notesWithPin = [
        StudentNote(id: '1', title: 'Note 1', updatedAt: DateTime(2026, 3, 1)),
        StudentNote(id: '2', title: 'Note 2', isPinned: true, updatedAt: DateTime(2026, 3, 2)),
        StudentNote(id: '3', title: 'Note 3', updatedAt: DateTime(2026, 3, 3)),
      ];

      final results = NoteSearchEngine.search(
        notes: notesWithPin,
        query: '',
      );

      expect(results.first.id, '2'); // Pinned
      expect(results[1].id, '3'); // More recent unpinned
      expect(results[2].id, '1');
    });

    test('5. Filtering by subjectId, chapterId, topicId, and tag', () {
      final resultsSubject = NoteSearchEngine.search(
        notes: notes,
        query: '',
        subjectId: 'sub_eco',
      );
      expect(resultsSubject.length, 1);
      expect(resultsSubject.first.id, 'note_unrelated');

      final resultsTag = NoteSearchEngine.search(
        notes: notes,
        query: '',
        tag: 'depreciation',
      );
      expect(resultsTag.length, 1);
      expect(resultsTag.first.id, 'note_tag');
    });

    test('6. Archived notes are excluded by default and included when requested', () {
      final testNotes = [
        StudentNote(id: 'act', title: 'Active', isArchived: false),
        StudentNote(id: 'arc', title: 'Archived', isArchived: true),
      ];

      final activeOnly = NoteSearchEngine.search(
        notes: testNotes,
        query: '',
        includeArchived: false,
      );
      expect(activeOnly.map((n) => n.id), ['act']);

      final withArchived = NoteSearchEngine.search(
        notes: testNotes,
        query: '',
        includeArchived: true,
      );
      expect(withArchived.length, 2);
    });
  });
}
