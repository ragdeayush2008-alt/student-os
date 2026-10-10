import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/services/streak_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_guard_controller.dart';
import 'package:student_os/features/focus/data/models/focus_guard_models.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/data/models/focus_preset.dart';
import 'package:student_os/features/focus/services/focus_intelligence_service.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.clearUser(userId: 'demo');
    FocusController.instance.clearData();
    FocusGuardController.instance.clearData();
    TaskController.instance.clearData();
    StreakService.instance.refresh();
  });

  group('Phase 9 — Focus Presets', () {
    test('default presets contain Sprint, Pomodoro, Deep Focus, Deep Work, Exam Prep, and Custom with correct configs', () {
      final presets = FocusPreset.presets;
      expect(presets.length, 6);

      final sprint = presets.firstWhere((p) => p.type == FocusPresetType.sprint);
      expect(sprint.title, 'Sprint');
      expect(sprint.defaultDuration, const Duration(minutes: 15));
      expect(sprint.focusMode, FocusMode.timer);

      final pomodoro = presets.firstWhere((p) => p.type == FocusPresetType.pomodoro);
      expect(pomodoro.title, 'Focus');
      expect(pomodoro.defaultDuration, const Duration(minutes: 25));
      expect(pomodoro.focusMode, FocusMode.timer);
      expect(pomodoro.guardMode, FocusGuardMode.standard);
      expect(pomodoro.guardEnabled, true);

      final deepFocus = presets.firstWhere((p) => p.type == FocusPresetType.deepFocus);
      expect(deepFocus.title, 'Deep Focus');
      expect(deepFocus.defaultDuration, const Duration(minutes: 45));
      expect(deepFocus.focusMode, FocusMode.focusGuard);
      expect(deepFocus.guardMode, FocusGuardMode.standard);

      final deepWork = presets.firstWhere((p) => p.type == FocusPresetType.deepWork);
      expect(deepWork.title, 'Deep Work');
      expect(deepWork.defaultDuration, const Duration(minutes: 60));
      expect(deepWork.focusMode, FocusMode.focusGuard);
      expect(deepWork.guardMode, FocusGuardMode.strict);

      final examPrep = presets.firstWhere((p) => p.type == FocusPresetType.examPrep);
      expect(examPrep.title, 'Exam Prep');
      expect(examPrep.defaultDuration, const Duration(minutes: 90));
      expect(examPrep.focusMode, FocusMode.timer);

      final custom = presets.firstWhere((p) => p.type == FocusPresetType.custom);
      expect(custom.title, 'Custom');
    });
  });
}