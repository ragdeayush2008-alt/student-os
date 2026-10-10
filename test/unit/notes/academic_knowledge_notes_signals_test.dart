import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/academic_knowledge_engine.dart';
import 'package:student_os/data/models/student_note.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';

void main() {
  group('AcademicKnowledgeEngine Note Signals Tests', () {
    final topic = Topic(
      id: 'top_dep',
      chapterId: 'ch_1',
      subjectId: 'sub_acc',
      title: 'Depreciation',
    );

    final subject = Subject(
      id: 'sub_acc',
      name: 'Accountancy',
      color: 0xFF2EC4B6,
    );

    test('1. Topic with no notes returns noNotes state', () {
      final state = AcademicKnowledgeEngine.assessTopicKnowledgeState(
        topic,
        notes: const [],
      );
      expect(state, TopicKnowledgeState.noNotes);
    });

    test('2. Topic with recently updated note (within 2 days) returns recentlyUpdated', () {
      final now = DateTime(2026, 3, 10);
      final note = StudentNote(
        id: 'note_1',
        title: 'Depreciation Rules',
        topicId: topic.id,
        subjectId: subject.id,
        updatedAt: DateTime(2026, 3, 9), // 1 day ago
      );

      final state = AcademicKnowledgeEngine.assessTopicKnowledgeState(
        topic,
        notes: [note],
        referenceTime: now,
      );
      expect(state, TopicKnowledgeState.recentlyUpdated);
    });

    test('3. Topic with note not reviewed in 14+ days returns needsReview', () {
      final now = DateTime(2026, 3, 20);
      final note = StudentNote(
        id: 'note_old',
        title: 'Depreciation Rules',
        topicId: topic.id,
        subjectId: subject.id,
        updatedAt: DateTime(2026, 3, 1), // 19 days ago
      );

      final state = AcademicKnowledgeEngine.assessTopicKnowledgeState(
        topic,
        notes: [note],
        referenceTime: now,
      );
      expect(state, TopicKnowledgeState.needsReview);
    });

    test('4. Assesses Subject Knowledge Coverage accurately', () {
      final topics = [
        Topic(id: 'top_1', chapterId: 'ch_1', subjectId: subject.id, title: 'Topic 1'),
        Topic(id: 'top_2', chapterId: 'ch_1', subjectId: subject.id, title: 'Topic 2'),
        Topic(id: 'top_3', chapterId: 'ch_1', subjectId: subject.id, title: 'Topic 3'),
        Topic(id: 'top_4', chapterId: 'ch_1', subjectId: subject.id, title: 'Topic 4'),
      ];

      final notes = [
        StudentNote(id: 'n1', title: 'N1', topicId: 'top_1', subjectId: subject.id),
        StudentNote(id: 'n2', title: 'N2', topicId: 'top_2', subjectId: subject.id),
        StudentNote(id: 'n3', title: 'N3', topicId: 'top_2', subjectId: subject.id), // duplicate topic note
      ];

      final coverage = AcademicKnowledgeEngine.assessSubjectKnowledgeCoverage(
        subject,
        topics: topics,
        notes: notes,
      );

      expect(coverage.notesCount, 3);
      expect(coverage.topicsWithNotes, 2);
      expect(coverage.topicsWithoutNotes, 2);
      expect(coverage.coveragePercentage, 50);
    });

    test('5. Clearly distinguishes Knowledge Coverage from Mastery (Note exists != Topic mastered)', () {
      final unstudiedTopic = Topic(
        id: 'top_unstudied',
        chapterId: 'ch_1',
        subjectId: subject.id,
        title: 'Capital Budgeting',
      );

      final note = StudentNote(
        id: 'note_cb',
        title: 'Capital Budgeting Theory',
        topicId: unstudiedTopic.id,
        subjectId: subject.id,
      );

      // Topic Progress evaluation (strictly from study sessions and practice)
      final topicProgress = AcademicKnowledgeEngine.assessTopicProgress(
        unstudiedTopic,
        sessions: const [], // Zero actual study sessions
      );

      // Mastery must remain notStarted even though a note exists
      expect(topicProgress.status, TopicStatus.notStarted);
      expect(topicProgress.mastery, TopicMasteryState.notStarted);

      // But Knowledge signal indicates notes exist
      final knowledgeState = AcademicKnowledgeEngine.assessTopicKnowledgeState(
        unstudiedTopic,
        notes: [note],
      );
      expect(knowledgeState, isNot(TopicKnowledgeState.noNotes));
    });
  });
}
