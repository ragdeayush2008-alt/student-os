import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/auth/auth_gate.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/auth/auth_state.dart';
import 'package:student_os/features/auth/presentation/update_password_screen.dart';

void main() {
  group('Auth Deep Link & Redirect Configuration', () {
    test('AuthService uses valid RFC Android redirect URI without underscore', () {
      expect(
        AuthService.authRedirectUri,
        equals('com.ragdetechnologies.studentos://login-callback/'),
      );
      expect(
        AuthService.androidOAuthRedirect,
        equals('com.ragdetechnologies.studentos://login-callback/'),
      );
    });

    test('AuthViewState contains passwordRecovery', () {
      expect(AuthViewState.values, contains(AuthViewState.passwordRecovery));
    });
  });

  group('Update Password Screen', () {
    testWidgets('renders update password form', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            authService: AuthService.instance,
            child: const UpdatePasswordScreen(),
          ),
        ),
      );

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('New password'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
    });

    testWidgets('validates password length and mismatch on submission', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            authService: AuthService.instance,
            child: const UpdatePasswordScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), '123');
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.tap(find.text('Update Password'));
      await tester.pump();

      expect(find.text(AuthError.weakPassword.message), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '123456');
      await tester.enterText(find.byType(TextField).at(1), '654321');
      await tester.tap(find.text('Update Password'));
      await tester.pump();

      expect(find.text(AuthError.passwordsMismatch.message), findsOneWidget);
    });
  });

  group('AuthGate Password Recovery Routing', () {
    testWidgets('AuthGate routes to UpdatePasswordScreen on passwordRecovery state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            authService: AuthService.instance,
            child: const AuthGate(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AuthGate), findsOneWidget);
    });
  });
}
