import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/time/app_clock.dart';
import 'package:student_os/features/home/home_screen.dart';
import 'package:student_os/features/student_life/student_life_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHome({double width = 390.0, double height = 844.0}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: const HomeScreen(),
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
    AppClock.freezeAt(DateTime(2026, 9, 30, 9));
  });

  tearDown(() {
    AppClock.reset();
  });

  group('Home — Student Life entry regression', () {
    testWidgets('R1. Home settles with an unloaded Student Life controller',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildHome());

      // Regression: a shimmer skeleton here animated forever and made every
      // Home pumpAndSettle time out.
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(StudentLifeController.instance.isLoaded, isFalse);
      expect(find.text('Set your sleep routine'), findsOneWidget);
    });

    testWidgets('R2. Home shows real sleep data once loaded', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      AuthIsolation.instance.setAuthenticatedUser('sl_home_entry');
      await StudentLifeController.instance.load();
      await StudentLifeController.instance.logSleep(
        bedtime: DateTime(2026, 9, 29, 23),
        wakeTime: DateTime(2026, 9, 30, 7),
      );

      await tester.pumpWidget(buildHome());
      await tester.pumpAndSettle();

      expect(find.text('Student Life'), findsOneWidget);
      expect(find.textContaining('bed 23:00'), findsOneWidget);
      expect(find.text('Set your sleep routine'), findsNothing);
    });
  });
}
