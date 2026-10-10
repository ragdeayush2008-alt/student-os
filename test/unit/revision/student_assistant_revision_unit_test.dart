import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_parser.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/revision/revision_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_assistant_revision_test');
    AcademicKnowledgeController.instance.clearData();
    RevisionController.instance.clearData();
    SubjectController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  group('Student Assistant Revision Unit Tests', () {
    const parser = DeterministicStudentIntentParser();
    const engine = StudentAssistantEngine();

    final subject = Subject(id: 'sub_acc', name: 'Accounting');
    final chapter = Chapter(id: 'ch_dep', subjectId: 'sub_acc', title: 'Depreciation');
    final topic = Topic(
      id: 'top_deprec',
      chapterId: 'ch_dep',
      subjectId: 'sub_acc',
      title: 'Depreciation',
    );

    test('1. Parser recognizes revision queries accurately', () {
      final intent1 = parser.parse(
        'What should I revise?',
        subjects: [subject],
        chapters: [chapter],
        topics: [topic],
      );
      expect(intent1.intentType, AssistantIntentType.whatShouldIRevise);

      final intent2 = parser.parse(
        'What is due for revision?',
        subjects: [subject],
        chapters: [chapter],
        topics: [topic],
      );
      expect(intent2.intentType, AssistantIntentType.whatShouldIRevise);

      final intent3 = parser.parse(
        'Revise depreciation',
        subjects: [subject],
        chapters: [chapter],
        topics: [topic],
      );
      expect(intent3.intentType, AssistantIntentType.reviseTopic);
      expect(intent3.topicId, 'top_deprec');
    });

    test('2. Engine returns startRevision recommendation when topic is due', () {
      final now = DateTime.now();
      final study = StudySession(
        id: 's_1',
        topicId: 'top_deprec',
        subject: 'sub_acc',
        startedAt: now.subtract(const Duration(days: 5)),
        completed: true,
      );

      final result = engine.process(
        'What should I revise?',
        subjects: [subject],
        topics: [topic],
        sessions: [study],
      );

      expect(result.success, isTrue);
      expect(result.primaryAction?.type, AssistantActionType.startRevision);
      expect(result.primaryAction?.topicId, 'top_deprec');
      expect(result.title, contains('Revise Depreciation'));
    });

    test('3. Engine returns honest up-to-date message when no revisions are due', () {
      final result = engine.process(
        'What should I revise?',
        subjects: [subject],
        topics: [topic],
        sessions: [],
      );

      expect(result.success, isTrue);
      expect(result.title, 'Up to Date on Revision');
      expect(result.message, contains('No topics or resources currently require'));
    });
  });
}
