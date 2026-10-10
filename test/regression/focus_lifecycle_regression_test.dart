import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';

void main() {
  group('Focus Lifecycle Regression', () {
    test(
      'FocusController clears data without duplicate notification crash',
      () {
        final fc = FocusController.instance;
        // Should not throw; data cleared safely
        fc.clearData();
        expect(fc.activeSession, isNull);
        expect(fc.sessions, isEmpty);
      },
    );
  });
}
