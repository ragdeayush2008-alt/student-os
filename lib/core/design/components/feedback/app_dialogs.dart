import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../buttons/app_button.dart';
import '../../glass/glass_dialog.dart';

/// Standard confirmation dialog for destructive or important actions.
class AppConfirmationDialog extends StatelessWidget {
  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.icon,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      icon: icon ?? (isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded),
      iconColor: isDestructive ? LiquidColors.error : LiquidColors.primary,
      title: title,
      content: Text(message),
      actions: [
        AppButton.tertiary(
          label: cancelLabel,
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
        ),
        if (isDestructive)
          AppButton.destructive(
            label: confirmLabel,
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm?.call();
            },
          )
        else
          AppButton.primary(
            label: confirmLabel,
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm?.call();
            },
          ),
      ],
    );
  }
}

/// Helper function to display an [AppConfirmationDialog].
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => AppConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      icon: icon,
    ),
  );
  return result ?? false;
}
