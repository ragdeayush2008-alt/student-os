import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/presentation/assistant_result_card.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_result.dart';
import 'package:student_os/core/theme/app_theme.dart';

/// P2 — proposal cards render Apply/Edit/Cancel and stay responsive.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  StudentAssistantResult proposalResult() {
    return const StudentAssistantResult(
      success: true,
      intent: StudentAssistantIntent(
        rawText: 'I have 2 hours',
        intentType: AssistantIntentType.planTime,
      ),
      title: 'Plan for 120 Minutes',
      message: '2 sessions planned.',
      cardKind: AssistantCardKind.schedulePreview,
      requiresConfirmation: true,
      primaryAction: StudentAssistantAction(
        id: 'act_apply_proposal',
        type: AssistantActionType.applyPlan,
        label: 'Apply Plan',
        requiresConfirmation: true,
      ),
    );
  }

  Widget wrap(Widget child, {double width = 390}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  testWidgets('confirmation card shows Cancel, Apply, Edit', (tester) async {
    var confirmed = false;
    var cancelled = false;
    var edited = false;
    await tester.pumpWidget(
      wrap(
        AssistantResultCard(
          result: proposalResult(),
          onExecuteAction: (_) async {},
          onConfirmAction: () async {
            confirmed = true;
          },
          onCancelConfirmation: () {
            cancelled = true;
          },
          onSelectChoice: (_) {},
          onEdit: () {
            edited = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Apply Plan'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);

    await tester.tap(find.text('Apply Plan'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);

    await tester.tap(find.text('Edit'));
    expect(edited, isTrue);

    await tester.tap(find.text('Cancel'));
    expect(cancelled, isTrue);
  });

  testWidgets('no Edit button when onEdit is null', (tester) async {
    await tester.pumpWidget(
      wrap(
        AssistantResultCard(
          result: proposalResult(),
          onExecuteAction: (_) async {},
          onConfirmAction: () async {},
          onCancelConfirmation: () {},
          onSelectChoice: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Apply Plan'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('no overflow at 360dp and 390dp', (tester) async {
    for (final width in [360.0, 390.0]) {
      await tester.pumpWidget(wrap(AssistantResultCard(
        result: proposalResult(),
        onExecuteAction: (_) async {},
        onConfirmAction: () async {},
        onCancelConfirmation: () {},
        onSelectChoice: (_) {},
        onEdit: () {},
      ), width: width));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
