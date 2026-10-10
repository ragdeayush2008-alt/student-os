/// Pure, safe arithmetic expression evaluator for the Student OS calculator.
///
/// Implements standard arithmetic using Shunting-yard without unsafe `eval`.
class CalculatorEngine {
  const CalculatorEngine();

  /// Evaluates an arithmetic expression string and returns the formatted result.
  /// Returns 'Error' on invalid syntax or division by zero.
  static String evaluate(String expression) {
    if (expression.trim().isEmpty) return '0';

    try {
      final tokens = _tokenize(expression);
      if (tokens.isEmpty) return '0';
      final rpn = _toRpn(tokens);
      final result = _evaluateRpn(rpn);

      if (result.isNaN || result.isInfinite) return 'Error';

      // Format result: if whole number, display without decimal
      if (result == result.roundToDouble() && result.abs() < 1e12) {
        return result.toInt().toString();
      }

      // Limit to 8 decimal places and remove trailing zeros
      String str = result.toStringAsFixed(8);
      if (str.contains('.')) {
        str = str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      return str;
    } catch (_) {
      return 'Error';
    }
  }

  static List<String> _tokenize(String expr) {
    final sanitized = expr
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(' ', '');

    final List<String> tokens = [];
    final StringBuffer numBuf = StringBuffer();

    for (int i = 0; i < sanitized.length; i++) {
      final char = sanitized[i];

      if ((char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) || char == '.') {
        numBuf.write(char);
      } else if (char == '+' || char == '-' || char == '*' || char == '/' || char == '%' || char == '(' || char == ')') {
        if (numBuf.isNotEmpty) {
          tokens.add(numBuf.toString());
          numBuf.clear();
        }

        // Handle negative sign as unary minus
        if (char == '-' && (tokens.isEmpty || tokens.last == '(' || _isOperator(tokens.last))) {
          numBuf.write('-');
        } else {
          tokens.add(char);
        }
      }
    }

    if (numBuf.isNotEmpty) {
      tokens.add(numBuf.toString());
    }

    return tokens;
  }

  static bool _isOperator(String token) =>
      token == '+' || token == '-' || token == '*' || token == '/' || token == '%';

  static int _precedence(String op) {
    switch (op) {
      case '+':
      case '-':
        return 1;
      case '*':
      case '/':
      case '%':
        return 2;
      default:
        return 0;
    }
  }

  static List<String> _toRpn(List<String> tokens) {
    final List<String> output = [];
    final List<String> ops = [];

    for (final token in tokens) {
      final numVal = double.tryParse(token);
      if (numVal != null) {
        output.add(token);
      } else if (_isOperator(token)) {
        while (ops.isNotEmpty && _isOperator(ops.last) && _precedence(ops.last) >= _precedence(token)) {
          output.add(ops.removeLast());
        }
        ops.add(token);
      } else if (token == '(') {
        ops.add(token);
      } else if (token == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          output.add(ops.removeLast());
        }
        if (ops.isNotEmpty && ops.last == '(') {
          ops.removeLast();
        }
      }
    }

    while (ops.isNotEmpty) {
      output.add(ops.removeLast());
    }

    return output;
  }

  static double _evaluateRpn(List<String> rpn) {
    final List<double> stack = [];

    for (final token in rpn) {
      final numVal = double.tryParse(token);
      if (numVal != null) {
        stack.add(numVal);
      } else if (_isOperator(token)) {
        if (stack.isEmpty) return double.nan;
        final b = stack.removeLast();
        if (stack.isEmpty) {
          // Unary percentage handling if single operand
          if (token == '%') {
            stack.add(b / 100.0);
            continue;
          }
          return double.nan;
        }
        final a = stack.removeLast();

        switch (token) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '*':
            stack.add(a * b);
            break;
          case '/':
            if (b == 0) return double.infinity;
            stack.add(a / b);
            break;
          case '%':
            if (b == 0) return double.nan;
            stack.add(a * (b / 100.0));
            break;
        }
      }
    }

    return stack.isNotEmpty ? stack.last : 0.0;
  }
}
