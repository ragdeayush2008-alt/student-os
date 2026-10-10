import 'package:flutter/material.dart';

import '../design/tokens/student_os_tokens.dart';

/// Consistent Student OS solid-surface card system (no glass).
///
/// Variants: standard, elevated, interactive, hero, compact, section.
enum StudentOSCardVariant {
  standard,
  elevated,
  interactive,
  hero,
  compact,
  section,
}

class StudentOSCard extends StatelessWidget {
  const StudentOSCard({
    super.key,
    required this.child,
    this.variant = StudentOSCardVariant.standard,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  /// Standard: white surface, 16-20 radius, subtle border, soft shadow.
  const StudentOSCard.standard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  }) : variant = StudentOSCardVariant.standard;

  const StudentOSCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  }) : variant = StudentOSCardVariant.elevated;

  const StudentOSCard.interactive({
    super.key,
    required this.child,
    this.padding,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
  }) : variant = StudentOSCardVariant.interactive;

  const StudentOSCard.hero({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  }) : variant = StudentOSCardVariant.hero;

  const StudentOSCard.compact({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  }) : variant = StudentOSCardVariant.compact;

  const StudentOSCard.section({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  }) : variant = StudentOSCardVariant.section;

  final Widget child;
  final StudentOSCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  double get _radius {
    switch (variant) {
      case StudentOSCardVariant.hero:
        return StudentOSRadius.hero;
      case StudentOSCardVariant.compact:
        return StudentOSRadius.medium;
      case StudentOSCardVariant.section:
        return StudentOSRadius.large;
      case StudentOSCardVariant.standard:
      case StudentOSCardVariant.elevated:
      case StudentOSCardVariant.interactive:
        return StudentOSRadius.standard;
    }
  }

  EdgeInsetsGeometry get _padding {
    if (padding != null) return padding!;
    switch (variant) {
      case StudentOSCardVariant.compact:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case StudentOSCardVariant.hero:
        return const EdgeInsets.all(20);
      case StudentOSCardVariant.section:
        return const EdgeInsets.all(16);
      case StudentOSCardVariant.standard:
      case StudentOSCardVariant.elevated:
      case StudentOSCardVariant.interactive:
        return const EdgeInsets.all(16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final bg = backgroundColor ??
        (variant == StudentOSCardVariant.section
            ? scheme.surfaceContainerLow
            : scheme.surface);
    final border = borderColor ?? scheme.outline.withValues(alpha: 0.7);
    final radius = BorderRadius.circular(_radius);
    final shadows = variant == StudentOSCardVariant.elevated ||
            variant == StudentOSCardVariant.hero
        ? StudentOSElevation.elevated(isDark)
        : StudentOSElevation.card(isDark);

    final content = Padding(padding: _padding, child: child);

    if (variant == StudentOSCardVariant.hero) {
      return Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: StudentOSColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: radius,
              boxShadow: shadows,
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white),
                child: content,
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: variant == StudentOSCardVariant.interactive || onTap != null
            ? onTap
            : null,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: Border.all(color: border, width: 1),
            boxShadow: shadows,
          ),
          child: content,
        ),
      ),
    );
  }
}
