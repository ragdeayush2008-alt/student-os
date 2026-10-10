import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_parser.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';

void main() {
  const parser = DeterministicStudentIntentParser();

  group('StudentIntentParser — Duration Parsing', () {
    test('parses various hour formats', () {
      expect(parser.parse('2 hours').availableMinutes, 120);
      expect(parser.parse('2 hr').availableMinutes, 120);
      expect(parser.parse('2 hrs').availableMinutes, 120);
      expect(parser.parse('2h').availableMinutes, 120);
      expect(parser.parse('1 hour').availableMinutes, 60);
      expect(parser.parse('1.5 hours').availableMinutes, 90);
      expect(parser.parse('1.5h').availableMinutes, 90);
      expect(parser.parse('half hour').availableMinutes, 30);
    });

    test('parses various minute formats', () {
      expect(parser.parse('120 minutes').availableMinutes, 120);
      expect(parser.parse('90 min').availableMinutes, 90);
      expect(parser.parse('45 mins').availableMinutes, 45);
      expect(parser.parse('30m').availableMinutes, 30);
      expect(parser.parse('25 minute').availableMinutes, 25);
    });
  });

  group('StudentIntentParser — Natural Language Intent Matching', () {
    test('identifies "What should I do?" and variants', () {
      expect(parser.parse('what should I do').intentType, AssistantIntentType.whatShouldIDo);
      expect(parser.parse('what should I do now?').intentType, AssistantIntentType.whatShouldIDo);
      expect(parser.parse('what do I do now').intentType, AssistantIntentType.whatShouldIDo);
      expect(parser.parse('what to do').intentType, AssistantIntentType.whatShouldIDo);
    });

    test('identifies "What should I study?" and variants', () {
      expect(parser.parse('what should I study').intentType, AssistantIntentType.whatShouldIStudy);
      expect(parser.parse('what should i learn today').intentType, AssistantIntentType.whatShouldIStudy);
      expect(parser.parse('what to study').intentType, AssistantIntentType.whatShouldIStudy);
    });

    test('identifies "What should I revise?" and variants', () {
      expect(parser.parse('what should I revise?').intentType, AssistantIntentType.whatShouldIRevise);
      expect(parser.parse('what needs revision').intentType, AssistantIntentType.whatShouldIRevise);
      expect(parser.parse('what to revise').intentType, AssistantIntentType.whatShouldIRevise);
    });

    test('identifies "I have X time" -> availableTime', () {
      final res1 = parser.parse('I have 2 hours');
      expect(res1.intentType, AssistantIntentType.availableTime);
      expect(res1.availableMinutes, 120);

      final res2 = parser.parse('I got 45 min');
      expect(res2.intentType, AssistantIntentType.availableTime);
      expect(res2.availableMinutes, 45);

      final res3 = parser.parse('available 90m');
      expect(res3.intentType, AssistantIntentType.availableTime);
      expect(res3.availableMinutes, 90);
    });

    test('identifies "Plan my next X minutes" -> planTime', () {
      final res = parser.parse('plan my next 90 minutes');
      expect(res.intentType, AssistantIntentType.planTime);
      expect(res.availableMinutes, 90);
      expect(res.requiresConfirmation, isTrue);
    });

    test('identifies "Start my day" and "Continue my day"', () {
      expect(parser.parse('start my day').intentType, AssistantIntentType.startMyDay);
      expect(parser.parse('begin my day').intentType, AssistantIntentType.startMyDay);
      expect(parser.parse('continue my day').intentType, AssistantIntentType.continueMyDay);
      expect(parser.parse('continue').intentType, AssistantIntentType.continueMyDay);
      expect(parser.parse('whats next').intentType, AssistantIntentType.continueMyDay);
    });

    test('identifies informational queries', () {
      expect(parser.parse('show my exams').intentType, AssistantIntentType.showExams);
      expect(parser.parse('what are my tasks').intentType, AssistantIntentType.showTasks);
      expect(parser.parse('what am I behind on?').intentType, AssistantIntentType.showWeakAreas);
      expect(parser.parse('show my goals').intentType, AssistantIntentType.showGoals);
      expect(parser.parse('how is my progress').intentType, AssistantIntentType.showProgress);
      expect(parser.parse('help').intentType, AssistantIntentType.help);
      expect(parser.parse('hello').intentType, AssistantIntentType.greeting);
    });
  });

  group('StudentIntentParser — Entity Resolution & Ambiguity Safety', () {
    final subjects = [
      Subject(id: 'sub_acc', name: 'Accountancy'),
      Subject(id: 'sub_law', name: 'Business Law'),
      Subject(id: 'sub_laws', name: 'Corporate Laws'),
    ];

    final topics = [
      Topic(
        id: 'top_adm',
        chapterId: 'ch_1',
        subjectId: 'sub_acc',
        title: 'Admission of a Partner',
        estimatedMinutes: 35,
      ),
      Topic(
        id: 'top_ret',
        chapterId: 'ch_1',
        subjectId: 'sub_acc',
        title: 'Retirement of a Partner',
        estimatedMinutes: 30,
      ),
      Topic(
        id: 'top_offer',
        chapterId: 'ch_2',
        subjectId: 'sub_law',
        title: 'Offer and Acceptance',
        estimatedMinutes: 25,
      ),
    ];

    test('unambiguously resolves exact topic name', () {
      final res = parser.parse(
        'Study Admission of a Partner',
        subjects: subjects,
        topics: topics,
      );

      expect(res.intentType, AssistantIntentType.studyTopic);
      expect(res.topicId, 'top_adm');
      expect(res.topicName, 'Admission of a Partner');
      expect(res.subjectId, 'sub_acc');
      expect(res.durationMinutes, 35);
      expect(res.clarificationRequired, isFalse);
    });

    test('unambiguously resolves exact subject name', () {
      final res = parser.parse(
        'Study Accountancy for 45 min',
        subjects: subjects,
        topics: topics,
      );

      expect(res.intentType, AssistantIntentType.studySubject);
      expect(res.subjectId, 'sub_acc');
      expect(res.subjectName, 'Accountancy');
      expect(res.durationMinutes, 45);
      expect(res.clarificationRequired, isFalse);
    });

    test('triggers clarification on ambiguous subject match', () {
      // User says "Study Law", which matches both "Business Law" and "Corporate Laws"
      final res = parser.parse(
        'Study Law',
        subjects: subjects,
        topics: topics,
      );

      expect(res.clarificationRequired, isTrue);
      expect(res.clarificationQuestion, isNotNull);
      expect(res.clarificationChoices.length, greaterThanOrEqualTo(2));
    });

    test('triggers clarification on ambiguous topic match', () {
      // User says "Study Partner", which matches both "Admission of a Partner" and "Retirement of a Partner"
      final res = parser.parse(
        'Study Partner',
        subjects: subjects,
        topics: topics,
      );

      expect(res.clarificationRequired, isTrue);
      expect(res.clarificationQuestion, isNotNull);
      expect(res.clarificationChoices.length, 2);
      expect(res.clarificationChoices, contains('Admission of a Partner'));
      expect(res.clarificationChoices, contains('Retirement of a Partner'));
    });

    test('reschedule without target triggers clarification', () {
      final res = parser.parse('Move this to tomorrow');
      expect(res.intentType, AssistantIntentType.reschedule);
      expect(res.clarificationRequired, isTrue);
      expect(res.clarificationQuestion, isNotNull);
    });
  });
}
