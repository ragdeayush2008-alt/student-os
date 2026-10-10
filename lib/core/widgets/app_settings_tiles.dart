import 'package:flutter/material.dart';

import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'student_os_page_header.dart';

/// A tappable settings row with icon, title, optional subtitle/trailing.
class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: EdgeInsets.zero,
      color: palette.surface,
      onTap: onTap,
      radius: AppRadius.md,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            StudentOSIconTreatment(
              icon: icon,
              color: iconColor ?? palette.primary,
              size: 44,
              iconSize: 20,
              semanticLabel: '$title icon',
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleSmall),
                  if (subtitle != null)
                    Text(subtitle!, style: context.text.bodySmall),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, size: 22),
          ],
        ),
      ),
    );
  }
}

/// A checkbox-style selection row used for theme/segmented choices.
class AppSettingsSelectTile extends StatelessWidget {
  const AppSettingsSelectTile({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: palette.primary),
      title: Text(title, style: context.text.titleSmall),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            )
          : null,
      trailing:
          trailing ??
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? palette.primary : Colors.transparent,
              border: Border.all(
                color: selected ? palette.primary : palette.outline,
                width: 2,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: 18, color: palette.onPrimary,)
                : null,
          ),
    );
  }
}

/// A settings group: a section header above a list of tiles.
class AppSettingsGroup extends StatelessWidget {
  const AppSettingsGroup({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(title.toUpperCase(), style: context.text.labelSmall),
        ),
        Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      ],
    );
  }
}
