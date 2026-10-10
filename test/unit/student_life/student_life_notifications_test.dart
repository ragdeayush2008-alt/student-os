import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/services/notification_coordinator.dart';
import 'package:student_os/core/services/notification_service.dart';
import 'package:student_os/features/student_life/models/student_life_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  group('Student Life notification guard', () {
    test('G1. overnight window covers bedtime through wake time', () {
      expect(
        NotificationCoordinator.isWithinSleepWindow(1380, 1380, 420),
        isTrue,
      );
      expect(
        NotificationCoordinator.isWithinSleepWindow(1439, 1380, 420),
        isTrue,
      );
      expect(NotificationCoordinator.isWithinSleepWindow(0, 1380, 420), isTrue);
      expect(
        NotificationCoordinator.isWithinSleepWindow(419, 1380, 420),
        isTrue,
      );
      expect(
        NotificationCoordinator.isWithinSleepWindow(420, 1380, 420),
        isFalse,
      );
      expect(
        NotificationCoordinator.isWithinSleepWindow(1080, 1380, 420),
        isFalse,
      );
    });

    test('G2. same-day window behaves differently from an overnight window', () {
      expect(NotificationCoordinator.isWithinSleepWindow(60, 0, 420), isTrue);
      expect(
        NotificationCoordinator.isWithinSleepWindow(300, 0, 420),
        isTrue,
      );
      expect(
        NotificationCoordinator.isWithinSleepWindow(500, 0, 420),
        isFalse,
      );
    });

    test('G3. a zero-length window never blocks reminders', () {
      expect(NotificationCoordinator.isWithinSleepWindow(500, 1380, 1380), isFalse);
      expect(NotificationCoordinator.isWithinSleepWindow(0, 0, 0), isFalse);
    });

    test('G4. notification ids are deterministic and per-routine', () {
      final first = NotificationIds.studentLifeReminder('hydration');
      final second = NotificationIds.studentLifeReminder('hydration');
      final bedtime = NotificationIds.studentLifeReminder('bedtime');

      expect(first, second);
      expect(first, isNot(bedtime));
      expect(NotificationIds.studentLifeReminder('hydration'),
          isNot(NotificationIds.studyReminder()));
    });

    test('G5. reconcile is a safe no-op without the notifications permission',
        () async {
      const prefs = StudentLifePreferences(mealRemindersEnabled: true);

      await NotificationCoordinator.instance
          .reconcileStudentLifeNotifications(preferences: prefs);

      expect(NotificationService.instance.hasPermission, isFalse);
    });

    test('G6. reconcile is idempotent for repeated calls', () async {
      const prefs = StudentLifePreferences(hydration: HydrationFrequency.frequent);

      await NotificationCoordinator.instance
          .reconcileStudentLifeNotifications(preferences: prefs);
      await NotificationCoordinator.instance
          .reconcileStudentLifeNotifications(preferences: prefs);
      await NotificationCoordinator.instance
          .reconcileStudentLifeNotifications(
        preferences: prefs.copyWith(enabled: false),
      );
    });
  });
}
