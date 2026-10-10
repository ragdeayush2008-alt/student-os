import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/app_card.dart';
import 'package:student_os/data/models/catalog/active_course_selection.dart';
import 'package:student_os/features/catalog/presentation/course_selection_screen.dart';
import 'package:student_os/features/profile/profile_screen.dart';

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
  group('Profile Change Course & Selection Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      CourseCatalogService.instance.ensureInitialized();
      CourseCatalogService.instance.loadDefaults();
      StudentService.instance.clearProfile();
      AuthIsolation.instance.setAuthenticatedUser('widget_test_user');
    });

    tearDown(() {
      StudentService.instance.clearProfile();
      AuthIsolation.instance.clearSession();
    });

    testWidgets('1. ProfileScreen displays Change Course tile with current course name', (tester) async {
      // Set initial course
      await CourseCatalogService.instance.setActiveCourse(
        ActiveCourseSelection(
          userId: 'widget_test_user',
          categoryId: 'commerce_accounting_finance',
          familyId: 'ca',
          programId: 'ca_foundation',
          programTitle: 'CA Foundation',
          levelId: 'ca_f_level',
          levelTitle: 'Foundation Level',
          year: '2026',
        ),
      );

      await tester.pumpWidget(_buildTestApp(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Change Course'), findsOneWidget);
      expect(find.textContaining('CA Foundation'), findsWidgets);
    });

    testWidgets('2. CourseSelectionScreen renders categories, popular chips, and search bar', (tester) async {
      await tester.pumpWidget(_buildTestApp(const CourseSelectionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Select Your Goal'), findsOneWidget);
      expect(find.text('Popular Exams & Goals'), findsOneWidget);
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('Commerce, Accounting & Finance'), findsOneWidget);
      expect(find.text('Engineering & Technology'), findsOneWidget);
      expect(find.text('Medical & Healthcare'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('3. CourseSelectionScreen filters by search query and allows selection', (tester) async {
      await tester.pumpWidget(_buildTestApp(const CourseSelectionScreen()));
      await tester.pumpAndSettle();

      // Enter search text — offline fast search
      await tester.enterText(find.byType(TextField), 'CA Foundation');
      await tester.pumpAndSettle();

      expect(find.textContaining('result'), findsOneWidget);
      expect(find.text('CA Foundation'), findsWidgets);

      // Tap specifically on CA Foundation search result (avoid CMA Foundation)
      final caResult = find.ancestor(
        of: find.text('CA Foundation').last,
        matching: find.byType(AppCard),
      );
      if (caResult.evaluate().isNotEmpty) {
        await tester.tap(caResult.first);
      } else {
        await tester.tap(find.text('CA Foundation').last);
      }
      await tester.pumpAndSettle();

      // Should open Program Detail View showing official 4 CA 2026 subjects
      expect(find.text('Core Papers'), findsOneWidget);
      expect(find.text('Accounting'), findsOneWidget);
      expect(find.text('Business Laws'), findsOneWidget);
      expect(find.text('Quantitative Aptitude'), findsOneWidget);
      expect(find.text('Business Economics'), findsOneWidget);
    });

    testWidgets('4. Selecting goal opens confirmation dialog with safety notice', (tester) async {
      // Pre-set an active course so change mode requires confirmation
      await CourseCatalogService.instance.setActiveCourse(
        ActiveCourseSelection(
          userId: 'widget_test_user',
          categoryId: 'commerce_accounting_finance',
          familyId: 'ca',
          programId: 'ca_foundation',
          programTitle: 'CA Foundation',
          levelId: 'ca_f_level',
          levelTitle: 'Foundation Level',
          year: '2026',
        ),
      );

      await tester.pumpWidget(_buildTestApp(const CourseSelectionScreen()));
      await tester.pumpAndSettle();

      // Search for JEE Main
      await tester.enterText(find.byType(TextField), 'JEE Main');
      await tester.pumpAndSettle();

      final jeeResult = find.ancestor(
        of: find.text('JEE Main').first,
        matching: find.byType(AppCard),
      );
      if (jeeResult.evaluate().isNotEmpty) {
        await tester.tap(jeeResult.first);
      } else {
        await tester.tap(find.byType(AppCard).first);
      }
      await tester.pumpAndSettle();

      // Unified premium CTA is Continue/Switch Course depending on mode
      expect(find.text('Switch Course'), findsOneWidget);
      await tester.tap(find.text('Switch Course'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog with data-preservation notice
      expect(find.text('Switch Active Course'), findsOneWidget);
      expect(find.textContaining('Your previous course data'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // Dialog CTA also says Switch Course
      expect(find.text('Switch Course'), findsWidgets);
    });
  });
}
