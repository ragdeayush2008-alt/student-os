import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/presentation/assistant_command_center_screen.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

Widget _buildTestableWidget(Widget child, {Size size = const Size(390, 844)}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ControllerIsolation.instance.clearAllControllers();
  });

  tearDown(() async {
    ControllerIsolation.instance.clearAllControllers();
  });

  group('Canonical Assistant surface Widget Tests', () {
    testWidgets('renders canonical surface with hero, input and question catalog', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(
        const AssistantCommandCenterScreen(),
      ));
      await tester.pumpAndSettle();

      expect(
          find.text('How can Student OS\nhelp you today?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Explore questions'), findsOneWidget);
      expect(find.text('Hey! What are we working on?'), findsOneWidget);
    });

    testWidgets('typing query and submitting updates result', (tester) async {
      await SubjectController.instance.createSubject(name: 'Accountancy');

      await tester.pumpWidget(_buildTestableWidget(
        const AssistantCommandCenterScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'I have 2 hours');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(find.textContaining('Plan for 120 Minutes'), findsOneWidget);
      expect(find.textContaining('Apply Plan'), findsOneWidget);
    });

    testWidgets('renders clarification choices on ambiguous input', (tester) async {
      final sc = SubjectController.instance;
      await sc.createSubject(name: 'Business Law');
      await sc.createSubject(name: 'Corporate Laws');

      await tester.pumpWidget(_buildTestableWidget(
        const AssistantCommandCenterScreen(initialQuery: 'Study Law'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Clarification Needed'), findsOneWidget);
      expect(find.text('Business Law'), findsOneWidget);
      expect(find.text('Corporate Laws'), findsOneWidget);
    });

    testWidgets('renders cleanly on narrow 320dp screen without overflow', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(
        const AssistantCommandCenterScreen(initialQuery: 'help'),
        size: const Size(320, 640),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
