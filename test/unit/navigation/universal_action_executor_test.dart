import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/core/navigation/universal_action_executor.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/preferences/user_preferences_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Universal Action Executor & Action Launcher (I, H, W, X)', () {
    test('UniversalActionExecutor handles focusActive safely when active session exists (F, G)', () {
      FocusController.instance.clearData();
      expect(FocusController.instance.hasActiveSession, isFalse);

      FocusController.instance.startQuickFocus(subjectName: 'Taxation');
      expect(FocusController.instance.hasActiveSession, isTrue);

      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: const [],
        hasActiveFocus: true,
        activeFocusObjective: 'Study Taxation',
      );

      expect(action.type, equals(StudentOSActionType.focusActive));
      expect(action.title, equals('Study Taxation'));
      expect(action.isFocusActive, isTrue);

      FocusController.instance.cancelSession();
    });

    test('Autopilot mode indicator formats correctly (W)', () {
      expect(AutopilotMode.off.label, equals('Off'));
      expect(AutopilotMode.suggest.label, equals('Suggest'));
      expect(AutopilotMode.autopilot.label, equals('Autopilot'));
    });

    testWidgets('GlobalAddSheet renders options without crashing (H)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlobalAddSheet(),
          ),
        ),
      );

      expect(find.text('Add to Student OS'), findsOneWidget);
      expect(find.text('New Task'), findsOneWidget);
      expect(find.text('New Exam'), findsOneWidget);
      expect(find.text('New Subject'), findsOneWidget);
      expect(find.text('Plan My Day'), findsOneWidget);
    });

    testWidgets('UniversalActionLauncherSheet renders action options without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UniversalActionLauncherSheet(),
          ),
        ),
      );

      expect(find.text('What do you want to do?'), findsOneWidget);
      expect(find.text('Start Focus Session'), findsOneWidget);
      expect(find.text('Plan My Day'), findsOneWidget);
      expect(find.text('Manage Tasks'), findsOneWidget);
      expect(find.text('Review Upcoming Exams'), findsOneWidget);
      expect(find.text('Revise Materials'), findsOneWidget);
    });
  });
}
