import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/design/tokens/student_os_tokens.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/student_os_action_cards.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  testWidgets('featured action shows value subtitle and handles tap',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(StudentOSFeaturedAction(
        icon: Icons.timer_rounded,
        title: 'Focus',
        subtitle: 'Start a focused session',
        color: StudentOSColors.forest,
        onTap: () => tapped = true,
      )),
    );
    await tester.pump();
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Start a focused session'), findsOneWidget);
    await tester.tap(find.text('Focus'));
    await tester.pump();
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('standard action renders compact label', (tester) async {
    await tester.pumpWidget(
      wrap(StudentOSStandardAction(
        icon: Icons.replay_rounded,
        label: 'Revise',
        color: StudentOSColors.softSage,
        onTap: () {},
      )),
    );
    await tester.pump();
    expect(find.text('Revise'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('insight card shows why text and CTA', (tester) async {
    var acted = false;
    await tester.pumpWidget(
      wrap(StudentOSInsightCard(
        icon: Icons.insights_rounded,
        title: 'Today is packed',
        body: '3h planned vs 2h available.',
        whyText: 'Why: two sessions overlap lunch.',
        color: StudentOSColors.forest,
        actionLabel: 'Rebalance',
        onAction: () => acted = true,
      )),
    );
    await tester.pump();
    expect(find.text('Why: two sessions overlap lunch.'), findsOneWidget);
    await tester.tap(find.text('Rebalance'));
    await tester.pump();
    expect(acted, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress card animates without overflow', (tester) async {
    await tester.pumpWidget(
      wrap(const StudentOSProgressCard(
        title: 'Today',
        subtitle: '2 of 5 done',
        progress: 0.4,
        progressLabel: '40%',
      )),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('list row navigates on tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(StudentOSListRow(
        icon: Icons.school_rounded,
        title: 'Physics',
        subtitle: 'In 3 days',
        color: StudentOSColors.forest,
        onTap: () => tapped = true,
      )),
    );
    await tester.pump();
    await tester.tap(find.text('Physics'));
    await tester.pump();
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });
}
