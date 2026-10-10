import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/app_card.dart';
import 'package:student_os/features/calculator/presentation/calculator_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: child,
    );
  }

  group('CalculatorScreen — Widget Tests', () {
    testWidgets('1. Performs simple addition on screen', (tester) async {
      await tester.pumpWidget(wrapWithApp(const CalculatorScreen()));
      await tester.pumpAndSettle();

      // Tap 5 + 3 =
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(AppCard), matching: find.text('5+3')), findsOneWidget);
      expect(find.descendant(of: find.byType(AppCard), matching: find.text('= 8')), findsOneWidget);

      await tester.tap(find.text('='));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AppCard), matching: find.text('8')), findsOneWidget);
    });

    testWidgets('2. Clear resets input display', (tester) async {
      await tester.pumpWidget(wrapWithApp(const CalculatorScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AppCard), matching: find.text('9')), findsOneWidget);

      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AppCard), matching: find.text('0')), findsOneWidget);
    });
  });
}
