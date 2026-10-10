import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/features/onboarding/presentation/onboarding_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  group('Onboarding & Course Setup Widget Tests (Unified 2.0)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      CourseCatalogService.instance.ensureInitialized();
      CourseCatalogService.instance.loadDefaults();
      SubjectController.instance.clearData();
      StudentService.instance.clearProfile();
      AuthIsolation.instance.setAuthenticatedUser('test_widget_user');
    });

    tearDown(() {
      SubjectController.instance.clearData();
      StudentService.instance.clearProfile();
      AuthIsolation.instance.clearSession();
    });

    testWidgets('Renders OnboardingScreen and steps through unified goal setup', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: Welcome & Name
      expect(find.text('Welcome to Student OS'), findsOneWidget);
      expect(find.text('YOUR NAME'), findsOneWidget);

      // Enter Name
      await tester.enterText(find.byType(TextField).first, 'John Doe');
      await tester.pumpAndSettle();

      // Tap Continue to Step 1 (Unified Select Your Goal)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 1: Unified Course Selection — same UI as Change Course
      expect(find.text('Select Your Goal'), findsOneWidget);
      expect(find.text('Popular Exams & Goals'), findsOneWidget);
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('Commerce, Accounting & Finance'), findsOneWidget);

      // Use search to select CA Foundation 2026
      final searchField = find.byType(TextField).last;
      await tester.enterText(searchField, 'CA Foundation');
      await tester.pumpAndSettle();
      expect(find.textContaining('result'), findsOneWidget);
      await tester.tap(find.text('CA Foundation').last);
      await tester.pumpAndSettle();

      // Program detail should show core papers
      expect(find.text('Core Papers'), findsWidgets);
      expect(find.text('Accounting'), findsWidgets);

      // Tap Continue to Step 2 (Academic Summary)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Goals & Confirmation
      expect(find.text('Academic Summary'), findsOneWidget);
      expect(find.textContaining('YOUR GOAL'), findsOneWidget);
      expect(find.text('Create Subjects & Launch'), findsOneWidget);

      // Tap "Create Subjects & Launch"
      await tester.tap(find.text('Create Subjects & Launch'));
      await tester.pumpAndSettle();

      // Verify subjects provisioned via Catalog 2.0 and profile persisted
      expect(SubjectController.instance.subjects.length, greaterThanOrEqualTo(4));
      expect(SubjectController.instance.subjects.any((s) => s.name == 'Accounting'), isTrue);
      expect(SubjectController.instance.subjects.any((s) => s.name == 'Business Economics'), isTrue);
      expect(StudentService.instance.profile.isOnboardingComplete, isTrue);
      // Course ID should be the Catalog 2.0 program id
      expect(StudentService.instance.profile.catalogCourseId, 'ca_foundation');
      expect(CourseCatalogService.instance.getActiveCourse(), 'CA Foundation');
    });
  });
}
