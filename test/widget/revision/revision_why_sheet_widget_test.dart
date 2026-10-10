import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/revision/widgets/revision_why_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_why_widget_test');
    PlanningBlockController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  final topic = Topic(
    id: 'top_why_test',
    chapterId: 'ch_1',
    subjectId: 'sub_acc',
    title: 'Bond Amortization',
  );

  Widget createWhyWidget({Size size = const Size(390, 844)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Scaffold(
          body: RevisionWhySheet(
            topic: topic,
            reasons: const [
              'Practice accuracy recently was 58%',
              'Last revised 6 days ago (interval: 3d)',
              'Upcoming exam in 4 days: Financial Accounting Final',
            ],
            suggestedDurationMinutes: 20,
            subjectName: 'Corporate Finance',
          ),
        ),
      ),
    );
  }

  group('RevisionWhySheet Widget Tests', () {
    testWidgets('1. Displays title, subject, key signals, and duration', (tester) async {
      await tester.pumpWidget(createWhyWidget());
      await tester.pumpAndSettle();

      expect(find.text('WHY REVISE THIS?'), findsOneWidget);
      expect(find.text('Bond Amortization'), findsOneWidget);
      expect(find.text('Corporate Finance'), findsOneWidget);
      expect(find.text('Practice accuracy recently was 58%'), findsOneWidget);
      expect(find.text('Last revised 6 days ago (interval: 3d)'), findsOneWidget);
      expect(find.text('Upcoming exam in 4 days: Financial Accounting Final'), findsOneWidget);
      expect(find.text('Suggested Duration: 20 minutes'), findsOneWidget);
      expect(find.text('Start Revision (20 min)'), findsOneWidget);
      expect(find.text('Schedule into Plan'), findsOneWidget);
    });

    testWidgets('2. Responsive rendering on 320dp, 360dp, 390dp, 412dp, 430dp without overflow', (tester) async {
      final widths = [320.0, 360.0, 390.0, 412.0, 430.0];
      for (final w in widths) {
        await tester.pumpWidget(createWhyWidget(size: Size(w, 800)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Bond Amortization'), findsOneWidget);
      }
    });
  });
}
