import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../controller/focus_guard_controller.dart';
import '../../data/models/focus_guard_models.dart';
import '../../../premium/services/premium_gate.dart';
import '../../../premium/widgets/premium_widgets.dart';
import 'blocked_apps_picker_screen.dart';

class FocusGuardSettingsScreen extends StatefulWidget {
  const FocusGuardSettingsScreen({super.key});

  @override
  State<FocusGuardSettingsScreen> createState() => _FocusGuardSettingsScreenState();
}

class _FocusGuardSettingsScreenState extends State<FocusGuardSettingsScreen> {
  @override
  void initState() {
    super.initState();
    FocusGuardController.instance.addListener(_onGuardChanged);
    // Fresh permission check every time the screen opens — the user may
    // have granted access in system settings since the last check.
    FocusGuardController.instance.refreshPermissions();
  }

  void _onGuardChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FocusGuardController.instance.removeListener(_onGuardChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guard = FocusGuardController.instance;
    final palette = AppTheme.colorsOf(context);

    return AppScaffold(
      title: 'Focus Guard',
      onBack: () => Navigator.of(context).pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Main Guard Toggle ───────────────────────────────────
            AppCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: palette.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      color: palette.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Focus Guard Protection',
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          guard.isGuardEnabled
                              ? 'Active during focus sessions'
                              : 'Disabled',
                          style: context.text.bodySmall?.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: guard.isGuardEnabled,
                    activeThumbColor: palette.primary,
                    onChanged: (val) => guard.setGuardEnabled(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Permissions (usage access + overlay are granted in system
            // settings — Android does not allow in-app permission dialogs
            // for these, so the app must deep-link the user there) ──
            _PermissionSetupSection(guard: guard),
            const SizedBox(height: AppSpacing.lg),

            // ── Blocking Mode ───────────────────────────────────────
            Text(
              'BLOCKING MODE',
              style: context.text.labelSmall?.copyWith(
                color: palette.onSurfaceMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...FocusGuardMode.values.map(
              (m) => _buildModeTile(m, guard, palette, context),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Apps to Block ───────────────────────────────────────
            Text(
              'BLOCKED APPLICATIONS',
              style: context.text.labelSmall?.copyWith(
                color: palette.onSurfaceMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${guard.blockedPackages.length} apps selected',
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppPressable(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BlockedAppsPickerScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Select Apps →',
                          style: context.text.labelMedium?.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (guard.blockedPackages.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: guard.blockedPackages.take(6).map((pkg) {
                        final shortName = pkg.split('.').last;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: palette.primaryContainer.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            shortName,
                            style: context.text.labelSmall?.copyWith(
                              color: palette.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (guard.blockedPackages.length > 6) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '+ ${guard.blockedPackages.length - 6} more',
                        style: context.text.labelSmall?.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Recent Interventions ────────────────────────────────
            if (guard.blockedAttempts.isNotEmpty) ...[
              Text(
                'RECENT INTERVENTIONS',
                style: context.text.labelSmall?.copyWith(
                  color: palette.onSurfaceMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  children: guard.blockedAttempts.take(5).map((attempt) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.block_rounded,
                            color: palette.warning,
                            size: 16,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              attempt.appLabel ?? attempt.packageName,
                              style: context.text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${attempt.timestamp.hour.toString().padLeft(2, '0')}:${attempt.timestamp.minute.toString().padLeft(2, '0')}',
                            style: context.text.labelSmall?.copyWith(
                              color: palette.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTile(
    FocusGuardMode mode,
    FocusGuardController guard,
    AppPalette palette,
    BuildContext context,
  ) {    final isSelected = guard.mode == mode;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppPressable(
        onTap: () {
          // Strict Focus is Pro; other modes stay free.
          if (mode == FocusGuardMode.strict &&
              !PremiumGate.check(context, 'premium.focus.strict')) {
            return;
          }
          guard.setMode(mode);
        },
        child: AppCard(
          color: isSelected
              ? palette.primaryContainer.withValues(alpha: 0.12)
              : palette.surface,
          borderColor: isSelected ? palette.primary : palette.outline,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? palette.primary : palette.onSurfaceMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mode.label,
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (mode == FocusGuardMode.strict)
                          const PremiumBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.description,
                      style: context.text.bodySmall?.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Permission setup for Focus Guard.
///
/// Android grants usage-access and display-over-other-apps ONLY through
/// system settings screens — no in-app permission dialog exists for these.
/// This section deep-links each step in order and re-checks on return
/// (plus a manual Recheck for safety), so "Setup Needed" can actually clear.
class _PermissionSetupSection extends StatelessWidget {
  const _PermissionSetupSection({required this.guard});

  final FocusGuardController guard;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final status = guard.permissionStatus;

    if (status == FocusGuardPermissionStatus.ready) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: palette.success,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permissions granted',
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Focus Guard can monitor apps and show its overlay.',
                    style: context.text.bodySmall?.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == FocusGuardPermissionStatus.unsupported) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: palette.onSurfaceMuted,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Focus Guard app blocking needs Android. Timers and sessions still work everywhere.',
                style: context.text.bodySmall?.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final needUsage =
        status == FocusGuardPermissionStatus.usageAccessRequired ||
        status == FocusGuardPermissionStatus.notReady;
    final needOverlay =
        status == FocusGuardPermissionStatus.overlayRequired ||
        status == FocusGuardPermissionStatus.notReady;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: palette.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: palette.warning,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Setup needed',
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => guard.refreshPermissions(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Text(
                    'Recheck',
                    style: context.text.labelMedium?.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Grant access in system settings (Android shows these outside the app).',
            style: context.text.bodySmall?.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PermissionStep(
            step: '1',
            title: 'App usage access',
            subtitle: guard.hasUsageAccess
                ? 'Granted'
                : 'Lets Focus Guard detect blocked apps',
            done: guard.hasUsageAccess,
            actionLabel: guard.hasUsageAccess ? null : 'Open Settings',
            onAction: guard.hasUsageAccess
                ? null
                : () => guard.requestUsageAccess(),
          ),
          const SizedBox(height: AppSpacing.xs),
          _PermissionStep(
            step: '2',
            title: 'Display over other apps',
            subtitle: guard.hasOverlayPermission
                ? 'Granted'
                : 'Lets Focus Guard show its overlay',
            done: guard.hasOverlayPermission,
            actionLabel: guard.hasOverlayPermission ? null : 'Open Settings',
            onAction: guard.hasOverlayPermission
                ? null
                : () => guard.requestOverlayPermission(),
          ),
          if (needUsage || needOverlay) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'After granting, return here — status refreshes automatically.',
              style: context.text.bodySmall?.copyWith(
                color: palette.onSurfaceMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionStep extends StatelessWidget {
  const _PermissionStep({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.done,
    this.actionLabel,
    this.onAction,
  });

  final String step;
  final String title;
  final String subtitle;
  final bool done;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? palette.success.withValues(alpha: 0.15)
                  : palette.primary.withValues(alpha: 0.12),
            ),
            child: done
                ? Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: palette.success,
                  )
                : Text(
                    step,
                    style: context.text.labelSmall?.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: context.text.bodySmall?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 36),
              ),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
