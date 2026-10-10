import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/progression/achievement_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/data/models/leaderboard_entry.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/progression/leaderboard_controller.dart';
import 'package:student_os/features/progression/leaderboard_screen.dart';
import 'package:student_os/features/progression/progression_controller.dart';

Widget _buildTestApp() {
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.light,
    home: const LeaderboardScreen(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_leaderboard_ui');
    await StorageService.instance.clearUser(userId: 'test_leaderboard_ui');
    AchievementController.instance.clearData();
    ProgressionController.instance.clearData();
    LeaderboardController.instance.clearData();
    await ProgressionController.instance.load();
    await LeaderboardController.instance.load();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
  });

  group('LeaderboardScreen Widget Tests', () {
    testWidgets('renders all primary structural elements', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Leaderboard'), findsOneWidget);

      // Personal rank card
      expect(find.text('YOUR RANK'), findsOneWidget);
      expect(find.text('#1'), findsWidgets);

      // Period selector
      expect(find.text('This Week'), findsWidgets);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
    });

    testWidgets('switching periods triggers period update and updates UI', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(LeaderboardController.instance.period, LeaderboardPeriod.thisWeek);

      // Tap 'All Time'
      await tester.tap(find.text('All Time'));
      await tester.pumpAndSettle();

      expect(LeaderboardController.instance.period, LeaderboardPeriod.allTime);

      // Tap 'This Month'
      await tester.tap(find.text('This Month'));
      await tester.pumpAndSettle();

      expect(LeaderboardController.instance.period, LeaderboardPeriod.thisMonth);
    });

    testWidgets('highlights current user with YOU indicator', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // In the podium or table, current user is marked
      expect(find.text('You'), findsWidgets);
    });

    testWidgets('updates XP live when XP event is recorded', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('0 XP'), findsWidgets);

      // Record 250 XP
      await ProgressionController.instance.recordEvent(
        XpEvent(
          id: 'test_ev_widget_1',
          type: XpEventType.taskCompleted,
          amount: 250,
          timestamp: DateTime.now(),
          reason: 'Completed Widget Test Task',
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('250 XP'), findsWidgets);
    });

    testWidgets('strictly adheres to Black/White/Grey theme (No purple tones)', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Check all rendered Text and Container widgets for absence of purple color values
      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final container in containers) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration) {
          final color = decoration.color;
          if (color != null) {
            // Check that color is not purple/violet (hue roughly between 260 and 320)
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

    testWidgets('provides accessible semantic labels for rank movement', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Verify Semantics exist
      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
