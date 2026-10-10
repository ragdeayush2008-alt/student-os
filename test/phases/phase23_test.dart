import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/widgets/accountability_center.dart';
import 'package:student_os/core/intelligence/intelligent_notification_engine.dart';

void main() {
  group('Phase 23 — Intelligent Notifications & Accountability', () {
    test('Notification engine produces critical for exam gap', () {
      const engine = IntelligentNotificationEngine();
      final result = engine.generateNotifications(
        daysUntilExam: 2,
        hasPreparationGap: true,
        hasOverdueTask: false,
        hasTodayPlan: true,
        consistencyScore: 50,
        hasRecentStudy: false,
      );
      expect(
        result.any((n) => n.priority == NotificationPriority.critical),
        isTrue,
      );
      expect(
        result.any((n) => n.category == NotificationCategory.examApproaching),
        isTrue,
      );
    });

    test('No spam when no exam and no gap', () {
      const engine = IntelligentNotificationEngine();
      final result = engine.generateNotifications(
        daysUntilExam: 30,
        hasPreparationGap: false,
        hasOverdueTask: false,
        hasTodayPlan: false,
        consistencyScore: 80,
        hasRecentStudy: true,
      );
      expect(result.isEmpty, isTrue);
    });

    test('Overdue task notifications fire', () {
      const engine = IntelligentNotificationEngine();
      final result = engine.generateNotifications(
        daysUntilExam: 30,
        hasPreparationGap: false,
        hasOverdueTask: true,
        hasTodayPlan: false,
        consistencyScore: 50,
        hasRecentStudy: false,
      );
      expect(
        result.any((n) => n.category == NotificationCategory.overdueTask),
        isTrue,
      );
      expect(result.any((n) => n.isActionable), isTrue);
    });

    test('Deterministic IDs from engine', () {
      const engine = IntelligentNotificationEngine();
      final r = engine.generateNotifications(
        daysUntilExam: 5,
        hasPreparationGap: true,
        hasOverdueTask: false,
        hasTodayPlan: true,
        consistencyScore: 60,
        hasRecentStudy: true,
      );
      expect(r.isNotEmpty, isTrue);
      expect(
        r.first.deterministicId.contains('examApproaching') ||
            r.first.deterministicId.contains('preparationGap'),
        isTrue,
      );
    });

    test('AccountabilityCenter builds', () {
      expect(const AccountabilityCenter(), isNotNull);
    });
  });
}
