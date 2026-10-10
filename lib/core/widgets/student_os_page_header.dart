import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_theme.dart';

/// Canonical page header: eyebrow micro-label, display title, supporting
/// subtitle. Gives every tab the same typographic DNA while letting copy
/// supply each area's personality.
class StudentOSPageHeader extends StatelessWidget {
  const StudentOSPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style:
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            fontSize: 10,
                            color: palette.primary,
                          ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: palette.onSurface,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.onSurfaceMuted,
                        height: 1.4,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

/// Canonical icon treatment: soft tonal rounded-rect container + glyph.
///
/// Matches the Setup/Onboarding card language (44px container, 12px radius,
/// tonal background, restrained accent) so icons read as one recognizable
/// Student OS component on Home, Tools, Workspace, and guides.
class StudentOSIconTreatment extends StatelessWidget {
  const StudentOSIconTreatment({
    super.key,
    required this.icon,
    required this.color,
    this.size = 46,
    this.iconSize = 22,
    this.semanticLabel,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
    if (semanticLabel == null) {
      return tile;
    }
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(child: tile),
    );
  }
}
