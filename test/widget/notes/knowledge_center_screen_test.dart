import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/knowledge/presentation/knowledge_center_screen.dart';
import 'package:student_os/features/notes/student_note_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child, {double width = 390, double height = 844}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: child,
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_kc_user');
    StudentNoteController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    StudentNoteController.instance.clearData();
  });

  group('KnowledgeCenterScreen Widget Tests', () {
    testWidgets('1. Empty state displays clean zero-content message without fake notes', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(const KnowledgeCenterScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Knowledge'), findsOneWidget);
      expect(find.text('Your knowledge base is empty.'), findsOneWidget);
      expect(find.text('Create First Note'), findsOneWidget);
    });

    testWidgets('2. Displays notes and knowledge coverage card when notes exist', (tester) async {
      final nc = StudentNoteController.instance;
      await nc.createNote(
        title: 'Trial Balance Rules',
        content: 'Debit and credit balance principles.',
        tags: const ['accounting'],
      );

      await tester.pumpWidget(
        wrapWithTheme(const KnowledgeCenterScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trial Balance Rules'), findsOneWidget);
      expect(find.text('Knowledge Coverage'), findsOneWidget);
      expect(find.text('#accounting'), findsOneWidget);
    });

    testWidgets('3. Real-time search filters displayed notes', (tester) async {
      final nc = StudentNoteController.instance;
      await nc.createNote(
        title: 'Depreciation Formulas',
        content: 'SLM and WDV methods.',
      );
      await nc.createNote(
        title: 'Partnership Fundamentals',
        content: 'Sharing ratio.',
      );

      await tester.pumpWidget(
        wrapWithTheme(const KnowledgeCenterScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Depreciation Formulas'), findsOneWidget);
      expect(find.text('Partnership Fundamentals'), findsOneWidget);

      // Search for "Partnership"
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Partnership');
      await tester.pumpAndSettle();

      expect(find.text('Partnership Fundamentals'), findsOneWidget);
      expect(find.text('Depreciation Formulas'), findsNothing);
    });

    testWidgets('4. Responsive widths with zero RenderFlex overflow (320dp, 360dp, 390dp, 412dp, 430dp)', (tester) async {
      final nc = StudentNoteController.instance;
      await nc.createNote(
        title: 'Very Long Subject and Topic Note Title For Testing Overflow Safety in Knowledge Center',
        content: 'Detailed note snippet for testing card rendering in small and large viewports.',
        tags: const ['accounting', 'business', 'law'],
      );

      const widths = [320.0, 360.0, 390.0, 412.0, 430.0];

      for (final width in widths) {
        await tester.pumpWidget(
          wrapWithTheme(const KnowledgeCenterScreen(), width: width),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Zero overflow on width $width');
      }
    });
  });
}
