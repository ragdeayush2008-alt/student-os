import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/features/auth/auth_gate.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/auth/auth_state.dart';
import 'package:student_os/features/auth/presentation/sign_in_screen.dart';
import 'package:student_os/features/auth/presentation/sign_up_screen.dart';
import 'package:student_os/features/auth/presentation/welcome_screen.dart';

Future<void> _pumpAuthGate(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    AuthScope(
      authService: AuthService.instance,
      child: const MaterialApp(home: AuthGate()),
    ),
  );
  await tester.pump();
}

void main() {
  group('Startup state machine', () {
    testWidgets('unauthenticated session shows Welcome, never the app shell', (
      tester,
    ) async {
      await _pumpAuthGate(tester);
      await tester.pump(const Duration(milliseconds: 800));

      // The auth flow, not the shell, must be the first screen for a
      // non-authenticated user.
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no demo user data is shown for a non-authenticated user', (
      tester,
    ) async {
      await _pumpAuthGate(tester);
      await tester.pump(const Duration(milliseconds: 800));

      // AuthService must not report an authenticated session when unauthenticated.
      expect(AuthService.instance.isAuthenticated, isFalse);
      expect(
        AuthService.instance.viewState,
        isNot(AuthViewState.authenticated),
      );
    });
  });

  group('Auth navigation from Welcome', () {
    testWidgets('Sign In button opens the Sign In screen', (tester) async {
      await _pumpAuthGate(tester);
      await tester.pump(const Duration(milliseconds: 800));

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('Create Account button opens the Sign Up screen', (
      tester,
    ) async {
      await _pumpAuthGate(tester);
      await tester.pump(const Duration(milliseconds: 800));

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpScreen), findsOneWidget);
    });
  });
}
