import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AcademicKnowledgeController.instance.clearData();
    SubjectController.instance.clearData();
  });

  tearDown(() async {
    AcademicKnowledgeController.instance.clearData();
    SubjectController.instance.clearData();
  });

  group('AcademicKnowledgeController - Chapter CRUD', () {
    test('creates and retrieves chapter for subject', () async {
      final kc = AcademicKnowledgeController.instance;
      final ch = await kc.createChapter(
        subjectId: 'sub_acc',
        title: 'Partnership',
        description: 'Partnership fundamental concepts',
        estimatedMinutes: 120,
      );

      expect(ch.id.isNotEmpty, isTrue);
      expect(ch.subjectId, 'sub_acc');
      expect(ch.title, 'Partnership');
      expect(ch.order, 0);

      final subjectChapters = kc.chaptersForSubject('sub_acc');
      expect(subjectChapters.length, 1);
      expect(subjectChapters.first.id, ch.id);
    });

    test('updates chapter properties', () async {
      final kc = AcademicKnowledgeController.instance;
      final ch = await kc.createChapter(
        subjectId: 'sub_acc',
        title: 'Partnership',
      );

      await kc.updateChapter(
        ch.copyWith(title: 'Partnership Accounting', order: 5),
      );

      final updated = kc.chapterById(ch.id);
      expect(updated?.title, 'Partnership Accounting');
      expect(updated?.order, 5);
    });

    test('deletes chapter and its topics', () async {
      final kc = AcademicKnowledgeController.instance;
      final ch = await kc.createChapter(
        subjectId: 'sub_acc',
        title: 'Partnership',
      );
      final top = await kc.createTopic(
        chapterId: ch.id,
        subjectId: 'sub_acc',
        title: 'Admission of Partner',
      );

      expect(kc.chaptersForSubject('sub_acc').length, 1);
      expect(kc.topicsForChapter(ch.id).length, 1);

      await kc.deleteChapter(ch.id);

      expect(kc.chaptersForSubject('sub_acc'), isEmpty);
      expect(kc.topicsForChapter(ch.id), isEmpty);
      expect(kc.topicById(top.id), isNull);
    });

    test('reorders chapters', () async {
      final kc = AcademicKnowledgeController.instance;
      final ch1 = await kc.createChapter(
        subjectId: 'sub_acc',
        title: 'Chapter 1',
        order: 0,
      );
      final ch2 = await kc.createChapter(
        subjectId: 'sub_acc',
        title: 'Chapter 2',
        order: 1,
      );

      await kc.reorderChapters('sub_acc', [ch2.id, ch1.id]);

      final chapters = kc.chaptersForSubject('sub_acc');
      expect(chapters.first.id, ch2.id);
      expect(chapters.last.id, ch1.id);
    });
  });

  group('AcademicKnowledgeController - Topic CRUD', () {
    test('creates and retrieves topic for chapter and subject', () async {
      final kc = AcademicKnowledgeController.instance;
      final ch = await kc.createChapter(
        subjectId: 'sub_law',
        title: 'Contract Act',
      );

      final top1 = await kc.createTopic(
        chapterId: ch.id,
        subjectId: 'sub_law',
        title: 'Offer and Acceptance',
        estimatedMinutes: 30,
        importance: TopicImportance.high,
      );

      final top2 = await kc.createTopic(
        chapterId: ch.id,
        subjectId: 'sub_law',
        title: 'Consideration',
        estimatedMinutes: 25,
      );

      expect(top1.order, 0);
      expect(top2.order, 1);

      final chapterTopics = kc.topicsForChapter(ch.id);
      expect(chapterTopics.length, 2);
      expect(chapterTopics.first.title, 'Offer and Acceptance');
      expect(chapterTopics.last.title, 'Consideration');

      final subjectTopics = kc.topicsForSubject('sub_law');
      expect(subjectTopics.length, 2);
    });

    test('updates topic', () async {
      final kc = AcademicKnowledgeController.instance;
      final ch = await kc.createChapter(
        subjectId: 'sub_eco',
        title: 'Microeconomics',
      );
      final top = await kc.createTopic(
        chapterId: ch.id,
        subjectId: 'sub_eco',
        title: 'Demand Theory',
      );

      await kc.updateTopic(
        top.copyWith(
          title: 'Advanced Demand & Elasticity',
          estimatedMinutes: 45,
          importance: TopicImportance.critical,
        ),
      );

      final updated = kc.topicById(top.id);
      expect(updated?.title, 'Advanced Demand & Elasticity');
      expect(updated?.estimatedMinutes, 45);
      expect(updated?.importance, TopicImportance.critical);
    });

    test('deletes individual topic', () async {
      final kc = AcademicKnowledgeController.instance;
      final ch = await kc.createChapter(
        subjectId: 'sub_eco',
        title: 'Microeconomics',
      );
      final top = await kc.createTopic(
        chapterId: ch.id,
        subjectId: 'sub_eco',
        title: 'Supply Theory',
      );

      expect(kc.topicsForChapter(ch.id).length, 1);
      await kc.deleteTopic(top.id);
      expect(kc.topicsForChapter(ch.id), isEmpty);
    });

    test('clearSubjectKnowledge cleans all subject chapters and topics', () async {
      final kc = AcademicKnowledgeController.instance;
      final ch = await kc.createChapter(
        subjectId: 'sub_delete_me',
        title: 'Doomed Chapter',
      );
      await kc.createTopic(
        chapterId: ch.id,
        subjectId: 'sub_delete_me',
        title: 'Doomed Topic',
      );

      expect(kc.hasKnowledge('sub_delete_me'), isTrue);

      await kc.clearSubjectKnowledge('sub_delete_me');

      expect(kc.hasKnowledge('sub_delete_me'), isFalse);
      expect(kc.chaptersForSubject('sub_delete_me'), isEmpty);
      expect(kc.topicsForSubject('sub_delete_me'), isEmpty);
    });
  });
}
