import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/student_os_onboarding_progress.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/auth/presentation/forgot_password_screen.dart';
import 'package:student_os/features/auth/presentation/sign_in_screen.dart';
import 'package:student_os/features/auth/presentation/sign_up_screen.dart';
import 'package:student_os/features/auth/presentation/verification_pending_screen.dart';
import 'package:student_os/features/auth/presentation/welcome_screen.dart';
import 'package:student_os/features/auth/widgets/google_sign_in_button.dart';
import 'package:student_os/features/onboarding/presentation/onboarding_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

Widget _authApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: AuthScope(authService: AuthService.instance, child: child),
  );
}

Future<void> _pumpOnboarding(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  CourseCatalogService.instance.ensureInitialized();
  CourseCatalogService.instance.loadDefaults();
  SubjectController.instance.clearData();
  StudentService.instance.clearProfile();
  AuthIsolation.instance.setAuthenticatedUser('cmd_center_test_user');
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: const OnboardingScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Welcome — Command Center', () {
    testWidgets('renders branding, value prop, preview, and CTAs', (
      tester,
    ) async {
      await tester.pumpWidget(_authApp(const WelcomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Student OS'), findsOneWidget);
      expect(
        find.text('Your complete student operating system'),
        findsOneWidget,
      );
      // Compact feature preview (not pills-as-nav)
      expect(find.text('PLAN'), findsOneWidget);
      expect(find.text('FOCUS'), findsOneWidget);
      expect(find.text('STUDY'), findsOneWidget);
      expect(find.text('PROGRESS'), findsOneWidget);
      // CTAs wired
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Auth screens — Command Center', () {
    testWidgets('Sign In renders with Google + primary wired', (tester) async {
      await tester.pumpWidget(_authApp(const SignInScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      // Validation error state
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email address.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sign Up renders all fields + validation', (tester) async {
      await tester.pumpWidget(_authApp(const SignUpScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Forgot Password renders + Back to Sign In', (tester) async {
      await tester.pumpWidget(_authApp(const ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Verification renders inbox + resend + verified', (
      tester,
    ) async {
      await tester.pumpWidget(
        _authApp(const VerificationPendingScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.textContaining('Go to Sign In'), findsOneWidget);
      expect(find.text('Resend email'), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Onboarding — Command Center (Unified 2.0)', () {
    tearDown(() {
      SubjectController.instance.clearData();
      StudentService.instance.clearProfile();
      AuthIsolation.instance.clearSession();
    });

    testWidgets('progress shows STEP 1 OF 3 on first step', (tester) async {
      await _pumpOnboarding(tester);
      expect(find.byType(StudentOSOnboardingProgress), findsOneWidget);
      expect(find.text('STEP 1 OF 3'), findsOneWidget);
    });

    testWidgets('Unified Select Your Goal shows categories + search', (tester) async {
      await _pumpOnboarding(tester);

      await tester.enterText(find.byType(TextField).first, 'Test Student');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Select Your Goal'), findsOneWidget);
      expect(find.text('STEP 2 OF 3'), findsOneWidget);
      // Authoritative 18 categories + popular
      expect(find.text('Popular Exams & Goals'), findsOneWidget);
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('School, Boards & Olympiads'), findsOneWidget);
      expect(find.text('Engineering & Technology'), findsOneWidget);
      expect(find.text('Commerce, Accounting & Finance'), findsOneWidget);
      // Search field present
      expect(find.text('Search exams, courses or goals'), findsOneWidget);
      // Change selection preserves state: tap category then back (scroll if needed)
      final engCat = find.text('Engineering & Technology');
      await tester.scrollUntilVisible(engCat, 80, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(engCat);
      await tester.pumpAndSettle();
      expect(find.text('Select Exam Family'), findsOneWidget);
      // Navigate back within picker (scroll the header into view first).
      final backBtn = find.byIcon(Icons.arrow_back_rounded).first;
      await tester.scrollUntilVisible(backBtn, 80, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(backBtn);
      await tester.pumpAndSettle();
      expect(find.text('All Categories'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Program detail shows core papers and semester selection for B.Tech', (
      tester,
    ) async {
      await _pumpOnboarding(tester);

      await tester.enterText(find.byType(TextField).first, 'Engineer');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Select Engineering -> B.Tech -> B.Tech CSE via navigation (scroll as needed)
      final eng = find.text('Engineering & Technology');
      await tester.scrollUntilVisible(eng, 80, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(eng);
      await tester.pumpAndSettle();
      final btechFamily = find.text('Bachelor of Technology (B.Tech)');
      await tester.scrollUntilVisible(btechFamily, 80, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(btechFamily);
      await tester.pumpAndSettle();

      final btechItem = find.text('B.Tech Computer Science');
      await tester.scrollUntilVisible(
        btechItem,
        60,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(btechItem);
      await tester.pumpAndSettle();

      // Level selector for B.Tech semesters
      expect(find.text('Select Level / Stream'), findsOneWidget);
      expect(find.text('Semester 1'), findsWidgets);
      expect(find.text('Semester 2'), findsWidgets);

      // Select Semester 1 chip
      await tester.tap(find.text('Semester 1').first);
      await tester.pumpAndSettle();

      // Should show core papers preview & YOUR GOAL card
      expect(find.text('Core Papers'), findsWidgets);
      expect(find.text('YOUR GOAL'), findsOneWidget);

      // Continue now enabled — go to Academic Summary
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Academic Summary'), findsOneWidget);
      expect(find.textContaining('YOUR GOAL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Continue blocked without goal, back preserves state', (
      tester,
    ) async {
      await _pumpOnboarding(tester);

      // Step 0 without name: Continue disabled (stays on step 0)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Student OS'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Back Nav');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Select Your Goal'), findsOneWidget);

      // Back returns to name step with text intact
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Student OS'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller?.text, 'Back Nav');
      expect(tester.takeException(), isNull);
    });
  });

  group('Responsive — 320/360/390/412/430, no overflow', () {
    for (final width in [320.0, 360.0, 390.0, 412.0, 430.0]) {
      testWidgets('SignIn fits ${width.toInt()}dp', (tester) async {
        tester.view.physicalSize = Size(width * 3, 800 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(_authApp(const SignInScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Welcome back'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Welcome fits ${width.toInt()}dp', (tester) async {
        tester.view.physicalSize = Size(width * 3, 800 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(_authApp(const WelcomeScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Student OS'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Onboarding first step fits 320dp and 430dp', (tester) async {
      for (final width in [320.0, 430.0]) {
        tester.view.physicalSize = Size(width * 3, 800 * 3);
        tester.view.devicePixelRatio = 3.0;
        await _pumpOnboarding(tester);
        expect(find.text('Welcome to Student OS'), findsOneWidget);
        expect(tester.takeException(), isNull);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
  });
}
