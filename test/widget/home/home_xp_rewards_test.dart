import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/home/home_screen.dart';
import 'package:student_os/features/rewards/rewards_screen.dart';

/// Home XP entry navigates to the existing Reward Centre (no duplicate).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp() {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: AppScope(
          controller: AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: const Scaffold(body: HomeScreen()),
          ),
        ),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
  });

  tearDown(() async {
    AuthIsolation.instance.clearSession();
  });

  testWidgets('XP bar is visible and tappable', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Scholar'), findsOneWidget);
  });

  testWidgets('tapping XP opens the Reward Centre', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('Scholar'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Scholar'));
    await tester.pumpAndSettle();

    expect(find.byType(RewardsScreen), findsOneWidget);
  });

  testWidgets('back from Reward Centre returns to Home', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('Scholar'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Scholar'));
    await tester.pumpAndSettle();
    expect(find.byType(RewardsScreen), findsOneWidget);

    Navigator.of(tester.element(find.byType(RewardsScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
