import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/student_note.dart';

void main() {
  group('StudentNote Model Tests', () {
    test('1. Creates StudentNote with default and custom values', () {
      final note = StudentNote(
        id: 'note_1',
        title: 'Depreciation Methods',
        content: '# Accounting\n- Straight line\n- Written down value',
        subjectId: 'sub_acc',
        chapterId: 'ch_dep',
        topicId: 'top_methods',
        tags: const ['depreciation', 'methods', 'accounting'],
        isPinned: true,
      );

      expect(note.id, 'note_1');
      expect(note.title, 'Depreciation Methods');
      expect(note.subjectId, 'sub_acc');
      expect(note.chapterId, 'ch_dep');
      expect(note.topicId, 'top_methods');
      expect(note.isPinned, isTrue);
      expect(note.isArchived, isFalse);
      expect(note.isActive, isTrue);
      expect(note.hasSubject, isTrue);
      expect(note.hasChapter, isTrue);
      expect(note.hasTopic, isTrue);
      expect(note.hasTags, isTrue);
      expect(note.tags, ['depreciation', 'methods', 'accounting']);
      expect(note.wordCount, greaterThan(0));
    });

    test('2. Deterministic word count computation', () {
      expect(StudentNote.computeWordCount(''), 0);
      expect(StudentNote.computeWordCount('   '), 0);
      expect(StudentNote.computeWordCount('Hello world'), 2);
      expect(StudentNote.computeWordCount('One\ntwo\tthree   four'), 4);
      expect(
        StudentNote.computeWordCount(
          'Accounting principles dictate that revenue is recognized when earned.',
        ),
        9,
      );
    });

    test('3. Plain text extraction from Markdown and notation', () {
      const markdown = '''# Unit 1: Introduction
## Overview
- First item
- [ ] Task item
- [x] Done item
1. Numbered item
> Blockquote text
`inline code`
**Bold word** and *italic*
[Link text](https://example.com)
''';

      final plain = StudentNote.extractPlainText(markdown);
      expect(plain.contains('#'), isFalse);
      expect(plain.contains('**'), isFalse);
      expect(plain.contains('>'), isFalse);
      expect(plain.contains('First item'), isTrue);
      expect(plain.contains('Task item'), isTrue);
      expect(plain.contains('Numbered item'), isTrue);
      expect(plain.contains('Link text'), isTrue);
      expect(plain.contains('https://example.com'), isFalse);
    });

    test('4. Tag normalization and deduplication', () {
      final raw = ['#Math', ' MATH ', '#algebra', 'algebra', 'calculus', ''];
      final normalized = StudentNote.normalizeTags(raw);
      expect(normalized, ['math', 'algebra', 'calculus']);
    });

    test('5. Estimated read time and snippet calculation', () {
      final shortNote = StudentNote(
        id: '1',
        title: 'Quick',
        content: 'Short note content.',
      );
      expect(shortNote.estimatedReadMinutes, 1);
      expect(shortNote.snippet, 'Short note content.');

      final longText = List.generate(300, (i) => 'word$i').join(' ');
      final longNote = StudentNote(
        id: '2',
        title: 'Long Note',
        content: longText,
      );
      expect(longNote.estimatedReadMinutes, 2);
      expect(longNote.snippet.length, lessThanOrEqualTo(120));
      expect(longNote.snippet.endsWith('...'), isTrue);
    });

    test('6. Serialization to JSON and deserialization from JSON roundtrip', () {
      final original = StudentNote(
        id: 'note_json_1',
        userId: 'user_123',
        title: 'Partnership Fundamentals',
        content: 'Profit sharing ratio rules\n1. Equal if no agreement',
        subjectId: 'sub_acc',
        chapterId: 'ch_part',
        topicId: 'top_ratios',
        resourceIds: const ['res_pdf_1', 'res_vid_2'],
        tags: const ['partnership', 'ratios'],
        isPinned: true,
        isArchived: false,
        createdAt: DateTime(2026, 3, 1, 10, 0),
        updatedAt: DateTime(2026, 3, 2, 14, 30),
        lastViewedAt: DateTime(2026, 3, 3, 9, 15),
      );

      final json = original.toJson();
      final reconstructed = StudentNote.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.userId, original.userId);
      expect(reconstructed.title, original.title);
      expect(reconstructed.content, original.content);
      expect(reconstructed.plainText, original.plainText);
      expect(reconstructed.subjectId, original.subjectId);
      expect(reconstructed.chapterId, original.chapterId);
      expect(reconstructed.topicId, original.topicId);
      expect(reconstructed.resourceIds, original.resourceIds);
      expect(reconstructed.tags, original.tags);
      expect(reconstructed.isPinned, original.isPinned);
      expect(reconstructed.isArchived, original.isArchived);
      expect(reconstructed.createdAt, original.createdAt);
      expect(reconstructed.updatedAt, original.updatedAt);
      expect(reconstructed.lastViewedAt, original.lastViewedAt);
      expect(reconstructed.wordCount, original.wordCount);
      expect(reconstructed, equals(original));
    });

    test('7. Deserialization handles missing and corrupted fields safely', () {
      final corruptJson = <String, dynamic>{
        'id': 'note_corrupt',
        'title': null,
        'content': null,
        'createdAt': 'invalid_date_string',
        'updatedAt': null,
        'tags': 'not_a_list',
        'resourceIds': null,
        'isPinned': 'not_a_bool',
        'wordCount': 'not_an_int',
      };

      final note = StudentNote.fromJson(corruptJson);
      expect(note.id, 'note_corrupt');
      expect(note.title, '');
      expect(note.content, '');
      expect(note.plainText, '');
      expect(note.tags, isEmpty);
      expect(note.resourceIds, isEmpty);
      expect(note.isPinned, isFalse);
      expect(note.isArchived, isFalse);
      expect(note.wordCount, 0);
      expect(note.createdAt, isNotNull);
      expect(note.updatedAt, isNotNull);
    });

    test('8. copyWith correctly updates and clears nullable fields', () {
      final initial = StudentNote(
        id: 'note_copy',
        title: 'Initial Title',
        content: 'Initial Content',
        subjectId: 'sub_1',
        chapterId: 'ch_1',
        topicId: 'top_1',
        isPinned: false,
      );

      final updated = initial.copyWith(
        title: 'Updated Title',
        isPinned: true,
        clearSubjectId: true,
        clearChapterId: true,
        clearTopicId: true,
      );

      expect(updated.title, 'Updated Title');
      expect(updated.isPinned, isTrue);
      expect(updated.subjectId, isNull);
      expect(updated.chapterId, isNull);
      expect(updated.topicId, isNull);
      expect(updated.content, 'Initial Content');
    });
  });
}
