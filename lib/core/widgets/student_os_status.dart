import 'package:flutter/material.dart';

import '../design/tokens/student_os_tokens.dart';
import 'shimmer_scope.dart';
import 'student_os_icon_glow.dart';

/// Compact status pill for statuses, filters, chips (not primary buttons).
enum StudentOSChipTone { neutral, primary, success, warning, danger, info }

class StudentOSStatusChip extends StatelessWidget {
  const StudentOSStatusChip({
    super.key,
    required this.label,
    this.tone = StudentOSChipTone.neutral,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final StudentOSChipTone tone;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final Color bg;
    late final Color fg;
    switch (tone) {
      case StudentOSChipTone.neutral:
        bg = scheme.surfaceContainer;
        fg = scheme.onSurfaceVariant;
        break;
      case StudentOSChipTone.primary:
        bg = scheme.primaryContainer;
        fg = scheme.primary;
        break;
      case StudentOSChipTone.success:
        bg = StudentOSColors.success.withValues(alpha: 0.12);
        fg = StudentOSColors.success;
        break;
      case StudentOSChipTone.warning:
        bg = StudentOSColors.warning.withValues(alpha: 0.14);
        fg = const Color(0xFFB54708);
        break;
      case StudentOSChipTone.danger:
        bg = StudentOSColors.danger.withValues(alpha: 0.12);
        fg = StudentOSColors.danger;
        break;
      case StudentOSChipTone.info:
        bg = StudentOSColors.info.withValues(alpha: 0.12);
        fg = StudentOSColors.info;
        break;
    }
    return Semantics(
      label: semanticLabel ?? label,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              BorderRadius.circular(StudentOSRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: fg, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Useful empty state: explanation + ONE primary action. No fake content.
class StudentOSEmptyState extends StatelessWidget {
  const StudentOSEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
    this.actionSemanticLabel,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  final String? actionSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius:
                  BorderRadius.circular(StudentOSRadius.large),
              // Soft ambient glow behind the illustration icon only.
              boxShadow: StudentOSGlow.tone(
                tone: StudentOSGlowTone.primary,
                intensity: StudentOSGlowIntensity.subtle,
                radius: StudentOSGlowRadius.medium,
                isDark: theme.brightness == Brightness.dark,
              ),
            ),
            child: Icon(icon, color: scheme.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: actionSemanticLabel ?? actionLabel,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        StudentOSRadius.medium),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Subtle loading skeleton — TCC shared ticker.
class StudentOSSkeleton extends StatelessWidget {
  const StudentOSSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = StudentOSRadius.small,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final animation = ShimmerScope.of(context);
    final staticBox = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (animation == null) return staticBox;
    return AnimatedBuilder(
      animation: animation,
      child: staticBox,
      builder: (context, child) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Color.lerp(
            scheme.surfaceContainer,
            scheme.surfaceContainerHighest,
            animation.value,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Concise, human-readable error with one retry action.
class StudentOSErrorState extends StatelessWidget {
  const StudentOSErrorState({
    super.key,
    this.title = "Couldn't load your content.",
    this.message = 'Please check your connection and try again.',
    this.actionLabel = 'Try again',
    this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 32),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
