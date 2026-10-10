import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/app/app_shell.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/widgets/student_os_bottom_nav.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/calculator/presentation/calculator_screen.dart';
import 'package:student_os/features/checklist/checklist_controller.dart';
import 'package:student_os/features/checklist/presentation/checklist_screen.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/presentation/screens/focus_distraction_inbox_screen.dart';
import 'package:student_os/features/habits/habit_controller.dart';
import 'package:student_os/features/habits/presentation/habits_screen.dart';
import 'package:student_os/features/notes/presentation/quick_notes_screen.dart';
import 'package:student_os/features/notes/student_note_controller.dart';
import 'package:student_os/features/tools/presentation/tools_hub_screen.dart';
import 'package:student_os/features/wellness/presentation/wellness_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  Widget wrapWithApp(Widget child, {AppShellController? controller, double width = 600}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: AppScope(
          controller: controller ?? AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Tools 2.0 — Comprehensive Integration Tests', () {
    testWidgets('1. Tools opens from bottom-navigation as 4th destination', (tester) async {
      final shellCtrl = AppShellController();
      await tester.pumpWidget(wrapWithApp(const AppShell(), controller: shellCtrl));
      await tester.pumpAndSettle();

      final navBar = find.byType(StudentOSBottomNavigation);
      await tester.tap(find.descendant(of: navBar, matching: find.text('Tools Hub')));
      await tester.pumpAndSettle();

      expect(shellCtrl.selectedIndex, 3);
      expect(find.byType(ToolsHubScreen), findsOneWidget);
    });

    testWidgets('2. Primary six tools navigate and return cleanly with back navigation', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      // Quick Notes
      await tester.tap(find.text('Quick Notes'));
      await tester.pumpAndSettle();
      expect(find.byType(QuickNotesScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ToolsHubScreen), findsOneWidget);

      // Calculator
      await tester.tap(find.text('Calculator'));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ToolsHubScreen), findsOneWidget);

      // Wellness
      await tester.tap(find.text('Wellness'));
      await tester.pumpAndSettle();
      expect(find.byType(WellnessScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ToolsHubScreen), findsOneWidget);

      // Checklist
      await tester.tap(find.text('Checklist'));
      await tester.pumpAndSettle();
      expect(find.byType(ChecklistScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ToolsHubScreen), findsOneWidget);

      // Habits
      await tester.tap(find.text('Habits'));
      await tester.pumpAndSettle();
      expect(find.byType(HabitsScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ToolsHubScreen), findsOneWidget);

      // Distraction Box
      await tester.tap(find.text('Distraction'));
      await tester.pumpAndSettle();
      expect(find.byType(FocusDistractionInboxScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ToolsHubScreen), findsOneWidget);
    });

    testWidgets('3. User Isolation A -> B -> A for Notes, Checklist, Habits, Distractions', (tester) async {
      // User A
      AuthIsolation.instance.setAuthenticatedUser('user_A');
      await StudentNoteController.instance.createNote(title: 'User A Note', content: 'Content A');
      await ChecklistController.instance.addItem('User A Checklist');
      await HabitController.instance.createHabit(title: 'User A Habit');
      FocusController.instance.captureDistraction('User A Distraction');

      expect(StudentNoteController.instance.notes.length, 1);
      expect(ChecklistController.instance.items.length, 1);
      expect(HabitController.instance.habits.length, 1);
      expect(FocusController.instance.distractions.length, 1);

      // Switch to User B
      AuthIsolation.instance.clearSession();
      ControllerIsolation.instance.clearAllControllers();

      expect(StudentNoteController.instance.notes.isEmpty, isTrue);
      expect(ChecklistController.instance.items.isEmpty, isTrue);
      expect(HabitController.instance.habits.isEmpty, isTrue);
      expect(FocusController.instance.distractions.isEmpty, isTrue);

      AuthIsolation.instance.setAuthenticatedUser('user_B');
      await StudentNoteController.instance.createNote(title: 'User B Note', content: 'Content B');
      await ChecklistController.instance.addItem('User B Checklist');
      expect(StudentNoteController.instance.notes.length, 1);

      // Switch back to User A
      AuthIsolation.instance.clearSession();
      ControllerIsolation.instance.clearAllControllers();

      AuthIsolation.instance.setAuthenticatedUser('user_A');
      await StudentNoteController.instance.load();
      await ChecklistController.instance.load();
      await HabitController.instance.load();
      await FocusController.instance.load();

      expect(StudentNoteController.instance.notes.length, 1);
      expect(StudentNoteController.instance.notes.first.title, 'User A Note');
      expect(ChecklistController.instance.items.length, 1);
      expect(ChecklistController.instance.items.first.title, 'User A Checklist');
      expect(HabitController.instance.habits.length, 1);
      expect(HabitController.instance.habits.first.title, 'User A Habit');
      expect(FocusController.instance.distractions.length, 1);
      expect(FocusController.instance.distractions.first.thought, 'User A Distraction');
    });
  });
}
