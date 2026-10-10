import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/assistant/assistant_daily_state.dart';

/// P3 — daily state model: roundtrip, date rollover, corrupt tolerance,
/// preference defaults.
void main() {
  group('DailyAssistantState', () {
    test('rollover: yesterday state never applies today', () {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final stale = DailyAssistantState(
        date: DailyAssistantState.dayOf(yesterday),
        prepared: true,
        planVersion: 3,
        dismissedTriggerIds: ['x'],
        actionLog: ['did something'],
      );
      final restored = DailyAssistantState.fromJson(stale.toJson());
      expect(restored.prepared, isFalse);
      expect(restored.planVersion, 0);
      expect(restored.dismissedTriggerIds, isEmpty);
      expect(restored.actionLog, isEmpty);
      expect(restored.isFor(DateTime.now()), isTrue);
    });

    test('same-day roundtrip preserves flags, log, dismissals', () {
      final state = DailyAssistantState(
        date: DailyAssistantState.dayOf(DateTime.now()),
        prepared: true,
        planVersion: 2,
        reviewed: true,
        appliedSessions: 3,
        dismissedTriggerIds: const ['2026-10-04:fixDay'],
        actionLog: const ['09:00 Applied plan (3 sessions)'],
        sleepFingerprint: '11 PM → 7 AM',
      );
      final restored = DailyAssistantState.fromJson(state.toJson());
      expect(restored.prepared, isTrue);
      expect(restored.planVersion, 2);
      expect(restored.reviewed, isTrue);
      expect(restored.appliedSessions, 3);
      expect(
        restored.isDismissed('2026-10-04:fixDay'),
        isTrue,
      );
      expect(restored.actionLog.length, 1);
      expect(restored.sleepFingerprint, '11 PM → 7 AM');
    });

    test('corrupt JSON degrades to fresh state', () {
      final restored = DailyAssistantState.fromJson({'nope': true});
      expect(restored.prepared, isFalse);
      expect(restored.isFor(DateTime.now()), isTrue);
    });
  });

  group('AssistantPreferences', () {
    test('defaults are calm and non-intrusive', () {
      const prefs = AssistantPreferences();
      expect(prefs.proactiveEnabled, isTrue);
      expect(prefs.morningBriefing, isTrue);
      expect(prefs.eveningReview, isTrue);
      expect(prefs.sleepAwarePlanning, isTrue);
      expect(prefs.briefingNotification, isTrue);
      expect(prefs.eveningNotification, isFalse);
    });

    test('roundtrip preserves toggles', () {
      const prefs = AssistantPreferences(
        proactiveEnabled: false,
        eveningNotification: true,
      );
      final restored = AssistantPreferences.fromJson(prefs.toJson());
      expect(restored.proactiveEnabled, isFalse);
      expect(restored.eveningNotification, isTrue);
      expect(restored.morningBriefing, isTrue);
    });
  });

  group('AssistantTriggerKind', () {
    test('every kind carries an executable prompt', () {
      for (final kind in AssistantTriggerKind.values) {
        expect(kind.prompt.isNotEmpty, isTrue, reason: kind.name);
        expect(kind.label.isNotEmpty, isTrue, reason: kind.name);
      }
    });
  });
}
