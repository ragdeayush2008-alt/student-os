import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/app/app.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/features/auth/auth_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Splash Freeze Regression Tests', () {
    test('FlutterNativeSplash.remove is safe to call multiple times', () {
      expect(() => FlutterNativeSplash.remove(), returnsNormally);
      expect(() => FlutterNativeSplash.remove(), returnsNormally);
    });

    testWidgets('StudentOsApp mounts immediately without freezing', (
      tester,
    ) async {
      final controller = AppShellController();
      await tester.pumpWidget(StudentOsApp(controller: controller));
      expect(find.byType(AuthGate), findsOneWidget);
    });
  });
}
