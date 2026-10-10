import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/student_os_assistant_visual.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  testWidgets('assistant visual renders spark without overflow', (tester) async {
    await tester.pumpWidget(
      wrap(const StudentOSAssistantVisual(
        breathing: false,
        semanticLabel: null,
      )),
    );
    await tester.pump();
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assistant entry card shows title and handles tap',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(StudentOSAssistantEntryCard(
        onTap: () => tapped = true,
        title: 'Ask Student OS',
        subtitle: 'What should I do next?',
      )),
    );
    await tester.pump();
    expect(find.text('Ask Student OS'), findsOneWidget);
    expect(find.text('What should I do next?'), findsOneWidget);
    await tester.tap(find.text('Ask Student OS'));
    await tester.pump();
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assistant hero entry renders on dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: StudentOSAssistantEntryCard(
            hero: true,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Ask Student OS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assistant visual is static under reduced motion',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: wrap(StudentOSAssistantEntryCard(onTap: () {})),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
  });
}
