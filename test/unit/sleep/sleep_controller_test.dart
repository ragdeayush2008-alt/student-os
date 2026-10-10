import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';

/// P1 — SleepController: persistence, edit, enable/disable, isolation,
/// corrupt-cache resilience (Home gates on isLoaded).
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    SleepController.instance.clearData();
  });

  tearDown(() async {
    await SleepController.instance.clearSchedule();
    AuthIsolation.instance.clearSession();
    SleepController.instance.clearData();
  });

  group('save + load persistence', () {
    test('saved schedule reloads with all fields', () async {
      AuthIsolation.instance.setAuthenticatedUser('p1_sleep_user_a');
      final error = await SleepController.instance.saveSchedule(
        const SleepSchedule(
          bedtimeMinutes: 1410,
          wakeMinutes: 450,
          days: [1, 2, 3],
          windDownMinutes: 45,
        ),
      );
      expect(error, isNull);
      expect(SleepController.instance.hasSchedule, isTrue);

      SleepController.instance.clearData();
      await SleepController.instance.load();

      final reloaded = SleepController.instance.schedule!;
      expect(reloaded.bedtimeMinutes, 1410);
      expect(reloaded.wakeMinutes, 450);
      expect(reloaded.days, [1, 2, 3]);
      expect(reloaded.windDownMinutes, 45);
    });

    test('invalid schedule rejected, previous kept', () async {
      AuthIsolation.instance.setAuthenticatedUser('p1_sleep_user_b');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      final error = await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 420, wakeMinutes: 420),
      );
      expect(error, isNotNull);
      expect(
        SleepController.instance.schedule!.bedtimeMinutes,
        1380,
      );
    });

    test('enable/disable preserves the window', () async {
      AuthIsolation.instance.setAuthenticatedUser('p1_sleep_user_c');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      await SleepController.instance.setEnabled(false);
      expect(SleepController.instance.schedule!.enabled, isFalse);
      expect(SleepController.instance.schedule!.plannedMinutes, 480);
      await SleepController.instance.setEnabled(true);
      expect(SleepController.instance.schedule!.enabled, isTrue);
    });

    test('clearSchedule removes stored data', () async {
      AuthIsolation.instance.setAuthenticatedUser('p1_sleep_user_d');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(),
      );
      await SleepController.instance.clearSchedule();
      expect(SleepController.instance.hasSchedule, isFalse);

      SleepController.instance.clearData();
      await SleepController.instance.load();
      expect(SleepController.instance.hasSchedule, isFalse);
    });
  });

  group('user isolation', () {
    test("user B never sees user A's schedule", () async {
      AuthIsolation.instance.setAuthenticatedUser('p1_sleep_user_a');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );

      // Logout: memory cleared, storage kept.
      AuthIsolation.instance.clearSession();
      SleepController.instance.clearData();

      // User B logs in: clean slate.
      AuthIsolation.instance.setAuthenticatedUser('p1_sleep_user_b');
      await SleepController.instance.load();
      expect(SleepController.instance.hasSchedule, isFalse);

      // User B saves their own window.
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1320, wakeMinutes: 360),
      );

      // Back to A: only A's window restored.
      AuthIsolation.instance.clearSession();
      SleepController.instance.clearData();
      AuthIsolation.instance.setAuthenticatedUser('p1_sleep_user_a');
      await SleepController.instance.load();
      expect(
        SleepController.instance.schedule!.bedtimeMinutes,
        1380,
      );
    });
  });

  group('loading resilience', () {
    test('load always terminates loaded', () async {
      AuthIsolation.instance.setAuthenticatedUser('p1_sleep_user_e');
      await SleepController.instance.load();
      expect(SleepController.instance.isLoaded, isTrue);
    });
  });
}
