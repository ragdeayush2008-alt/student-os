import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../glass/glass_sheet.dart';

/// Single action item for [AppActionSheet].
class AppSheetAction {
  const AppSheetAction({
    required this.title,
    this.subtitle,
    this.icon,
    this.isDestructive = false,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isDestructive;
  final VoidCallback onTap;
}

/// Action sheet modal menu.
class AppActionSheet extends StatelessWidget {
  const AppActionSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.actions,
  });

  final String? title;
  final String? subtitle;
  final List<AppSheetAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassSheet(
      title: title,
      subtitle: subtitle,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.5,
                color: isDark
                    ? LiquidColors.borderDark
                    : LiquidColors.borderLight,
              ),
            ListTile(
              leading: actions[i].icon != null
                  ? Icon(
                      actions[i].icon,
                      color: actions[i].isDestructive
                          ? LiquidColors.error
                          : theme.colorScheme.primary,
                      size: 20,
                    )
                  : null,
              title: Text(
                actions[i].title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: actions[i].isDestructive
                      ? LiquidColors.error
                      : null,
                ),
              ),
              subtitle: actions[i].subtitle != null
                  ? Text(actions[i].subtitle!)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                actions[i].onTap();
              },
              shape: RoundedRectangleBorder(
                borderRadius: LiquidRadius.mdAll,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: LiquidSpacing.screen,
                vertical: 2,
              ),
            ),
          ],
          const SizedBox(height: LiquidSpacing.md),
        ],
      ),
    );
  }
}

/// Helper function to show [AppActionSheet].
Future<void> showAppActionSheet({
  required BuildContext context,
  String? title,
  String? subtitle,
  required List<AppSheetAction> actions,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    builder: (_) => AppActionSheet(
      title: title,
      subtitle: subtitle,
      actions: actions,
    ),
  );
}
