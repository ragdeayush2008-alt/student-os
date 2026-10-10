import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_parser.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';

void main() {
  const parser = DeterministicStudentIntentParser();

  final subject = Subject(id: 's1', name: 'Accountancy');
  final chapter = Chapter(id: 'c1', subjectId: 's1', title: 'Partnership');
  final topic = Topic(
    id: 't1',
    chapterId: 'c1',
    subjectId: 's1',
    title: 'Admission of a Partner',
  );

  final subjects = [subject];
  final chapters = [chapter];
  final topics = [topic];

  StudentAssistantIntent parse(String text) => parser.parse(
        text,
        subjects: subjects,
        chapters: chapters,
        topics: topics,
      );

  group('Assistant 4.0 parser — previously swallowed phrasings', () {
    test('clarifies/plans previously unknown natural phrasings', () {
      final cases = <String, AssistantIntentType>{
        'Make my plan for today.': AssistantIntentType.startMyDay,
        'What am I weak at?': AssistantIntentType.showWeakAreas,
        'What exam is closest?': AssistantIntentType.showExams,
        'Start my next task.': AssistantIntentType.startTask,
        'Start my next study session.': AssistantIntentType.startFocus,
        "Show today's plan.": AssistantIntentType.showTodayPlan,
        'What have I completed today?': AssistantIntentType.showCompleted,
        'What should I prioritize?': AssistantIntentType.showPriorities,
        'Change my study time.': AssistantIntentType.changeStudyTime,
        'Give me a recovery plan.': AssistantIntentType.recoverMissedSession,
        'Stop focus.': AssistantIntentType.stopFocus,
        'Start this task.': AssistantIntentType.startTask,
        'I have time until 7 PM.': AssistantIntentType.availableTime,
      };

      cases.forEach((text, expected) {
        expect(parse(text).intentType, expected, reason: text);
      });
    });

    test('schedule/plan topic phrasings map to scheduleTopic', () {
      for (final text in const [
        'Plan this topic.',
        'Schedule revision for this topic.',
        'Schedule this topic.',
      ]) {
        expect(parse(text).intentType, AssistantIntentType.scheduleTopic,
            reason: text);
      }
    });

    test('reschedule missed block maps to recovery, not a generic plan', () {
      final result = parse('Reschedule my missed block.');
      expect(result.intentType, AssistantIntentType.recoverMissedSession);
    });

    test('overdue query keeps overdueOnly and never becomes weak areas', () {
      final result = parse('What tasks are overdue?');
      expect(result.intentType, AssistantIntentType.showTasks);
      expect(result.overdueOnly, isTrue);
    });

    test('overdue query tolerates alternative orderings', () {
      for (final text in const [
        'Show me my overdue tasks',
        'Which tasks are overdue?',
        'Do I have overdue work?',
      ]) {
        final result = parse(text);
        expect(result.intentType, AssistantIntentType.showTasks,
            reason: text);
        expect(result.overdueOnly, isTrue, reason: text);
      }
    });

    test('"focus on X" is focus, not study, and keeps the duration', () {
      final result = parse('Focus on Accountancy for 45 minutes.');
      expect(result.intentType, AssistantIntentType.focusSubject);
      expect(result.durationMinutes, 45);
      expect(result.subjectName, 'Accountancy');
    });

    test('"I finished this" completes the pending action by reference', () {
      final result = parse('I finished this.');
      expect(result.intentType, AssistantIntentType.completeTask);
      expect(result.refersToPendingAction, isTrue);
    });

    test('mark-this-complete variants also set the reference flag', () {
      for (final text in const [
        'Mark this complete',
        'I completed this',
        'This is done',
      ]) {
        final result = parse(text);
        expect(result.intentType, AssistantIntentType.completeTask,
            reason: text);
        expect(result.refersToPendingAction, isTrue, reason: text);
      }
    });
  });

  group('Assistant 4.0 parser — Hinglish', () {
    test('maps common Hinglish availability and recommendation phrases', () {
      expect(parse('aaj kya padhna chahiye').intentType,
          AssistantIntentType.whatShouldIStudy);
      expect(parse('abhi kya karu').intentType,
          AssistantIntentType.whatShouldIDo);
      expect(parse('mera plan banao').intentType,
          AssistantIntentType.startMyDay);
      expect(parse('aaj ka schedule dikhao').intentType,
          AssistantIntentType.showTodayPlan);
      expect(parse('kitna time bacha hai').intentType,
          AssistantIntentType.checkFreeTime);
    });

    test('maps trailing subject revise Hinglish to reviseTopic', () {
      final result = parse('Accountancy revise karna hai');
      expect(result.intentType, AssistantIntentType.reviseTopic);
      expect(result.subjectName, 'Accountancy');
    });

    test('does not crash on Hinglish without data and stays deterministic', () {
      final a = parser.parse('kal kya karna hai');
      final b = parser.parse('kal kya karna hai');
      expect(a.intentType, b.intentType);
    });
  });

  group('Assistant 4.0 parser — preservation of 3.0 intents', () {
    test('core 3.0 intents still resolve', () {
      expect(parse('What should I do?').intentType,
          AssistantIntentType.whatShouldIDo);
      expect(parse('I have 2 hours').intentType,
          AssistantIntentType.availableTime);
      expect(parse('What should I revise?').intentType,
          AssistantIntentType.whatShouldIRevise);
      expect(parse('Start my day').intentType,
          AssistantIntentType.startMyDay);
      // ("show my exams" also carries task-list semantics in 3.x; assert it is
      // a known intent rather than unknown.)
      expect(parse('Show my exams').isKnown, isTrue);
    });

    test('entity resolution still prefers exact topic matches', () {
      final result = parse('Study Admission of a Partner');
      expect(result.intentType, AssistantIntentType.studyTopic);
      expect(result.topicName, 'Admission of a Partner');
    });
  });

  group('Assistant 4.0 parser — determinism', () {
    test('same input yields identical intent twice', () {
      const text = 'Plan this topic.';
      final a = parse(text);
      final b = parse(text);
      expect(a.intentType, b.intentType);
      expect(a.durationMinutes, b.durationMinutes);
      expect(a.subjectName, b.subjectName);
      expect(a.topicName, b.topicName);
    });
  });
}
