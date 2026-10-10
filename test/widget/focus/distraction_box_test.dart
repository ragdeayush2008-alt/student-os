import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/presentation/screens/focus_distraction_inbox_screen.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('distract_user');
    ControllerIsolation.instance.clearAllControllers();
  });

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: child,
    );
  }

  group('Distraction Box — Widget Tests', () {
    testWidgets('1. Captures a distraction, resolves it, and converts to task', (tester) async {
      await TaskController.instance.load();
      await FocusController.instance.load();

      await tester.pumpWidget(wrapWithApp(const FocusDistractionInboxScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Distraction Box'), findsOneWidget);
      expect(find.text('Distraction Box is clear'), findsOneWidget);

      // Capture distraction
      await tester.enterText(find.byType(TextField), 'Check math formula');
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Check math formula'), findsOneWidget);
      expect(find.text('Pending (1)'), findsOneWidget);

      // Convert to task
      await tester.tap(find.byIcon(Icons.add_task_rounded));
      await tester.pumpAndSettle();

      // Distraction should now be resolved and task created
      expect(TaskController.instance.tasks.any((t) => t.title == 'Check math formula'), isTrue);
      expect(find.text('Pending (0)'), findsOneWidget);
    });
  });
}
