import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'glass_surface.dart';

/// Modal dialog styled with Liquid Glass.
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.content,
    this.actions,
    this.contentPadding = LiquidSpacing.allScreen,
  });

  final IconData? icon;
  final Color? iconColor;
  final String title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = iconColor ?? theme.colorScheme.primary;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.symmetric(horizontal: LiquidSpacing.xxl),
        child: GlassSurface(
          level: GlassLevel.modal,
          borderRadius: LiquidRadius.dialog,
          padding: contentPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(LiquidSpacing.md),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 28, color: primary),
                  ),
                ),
                const SizedBox(height: LiquidSpacing.md),
              ],
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              if (content != null) ...[
                const SizedBox(height: LiquidSpacing.sm),
                DefaultTextStyle(
                  style: theme.textTheme.bodyMedium ?? const TextStyle(),
                  textAlign: TextAlign.center,
                  child: content!,
                ),
              ],
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: LiquidSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < actions!.length; i++) ...[
                      if (i > 0) const SizedBox(width: LiquidSpacing.xs),
                      Flexible(child: actions![i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper to show a [GlassDialog].
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  IconData? icon,
  Color? iconColor,
  required String title,
  Widget? content,
  List<Widget>? actions,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => GlassDialog(
      icon: icon,
      iconColor: iconColor,
      title: title,
      content: content,
      actions: actions,
    ),
  );
}
