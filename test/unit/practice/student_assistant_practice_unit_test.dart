import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_parser.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/knowledge/practice_question_controller.dart';
import 'package:student_os/features/knowledge/topic_practice_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_assistant_practice_test');
    AcademicKnowledgeController.instance.clearData();
    PracticeQuestionController.instance.clearData();
    TopicPracticeController.instance.clearData();
    SubjectController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  group('Student Assistant Practice Unit Tests', () {
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

    test('1. Parser recognizes practice intents accurately', () {
      final intent1 = parser.parse(
        'Give me practice for depreciation',
        subjects: [subject],
        chapters: [chapter],
        topics: [topic],
      );
      expect(intent1.intentType, AssistantIntentType.practiceTopic);
      expect(intent1.topicId, 'top_deprec');

      final intent2 = parser.parse(
        'Practice my weakest topic',
        subjects: [subject],
        chapters: [chapter],
        topics: [topic],
      );
      expect(intent2.intentType, AssistantIntentType.practiceWeakest);

      final intent3 = parser.parse(
        'What should I practice?',
        subjects: [subject],
        chapters: [chapter],
        topics: [topic],
      );
      expect(intent3.intentType, AssistantIntentType.practiceWeakest);

      final intent4 = parser.parse(
        'How did I do in practice?',
        subjects: [subject],
        chapters: [chapter],
        topics: [topic],
      );
      expect(intent4.intentType, AssistantIntentType.showPracticeHistory);

      final intent5 = parser.parse(
        'Show my practice history',
        subjects: [subject],
        chapters: [chapter],
        topics: [topic],
      );
      expect(intent5.intentType, AssistantIntentType.showPracticeHistory);

      final intent6 = parser.parse(
        'Give me 10 questions on depreciation',
        subjects: [subject],
        chapters: [chapter],
        topics: [topic],
      );
      expect(intent6.intentType, AssistantIntentType.practiceTopic);
      expect(intent6.topicId, 'top_deprec');
    });

    test('2. Engine returns startPractice when real questions exist', () async {
      await PracticeQuestionController.instance.addQuestion(
        topicId: 'top_deprec',
        subjectId: 'sub_acc',
        questionText: 'What is SLM?',
        options: ['Straight line', 'Written down'],
        correctAnswer: 'Straight line',
      );

      final result = engine.process(
        'Practice depreciation',
        subjects: [subject],
        topics: [topic],
      );

      expect(result.success, isTrue);
      expect(result.primaryAction?.type, AssistantActionType.startPractice);
      expect(result.primaryAction?.topicId, 'top_deprec');
      expect(result.message, contains('1 question(s) available'));
    });

    test('3. Engine returns truthful empty response when no questions exist', () {
      final result = engine.process(
        'Practice depreciation',
        subjects: [subject],
        topics: [topic],
      );

      expect(result.success, isTrue);
      expect(result.primaryAction?.type, AssistantActionType.openPractice);
      expect(result.message, contains('No interactive questions are available'));
    });

    test('4. Engine identifies weakest topic for practice correctly', () async {
      final topic2 = Topic(
        id: 'top_journal',
        chapterId: 'ch_dep',
        subjectId: 'sub_acc',
        title: 'Journal Entries',
      );

      await TopicPracticeController.instance.recordAttempt(
        topicId: 'top_journal',
        subjectId: 'sub_acc',
        totalQuestions: 10,
        correctAnswers: 3, // 30% accuracy -> weak
        durationSec: 300,
      );

      final result = engine.process(
        'Practice my weakest topic',
        subjects: [subject],
        topics: [topic, topic2],
      );

      expect(result.success, isTrue);
      expect(result.primaryAction?.type, AssistantActionType.startPractice);
      expect(result.primaryAction?.topicId, 'top_journal');
      expect(result.title, contains('Weak Topic: Journal Entries'));
    });
  });
}
