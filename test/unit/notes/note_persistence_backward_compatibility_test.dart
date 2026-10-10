import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/student_note.dart';

void main() {
  group('StudentNote Backward Compatibility & Edge Cases', () {
    test('1. Deserializes legacy minimal note JSON without modern fields', () {
      final legacyJson = {
        'id': 'note_legacy_101',
        'title': 'Minimal Note',
        'content': 'Basic text content without metadata',
      };

      final note = StudentNote.fromJson(legacyJson);

      expect(note.id, 'note_legacy_101');
      expect(note.title, 'Minimal Note');
      expect(note.content, 'Basic text content without metadata');
      expect(note.plainText, 'Basic text content without metadata');
      expect(note.subjectId, isNull);
      expect(note.chapterId, isNull);
      expect(note.topicId, isNull);
      expect(note.resourceIds, isEmpty);
      expect(note.tags, isEmpty);
      expect(note.isPinned, isFalse);
      expect(note.isArchived, isFalse);
      expect(note.createdAt, isNotNull);
      expect(note.updatedAt, isNotNull);
      expect(note.lastViewedAt, isNull);
      expect(note.wordCount, 5);
    });

    test('2. Handles complex Unicode, formulas, and mathematical notation', () {
      const mathContent = r'''
$$ \sigma = \sqrt{\frac{1}{N} \sum_{i=1}^N (x_i - \mu)^2} $$
$$\int_{0}^{\infty} e^{-x^2} dx = \frac{\sqrt{\pi}}{2}$$
α β γ δ ε θ λ μ π σ τ φ ψ ω
''';

      final note = StudentNote(
        id: 'note_math',
        title: 'Statistical Formulas: σ, μ, ∑',
        content: mathContent,
        tags: const ['math', 'statistics', 'σ'],
      );

      final json = note.toJson();
      final reconstructed = StudentNote.fromJson(json);

      expect(reconstructed.title, 'Statistical Formulas: σ, μ, ∑');
      expect(reconstructed.content, mathContent);
      expect(reconstructed.tags, contains('math'));
      expect(reconstructed.tags, contains('statistics'));
    });

    test('3. Handles extreme note sizes (100,000 characters)', () {
      final hugeContent = 'Paragraph of academic text.\n' * 3500;
      final note = StudentNote(
        id: 'note_huge',
        title: 'Massive Monograph',
        content: hugeContent,
      );

      expect(note.content.length, greaterThan(90000));
      expect(note.wordCount, greaterThan(10000));

      final json = note.toJson();
      final restored = StudentNote.fromJson(json);
      expect(restored.content.length, note.content.length);
      expect(restored.wordCount, note.wordCount);
    });

    test('4. Empty strings and whitespace normalization', () {
      final note = StudentNote(
        id: 'note_empty',
        title: '   ',
        content: '   \n\t  ',
      );

      expect(note.isEmpty, isTrue);
      expect(note.wordCount, 0);
      expect(note.plainText, '');
      expect(note.snippet, 'No additional text');
    });

    test('5. Safe handling of invalid types in every JSON field', () {
      final badJson = {
        'id': 12345,
        'userId': true,
        'title': false,
        'content': 999,
        'plainText': ['not', 'a', 'string'],
        'subjectId': 456,
        'chapterId': 789,
        'topicId': 101112,
        'resourceIds': 'single_id_instead_of_list',
        'tags': {'set': 'instead_of_list'},
        'isPinned': 'true',
        'isArchived': 1,
        'createdAt': 123456789,
        'updatedAt': 'not_a_date',
        'lastViewedAt': {},
        'wordCount': '50',
      };

      final note = StudentNote.fromJson(badJson);
      expect(note.id, isNotNull);
      expect(note.title, '');
      expect(note.content, '');
      expect(note.tags, isEmpty);
      expect(note.resourceIds, isEmpty);
      expect(note.isPinned, isFalse);
      expect(note.isArchived, isFalse);
      expect(note.createdAt, isNotNull);
      expect(note.updatedAt, isNotNull);
    });
  });
}
