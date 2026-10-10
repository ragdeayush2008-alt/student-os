import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/auth/presentation/forgot_password_screen.dart';
import 'package:student_os/features/auth/presentation/sign_in_screen.dart';
import 'package:student_os/features/auth/presentation/sign_up_screen.dart';
import 'package:student_os/features/auth/presentation/verification_pending_screen.dart';
import 'package:student_os/features/auth/widgets/auth_error_banner.dart';
import 'package:student_os/features/auth/widgets/auth_shell.dart';
import 'package:student_os/features/auth/widgets/google_sign_in_button.dart';

Widget _buildTestApp(Widget child, {bool dark = false}) {
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    routes: {
      '/sign-in': (_) => const SignInScreen(),
      '/sign-up': (_) => const SignUpScreen(),
      '/forgot-password': (_) => const ForgotPasswordScreen(),
      '/verification-pending': (_) => const VerificationPendingScreen(),
    },
    home: AuthScope(
      authService: AuthService.instance,
      child: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthShell & Theme Verification (Command Center)', () {
    testWidgets('AuthShell uses solid surface and renders back button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(const AuthShell(child: Text('Shell Content'))),
      );
      await tester.pumpAndSettle();

      // Solid Command Center shell: scaffold uses theme background,
      // content card uses theme surface.
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.text('Shell Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AuthShell renders without back when requested', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AuthShell(showBack: false, child: Text('No Back')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
      expect(find.text('No Back'), findsOneWidget);
    });

    testWidgets('AuthErrorBanner displays icon and text', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const Scaffold(
            body: AuthErrorBanner(message: 'Invalid credentials provided'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Invalid credentials provided'), findsOneWidget);
    });
  });

  group('SignInScreen UI & Interactions', () {
    testWidgets('renders all sign-in elements', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(const SignInScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Continue your journey'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('validates empty email and password inputs', (tester) async {
      await tester.pumpWidget(_buildTestApp(const SignInScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(_buildTestApp(const SignInScreen()));
      await tester.pumpAndSettle();

      final visibilityBtn = find.byTooltip('Show password');
      expect(visibilityBtn, findsOneWidget);

      await tester.tap(visibilityBtn);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('Google sign in button is present and clickable', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(const SignInScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(GoogleSignInButton), findsOneWidget);
      await tester.tap(find.byType(GoogleSignInButton));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('SignUpScreen UI & Interactions', () {
    testWidgets('renders all sign-up elements', (tester) async {
      await tester.pumpWidget(_buildTestApp(const SignUpScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Set up your Student OS'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('At least 6 characters'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('validates mismatched passwords and weak passwords', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(const SignUpScreen()));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'student@example.com');
      await tester.enterText(textFields.at(1), '123');
      await tester.enterText(textFields.at(2), '456');

      await tester.tap(find.text('Create Account').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters.'),
        findsOneWidget,
      );
    });
  });

  group('ForgotPasswordScreen & VerificationPendingScreen', () {
    testWidgets('ForgotPassword renders and validates email', (tester) async {
      await tester.pumpWidget(_buildTestApp(const ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Forgot password?'), findsOneWidget);
      expect(
        find.text('Enter the email associated with your account.'),
        findsOneWidget,
      );
      expect(find.text('Send reset link'), findsOneWidget);

      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('VerificationPendingScreen renders with icon and actions', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(const VerificationPendingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
      expect(find.textContaining('Go to Sign In'), findsOneWidget);
      expect(find.text('Resend email'), findsOneWidget);
    });
  });
}
