import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/auth/auth_state.dart';
import 'package:student_os/features/auth/presentation/welcome_screen.dart';

void main() {
  group('AuthValidator — email validation', () {
    test('rejects empty email', () {
      expect(AuthValidator.isValidEmail(''), isFalse);
      expect(AuthValidator.isValidEmail('   '), isFalse);
    });

    test('rejects emails without @ or domain', () {
      expect(AuthValidator.isValidEmail('notanemail'), isFalse);
      expect(AuthValidator.isValidEmail('missing@'), isFalse);
      expect(AuthValidator.isValidEmail('@nodomain.com'), isFalse);
    });

    test('accepts valid email formats', () {
      expect(AuthValidator.isValidEmail('user@example.com'), isTrue);
      expect(AuthValidator.isValidEmail('a+b@test.co'), isTrue);
      expect(AuthValidator.isValidEmail('  user@test.com  '), isTrue);
    });
  });

  group('AuthValidator — password validation', () {
    test('rejects passwords shorter than 6 characters', () {
      expect(AuthValidator.isStrongPassword(''), isFalse);
      expect(AuthValidator.isStrongPassword('abc'), isFalse);
      expect(AuthValidator.isStrongPassword('12345'), isFalse);
    });

    test('accepts passwords of 6 or more characters', () {
      expect(AuthValidator.isStrongPassword('123456'), isTrue);
      expect(AuthValidator.isStrongPassword('abcdef'), isTrue);
      expect(AuthValidator.isStrongPassword('longpassword'), isTrue);
    });
  });

  group('AuthValidator — password matching', () {
    test('passwords match when identical', () {
      expect(AuthValidator.passwordsMatch('password', 'password'), isTrue);
    });

    test('passwords do not match when different', () {
      expect(AuthValidator.passwordsMatch('password', 'wrong'), isFalse);
      expect(AuthValidator.passwordsMatch('password', 'Password'), isFalse);
    });
  });

  group('classifyAuthError — mapping', () {
    test('maps invalid credentials', () {
      expect(
        classifyAuthError(Exception('invalid login credentials')),
        AuthError.invalidCredentials,
      );
    });

    test('maps email already registered', () {
      expect(
        classifyAuthError(
          Exception('email address has already been registered'),
        ),
        AuthError.emailAlreadyInUse,
      );
    });

    test('maps email not confirmed', () {
      expect(
        classifyAuthError(Exception('email not confirmed')),
        AuthError.emailNotConfirmed,
      );
    });

    test('maps user not found', () {
      expect(
        classifyAuthError(Exception('user not found')),
        AuthError.userNotFound,
      );
    });

    test('maps network errors', () {
      expect(
        classifyAuthError(Exception('SocketException: network unreachable')),
        AuthError.network,
      );
    });

    test('falls back to unknown for unrecognized errors', () {
      expect(
        classifyAuthError(Exception('something weird happened')),
        AuthError.unknown,
      );
    });
  });

  group('AuthResult — construction', () {
    test('success result is success', () {
      const result = AuthResult.success();
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.isEmailConfirmationPending, isFalse);
      expect(result.error, isNull);
    });

    test('email confirmation pending result', () {
      const result = AuthResult.emailConfirmationPending();
      expect(result.isEmailConfirmationPending, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.error, isNull);
    });

    test('failure result carries error', () {
      const result = AuthResult.failure(AuthError.invalidCredentials);
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.error, AuthError.invalidCredentials);
    });
  });

  group('AuthService — state', () {
    test('isAuthenticated is false by default', () {
      expect(AuthService.instance.isAuthenticated, isFalse);
    });

    test('viewState is not authenticated by default', () {
      final state = AuthService.instance.viewState;
      expect(state, isNot(equals(AuthViewState.authenticated)));
    });
  });

  group('Auth UI — small screen layout', () {
    testWidgets('WelcomeScreen renders without overflow on small screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: AuthScope(
            authService: AuthService.instance,
            child: const WelcomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Student OS'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'WelcomeScreen renders without overflow on extra-narrow screen (320px)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: AuthScope(
              authService: AuthService.instance,
              child: const WelcomeScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));

        expect(find.text('Student OS'), findsOneWidget);
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
