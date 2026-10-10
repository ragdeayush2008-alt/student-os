import 'package:flutter/material.dart';

import '../design/tokens/student_os_tokens.dart';

/// Section title + optional action + child, with breathable spacing.
class StudentOSSection extends StatelessWidget {
  const StudentOSSection({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionSemanticLabel,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? actionSemanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (actionLabel != null)
              Semantics(
                button: true,
                label: actionSemanticLabel ?? actionLabel,
                child: TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Reusable page header: bold menu icon left, title, single contextual action.
class StudentOSHeader extends StatelessWidget implements PreferredSizeWidget {
  const StudentOSHeader({
    super.key,
    this.title,
    this.menuProgress = 0,
    this.onMenuTap,
    this.menuSemanticLabel = 'Open navigation',
    this.action,
    this.subtitle,
  });

  final String? title;
  final double menuProgress;
  final VoidCallback? onMenuTap;
  final String menuSemanticLabel;
  final Widget? action;
  final String? subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.only(
        top: topInset + 4,
        left: 8,
        right: 12,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outline, width: 1),
        ),
      ),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            _MenuButton(
              progress: menuProgress,
              onTap: onMenuTap,
              semanticLabel: menuSemanticLabel,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 8),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.progress,
    required this.onTap,
    required this.semanticLabel,
  });

  final double progress;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    // Import cycle-safe local import of the menu icon painter via dynamic
    // path is avoided: reuse the canonical widget through a builder.
    return _MenuButtonInner(
      progress: progress,
      onTap: onTap,
      semanticLabel: semanticLabel,
    );
  }
}

class _MenuButtonInner extends StatelessWidget {
  const _MenuButtonInner({
    required this.progress,
    required this.onTap,
    required this.semanticLabel,
  });

  final double progress;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: CustomPaint(
                size: const Size(34, 34),
                painter: _HeaderMenuPainter(
                  progress: progress.clamp(0.0, 1.0),
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderMenuPainter extends CustomPainter {
  _HeaderMenuPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.5;
    const startX = 2.0;
    const totalH = 4.5 * 3 + 5.5 * 2;
    final startY = (size.height - totalH) / 2 + 4.5 / 2;
    final midY = startY + 4.5 + 5.5;

    if (progress <= 0.001) {
      canvas.drawLine(const Offset(startX, 0) + Offset(0, startY),
          Offset(startX + 30, startY), paint);
      canvas.drawLine(const Offset(startX, 0) + Offset(0, midY),
          Offset(startX + 21, midY), paint);
      canvas.drawLine(
          Offset(startX, midY + 4.5 + 5.5),
          Offset(startX + 13, midY + 4.5 + 5.5),
          paint);
      return;
    }
    final c = Offset(startX + 15, startY + (totalH - 4.5) / 2);
    final angle = progress * 0.785398;
    const len = 26.0;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawLine(const Offset(-len / 2, 0), const Offset(len / 2, 0), paint);
    canvas.restore();
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-angle);
    canvas.drawLine(const Offset(-len / 2, 0), const Offset(len / 2, 0), paint);
    canvas.restore();
    if (progress < 0.7) {
      final p = Paint()
        ..color = color.withValues(alpha: (1 - progress / 0.7))
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.5;
      canvas.drawLine(Offset(startX, midY),
          Offset(startX + 21 * (1 - progress * 0.6), midY), p);
    }
  }

  @override
  bool shouldRepaint(covariant _HeaderMenuPainter old) =>
      old.progress != progress || old.color != color;
}

/// Centered, max-width responsive wrapper (mobile-first, desktop capped).
class StudentOSResponsive extends StatelessWidget {
  const StudentOSResponsive({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cap = maxWidth ?? StudentOSSpacing.maxContentWidth;
    if (width <= cap + 32) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cap),
        child: child,
      ),
    );
  }
}
