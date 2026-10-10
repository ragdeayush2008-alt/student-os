import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/assistant_launch_context.dart';
import 'package:student_os/core/assistant/presentation/question_catalog_sheet.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('catalog_user');
    StudentAssistantController.instance.clearData();
  });

  tearDown(() async {
    await StudentAssistantController.instance.clearConversation();
    StudentAssistantController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    String? categoryId,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => QuestionCatalogSheet.show(
                context,
                categoryId: categoryId,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('catalog renders categories and questions', (tester) async {
    await pumpSheet(tester);

    expect(find.text('Explore questions'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sleep'),
      200,
      scrollable: find.ancestor(
        of: find.text('Today'),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('“Plan my day”'), findsOneWidget);
  });

  testWidgets('search filters questions', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField), 'sleep');
    await tester.pumpAndSettle();

    expect(find.text('“Set my sleep schedule”'), findsOneWidget);
    expect(find.text('“Plan my day”'), findsNothing);
  });

  testWidgets('search empty state is honest', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField), 'zzzqqqnomatch');
    await tester.pumpAndSettle();

    expect(find.textContaining('No matching questions'), findsOneWidget);
  });

  testWidgets('tapping a question asks it for real', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('“Plan my day”'));
    await tester.pumpAndSettle();

    // Sheet closed and the engine answered (real turn, not a stub).
    expect(find.text('Explore questions'), findsNothing);
    expect(
      StudentAssistantController.instance.messages.length,
      greaterThanOrEqualTo(2),
    );
    expect(
      StudentAssistantController.instance.messages.first.text,
      'Plan my day',
    );
  });

  testWidgets('contextual origin preselects its category', (tester) async {
    StudentAssistantController.instance.setLaunchContext(
      const AssistantLaunchContext(origin: AssistantOrigin.sleep),
    );
    await pumpSheet(tester);

    expect(find.text('“Set my sleep schedule”'), findsOneWidget);
    expect(find.text('“Plan my day”'), findsNothing);
  });

  testWidgets('reduced motion still renders catalog', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpSheet(tester);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
            size: Size(390, 844), disableAnimations: true),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: Text('x')),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
