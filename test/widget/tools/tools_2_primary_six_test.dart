import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/calculator/presentation/calculator_screen.dart';
import 'package:student_os/features/checklist/presentation/checklist_screen.dart';
import 'package:student_os/features/habits/presentation/habits_screen.dart';
import 'package:student_os/features/notes/presentation/quick_notes_screen.dart';
import 'package:student_os/features/tools/presentation/tools_hub_screen.dart';
import 'package:student_os/features/wellness/presentation/wellness_screen.dart';
import 'package:student_os/features/focus/presentation/screens/focus_distraction_inbox_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapWithApp(Widget child, {double width = 600}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: AppScope(
          controller: AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Tools 2.0 — Primary Six Tools Widget Tests', () {
    testWidgets('1. Top of Tools contains exactly the primary six tools in icon-first presentation', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Quick Utilities'), findsOneWidget);
      expect(find.text('Quick Notes'), findsOneWidget);
      expect(find.text('Calculator'), findsOneWidget);
      expect(find.text('Wellness'), findsOneWidget);
      expect(find.text('Checklist'), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
      expect(find.text('Distraction'), findsOneWidget);
    });

    testWidgets('2. Tapping Quick Notes opens QuickNotesScreen', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quick Notes'));
      await tester.pumpAndSettle();

      expect(find.byType(QuickNotesScreen), findsOneWidget);
    });

    testWidgets('3. Tapping Calculator opens CalculatorScreen', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calculator'));
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScreen), findsOneWidget);
    });

    testWidgets('4. Tapping Wellness opens WellnessScreen', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wellness'));
      await tester.pumpAndSettle();

      expect(find.byType(WellnessScreen), findsOneWidget);
    });

    testWidgets('5. Tapping Checklist opens ChecklistScreen', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Checklist'));
      await tester.pumpAndSettle();

      expect(find.byType(ChecklistScreen), findsOneWidget);
    });

    testWidgets('6. Tapping Habits opens HabitsScreen', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Habits'));
      await tester.pumpAndSettle();

      expect(find.byType(HabitsScreen), findsOneWidget);
    });

    testWidgets('7. Tapping Distraction opens FocusDistractionInboxScreen', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Distraction'));
      await tester.pumpAndSettle();

      expect(find.byType(FocusDistractionInboxScreen), findsOneWidget);
    });
  });
}
