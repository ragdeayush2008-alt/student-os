import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/assistant/assistant_launch_context.dart';
import 'package:student_os/core/assistant/question_catalog.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_parser.dart';
import 'package:student_os/features/guides/guide_registry.dart';

void main() {
  const parser = DeterministicStudentIntentParser();

  StudentAssistantIntent parse(String prompt) =>
      parser.parse(prompt);

  group('QuestionCatalog integrity', () {
    test('categories and questions are well-formed', () {
      expect(QuestionCatalog.categories.length, greaterThanOrEqualTo(8));
      var total = 0;
      for (final c in QuestionCatalog.categories) {
        expect(c.questions, isNotEmpty, reason: c.id);
        total += c.questions.length;
      }
      expect(total, greaterThanOrEqualTo(30));
    });

    test('every engine prompt resolves to a known intent', () {
      final failures = <String>[];
      for (final c in QuestionCatalog.categories) {
        for (final q in c.questions) {
          if (q.guideId != null) {
            continue;
          }
          final intent = parse(q.prompt);
          if (!intent.isKnown) {
            failures.add('${c.id}: "${q.prompt}"');
          }
        }
      }
      expect(failures, isEmpty,
          reason: 'Prompts with no intent:\n${failures.join('\n')}');
    });

    test('every guide entry maps to a real guide', () {
      for (final c in QuestionCatalog.categories) {
        for (final q in c.questions) {
          final id = q.guideId;
          if (id == null) {
            continue;
          }
          expect(GuideRegistry.byId(id), isNotNull,
              reason: '"${q.prompt}" -> $id');
          // The prompt itself must trigger the teach-me interception.
          expect(GuideRegistry.matchQuery(q.prompt), id,
              reason: '"${q.prompt}" does not match guide $id');
        }
      }
    });

    test('preferred categories resolve per origin', () {
      expect(
        QuestionCatalog.preferredCategoryFor(AssistantOrigin.sleep),
        'sleep',
      );
      expect(
        QuestionCatalog.preferredCategoryFor(AssistantOrigin.exam),
        'exams',
      );
      expect(
        QuestionCatalog.preferredCategoryFor(AssistantOrigin.global),
        'today',
      );
    });

    test('workspace origin resolves to today with a context line', () {
      expect(
        QuestionCatalog.preferredCategoryFor(AssistantOrigin.workspace),
        'today',
      );
      expect(
        const AssistantLaunchContext(origin: AssistantOrigin.workspace)
            .contextLine,
        'Looking at your workspace',
      );
    });

    test('popular starters all resolve to known intents', () {
      expect(QuestionCatalog.popular, isNotEmpty);
      for (final q in QuestionCatalog.popular) {
        expect(parse(q.prompt).isKnown, isTrue,
            reason: 'Popular prompt has no intent: "${q.prompt}"');
      }
    });

    test('search finds by prompt and category', () {
      expect(
        QuestionCatalog.search('sleep').length,
        greaterThanOrEqualTo(3),
      );
      expect(
        QuestionCatalog.search('ZzzNoMatch').isEmpty,
        isTrue,
      );
      expect(QuestionCatalog.search('  ').isEmpty, isTrue);
    });
  });
}
