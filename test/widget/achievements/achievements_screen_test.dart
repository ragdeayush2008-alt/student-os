import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/progression/achievement_controller.dart';
import 'package:student_os/features/progression/achievements_screen.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

Widget _buildTestApp() {
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    home: const AchievementsScreen(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AchievementController.instance.clearData();
    ProgressionController.instance.clearData();
    TaskController.instance.clearData();
    await ProgressionController.instance.load();
    await AchievementController.instance.load();
  });

  group('AchievementsScreen Widget Tests', () {
    testWidgets('renders all primary structural elements', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Screen title
      expect(find.text('Achievements'), findsOneWidget);

      // Summary Hero Card
      expect(find.text('OVERALL PROGRESS'), findsOneWidget);
      expect(find.textContaining('of'), findsWidgets);

      // Category filters
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Academic'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('Consistency'), findsOneWidget);
    });

    testWidgets('tapping category filter updates displayed list', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Tap 'Focus'
      await tester.tap(find.text('Focus'));
      await tester.pumpAndSettle();

      // Focus achievements should be visible
      expect(find.text('Deep Focus'), findsOneWidget);
      expect(find.text('Focused Mind'), findsOneWidget);

      // Tap 'Consistency'
      await tester.tap(find.text('Consistency'));
      await tester.pumpAndSettle();

      expect(find.text('Momentum'), findsOneWidget);
      expect(find.text('Week Warrior'), findsOneWidget);
    });

    testWidgets('tapping an achievement opens the detailed bottom sheet', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Tap 'First Steps'
      await tester.tap(find.text('First Steps'));
      await tester.pumpAndSettle();

      // Detail sheet elements
      expect(find.text('Progress'), findsOneWidget);
      expect(find.textContaining('Complete'), findsWidgets);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('strictly adheres to Black/White/Grey monochromatic theme (No purple)', (tester) async {
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
                reason: 'Found purple tone hue: ${hsv.hue}',
              );
            }
          }
        }
      }
    });
  });
}
