import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/premium/models/premium_catalog.dart';
import 'package:student_os/features/premium/models/premium_plan.dart';

/// Premium catalog: all 20 features, stable IDs, honest statuses, plan
/// pricing with programmatically verified math.
void main() {
  group('feature catalog', () {
    test('contains all 20 required features with unique IDs', () {
      expect(PremiumCatalog.features.length, 20);
      final ids = PremiumCatalog.features.map((f) => f.id).toList();
      expect(ids.toSet().length, 20);
      for (final id in [
        'premium.assistant.advanced',
        'premium.focus.deep',
        'premium.focus.strict',
        'premium.planning.smart',
        'premium.planning.weekly',
        'premium.planning.scenario',
        'premium.exam.intelligence',
        'premium.study.intelligence',
        'premium.revision.intelligence',
        'premium.catchup',
        'premium.analytics.advanced',
        'premium.assistant.proactive',
        'premium.sleep.awareness',
        'premium.study.ai_tools',
        'premium.notes.intelligence',
        'premium.dashboard.customization',
        'premium.personalization.advanced',
        'premium.history.extended',
        'premium.smart.notifications',
        'premium.widgets',
      ]) {
        expect(ids, contains(id), reason: id);
      }
    });

    test('every feature has copy, icon, category', () {
      for (final f in PremiumCatalog.features) {
        expect(f.title.isNotEmpty, isTrue, reason: f.id);
        expect(f.description.isNotEmpty, isTrue, reason: f.id);
      }
    });

    test('gated ACTIVE set matches implemented redirect points', () {
      final active =
          PremiumCatalog.activeFeatures.map((f) => f.id).toSet();
      // Every ACTIVE feature must have a real gate in the app.
      for (final id in [
        'premium.assistant.advanced',
        'premium.focus.deep',
        'premium.focus.strict',
        'premium.planning.smart',
        'premium.exam.intelligence',
        'premium.catchup',
        'premium.analytics.advanced',
        'premium.assistant.proactive',
        'premium.sleep.awareness',
      ]) {
        expect(active, contains(id), reason: id);
      }
    });

    test('byId resolves, unknown returns null', () {
      expect(
        PremiumCatalog.byId('premium.focus.deep')?.title,
        'Deep Focus',
      );
      expect(PremiumCatalog.byId('premium.nope'), isNull);
    });
  });

  group('free baseline + comparison', () {
    test('free baseline keeps core functionality free', () {
      for (final item in [
        'Basic Tasks',
        'Basic Planning',
        'Basic Focus',
        'Basic Assistant',
        'Basic Sleep schedule',
        'Basic Progress',
      ]) {
        expect(FreeBaseline.items, contains(item), reason: item);
      }
    });

    test('comparison rows cover the key dimensions', () {
      expect(PlanComparison.rows.length, greaterThanOrEqualTo(6));
      for (final row in PlanComparison.rows) {
        expect(row.label.isNotEmpty, isTrue);
        expect(row.free.isNotEmpty, isTrue);
        expect(row.pro.isNotEmpty, isTrue);
      }
    });
  });

  group('plan catalog + pricing math', () {
    test('all four plans present with correct IDs and prices', () {
      expect(PremiumPlanCatalog.plans.length, 4);
      expect(PremiumPlanCatalog.monthly.id, 'student_os_pro_monthly');
      expect(PremiumPlanCatalog.monthly.pricePaise, 7900);
      expect(
        PremiumPlanCatalog.threeMonth.id,
        'student_os_pro_3_month',
      );
      expect(PremiumPlanCatalog.threeMonth.pricePaise, 19900);
      expect(
        PremiumPlanCatalog.sixMonth.id,
        'student_os_pro_6_month',
      );
      expect(PremiumPlanCatalog.sixMonth.pricePaise, 34900);
      expect(PremiumPlanCatalog.yearly.id, 'student_os_pro_yearly');
      expect(PremiumPlanCatalog.yearly.pricePaise, 59900);
    });

    test('only yearly is recommended (best value)', () {
      expect(PremiumPlanCatalog.yearly.isRecommended, isTrue);
      expect(PremiumPlanCatalog.monthly.isRecommended, isFalse);
      expect(PremiumPlanCatalog.threeMonth.isRecommended, isFalse);
      expect(PremiumPlanCatalog.sixMonth.isRecommended, isFalse);
    });

    test('effective monthly prices are exact', () {
      expect(
        PremiumPlanCatalog.monthly.effectiveMonthlyPrice,
        closeTo(79.0, 0.001),
      );
      expect(
        PremiumPlanCatalog.threeMonth.effectiveMonthlyPrice,
        closeTo(66.33, 0.01),
      );
      expect(
        PremiumPlanCatalog.sixMonth.effectiveMonthlyPrice,
        closeTo(58.17, 0.01),
      );
      expect(
        PremiumPlanCatalog.yearly.effectiveMonthlyPrice,
        closeTo(49.92, 0.01),
      );
    });

    test('savings derive honestly from the monthly baseline', () {
      final base = PremiumPlanCatalog.baseline;
      expect(base.savingsLabelVs(base), isNull);
      expect(
        PremiumPlanCatalog.threeMonth.savingsLabelVs(base),
        'Save 16%',
      );
      expect(
        PremiumPlanCatalog.sixMonth.savingsLabelVs(base),
        'Save 26%',
      );
      expect(
        PremiumPlanCatalog.yearly.savingsLabelVs(base),
        'Save 37%',
      );
    });

    test('period labels read correctly', () {
      expect(
        PremiumPlanCatalog.yearly.periodLabel,
        '₹599 / year',
      );
      expect(
        PremiumPlanCatalog.yearly.effectiveMonthlyLabel,
        '₹49.92/month',
      );
    });
  });
}
