import 'package:flutter/material.dart';

import '../design/tokens/student_os_tokens.dart';

/// Centralized soft icon-glow system.
///
/// "Soft light around an icon", never a neon sign:
/// - one restrained [BoxShadow], offset zero, wide soft blur
/// - tinted toward the icon's semantic/brand color
/// - low opacity, fading smoothly outward
///
/// Restrained by design — the green family carries the product, so glow is
/// used sparingly and only for meaningful/actionable states.
///
/// Hierarchy:
/// - important/actionable → [StudentOSGlowIntensity.standard]/prominent
/// - secondary → subtle/minimal
/// - decorative → minimal
/// - disabled → [StudentOSGlowIntensity.none] (never glow a disabled icon)
///
/// Performance: static single shadow, no BackdropFilter, no continuous
/// animation. Only [StudentOSIconGlow.interactive] animates (hover/active)
/// with a 180ms transition.
enum StudentOSGlowTone { primary, secondary, success, warning, danger, info }

/// Glow strength. Opacity is restrained by design; even [prominent] stays
/// well below neon territory. Reserved for immersive Focus states.
enum StudentOSGlowIntensity { none, minimal, subtle, standard, prominent }

/// How far the light extends beyond the icon container.
enum StudentOSGlowRadius {
  /// Small icons: 4dp spread, soft 12dp blur.
  small,

  /// Medium icons: 6dp spread, soft 18dp blur.
  medium,

  /// Hero icons: 8dp spread, soft 26dp blur.
  hero,
}

/// Single source of truth for soft icon glow shadows.
abstract final class StudentOSGlow {
  /// Resolves a tone to its canonical Student OS color.
  static Color colorFor(StudentOSGlowTone tone) {
    return switch (tone) {
      StudentOSGlowTone.primary => StudentOSColors.primary,
      StudentOSGlowTone.secondary => StudentOSColors.secondary,
      StudentOSGlowTone.success => StudentOSColors.success,
      StudentOSGlowTone.warning => StudentOSColors.warning,
      StudentOSGlowTone.danger => StudentOSColors.danger,
      StudentOSGlowTone.info => StudentOSColors.info,
    };
  }

  /// Base opacity per intensity (light mode). Dark mode adds a small
  /// visibility bump since deep backgrounds absorb light.
  static double opacityFor(StudentOSGlowIntensity intensity, bool isDark) {
    final base = switch (intensity) {
      StudentOSGlowIntensity.none => 0.0,
      StudentOSGlowIntensity.minimal => 0.08,
      StudentOSGlowIntensity.subtle => 0.13,
      StudentOSGlowIntensity.standard => 0.18,
      StudentOSGlowIntensity.prominent => 0.24,
    };
    if (base == 0.0) return 0.0;
    return (base + (isDark ? 0.04 : 0.0)).clamp(0.0, 0.30);
  }

  /// Spread (reach) per radius token.
  static double spreadFor(StudentOSGlowRadius radius) {
    return switch (radius) {
      StudentOSGlowRadius.small => 4.0,
      StudentOSGlowRadius.medium => 6.0,
      StudentOSGlowRadius.hero => 8.0,
    };
  }

  /// Blur is wide/soft so the light fades smoothly outward.
  static double blurFor(StudentOSGlowRadius radius) {
    return switch (radius) {
      StudentOSGlowRadius.small => 12.0,
      StudentOSGlowRadius.medium => 18.0,
      StudentOSGlowRadius.hero => 26.0,
    };
  }

  /// Builds the single soft shadow for [glowColor]. Returns empty when
  /// [intensity] is none or [enabled] is false — disabled icons never glow.
  static List<BoxShadow> shadows({
    required Color glowColor,
    StudentOSGlowIntensity intensity = StudentOSGlowIntensity.subtle,
    StudentOSGlowRadius radius = StudentOSGlowRadius.small,
    bool enabled = true,
    bool isDark = false,
  }) {
    if (!enabled || intensity == StudentOSGlowIntensity.none) return const [];
    final opacity = opacityFor(intensity, isDark);
    if (opacity <= 0.0) return const [];
    return [
      BoxShadow(
        color: glowColor.withValues(alpha: opacity),
        blurRadius: blurFor(radius),
        spreadRadius: spreadFor(radius),
        offset: Offset.zero,
      ),
    ];
  }

  /// Tone convenience over [shadows].
  static List<BoxShadow> tone({
    required StudentOSGlowTone tone,
    StudentOSGlowIntensity intensity = StudentOSGlowIntensity.subtle,
    StudentOSGlowRadius radius = StudentOSGlowRadius.small,
    bool enabled = true,
    bool isDark = false,
  }) {
    return shadows(
      glowColor: colorFor(tone),
      intensity: intensity,
      radius: radius,
      enabled: enabled,
      isDark: isDark,
    );
  }
}

/// Wraps an icon (or its solid container) in a soft ambient glow.
///
/// The child itself is untouched — glow is purely decorative enhancement and
/// never the sole indicator of state (shape, color, text, borders remain).
class StudentOSIconGlow extends StatelessWidget {
  const StudentOSIconGlow({
    super.key,
    required this.child,
    required this.glowColor,
    this.intensity = StudentOSGlowIntensity.subtle,
    this.radius = StudentOSGlowRadius.small,
    this.enabled = true,
    this.borderRadius,
  }) : _tone = null;

  /// Tone convenience constructor.
  const StudentOSIconGlow.tone({
    super.key,
    required this.child,
    required StudentOSGlowTone tone,
    this.intensity = StudentOSGlowIntensity.subtle,
    this.radius = StudentOSGlowRadius.small,
    this.enabled = true,
    this.borderRadius,
  }) : glowColor = null,
       // ignore: prefer_initializing_formals, public `tone` maps to private `_tone`
       _tone = tone;

  final Widget child;

  /// Explicit glow color. Ignored when the [.tone] constructor is used.
  final Color? glowColor;
  final StudentOSGlowTone? _tone;
  final StudentOSGlowIntensity intensity;
  final StudentOSGlowRadius radius;
  final bool enabled;

  /// Border radius of the glowing box. When null, the child's shape is
  /// preserved via a circular approximation only for icon-sized boxes —
  /// prefer passing the container's own radius for square containers.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _tone != null ? StudentOSGlow.colorFor(_tone) : glowColor;
    if (!enabled ||
        intensity == StudentOSGlowIntensity.none ||
        color == null) {
      return child;
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: StudentOSGlow.shadows(
          glowColor: color,
          intensity: intensity,
          radius: radius,
          isDark: isDark,
        ),
      ),
      child: child,
    );
  }
}

/// Interactive variant: glow brightens slightly on hover (desktop) and holds
/// a stable soft glow when [active]. No continuous pulsing. Pressed state is
/// intentionally left to the child's own ink/scale feedback.
///
/// Animation: 180ms ease-out (within the 150–220ms budget).
class StudentOSInteractiveGlow extends StatefulWidget {
  const StudentOSInteractiveGlow({
    super.key,
    required this.child,
    required this.glowColor,
    this.intensity = StudentOSGlowIntensity.subtle,
    this.activeIntensity = StudentOSGlowIntensity.standard,
    this.radius = StudentOSGlowRadius.small,
    this.enabled = true,
    this.active = false,
    this.borderRadius,
  });

  final Widget child;
  final Color glowColor;
  final StudentOSGlowIntensity intensity;
  final StudentOSGlowIntensity activeIntensity;
  final StudentOSGlowRadius radius;
  final bool enabled;
  final bool active;
  final BorderRadius? borderRadius;

  @override
  State<StudentOSInteractiveGlow> createState() =>
      _StudentOSInteractiveGlowState();
}

class _StudentOSInteractiveGlowState extends State<StudentOSInteractiveGlow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    var intensity = widget.intensity;
    if (widget.active) intensity = widget.activeIntensity;
    if (_hovered && intensity.index < StudentOSGlowIntensity.prominent.index) {
      intensity = StudentOSGlowIntensity.values[intensity.index + 1];
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        // 180ms hover/active transition (within the 150–220ms budget).
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        curve: StudentOSMotion.easeOut,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: StudentOSGlow.shadows(
            glowColor: widget.glowColor,
            intensity: intensity,
            radius: widget.radius,
            enabled: widget.enabled,
            isDark: isDark,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Very subtle ambient glow behind emoji / symbol visuals.
///
/// The emoji itself stays crisp and natural (never recolored, never boxed in
/// a glowing border) — only a faint radial light sits behind it.
class StudentOSAmbientGlow extends StatelessWidget {
  const StudentOSAmbientGlow({
    super.key,
    required this.child,
    required this.glowColor,
    this.intensity = StudentOSGlowIntensity.minimal,
    this.size = 64,
  }) : _tone = null;

  /// Tone convenience constructor.
  const StudentOSAmbientGlow.tone({
    super.key,
    required this.child,
    required StudentOSGlowTone tone,
    this.intensity = StudentOSGlowIntensity.minimal,
    this.size = 64,
  }) : glowColor = null,
       // ignore: prefer_initializing_formals, public `tone` maps to private `_tone`
       _tone = tone;

  final Widget child;
  final Color? glowColor;
  final StudentOSGlowTone? _tone;
  final StudentOSGlowIntensity intensity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _tone != null ? StudentOSGlow.colorFor(_tone) : glowColor;
    final opacity = StudentOSGlow.opacityFor(intensity, isDark);
    if (color == null || opacity <= 0.0) return child;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity + 0.06),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
