import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/widgets/widget_catalog.dart';
import 'package:student_os/features/widgets/widget_deep_links.dart';

/// Catalog integrity + deep-link parsing (no fake routes, no crashes).
void main() {
  group('WidgetCatalog', () {
    test('all 20 widgets present with unique ids', () {
      expect(WidgetCatalog.widgets.length, 20);
      final ids = WidgetCatalog.widgets.map((w) => w.id).toList();
      expect(ids.toSet().length, 20);
    });

    test('tier 1 flagships all present', () {
      final tier1 =
          WidgetCatalog.byTier(WidgetTier.tier1).map((w) => w.id).toSet();
      for (final id in [
        'exam_countdown',
        'next_action',
        'today_tasks',
        'daily_plan',
        'quick_focus',
        'assistant',
        'exam_prep',
        'sleep_schedule',
      ]) {
        expect(tier1, contains(id), reason: id);
      }
    });

    test('every widget has a valid deep link', () {
      for (final def in WidgetCatalog.widgets) {
        final link = WidgetDeepLinks.parse(def.deepLink);
        expect(link.isKnown, isTrue, reason: def.id);
      }
    });

    test('free tier-1 widgets carry no premium gate', () {
      for (final def in WidgetCatalog.byTier(WidgetTier.tier1)) {
        if (def.id == 'daily_brief') continue; // tier 3 by design
        expect(def.premiumFeatureId, isNull, reason: def.id);
      }
    });

    test('pro widgets map to real catalog features', () {
      final pro = WidgetCatalog.widgets
          .where((w) => w.premiumFeatureId != null)
          .toList();
      expect(pro, isNotEmpty);
      for (final def in pro) {
        expect(def.premiumFeatureId!.startsWith('premium.'), isTrue);
      }
    });

    test('locked routing points at the paywall with context', () {
      final brief = WidgetCatalog.byId('daily_brief')!;
      final locked = widgetDeepLinkFor(brief, locked: true);
      expect(locked, contains('premium'));
      expect(locked, contains('premium.assistant.proactive'));
      final open = widgetDeepLinkFor(brief, locked: false);
      expect(open, brief.deepLink);
    });
  });

  group('WidgetDeepLinks.parse', () {
    test('all catalog targets resolve', () {
      expect(
        WidgetDeepLinks.parse('studentos://widget/tasks').target,
        WidgetDeepLinkTarget.tasks,
      );
      expect(
        WidgetDeepLinks.parse('studentos://widget/exam?id=abc').target,
        WidgetDeepLinkTarget.exam,
      );
      expect(
        WidgetDeepLinks.parse('studentos://widget/exam?id=abc').id,
        'abc',
      );
      expect(
        WidgetDeepLinks.parse('studentos://widget/custom-focus?minutes=45')
            .minutes,
        45,
      );
      expect(
        WidgetDeepLinks.parse(
          'studentos://widget/premium?feature=premium.focus.deep',
        ).feature,
        'premium.focus.deep',
      );
    });

    test('minutes clamp to 1..360', () {
      expect(
        WidgetDeepLinks.parse('studentos://widget/custom-focus?minutes=0')
            .minutes,
        isNull,
      );
      expect(
        WidgetDeepLinks.parse('studentos://widget/custom-focus?minutes=999')
            .minutes,
        isNull,
      );
      expect(
        WidgetDeepLinks.parse('studentos://widget/custom-focus?minutes=abc')
            .minutes,
        isNull,
      );
    });

    test('garbage never throws, falls back to unknown', () {
      expect(
        WidgetDeepLinks.parse(null).isKnown,
        isFalse,
      );
      expect(
        WidgetDeepLinks.parse('').isKnown,
        isFalse,
      );
      expect(
        WidgetDeepLinks.parse('not a uri at all').isKnown,
        isFalse,
      );
      expect(
        WidgetDeepLinks.parse('https://example.com/x').isKnown,
        isFalse,
      );
      // OAuth host is a different system, never a widget target.
      expect(
        WidgetDeepLinks.parse(
          'com.ragdetechnologies.studentos://login-callback/',
        ).isKnown,
        isFalse,
      );
      expect(
        WidgetDeepLinks.parse('studentos://widget/nope').isKnown,
        isFalse,
      );
    });
  });
}
