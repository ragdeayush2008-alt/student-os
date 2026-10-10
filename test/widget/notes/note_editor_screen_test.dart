import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/notes/presentation/note_editor_screen.dart';
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
    AuthIsolation.instance.setAuthenticatedUser('test_widget_user');
    StudentNoteController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    StudentNoteController.instance.clearData();
  });

  group('NoteEditorScreen Widget Tests', () {
    testWidgets('1. Renders Note Editor with title, content, toolbar, and tags', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const NoteEditorScreen(
            initialTitle: 'Test Note Title',
            initialContent: 'Initial paragraph text',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Note Title'), findsOneWidget);
      expect(find.text('Initial paragraph text'), findsOneWidget);
      expect(find.text('TAGS'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byIcon(Icons.title_rounded), findsOneWidget); // Heading button
      expect(find.byIcon(Icons.format_bold_rounded), findsOneWidget); // Bold button
      expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget); // Bullet button
    });

    testWidgets('2. Formatting toolbar inserts markdown prefix correctly', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const NoteEditorScreen(
            initialTitle: 'Formatting Test',
            initialContent: 'My heading',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap heading button
      await tester.tap(find.byIcon(Icons.title_rounded));
      await tester.pumpAndSettle();

      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      final contentField = textFields[1];
      expect(contentField.controller?.text.contains('# '), isTrue);
    });

    testWidgets('3. Saves note to controller on save button press', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const NoteEditorScreen(
            initialTitle: 'Saved Note',
            initialContent: 'Important study points.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      final notes = StudentNoteController.instance.allActiveNotes;
      expect(notes.length, 1);
      expect(notes.first.title, 'Saved Note');
      expect(notes.first.content, 'Important study points.');
    });

    testWidgets('4. Responsive widths with zero RenderFlex overflow (320dp, 360dp, 390dp, 412dp, 430dp)', (tester) async {
      const widths = [320.0, 360.0, 390.0, 412.0, 430.0];

      for (final width in widths) {
        await tester.pumpWidget(
          wrapWithTheme(
            const NoteEditorScreen(
              initialTitle: 'Very Long Subject and Topic Note Title For Testing Overflow Safety in Extreme Screens',
              initialContent: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
            ),
            width: width,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Zero overflow on width $width');
      }
    });
  });
}
