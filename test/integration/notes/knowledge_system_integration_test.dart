import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/analytics/academic_analytics_engine.dart';
import 'package:student_os/core/analytics/performance_snapshot.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/data/models/academic_resource.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/notes/student_note_controller.dart';
import 'package:student_os/features/resources/resource_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_integ_a');
    await StorageService.instance.clearUser(userId: 'user_integ_a');
    await StorageService.instance.clearUser(userId: 'user_alpha');
    await StorageService.instance.clearUser(userId: 'user_beta');
    ControllerIsolation.instance.clearAllControllers();
    await StudentNoteController.instance.load();
    await SubjectController.instance.load();
    await AcademicKnowledgeController.instance.load();
    await ResourceController.instance.load();
    await TaskController.instance.load();
    await StudyController.instance.load();
  });

  tearDown(() async {
    await StorageService.instance.clearUser(userId: 'user_integ_a');
    await StorageService.instance.clearUser(userId: 'user_alpha');
    await StorageService.instance.clearUser(userId: 'user_beta');
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  group('Knowledge & Notes System Integration Tests', () {
    test('1. Full Flow: Subject -> Chapter -> Topic -> Note creation with inherited context', () async {
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final nc = StudentNoteController.instance;

      // 1. Create Subject
      final subject = await sc.createSubject(
        name: 'Accountancy',
        color: 0xFF2EC4B6,
      );

      // 2. Create Chapter
      final chapter = await kc.createChapter(
        subjectId: subject.id,
        title: 'Depreciation Accounting',
      );

      // 3. Create Topic
      final topic = await kc.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Straight Line Method',
      );

      // 4. Create Note under Topic
      final note = await nc.createNote(
        title: 'SLM Formula & Examples',
        content: 'SLM Depreciation = (Original Cost - Estimated Residual Value) / Useful Life.',
        subjectId: subject.id,
        chapterId: chapter.id,
        topicId: topic.id,
        tags: const ['depreciation', 'slm'],
        isPinned: true,
      );

      expect(note.subjectId, subject.id);
      expect(note.chapterId, chapter.id);
      expect(note.topicId, topic.id);

      // Verify Queries
      expect(nc.notesForSubject(subject.id).length, 1);
      expect(nc.notesForChapter(chapter.id).length, 1);
      expect(nc.notesForTopic(topic.id).length, 1);
      expect(nc.pinnedNotes.length, 1);
    });

    test('2. Resource ↔ Note Integration and Safe Resource Deletion', () async {
      final rc = ResourceController.instance;
      final nc = StudentNoteController.instance;

      // Create an academic resource
      final resource = await rc.createResource(
        title: 'Depreciation Quick Guide PDF',
        resourceType: ResourceType.document,
      );

      // Create note and link resource
      final note = await nc.createNote(
        title: 'Chapter Review Notes',
        content: 'Reviewing key concepts from the guide.',
        resourceIds: [resource.id],
      );

      expect(nc.notesForResource(resource.id).length, 1);
      expect(nc.notesForResource(resource.id).first.id, note.id);

      // Delete the resource -> Note reference is cleanly removed, note remains safe
      await rc.deleteResource(resource.id);

      expect(rc.resources, isEmpty);
      expect(nc.notes.length, 1);
      expect(nc.notes.first.resourceIds, isEmpty);
      expect(nc.notes.first.content, 'Reviewing key concepts from the guide.');
    });

    test('3. Note != Task & Note != StudySession (Creating note never auto-completes tasks or study)', () async {
      final tc = TaskController.instance;
      final sc = StudyController.instance;
      final nc = StudentNoteController.instance;

      // Create a task
      final task = await tc.createTask(
        title: 'Solve 10 depreciation problems',
      );
      expect(task.isCompleted, isFalse);

      // Create note
      await nc.createNote(
        title: 'Solved Problem Notes',
        content: 'Step-by-step working.',
      );

      // Verify Task remains uncompleted
      final currentTask = tc.tasks.firstWhere((t) => t.id == task.id);
      expect(currentTask.isCompleted, isFalse);

      // Verify Study sessions count remains unchanged (zero auto study sessions)
      expect(sc.sessions, isEmpty);
    });

    test('4. Multi-User Isolation (User A -> Logout -> User B -> User A)', () async {
      final nc = StudentNoteController.instance;

      // User A logs in and creates 2 notes
      AuthIsolation.instance.setAuthenticatedUser('user_alpha');
      ControllerIsolation.instance.reloadAllControllers('user_alpha');

      await nc.createNote(
        title: 'User A Secret Note 1',
        content: 'Confidential alpha notes',
        tags: const ['alpha'],
      );
      await nc.createNote(
        title: 'User A Secret Note 2',
        content: 'More alpha notes',
      );
      expect(nc.notes.length, 2);

      // User A logs out
      AuthIsolation.instance.clearSession();
      ControllerIsolation.instance.clearAllControllers();
      expect(nc.notes, isEmpty);

      // User B logs in
      AuthIsolation.instance.setAuthenticatedUser('user_beta');
      ControllerIsolation.instance.reloadAllControllers('user_beta');
      await nc.load();

      // User B sees ZERO of User A's notes
      expect(nc.notes, isEmpty);
      expect(nc.searchNotes('Secret'), isEmpty);
      expect(nc.notesByTag('alpha'), isEmpty);

      // User B creates a note
      await nc.createNote(
        title: 'User B Biology Note',
        content: 'Photosynthesis dark reaction',
      );
      expect(nc.notes.length, 1);
      expect(nc.notes.first.title, 'User B Biology Note');

      // User B logs out
      AuthIsolation.instance.clearSession();
      ControllerIsolation.instance.clearAllControllers();
      expect(nc.notes, isEmpty);

      // User A logs back in
      AuthIsolation.instance.setAuthenticatedUser('user_alpha');
      ControllerIsolation.instance.reloadAllControllers('user_alpha');
      await nc.load();

      // User A's 2 notes return intact
      expect(nc.notes.length, 2);
      expect(nc.notes.any((n) => n.title == 'User A Secret Note 1'), isTrue);
      expect(nc.notes.any((n) => n.title == 'User A Secret Note 2'), isTrue);
      expect(nc.notes.any((n) => n.title == 'User B Biology Note'), isFalse);
    });

    test('5. Performance Snapshot & Analytics Integration', () async {
      final nc = StudentNoteController.instance;
      final sc = SubjectController.instance;

      final subject = await sc.createSubject(
        name: 'Accountancy',
        color: 0xFF2EC4B6,
      );

      await nc.createNote(
        title: 'Accounting Standards Note 1',
        subjectId: subject.id,
      );
      await nc.createNote(
        title: 'Accounting Standards Note 2',
        subjectId: subject.id,
      );

      final snapshot = PerformanceSnapshot.fromControllers();
      const analyticsEngine = AcademicAnalyticsEngine();

      expect(snapshot.allNotes.length, 2);
      expect(analyticsEngine.calculateTotalNotes(snapshot), 2);
      expect(analyticsEngine.calculateNotesCreatedThisWeek(snapshot), 2);

      final bySubject = analyticsEngine.calculateNotesBySubject(snapshot);
      expect(bySubject['Accountancy'], 2);
    });
  });
}
