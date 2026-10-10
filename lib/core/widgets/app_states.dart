import 'package:flutter/material.dart';

import '../animations/animated_entrance.dart';
import '../constants/app_icon_size.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_buttons.dart';
import 'app_card.dart';
import 'shimmer_scope.dart';

/// A premium, reusable empty-state component. Used when a screen has no data
/// to show. Includes an icon, title, optional description and optional action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.icon = Icons.inbox_outlined,
    this.description,
    this.action,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final String? description;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AnimatedEntrance(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: palette.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: AppIconSize.xl, color: palette.primary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: context.text.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (description != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description!,
                  style: context.text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A premium, reusable error-state component.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Something went wrong',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline_rounded,
      title: title,
      description: message,
      action: onRetry != null
          ? AppOutlineButton(label: 'Try again', onPressed: onRetry)
          : null,
    );
  }
}

/// A shimmer-style skeleton placeholder for loading states.
///
/// TCC-optimized: shared [ShimmerScope] ticker — no per-box controller.
/// Falls back to static color when outside a scope or in reduced-motion.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = AppRadius.sm,
    this.circle = false,
  });

  final double width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    // Use shared shimmer when available, otherwise static.
    // Import shimmer_scope for animation; fallback is static box.
    final animation = ShimmerScope.of(context);
    final staticBox = Container(
      width: circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius:
            circle ? null : BorderRadius.circular(radius),
      ),
    );
    if (animation == null) return staticBox;
    return AnimatedBuilder(
      animation: animation,
      child: staticBox,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              palette.surfaceVariant,
              palette.surface,
              palette.surfaceVariant,
            ],
            stops: const [0.3, 0.5, 0.7],
            begin: Alignment(-1 + animation.value * 2, -1),
            end: Alignment(1 - (1 - animation.value) * 2, 1),
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// Convenience: a skeleton card placeholder for lists — wraps [ShimmerScope]
/// so all boxes in the card share one ticker.
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({super.key, this.lines = 2});

  final int lines;

  @override
  Widget build(BuildContext context) {
    // One shared ticker per card — not per-box.
    return ShimmerScope(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSkeleton(width: 40, height: 40, circle: true),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < lines; i++) ...[
              AppSkeleton(
                height: 14,
                width: i == lines - 1 ? 0.6 : double.infinity,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}
