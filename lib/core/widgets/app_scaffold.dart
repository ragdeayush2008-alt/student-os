import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../design/student_os_atmosphere.dart';
import '../theme/app_theme.dart';

/// Standard workspace scaffold for Student OS Academic Command Center.
///
/// Solid surfaces, clean hierarchy, no ambient blur, no glass header.
/// Provides a solid header with back button + actions, SafeArea, and
/// responsive max-width content.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.onBack,
    this.slivers = false,
    this.showGradient = false,
    this.ambientVariant,
    this.showAmbient = false,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool slivers;
  final bool showGradient;
  final Object? ambientVariant;
  final bool showAmbient;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) _buildHeader(context, colors),
          Expanded(child: body),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: colors.background,
      // Clean by default: solid theme background, no painted decoration, so
      // content always stays visually dominant. Screens opt into the subtle
      // atmospheric wash explicitly via [showAmbient].
      body: showAmbient
          ? StudentOSAtmosphere(
              variant: ambientVariant is StudentOSAtmosphereVariant
                  ? ambientVariant as StudentOSAtmosphereVariant
                  : StudentOSAtmosphereVariant.calm,
              child: content,
            )
          : content,
    );
  }

  Widget _buildHeader(BuildContext context, AppPalette colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            if (onBack != null || (ModalRoute.of(context)?.canPop ?? false))
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: _NavCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  colors: colors,
                ),
              ),
            Expanded(
              child: Text(
                title!,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: colors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...?actions,
          ],
        ),
      ),
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final AppPalette colors;

  const _NavCircleButton({
    required this.icon,
    required this.onPressed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Back',
      button: true,
      child: Material(
        color: colors.onSurface.withValues(alpha: 0.08),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: colors.onSurface),
          ),
        ),
      ),
    );
  }
}
