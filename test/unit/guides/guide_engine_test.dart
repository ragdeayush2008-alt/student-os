import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/guides/guide_registry.dart';
import 'package:student_os/features/guides/models/guide_models.dart';

void main() {
  group('GuideRegistry', () {
    test('all 17 guides registered with unique ids and non-empty steps', () {
      final all = GuideRegistry.all;
      expect(all.length, 17);
      final ids = all.map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final g in all) {
        expect(g.title, isNotEmpty, reason: g.id);
        expect(g.description, isNotEmpty, reason: g.id);
        expect(g.steps, isNotEmpty, reason: g.id);
        for (final s in g.steps) {
          expect(s.id, isNotEmpty);
          expect(s.title, isNotEmpty);
          expect(s.message, isNotEmpty);
        }
      }
    });

    test('required guide ids exist', () {
      for (final id in [
        'quick_tour',
        'basics',
        'home',
        'planning',
        'tasks',
        'add_exam',
        'exam_planning',
        'sprintx',
        'focus',
        'custom_focus',
        'deep_focus',
        'sleep',
        'assistant',
        'rewards',
        'progress',
        'tools',
      ]) {
        expect(GuideRegistry.byId(id), isNotNull, reason: id);
      }
      expect(GuideRegistry.byId('nope'), isNull);
    });

    test('categories cover the Learn center structure', () {
      expect(
        GuideRegistry.inCategory(GuideCategory.startHere).map((g) => g.id),
        containsAll(['quick_tour', 'basics', 'home']),
      );
      expect(
        GuideRegistry.inCategory(GuideCategory.focus).map((g) => g.id),
        containsAll(['sprintx', 'focus', 'custom_focus', 'deep_focus']),
      );
      expect(
        GuideRegistry.inCategory(GuideCategory.tools).map((g) => g.id),
        containsAll(['tools']),
      );
    });

    test('progressive unlocking: advanced locked until basics complete', () {
      final deep = GuideRegistry.byId('deep_focus')!;
      expect(GuideRegistry.isUnlocked(deep, {}), isFalse);
      expect(
        GuideRegistry.isUnlocked(deep, {
          'sprintx': const GuideProgress(status: GuideStatus.completed),
        }),
        isFalse,
      );
      expect(
        GuideRegistry.isUnlocked(deep, {
          'sprintx': const GuideProgress(status: GuideStatus.completed),
          'focus': const GuideProgress(status: GuideStatus.completed),
        }),
        isTrue,
      );
      final basics = GuideRegistry.byId('basics')!;
      expect(GuideRegistry.isUnlocked(basics, {}), isTrue);
    });

    test('durations are labeled honestly', () {
      expect(
        GuideRegistry.byId('quick_tour')!.durationLabel,
        anyOf(['~1 min', '~60 sec']),
      );
    });
  });

  group('GuideRegistry.matchQuery', () {
    test('explicit teach-me phrasing matches', () {
      expect(GuideRegistry.matchQuery('how do I use deep focus'), 'deep_focus');
      expect(GuideRegistry.matchQuery('How to use Sleep?'), 'sleep');
      expect(GuideRegistry.matchQuery('show me how to add an exam'), 'add_exam');
      expect(GuideRegistry.matchQuery('teach me planning'), 'planning');
      expect(
          GuideRegistry.matchQuery('walk me through custom focus'), 'custom_focus');
      expect(GuideRegistry.matchQuery('guide to rewards'), 'rewards');
      expect(GuideRegistry.matchQuery('how do I use the tools hub'), 'tools');
      expect(
          GuideRegistry.matchQuery('teach me how to use habits'), 'tools');
    });

    test('plain questions never match (engine owns them)', () {
      expect(GuideRegistry.matchQuery('plan my day'), isNull);
      expect(GuideRegistry.matchQuery('what should I study?'), isNull);
      expect(GuideRegistry.matchQuery('I have an exam in 10 days'), isNull);
      expect(GuideRegistry.matchQuery('deep focus'), isNull);
      expect(GuideRegistry.matchQuery('sleep at 11pm'), isNull);
    });

    test('generic how-does-this-work falls back to basics', () {
      expect(GuideRegistry.matchQuery('how does this work'), 'basics');
    });
  });

  group('Guide models json round-trip', () {
    test('GuideProgress survives corrupt input', () {
      expect(
        GuideProgress.fromJson({}).status,
        GuideStatus.notStarted,
      );
      expect(
        GuideProgress.fromJson({'status': 'bogus'}).status,
        GuideStatus.notStarted,
      );
      final p = const GuideProgress(
          status: GuideStatus.inProgress, stepIndex: 2);
      final back = GuideProgress.fromJson(p.toJson());
      expect(back.status, GuideStatus.inProgress);
      expect(back.stepIndex, 2);
    });

    test('GuideStep round-trips', () {
      const s = GuideStep(
        id: 's1',
        title: 'T',
        message: 'M',
        targetAnchorId: 'a.b',
      );
      final back = GuideStep.fromJson(s.toJson());
      expect(back.id, 's1');
      expect(back.expectation, GuideExpectationKind.continueTap);
      expect(back.navigateOnEnter, isTrue);
    });
  });
}
