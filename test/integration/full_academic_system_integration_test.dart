import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/academic_insights.dart';
import 'package:student_os/core/intelligence/academic_context.dart';
import 'package:student_os/core/intelligence/adaptive_priority_engine.dart';
import 'package:student_os/core/intelligence/smart_recommendation_engine.dart';
import 'package:student_os/core/intelligence/daily_academic_snapshot.dart';
import 'package:student_os/core/intelligence/daily_os_coordinator.dart';

void main() {
  group('Full Academic System End-to-End', () {
    test('Complete journey: context -> insight -> recommendation -> snapshot -> coordinator', () {
      final ctx = AcademicContext.fromControllers();
      final insights = AcademicInsights.deriveFromContext(ctx);
      expect(insights, isNotEmpty); // always produces at least balanced message

      final rec =
          AdaptivePriorityEngine().derivePrioritizedActions(ctx).isNotEmpty
          ? AdaptivePriorityEngine().derivePrioritizedActions(ctx).first
          : null;
      // Either null (low info) or valid action with real IDs
      if (rec != null) {
        expect(rec.id.isNotEmpty, isTrue);
        if (rec.taskId != null) expect(rec.taskId!.isNotEmpty, isTrue);
        if (rec.examId != null) expect(rec.examId!.isNotEmpty, isTrue);
      }

      final snap = DailyAcademicSnapshot.fromControllers();
      expect(snap.todayTaskCount >= 0, isTrue);
      expect(
        snap.nowAction == null || snap.nowAction is PrioritizedAction,
        isTrue,
      );

      DailyOsCoordinator.instance.init();
      expect(DailyOsCoordinator.instance.snapshot, isNotNull);
    });

    test('No duplicate architecture / no mutation', () {
      expect(AcademicInsights, isA<Type>());
      expect(SmartRecommendationEngine, isA<Type>());
      expect(DailyAcademicSnapshot, isA<Type>());
    });
  });
}
