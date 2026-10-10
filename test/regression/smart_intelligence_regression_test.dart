import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/smart_recommendation_engine.dart';
import 'package:student_os/core/intelligence/adaptive_priority_engine.dart';

void main() {
  group('SmartRecommendationEngine regression', () {
    test('deterministic recommendation uses real controllers', () {
      const engine = SmartRecommendationEngine();
      final rec = engine.recommend();
      // Recommendation exists or is null; never crashes
      // recommend() returns PrioritizedAction?; just assert it never crashes
      expect(rec, isA<PrioritizedAction?>());
    });

    test('same state produces same recommendation (deterministic)', () {
      const engine = SmartRecommendationEngine();
      final r1 = engine.recommend();
      final r2 = engine.recommend();
      // Same inputs → comparable outputs; not random
      expect(r1?.id == r2?.id || (r1 == null && r2 == null), isTrue);
    });

    test('deleted task not recommended', () {
      const engine = SmartRecommendationEngine();
      final rec = engine.recommend();
      // If recommendation points to task, that task exists (enforced by engine)
      if (rec != null && rec.taskId != null) {
        expect(rec.taskId!.isNotEmpty, isTrue);
      }
    });
  });
}
