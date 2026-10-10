import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/rewards/redemption_controller.dart';
import 'package:student_os/features/rewards/rewards_screen.dart';
import 'package:student_os/features/rewards/widgets/my_collection_sheet.dart';
import 'package:student_os/features/rewards/widgets/reward_history_screen.dart';

Widget _buildTestApp(Widget child) {
  return AppScope(
    controller: AppShellController(),
    child: MaterialApp(
      theme: AppTheme.light(),
      home: child,
    ),
  );
}

void main() {
  group('Rewards Marketplace 2.0 — Widget Tests', () {
    late ProgressionController progression;
    late RedemptionController redemption;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      progression = ProgressionController.instance;
      progression.clearData();

      redemption = RedemptionController.instance;
      redemption.clearData();

      AuthIsolation.instance.setAuthenticatedUser('widget_rewards_user');
      await progression.load();
      await redemption.load();
    });

    tearDown(() {
      progression.clearData();
      redemption.clearData();
      AuthIsolation.instance.clearSession();
    });

    testWidgets('1. RewardsScreen renders Header, Summary, Next Goal, Collections, and Grid', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(const RewardsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Rewards Marketplace'), findsOneWidget);
      expect(find.text('Lifetime XP'), findsOneWidget);
      expect(find.text('XP Spent'), findsOneWidget);
      expect(find.text('Unlocked'), findsOneWidget);
      expect(find.text('My Collection & Equipment'), findsOneWidget);
      expect(find.text('Themed Collections'), findsOneWidget);
      expect(find.text('First Steps'), findsWidgets);
    });

    testWidgets('2. Tab navigation filters rewards by category', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(const RewardsScreen()));
      await tester.pumpAndSettle();

      // Tap on Cosmetics tab
      await tester.tap(find.text('🎨 Cosmetics'));
      await tester.pumpAndSettle();

      expect(find.text('Focus Theme'), findsWidgets);
      expect(find.text('Academic Light'), findsWidgets);
    });

    testWidgets('3. Search bar filters rewards interactively', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(const RewardsScreen()));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Analytics');
      await tester.pumpAndSettle();

      expect(find.text('Advanced Analytics'), findsWidgets);
    });

    testWidgets('4. Tapping a reward card opens RewardDetailSheet', (tester) async {
      await tester.pumpWidget(_buildTestApp(const RewardsScreen()));
      await tester.pumpAndSettle();

      // Tap on First Steps reward
      await tester.tap(find.text('First Steps').first);
      await tester.pumpAndSettle();

      // Detail sheet content
      expect(find.text('XP Cost'), findsOneWidget);
      expect(find.text('Required Level'), findsOneWidget);
      expect(find.textContaining('Welcome to Student OS'), findsWidgets);
    });

    testWidgets('5. MyCollectionScreen displays collections and inventory filters', (tester) async {
      await tester.pumpWidget(_buildTestApp(const MyCollectionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('My Collection'), findsOneWidget);
      expect(find.text('Collection Progress'), findsOneWidget);
      expect(find.textContaining('Focus Master Collection'), findsOneWidget);
    });

    testWidgets('6. RewardHistoryScreen displays Redemptions and XP Ledger tabs', (tester) async {
      await progression.recordEvent(
        XpEvent(
          id: 'xp_widget_test_1',
          type: XpEventType.studySessionCompleted,
          amount: 50,
          reason: 'Completed 30m study',
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(_buildTestApp(const RewardHistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('History & Activity'), findsOneWidget);
      expect(find.textContaining('Redemptions'), findsOneWidget);
      expect(find.textContaining('XP Ledger'), findsOneWidget);

      // Switch to XP Ledger tab
      await tester.tap(find.textContaining('XP Ledger'));
      await tester.pumpAndSettle();

      expect(find.text('Completed 30m study'), findsOneWidget);
      expect(find.text('+50 XP'), findsOneWidget);
    });
  });
}
