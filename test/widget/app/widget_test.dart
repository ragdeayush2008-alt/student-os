import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/app/app.dart';
import 'package:student_os/features/auth/presentation/welcome_screen.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme_mode.dart';

void main() {
  testWidgets(
    'StudentOsApp shows the auth flow (never the shell) when Supabase is not configured',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = AppShellController();

      await tester.pumpWidget(StudentOsApp(controller: controller));
      await tester.pump(const Duration(milliseconds: 800));

      // Safe state: the auth/Welcome flow is shown for a non-authenticated
      // user, never the authenticated app shell. No private data is exposed.
      expect(find.text('Student OS'), findsWidgets);
      expect(find.byType(WelcomeScreen), findsOneWidget);

      controller.dispose();
    },
  );

  testWidgets('theme mode resolves and persists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppShellController();
    await controller.setThemeMode(AppThemeMode.dark);

    expect(controller.themeMode, AppThemeMode.dark);
    expect(controller.effectiveThemeMode, ThemeMode.dark);

    controller.dispose();
  });
}
