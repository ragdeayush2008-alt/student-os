import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/assistant/presentation/assistant_orb.dart';
import 'package:student_os/core/theme/app_theme.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('orb renders luminous body without overflow', (tester) async {
    await tester.pumpWidget(wrap(const AssistantOrb(size: 104)));
    await tester.pump();
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('orb is static under reduced motion', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: wrap(const AssistantOrb(size: 104)),
      ),
    );
    await tester.pump();
    // No infinite animation may run: pumpAndSettle must complete.
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
  });

  testWidgets('orb breathing can be disabled', (tester) async {
    await tester.pumpWidget(
      wrap(const AssistantOrb(size: 80, breathing: false)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
