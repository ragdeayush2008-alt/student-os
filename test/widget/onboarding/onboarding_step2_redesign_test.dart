import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/onboarding/presentation/onboarding_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

/// Step 2 "Select Your Goal" premium redesign: structure, states,
/// selection, CTA, responsive and accessibility behavior.
/// Business logic is untouched — these verify presentation + flow.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CourseCatalogService.instance.ensureInitialized();
    CourseCatalogService.instance.loadDefaults();
    SubjectController.instance.clearData();
    StudentService.instance.clearProfile();
    AuthIsolation.instance.setAuthenticatedUser('test_step2_redesign');
  });

  tearDown(() {
    SubjectController.instance.clearData();
    StudentService.instance.clearProfile();
    AuthIsolation.instance.clearSession();
  });

  Future<void> pumpOnboarding(WidgetTester tester, {Size size = const Size(390, 844)}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const OnboardingScreen(),
        ),
      ),
    );
  }

  /// Step 0 (name) → Step 1 (Select Your Goal).
  Future<void> goToStep2(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'Aarav');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Select Your Goal'), findsOneWidget);
  }

  testWidgets('1. Step 2 opens with title, search, popular, categories', (tester) async {
    await pumpOnboarding(tester);
    await tester.pumpAndSettle();
    await goToStep2(tester);

    expect(find.text('Select Your Goal'), findsOneWidget);
    expect(find.text('Popular Exams & Goals'), findsOneWidget);
    expect(find.text('All Categories'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('2. Back returns to the name step', (tester) async {
    await pumpOnboarding(tester);
    await tester.pumpAndSettle();
    await goToStep2(tester);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('YOUR NAME'), findsOneWidget);
  });

  testWidgets('3. progress announces Step 2 of 3', (tester) async {
    await pumpOnboarding(tester);
    await tester.pumpAndSettle();
    await goToStep2(tester);

    expect(find.text('STEP 2 OF 3'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Step 2 of 3')),
      findsOneWidget,
    );
  });

  testWidgets('4-5. search filters programs; empty query restores home', (tester) async {
    await pumpOnboarding(tester);
    await tester.pumpAndSettle();
    await goToStep2(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.last, 'JEE');
    await tester.pumpAndSettle();
    // Filtered results replace the popular section.
    expect(find.text('Popular Exams & Goals'), findsNothing);

    await tester.enterText(fields.last, '');
    await tester.pumpAndSettle();
    expect(find.text('Popular Exams & Goals'), findsOneWidget);
  });

  testWidgets('6. gibberish search shows the honest empty state', (tester) async {
    await pumpOnboarding(tester);
    await tester.pumpAndSettle();
    await goToStep2(tester);

    await tester.enterText(find.byType(TextField).last, 'zzzqqqkjo');
    await tester.pumpAndSettle();
    expect(find.text('No matching courses found'), findsOneWidget);
  });

  testWidgets('7. popular goal tap opens its detail', (tester) async {
    await pumpOnboarding(tester);
    await tester.pumpAndSettle();
    await goToStep2(tester);

    final popular = find.text('Popular Exams & Goals');
    expect(popular, findsOneWidget);
    // Tap the first premium popular goal card (no lightning icon — uses
    // goal-specific visual identity via PremiumGoalCard).
    expect(find.byIcon(Icons.bolt_rounded), findsNothing,
        reason: 'Repeated lightning icon must be gone');
    final firstCard = find
        .byWidgetPredicate(
          (w) =>
              w.runtimeType.toString() == 'PremiumGoalCard' ||
              (w is GestureDetector && w.child != null),
        )
        .first;
    // Fall back to tapping any InkWell inside the popular grid if needed.
    final tapTarget = find.ancestor(
      of: find.textContaining('JEE').first,
      matching: find.byType(GestureDetector),
    );
    final target =
        tapTarget.evaluate().isNotEmpty ? tapTarget.first : firstCard;
    await tester.tap(target, warnIfMissed: false);
    await tester.pumpAndSettle();
    // Detail view replaces the home list (or at least navigates away).
    // PremiumGoalCard tap selects program → detail; home header disappears.
    expect(find.text('Popular Exams & Goals'), findsNothing);
  });

  testWidgets('8. category tap opens its families', (tester) async {
    await pumpOnboarding(tester);
    await tester.pumpAndSettle();
    await goToStep2(tester);

    // Tap the first category card's arrow.
    final arrows = find.byIcon(Icons.arrow_forward_rounded);
    expect(arrows, findsWidgets);
    await tester.ensureVisible(arrows.first);
    await tester.pumpAndSettle();
    await tester.tap(arrows.first);
    await tester.pumpAndSettle();
    expect(find.text('Popular Exams & Goals'), findsNothing);
  });

  testWidgets('10-12. Continue disabled until valid, then reaches Step 3', (tester) async {
    await pumpOnboarding(tester);
    await tester.pumpAndSettle();
    await goToStep2(tester);

    final continueBtn = find.text('Continue');
    expect(continueBtn, findsOneWidget);
    // Disabled with no selection: tapping does nothing.
    await tester.tap(continueBtn, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Select Your Goal'), findsOneWidget);

    // Select a category → family → program → level, then Continue works.
    Future<void> tapFirstVisible(Finder finder) async {
      expect(finder, findsWidgets);
      await tester.ensureVisible(finder.first);
      await tester.pumpAndSettle();
      await tester.tap(finder.first);
      await tester.pumpAndSettle();
    }

    await tapFirstVisible(find.byIcon(Icons.arrow_forward_rounded));
    // Family list: tap first family row.
    await tapFirstVisible(find.byIcon(Icons.chevron_right_rounded));
    // Program list: tap first program row.
    await tapFirstVisible(find.byIcon(Icons.chevron_right_rounded));
    // Program detail shows level chips; pick defaults exist — Continue on.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    // Step 3 reached (goals & confirmation summary).
    expect(find.text('Select Your Goal'), findsNothing);
  });

  testWidgets('14. narrow 320dp layout has no overflow', (tester) async {
    await pumpOnboarding(tester, size: const Size(320, 568));
    await tester.pumpAndSettle();
    await goToStep2(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('16. search carries an accessible label', (tester) async {
    await pumpOnboarding(tester);
    await tester.pumpAndSettle();
    await goToStep2(tester);

    expect(
      find.bySemanticsLabel('Search exams, courses or goals'),
      findsWidgets,
    );
  });
}
