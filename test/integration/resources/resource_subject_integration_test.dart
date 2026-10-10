import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/data/models/academic_resource.dart';
import 'package:student_os/features/resources/resource_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ResourceController — subject & tag queries', () {
    test('resourcesForSubject returns only linked resources', () async {
      final subId = 'sub_res_query_1';
      final linked = await ResourceController.instance.createResource(
        title: 'Linked',
        resourceType: ResourceType.note,
        subjectId: subId,
      );
      await ResourceController.instance.createResource(
        title: 'Unlinked',
        resourceType: ResourceType.link,
      );

      final result = ResourceController.instance.resourcesForSubject(subId);
      expect(result.length, 1);
      expect(result.single.id, linked.id);

      await ResourceController.instance.deleteResource(linked.id);
      final unlinked = ResourceController.instance.resources
          .where((r) => r.title == 'Unlinked')
          .toList();
      for (final r in unlinked) {
        await ResourceController.instance.deleteResource(r.id);
      }
    });

    test('resourcesForTag returns only matching resources', () async {
      final tagged = await ResourceController.instance.createResource(
        title: 'Tagged',
        resourceType: ResourceType.note,
        tags: ['physics'],
      );
      await ResourceController.instance.createResource(
        title: 'Untagged',
        resourceType: ResourceType.link,
      );

      final result = ResourceController.instance.resourcesForTag('Physics');
      expect(result.length, 1);
      expect(result.single.id, tagged.id);

      await ResourceController.instance.deleteResource(tagged.id);
      final untagged = ResourceController.instance.resources
          .where((r) => r.title == 'Untagged')
          .toList();
      for (final r in untagged) {
        await ResourceController.instance.deleteResource(r.id);
      }
    });

    test(
      'clearSubjectReference preserves resource but clears subjectId',
      () async {
        final subId = 'sub_res_query_2';
        final linked = await ResourceController.instance.createResource(
          title: 'To unlink',
          resourceType: ResourceType.note,
          subjectId: subId,
        );

        await ResourceController.instance.clearSubjectReference(subId);

        expect(ResourceController.instance.resourcesForSubject(subId), isEmpty);
        final remaining = ResourceController.instance.resources
            .where((r) => r.id == linked.id)
            .single;
        expect(remaining.subjectId, isNull);

        await ResourceController.instance.deleteResource(linked.id);
      },
    );

    test(
      'resource stays searchable after subject reference is cleared',
      () async {
        final subId = 'sub_res_query_3';
        final linked = await ResourceController.instance.createResource(
          title: 'Still findable',
          description: 'unique searchable phrase',
          resourceType: ResourceType.note,
          subjectId: subId,
        );

        await ResourceController.instance.clearSubjectReference(subId);

        final found = ResourceController.instance.searchResources(
          'unique searchable phrase',
        );
        expect(found.any((r) => r.id == linked.id), isTrue);

        await ResourceController.instance.deleteResource(linked.id);
      },
    );

    test(
      'resource can be re-linked to another subject after clearing',
      () async {
        final subA = 'sub_res_query_4';
        final subB = 'sub_res_query_5';
        final linked = await ResourceController.instance.createResource(
          title: 'Re-linkable',
          resourceType: ResourceType.note,
          subjectId: subA,
        );

        await ResourceController.instance.clearSubjectReference(subA);
        await ResourceController.instance.updateResource(
          linked.copyWith(subjectId: subB),
        );

        final relinked = ResourceController.instance.resources
            .where((r) => r.id == linked.id)
            .single;
        expect(relinked.subjectId, subB);
        expect(
          ResourceController.instance.resourcesForSubject(subB).single.id,
          linked.id,
        );

        await ResourceController.instance.deleteResource(linked.id);
      },
    );
  });

  group('Subject deletion — reference safety', () {
    test(
      'deleting a subject preserves resources and clears subjectId',
      () async {
        final sub = await SubjectController.instance.createSubject(
          name: 'Res Deleting Subject',
        );
        final resource = await ResourceController.instance.createResource(
          title: 'Subject-bound resource',
          resourceType: ResourceType.note,
          subjectId: sub.id,
        );

        await SubjectController.instance.deleteSubject(sub.id);

        expect(
          ResourceController.instance.resources.any((r) => r.id == resource.id),
          isTrue,
        );
        expect(
          ResourceController.instance.resourcesForSubject(sub.id),
          isEmpty,
        );
        final remaining = ResourceController.instance.resources
            .where((r) => r.id == resource.id)
            .single;
        expect(remaining.subjectId, isNull);

        await ResourceController.instance.deleteResource(resource.id);
      },
    );

    test(
      'deleting a subject preserves tasks and clears task.subjectId',
      () async {
        final sub = await SubjectController.instance.createSubject(
          name: 'Res Deleting Tasks Subject',
        );
        final task = await TaskController.instance.createTask(
          title: 'Subject-bound task',
          subjectId: sub.id,
        );

        await SubjectController.instance.deleteSubject(sub.id);

        expect(
          TaskController.instance.tasks.any((t) => t.id == task.id),
          isTrue,
        );
        expect(TaskController.instance.tasksForSubject(sub.id), isEmpty);
        expect(
          TaskController.instance.tasks
              .where((t) => t.id == task.id)
              .single
              .subjectId,
          isNull,
        );

        await TaskController.instance.deleteTask(task.id);
      },
    );

    test('archiving a subject keeps resource and task references', () async {
      final sub = await SubjectController.instance.createSubject(
        name: 'Res Archiving Subject',
      );
      final resource = await ResourceController.instance.createResource(
        title: 'Archive-bound resource',
        resourceType: ResourceType.note,
        subjectId: sub.id,
      );
      final task = await TaskController.instance.createTask(
        title: 'Archive-bound task',
        subjectId: sub.id,
      );

      await SubjectController.instance.archiveSubject(sub.id);

      expect(
        ResourceController.instance.resourcesForSubject(sub.id).single.id,
        resource.id,
      );
      expect(
        TaskController.instance.tasksForSubject(sub.id).single.id,
        task.id,
      );
      expect(
        ResourceController.instance.resources
            .where((r) => r.id == resource.id)
            .single
            .subjectId,
        sub.id,
      );

      await ResourceController.instance.deleteResource(resource.id);
      await TaskController.instance.deleteTask(task.id);
      await SubjectController.instance.deleteSubject(sub.id);
    });

    test(
      'renaming a subject keeps explicit resource/task relationships',
      () async {
        final sub = await SubjectController.instance.createSubject(
          name: 'Original name',
        );
        final resource = await ResourceController.instance.createResource(
          title: 'Renamed-context resource',
          resourceType: ResourceType.note,
          subjectId: sub.id,
        );
        final task = await TaskController.instance.createTask(
          title: 'Renamed-context task',
          subjectId: sub.id,
        );

        await SubjectController.instance.updateSubject(
          sub.copyWith(name: 'Renamed subject'),
        );

        final renamed = SubjectController.instance.subjectById(sub.id)!;
        expect(renamed.name, 'Renamed subject');
        // Lookup is keyed on subjectId, so relationships survive renames.
        expect(
          ResourceController.instance.resourcesForSubject(sub.id).single.id,
          resource.id,
        );
        expect(
          TaskController.instance.tasksForSubject(sub.id).single.id,
          task.id,
        );
        expect(
          ResourceController.instance.resources
              .where((r) => r.id == resource.id)
              .single
              .subjectId,
          sub.id,
        );

        await ResourceController.instance.deleteResource(resource.id);
        await TaskController.instance.deleteTask(task.id);
        await SubjectController.instance.deleteSubject(sub.id);
      },
    );
  });
}
