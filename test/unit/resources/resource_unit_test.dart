import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/data/models/academic_resource.dart';
import 'package:student_os/features/resources/resource_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AcademicResource — tag normalization', () {
    test('normalizeTags lowercases, trims and deduplicates', () {
      final result = AcademicResource.normalizeTags([
        '  Math  ',
        'MATH',
        'Revision',
        ' revision ',
        '',
        'math',
        '  ',
      ]);
      expect(result, ['math', 'revision']);
    });

    test('normalizeTags preserves first-seen order', () {
      final result = AcademicResource.normalizeTags(['Zulu', 'alpha', 'ZULU']);
      expect(result, ['zulu', 'alpha']);
    });

    test('duplicate tags collapse on create', () async {
      final r = await ResourceController.instance.createResource(
        title: 'Tagged note',
        resourceType: ResourceType.note,
        tags: ['Physics', ' physics ', 'PHYSICS', 'Exam'],
      );
      expect(r.tags, ['physics', 'exam']);

      await ResourceController.instance.deleteResource(r.id);
    });

    test('updateResource normalizes edited tags', () async {
      final created = await ResourceController.instance.createResource(
        title: 'Editable',
        resourceType: ResourceType.note,
        tags: ['one'],
      );
      await ResourceController.instance.updateResource(
        created.copyWith(tags: ['Two', ' two ', 'Three']),
      );
      final updated = ResourceController.instance.resources
          .where((r) => r.id == created.id)
          .single;
      expect(updated.tags, ['two', 'three']);

      await ResourceController.instance.deleteResource(created.id);
    });
  });

  group('AcademicResource — old JSON compatibility', () {
    test('legacy resource JSON deserializes with defaults', () {
      final oldJson = {
        'id': 'res_old',
        'title': 'Legacy note',
        'resourceType': 'note',
        'description': 'from an older phase',
      };
      final r = AcademicResource.fromJson(oldJson);
      expect(r.id, 'res_old');
      expect(r.title, 'Legacy note');
      expect(r.tags, isEmpty);
      expect(r.subjectId, isNull);
      expect(r.examId, isNull);
      expect(r.reference, isNull);
      expect(r.isFavorite, isFalse);
      expect(r.archived, isFalse);
      expect(r.accessCount, 0);
    });

    test('full JSON roundtrip preserves all fields', () {
      final r = AcademicResource(
        id: 'res_1',
        title: 'Round trip',
        description: 'Desc',
        resourceType: ResourceType.link,
        subjectId: 'sub_1',
        examId: 'exam_1',
        reference: 'https://example.com',
        content: 'Body',
        tags: ['math', 'exam'],
        isFavorite: true,
      );
      final restored = AcademicResource.fromJson(r.toJson());
      expect(restored.id, r.id);
      expect(restored.title, r.title);
      expect(restored.resourceType, ResourceType.link);
      expect(restored.subjectId, 'sub_1');
      expect(restored.examId, 'exam_1');
      expect(restored.reference, r.reference);
      expect(restored.content, r.content);
      expect(restored.tags, ['math', 'exam']);
      expect(restored.isFavorite, isTrue);
    });
  });
}
