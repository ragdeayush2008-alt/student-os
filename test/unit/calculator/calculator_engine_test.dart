import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/calculator/services/calculator_engine.dart';

void main() {
  group('CalculatorEngine — Unit Tests', () {
    test('1. Basic addition, subtraction, multiplication, division', () {
      expect(CalculatorEngine.evaluate('2 + 3'), '5');
      expect(CalculatorEngine.evaluate('10 - 4'), '6');
      expect(CalculatorEngine.evaluate('6 * 7'), '42');
      expect(CalculatorEngine.evaluate('6 × 7'), '42');
      expect(CalculatorEngine.evaluate('20 / 4'), '5');
      expect(CalculatorEngine.evaluate('20 ÷ 4'), '5');
    });

    test('2. Decimals and floating point operations', () {
      expect(CalculatorEngine.evaluate('2.5 + 3.5'), '6');
      expect(CalculatorEngine.evaluate('10.5 * 2'), '21');
      expect(CalculatorEngine.evaluate('7.5 / 2.5'), '3');
      expect(CalculatorEngine.evaluate('1 / 8'), '0.125');
    });

    test('3. Operator precedence and parentheses', () {
      expect(CalculatorEngine.evaluate('2 + 3 * 4'), '14');
      expect(CalculatorEngine.evaluate('(2 + 3) * 4'), '20');
      expect(CalculatorEngine.evaluate('10 - (2 + 3) * 2'), '0');
      expect(CalculatorEngine.evaluate('((2 + 3) * (4 + 1))'), '25');
    });

    test('4. Percentage operations', () {
      expect(CalculatorEngine.evaluate('200 * 15%'), '30');
      expect(CalculatorEngine.evaluate('50%'), '0.5');
    });

    test('5. Negative numbers and unary minus', () {
      expect(CalculatorEngine.evaluate('-5 + 10'), '5');
      expect(CalculatorEngine.evaluate('10 + -3'), '7');
      expect(CalculatorEngine.evaluate('-4 * -5'), '20');
    });

    test('6. Division by zero and error handling', () {
      expect(CalculatorEngine.evaluate('10 / 0'), 'Error');
      expect(CalculatorEngine.evaluate('10 ÷ 0'), 'Error');
      expect(CalculatorEngine.evaluate('++--'), 'Error');
      expect(CalculatorEngine.evaluate(''), '0');
    });
  });
}
