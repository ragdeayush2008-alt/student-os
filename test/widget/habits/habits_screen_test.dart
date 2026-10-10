import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/habits/habit_controller.dart';
import 'package:student_os/features/habits/presentation/habits_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('hbt_widget_user');
    ControllerIsolation.instance.clearAllControllers();
  });

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: child,
    );
  }

  group('HabitsScreen — Widget Tests', () {
    testWidgets('1. Renders habits list and toggles today completion', (tester) async {
      await HabitController.instance.createHabit(title: 'Hydrate 2L');

      await tester.pumpWidget(wrapWithApp(const HabitsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Habits Tracker'), findsOneWidget);
      expect(find.text('Hydrate 2L'), findsOneWidget);

      // Toggle today check box
      await tester.tap(find.byIcon(Icons.check_box_outline_blank_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box_rounded), findsOneWidget);
    });
  });
}
