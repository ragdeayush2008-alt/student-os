import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/supabase_service.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/progression/leaderboard_controller.dart';
import 'package:student_os/features/progression/leaderboard_screen.dart';
import 'package:student_os/features/progression/progression_controller.dart';

Widget _buildTestApp() {
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.dark,
    home: const LeaderboardScreen(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_leaderboard_widget_user');
    ProgressionController.instance.clearData();
    LeaderboardController.instance.clearData();
    SupabaseService.instance.resetForTesting();
    await ProgressionController.instance.load();
    await LeaderboardController.instance.load();
  });

  tearDown(() {
    ProgressionController.instance.clearData();
    LeaderboardController.instance.clearData();
    SupabaseService.instance.resetForTesting();
    AuthIsolation.instance.clearSession();
  });

  group('Leaderboard Sync Status Banner Widget Tests', () {
    testWidgets('renders honest offline fallback banner when remote is unreachable', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Leaderboard'), findsOneWidget);
      // Offline fallback banner text
      expect(find.text('Offline · Showing cached rankings'), findsOneWidget);
    });

    testWidgets('respects dark theme and monochrome palette without purple hues', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final container in containers) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration) {
          final color = decoration.color;
          if (color != null) {
            final hsv = HSVColor.fromColor(color);
            if (hsv.saturation > 0.15) {
              expect(
                hsv.hue < 250 || hsv.hue > 330,
                isTrue,
                reason: 'Purple tone hue found: ${hsv.hue}',
              );
            }
          }
        }
      }
    });
  });
}
