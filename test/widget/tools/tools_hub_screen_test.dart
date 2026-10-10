import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/tools/presentation/tools_hub_screen.dart';

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

  group('ToolsHubScreen — Widget Tests', () {
    testWidgets('1. Renders Tools Hub header, search bar, and primary six tools', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      // Canonical sibling header (same DNA as Home/Plan/Workspace).
      expect(find.text('Tools Hub'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Quick Utilities'), findsOneWidget);
      expect(find.text('Quick Notes'), findsOneWidget);
      expect(find.text('Calculator'), findsOneWidget);
      expect(find.text('Wellness'), findsOneWidget);
      expect(find.text('Checklist'), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
      expect(find.text('Distraction'), findsOneWidget);
    });

    testWidgets('2. Displays secondary tools in categorized groups', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Student OS Assistant'), findsOneWidget);
      expect(find.text('Academic Analytics'), findsOneWidget);
      expect(find.text('Markdown Note Editor'), findsOneWidget);
      expect(find.text('Study Resources Library'), findsOneWidget);
    });

    testWidgets('3. Filters tools dynamically using search query', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      // Type 'calendar' in search
      await tester.enterText(find.byType(TextField), 'calendar');
      await tester.pumpAndSettle();

      expect(find.text('Academic Calendar'), findsOneWidget);
      expect(find.text('Study Resources Library'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Study Resources Library'), findsOneWidget);
    });

    testWidgets('4. Filters tools by category chip selection', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      // Tap 'Schedule & Tasks' category chip
      final chipFinder = find.text('Schedule & Tasks').first;
      await tester.ensureVisible(chipFinder);
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      expect(find.text('Academic Calendar'), findsOneWidget);
      expect(find.text('Academic Tasks & Deliverables'), findsOneWidget);
      expect(find.text('Activity & Notifications'), findsOneWidget);
      expect(find.text('Knowledge Base'), findsNothing);
    });

    testWidgets('5. Renders without overflow at 320dp width', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen(), width: 320));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Tools Hub'), findsOneWidget);
    });

    testWidgets('6. Shows interactive study time budgeter modal when tapped', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      // Filter to Academic Utilities chip
      final chipFinder = find.text('Academic Utilities').first;
      await tester.ensureVisible(chipFinder);
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      final budgeterFinder = find.text('Study Time Budgeter');
      expect(budgeterFinder, findsOneWidget);

      await tester.tap(budgeterFinder);
      await tester.pumpAndSettle();

      expect(find.text('Study Time Budgeter'), findsWidgets);
      expect(find.text('Available Time Today:'), findsOneWidget);
      expect(find.text('60m'), findsWidgets);

      // Close sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });
  });
}
