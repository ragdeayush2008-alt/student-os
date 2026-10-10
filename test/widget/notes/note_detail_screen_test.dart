import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/notes/presentation/note_detail_screen.dart';
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
    AuthIsolation.instance.setAuthenticatedUser('test_detail_user');
    StudentNoteController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    StudentNoteController.instance.clearData();
  });

  group('NoteDetailScreen Widget Tests', () {
    testWidgets('1. Renders Note Detail with formatted blocks and action bar', (tester) async {
      final note = await StudentNoteController.instance.createNote(
        title: 'Accounting Standards 10',
        content: '# Unit Overview\n- [ ] Review historical cost\n- [x] Review salvage value\n- Depreciation definition\n1. Straight line\n> Note this carefully\n\$\$(Cost - Salvage) / Life\$\$',
        tags: const ['accounting', 'standards'],
      );

      await tester.pumpWidget(
        wrapWithTheme(NoteDetailScreen(noteId: note.id)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accounting Standards 10'), findsOneWidget);
      expect(find.text('Unit Overview'), findsOneWidget);
      expect(find.text('Review historical cost'), findsOneWidget);
      expect(find.text('Review salvage value'), findsOneWidget);
      expect(find.text('Depreciation definition'), findsOneWidget);
      expect(find.text('Note this carefully'), findsOneWidget);
      expect(find.text('#accounting'), findsOneWidget);

      // Action bar
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Revise'), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);
    });

    testWidgets('2. Toggling checklist item updates note content in controller', (tester) async {
      final note = await StudentNoteController.instance.createNote(
        title: 'Checklist Note',
        content: '- [ ] Step 1: Read chapter\n- [ ] Step 2: Solve exercises',
      );

      await tester.pumpWidget(
        wrapWithTheme(NoteDetailScreen(noteId: note.id)),
      );
      await tester.pumpAndSettle();

      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(2));

      // Tap first checkbox
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      final updated = StudentNoteController.instance.noteById(note.id);
      expect(updated?.content.contains('- [x] Step 1: Read chapter'), isTrue);
    });

    testWidgets('3. Responsive screen widths and zero overflow (320dp, 360dp, 390dp, 412dp, 430dp)', (tester) async {
      final note = await StudentNoteController.instance.createNote(
        title: 'Very Long Comprehensive Advanced Accounting Note Title For Extreme Layout Testing',
        content: '# Comprehensive Overview of Depreciation\n'
            'Here is a long detailed paragraph analyzing various methods of asset valuation and historical amortisation rules over long time horizons.\n'
            '- [ ] First checklist item with descriptive detailed text\n'
            '- Second regular bullet item\n'
            '\$\$(Cost - Scrap) / UsefulLifeInYears\$\$',
        tags: const ['accounting', 'depreciation', 'finance', 'standards', 'calculations'],
      );

      const widths = [320.0, 360.0, 390.0, 412.0, 430.0];

      for (final width in widths) {
        await tester.pumpWidget(
          wrapWithTheme(NoteDetailScreen(noteId: note.id), width: width),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Zero overflow on width $width');
      }
    });
  });
}
