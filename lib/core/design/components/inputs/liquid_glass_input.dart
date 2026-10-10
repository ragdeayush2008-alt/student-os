import 'package:flutter/material.dart';

import '../../tokens/app_borders.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../glass/glass_surface.dart';

/// Translucent Liquid Glass Text Field for forms, authentication, and search.
class LiquidGlassInput extends StatefulWidget {
  const LiquidGlassInput({
    super.key,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.errorText,
    this.enabled = true,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.radius = LiquidRadius.md,
  });

  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;
  final bool enabled;
  final List<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final double radius;

  @override
  State<LiquidGlassInput> createState() => _LiquidGlassInputState();
}

class _LiquidGlassInputState extends State<LiquidGlassInput> {
  late bool _obscure;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChanged);
    }
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color textPrimary =
        isDark ? LiquidColors.textPrimaryDark : LiquidColors.textPrimaryLight;
    final Color textMuted =
        isDark ? LiquidColors.textTertiaryDark : LiquidColors.textTertiaryLight;

    final Color borderColor = widget.errorText != null
        ? LiquidColors.error
        : _isFocused
        ? LiquidColors.primary
        : (isDark ? const Color(0x33FFFFFF) : const Color(0x2E000000));

    final Color bg = isDark
        ? const Color(0x66131D33)
        : const Color(0x99FFFFFF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark
                  ? LiquidColors.textSecondaryDark
                  : LiquidColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: LiquidSpacing.xs),
        ],
        GlassSurface(
          level: _isFocused ? GlassLevel.elevated : GlassLevel.standard,
          radius: widget.radius,
          backgroundColor: bg,
          borderColor: borderColor,
          borderWidth: _isFocused ? LiquidBorders.medium : LiquidBorders.thin,
          shadows: _isFocused
              ? [
                  BoxShadow(
                    color: LiquidColors.primary.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          padding: EdgeInsets.zero,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscure,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            enabled: widget.enabled,
            autofillHints: widget.autofillHints,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            cursorColor: LiquidColors.primary,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textMuted,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? LiquidColors.primary
                          : textMuted,
                      size: 20,
                    )
                  : null,
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: textMuted,
                        size: 20,
                      ),
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : widget.suffixIcon,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: LiquidColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
