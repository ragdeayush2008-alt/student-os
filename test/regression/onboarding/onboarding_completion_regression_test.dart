import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/onboarding/presentation/onboarding_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  group('Onboarding Completion & Black Screen Regression Tests (Unified 2.0)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      CourseCatalogService.instance.ensureInitialized();
      CourseCatalogService.instance.loadDefaults();
      SubjectController.instance.clearData();
      StudentService.instance.clearProfile();
      AuthIsolation.instance.setAuthenticatedUser('test_regression_user');
    });

    tearDown(() {
      SubjectController.instance.clearData();
      StudentService.instance.clearProfile();
      AuthIsolation.instance.clearSession();
    });

    testWidgets('Completing onboarding via unified Select Your Goal transitions without popping root', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            authService: AuthService.instance,
            child: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Test Student');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Unified home: Select Your Goal with popular + categories
      expect(find.text('Select Your Goal'), findsOneWidget);
      expect(find.text('Popular Exams & Goals'), findsOneWidget);
      expect(find.text('All Categories'), findsOneWidget);

      // Use search shortcut to select CA Foundation 2026 (authoritative catalog)
      final searchField = find.byType(TextField).last;
      await tester.enterText(searchField, 'CA Foundation');
      await tester.pumpAndSettle();

      expect(find.textContaining('result'), findsOneWidget);
      // Tap search result AppCard by finding CA Foundation inside results
      // Find the AppCard that contains CA Foundation and tap it
      final caCard = find.widgetWithText(Card, 'CA Foundation').evaluate().isNotEmpty
          ? find.widgetWithText(Card, 'CA Foundation')
          : find.ancestor(of: find.text('CA Foundation'), matching: find.byType(InkWell));
      if (caCard.evaluate().isNotEmpty) {
        await tester.tap(caCard.first);
      } else {
        // Fallback: tap text with scroll visible
        await tester.tap(find.text('CA Foundation').last);
      }
      await tester.pumpAndSettle();

      // Now in program detail showing core papers
      expect(find.text('Core Papers'), findsWidgets);
      expect(find.text('Accounting'), findsWidgets);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Academic Summary'), findsOneWidget);
      expect(find.textContaining('YOUR GOAL'), findsOneWidget);

      await tester.tap(find.text('Create Subjects & Launch'));
      await tester.pumpAndSettle();

      expect(StudentService.instance.profile.isOnboardingComplete, isTrue);
      expect(StudentService.instance.profile.course, 'CA Foundation');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Engineering B.Tech flow allows selecting semester and completing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            authService: AuthService.instance,
            child: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Engineer');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Select Your Goal'), findsOneWidget);

      // Use search shortcut for B.Tech Computer Science (authoritative catalog)
      final searchField2 = find.byType(TextField).last;
      await tester.enterText(searchField2, 'B.Tech Computer Science');
      await tester.pumpAndSettle();
      expect(find.textContaining('result'), findsOneWidget);
      // Tap search result card
      await tester.tap(find.text('B.Tech Computer Science').last);
      await tester.pumpAndSettle();

      // Level chips should appear — Semester 1
      expect(find.text('Select Level / Stream'), findsOneWidget);
      expect(find.text('Semester 1'), findsWidgets);

      await tester.tap(find.text('Semester 1').first);
      await tester.pumpAndSettle();

      // Continue to goals summary
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Academic Summary'), findsOneWidget);
      expect(find.text('Semester 1'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
