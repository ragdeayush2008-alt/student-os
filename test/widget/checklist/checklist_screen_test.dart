import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/checklist/presentation/checklist_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('chk_widget_user');
    ControllerIsolation.instance.clearAllControllers();
  });

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: child,
    );
  }

  group('ChecklistScreen — Widget Tests', () {
    testWidgets('1. Adds a checklist item and toggles completion', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ChecklistScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Quick Checklist'), findsOneWidget);
      expect(find.text('No checklist items'), findsOneWidget);

      // Add item
      await tester.enterText(find.byType(TextField), 'Print syllabus');
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Print syllabus'), findsOneWidget);
      expect(find.text('1 pending · 0 done'), findsOneWidget);

      // Toggle check
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(find.text('0 pending · 1 done'), findsOneWidget);
    });
  });
}
