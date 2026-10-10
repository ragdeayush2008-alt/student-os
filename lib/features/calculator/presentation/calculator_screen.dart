import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../services/calculator_engine.dart';

/// Lightweight, offline-first student calculator workspace.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = '';
  String _previewResult = '';

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'C') {
        _input = '';
        _previewResult = '';
      } else if (key == '⌫') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
          _updatePreview();
        }
      } else if (key == '=') {
        if (_input.isNotEmpty) {
          final res = CalculatorEngine.evaluate(_input);
          _input = res == 'Error' ? '' : res;
          _previewResult = res == 'Error' ? 'Error' : '';
        }
      } else {
        _input += key;
        _updatePreview();
      }
    });
  }

  void _updatePreview() {
    if (_input.isEmpty) {
      _previewResult = '';
      return;
    }
    final res = CalculatorEngine.evaluate(_input);
    _previewResult = res == 'Error' ? '' : res;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppScaffold(
      title: 'Calculator',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Display Screen ──
              Expanded(
                flex: 3,
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _input.isEmpty ? '0' : _input,
                          style: context.text.headlineMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _previewResult.isNotEmpty && _previewResult != _input
                            ? '= $_previewResult'
                            : '',
                        style: context.text.titleLarge!.copyWith(
                          color: palette.onSurfaceMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Keypad Grid ──
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _buildRow(['C', '(', ')', '÷'], palette),
                    const SizedBox(height: AppSpacing.xs),
                    _buildRow(['7', '8', '9', '×'], palette),
                    const SizedBox(height: AppSpacing.xs),
                    _buildRow(['4', '5', '6', '-'], palette),
                    const SizedBox(height: AppSpacing.xs),
                    _buildRow(['1', '2', '3', '+'], palette),
                    const SizedBox(height: AppSpacing.xs),
                    _buildRow(['%', '0', '.', '='], palette),
                    const SizedBox(height: AppSpacing.xs),
                    _buildBottomRow(palette),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys, AppPalette palette) {
    return Expanded(
      child: Row(
        children: [
          for (int i = 0; i < keys.length; i++) ...[
            Expanded(
              child: _CalcButton(
                label: keys[i],
                onTap: () => _onKeyPress(keys[i]),
                isOperator: _isOp(keys[i]),
                isAction: keys[i] == 'C' || keys[i] == '=',
              ),
            ),
            if (i < keys.length - 1) const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomRow(AppPalette palette) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () => _onKeyPress('⌫'),
            icon: const Icon(Icons.backspace_outlined, size: 18),
            label: const Text('Backspace'),
            style: TextButton.styleFrom(
              foregroundColor: palette.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }

  bool _isOp(String key) =>
      key == '÷' || key == '×' || key == '-' || key == '+' || key == '%' || key == '(' || key == ')';
}

class _CalcButton extends StatelessWidget {
  const _CalcButton({
    required this.label,
    required this.onTap,
    this.isOperator = false,
    this.isAction = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isOperator;
  final bool isAction;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    final Color bgColor = isAction
        ? (label == '=' ? palette.primary : palette.surfaceVariant)
        : (isOperator
            ? palette.surfaceVariant.withValues(alpha: 0.6)
            : palette.surface);

    final Color textColor = isAction && label == '='
        ? Colors.white
        : (isOperator ? palette.primary : palette.onSurface);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: palette.outline.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: isOperator || isAction ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
