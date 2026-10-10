import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/knowledge/practice_question_controller.dart';
import 'package:student_os/features/revision/presentation/revision_session_screen.dart';
import 'package:student_os/features/revision/revision_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_rev_session_test');
    RevisionController.instance.clearData();
    PracticeQuestionController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  final topic = Topic(
    id: 'top_deprec_sess',
    chapterId: 'ch_1',
    subjectId: 'sub_acc',
    title: 'Depreciation Session Test',
    description: 'Straight-line and reducing balance methods.',
  );

  Widget createSessionWidget({Size size = const Size(390, 844)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: RevisionSessionScreen(
          topic: topic,
          suggestedDurationMinutes: 20,
        ),
      ),
    );
  }

  group('RevisionSessionScreen Widget Tests', () {
    testWidgets('1. Displays active recall prompt, reveal notes, recall buttons, and notes input', (tester) async {
      await tester.pumpWidget(createSessionWidget());
      await tester.pumpAndSettle();

      expect(find.text('Depreciation Session Test'), findsWidgets);
      expect(find.text('ACTIVE RECALL REVISION'), findsOneWidget);
      expect(find.text('Step 1: Active Retrieval'), findsOneWidget);
      expect(find.text('Reveal Notes & Resources'), findsOneWidget);
      expect(find.text('HOW WAS YOUR RECALL?'), findsOneWidget);
      expect(find.text('I Knew It'), findsOneWidget);
      expect(find.text('Partly'), findsOneWidget);
      expect(find.text('Forgot'), findsOneWidget);

      // Tap Reveal Notes
      await tester.tap(find.text('Reveal Notes & Resources'));
      await tester.pumpAndSettle();

      expect(find.text('REFERENCE CONTENT'), findsOneWidget);
      expect(find.text('Straight-line and reducing balance methods.'), findsOneWidget);
    });

    testWidgets('2. Exit confirmation dialog prevents accidental abandonment', (tester) async {
      await tester.pumpWidget(createSessionWidget());
      await tester.pumpAndSettle();

      // Tap Close (X) icon in AppBar
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Exit revision?'), findsOneWidget);
      expect(find.text('Keep Revising'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);

      await tester.tap(find.text('Keep Revising'));
      await tester.pumpAndSettle();

      expect(find.text('Exit revision?'), findsNothing);
      expect(RevisionController.instance.records, isEmpty);
    });

    testWidgets('3. Responsive rendering on 320dp, 360dp, 390dp, 412dp, 430dp without overflow', (tester) async {
      final widths = [320.0, 360.0, 390.0, 412.0, 430.0];
      for (final w in widths) {
        await tester.pumpWidget(createSessionWidget(size: Size(w, 800)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('ACTIVE RECALL REVISION'), findsOneWidget);
      }
    });
  });
}
