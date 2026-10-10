import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_parser.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/notes/student_note_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_assistant_user');
    StudentNoteController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    StudentNoteController.instance.clearData();
  });

  group('Student Assistant Notes Intent & Execution Tests', () {
    const parser = DeterministicStudentIntentParser();
    final engine = StudentAssistantEngine();

    final subjects = [
      Subject(id: 'sub_acc', name: 'Accountancy', color: 0xFF2EC4B6),
    ];

    final chapters = [
      Chapter(id: 'ch_dep', subjectId: 'sub_acc', title: 'Depreciation Accounting'),
    ];

    final topics = [
      Topic(id: 'top_dep', chapterId: 'ch_dep', subjectId: 'sub_acc', title: 'Depreciation'),
      Topic(id: 'top_part', chapterId: 'ch_dep', subjectId: 'sub_acc', title: 'Partnership'),
    ];

    test('1. Parses "show my notes" intent correctly', () {
      final intent = parser.parse(
        'show my notes',
        subjects: subjects,
        chapters: chapters,
        topics: topics,
      );

      expect(intent.intentType, AssistantIntentType.showNotes);
    });

    test('2. Parses "show notes on depreciation" and resolves topic', () {
      final intent = parser.parse(
        'show notes on depreciation',
        subjects: subjects,
        chapters: chapters,
        topics: topics,
      );

      expect(intent.intentType, AssistantIntentType.showNotes);
      expect(intent.topicId, 'top_dep');
    });

    test('3. Parses "show pinned notes"', () {
      final intent = parser.parse(
        'show pinned notes',
        subjects: subjects,
        chapters: chapters,
        topics: topics,
      );

      expect(intent.intentType, AssistantIntentType.showPinnedNotes);
    });

    test('4. Parses "open my latest note"', () {
      final intent = parser.parse(
        'open my latest note',
        subjects: subjects,
        chapters: chapters,
        topics: topics,
      );

      expect(intent.intentType, AssistantIntentType.openNote);
    });

    test('5. Parses "create a note for depreciation"', () {
      final intent = parser.parse(
        'create a note for depreciation',
        subjects: subjects,
        chapters: chapters,
        topics: topics,
      );

      expect(intent.intentType, AssistantIntentType.createNote);
      expect(intent.topicId, 'top_dep');
    });

    test('6. Executes showNotes when knowledge base has notes', () async {
      final nc = StudentNoteController.instance;
      await nc.createNote(
        title: 'Depreciation Straight Line Method',
        content: 'Formula: Cost minus salvage divided by years.',
        subjectId: 'sub_acc',
        topicId: 'top_dep',
      );

      final intent = StudentAssistantIntent(
        rawText: 'show notes on depreciation',
        intentType: AssistantIntentType.showNotes,
        subjectId: 'sub_acc',
        topicId: 'top_dep',
        topicName: 'Depreciation',
      );

      final result = engine.process(
        intent.rawText,
        explicitIntent: intent,
      );

      expect(result.success, isTrue);
      expect(result.title.contains('Depreciation'), isTrue);
      expect(result.primaryAction, isNotNull);
      expect(result.primaryAction!.type, AssistantActionType.openNote);
    });

    test('7. Executes searchNotes with matching query', () async {
      final nc = StudentNoteController.instance;
      await nc.createNote(
        title: 'Valuation of Goodwill in Partnership',
        content: 'Super profit method and capitalization method.',
      );

      final intent = const StudentAssistantIntent(
        rawText: 'find my notes about goodwill',
        intentType: AssistantIntentType.searchNotes,
        searchQuery: 'goodwill',
      );

      final result = engine.process(
        intent.rawText,
        explicitIntent: intent,
      );

      expect(result.success, isTrue);
      expect(result.previewItems, isNotEmpty);
      expect(result.primaryAction!.type, AssistantActionType.openNote);
    });

    test('8. Handles empty notes gracefully with create note action', () {
      final intent = const StudentAssistantIntent(
        rawText: 'show my notes',
        intentType: AssistantIntentType.showNotes,
      );

      final result = engine.process(
        intent.rawText,
        explicitIntent: intent,
      );

      expect(result.success, isTrue);
      expect(result.primaryAction!.type, AssistantActionType.createNote);
    });
  });
}
