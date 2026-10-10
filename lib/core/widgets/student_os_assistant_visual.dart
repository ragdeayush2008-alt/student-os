import 'dart:io';

import 'package:flutter/material.dart';

import '../design/tokens/student_os_tokens.dart';
import 'app_pressable.dart';

/// Canonical Student OS Assistant visual identity.
///
/// Forest/emerald/sage only — never purple/blue/orange. Every Assistant entry
/// point (Home, Tools Hub, Planning, Workspace) uses this component so the
/// Assistant reads as ONE entity across the product.
///
/// Composition: deep-forest orb core → emerald body → sage halo, white spark
/// glyph, subtle 6s breathing scale + optional status dot. Static when
/// reduced-motion is on or in widget tests.
enum StudentOSAssistantSize { small, medium, large }

enum StudentOSAssistantStatus { idle, listening, thinking, ready }

class StudentOSAssistantVisual extends StatefulWidget {
  const StudentOSAssistantVisual({
    super.key,
    this.size = StudentOSAssistantSize.medium,
    this.status = StudentOSAssistantStatus.idle,
    this.breathing = true,
    this.semanticLabel = 'Student OS Assistant',
  });

  final StudentOSAssistantSize size;
  final StudentOSAssistantStatus status;
  final bool breathing;
  final String? semanticLabel;

  double get _orbDiameter {
    switch (size) {
      case StudentOSAssistantSize.small:
        return 40;
      case StudentOSAssistantSize.medium:
        return 52;
      case StudentOSAssistantSize.large:
        return 72;
    }
  }

  @override
  State<StudentOSAssistantVisual> createState() =>
      _StudentOSAssistantVisualState();
}

class _StudentOSAssistantVisualState extends State<StudentOSAssistantVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _t = CurvedAnimation(parent: _breath, curve: Curves.easeInOut);
  }

  bool get _isTest {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    // Never repeat forever in widget tests — pumpAndSettle must settle.
    if (reduce || !widget.breathing || _isTest) {
      if (_breath.isAnimating) _breath.stop();
      return;
    }
    if (!_breath.isAnimating) _breath.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = widget._orbDiameter;
    final statusColor = _statusColor(widget.status, isDark);

    Widget orb = SizedBox(
      width: d * 1.36,
      height: d * 1.36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sage halo.
          Container(
            width: d * 1.36,
            height: d * 1.36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  StudentOSColors.sage
                      .withValues(alpha: isDark ? 0.24 : 0.18),
                  StudentOSColors.sage.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          // Emerald mid-glow.
          Container(
            width: d * 1.08,
            height: d * 1.08,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  StudentOSColors.mutedGreen
                      .withValues(alpha: isDark ? 0.34 : 0.26),
                  StudentOSColors.mutedGreen.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          // Orb body: forest depth.
          Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.25, -0.3),
                colors: [
                  Color(0xFF3D7F6F),
                  StudentOSColors.forest,
                  StudentOSColors.deepForest,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: StudentOSColors.forest
                      .withValues(alpha: isDark ? 0.45 : 0.30),
                  blurRadius: 22,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white.withValues(alpha: 0.95),
                size: d * 0.42,
              ),
            ),
          ),
          // Status dot.
          if (widget.status != StudentOSAssistantStatus.idle)
            Positioned(
              right: d * 0.10,
              bottom: d * 0.10,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  border: Border.all(
                    color: isDark
                        ? StudentOSColors.deepForestDark
                        : Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (MediaQuery.disableAnimationsOf(context) || !widget.breathing) {
      return _semantics(orb);
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final s = 1.0 + (_t.value - 0.5) * 0.05;
          return _semantics(Transform.scale(scale: s, child: orb));
        },
      ),
    );
  }

  Widget _semantics(Widget child) {
    final label = widget.semanticLabel;
    if (label == null) return child;
    return Semantics(image: true, label: label, child: ExcludeSemantics(child: child));
  }

  Color _statusColor(StudentOSAssistantStatus status, bool isDark) {
    switch (status) {
      case StudentOSAssistantStatus.idle:
        return Colors.transparent;
      case StudentOSAssistantStatus.listening:
        return StudentOSColors.sage;
      case StudentOSAssistantStatus.thinking:
        return StudentOSColors.softSage;
      case StudentOSAssistantStatus.ready:
        return StudentOSColors.success;
    }
  }
}

/// Canonical Assistant entry card — the ONE "Ask Student OS" surface.
///
/// [hero]: forest-gradient treatment for high-emphasis placements
/// (Tools Hub). Default standard treatment (sage-tinted surface) for Home.
class StudentOSAssistantEntryCard extends StatelessWidget {
  const StudentOSAssistantEntryCard({
    super.key,
    required this.onTap,
    this.title = 'Ask Student OS',
    this.subtitle = 'What should I do next?',
    this.statusLabel,
    this.status = StudentOSAssistantStatus.idle,
    this.hero = false,
  });

  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String? statusLabel;
  final StudentOSAssistantStatus status;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(StudentOSRadius.large);

    final content = Row(
      children: [
        StudentOSAssistantVisual(
          size: hero
              ? StudentOSAssistantSize.large
              : StudentOSAssistantSize.medium,
          status: status,
          semanticLabel: null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: hero ? Colors.white : scheme.onSurface,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (statusLabel != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: hero
                            ? Colors.white.withValues(alpha: 0.18)
                            : StudentOSColors.forest
                                .withValues(alpha: isDark ? 0.24 : 0.12),
                        borderRadius:
                            BorderRadius.circular(StudentOSRadius.pill),
                      ),
                      child: Text(
                        statusLabel!,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: hero
                                      ? Colors.white
                                      : isDark
                                          ? StudentOSColors.sageDark
                                          : StudentOSColors.forest,
                                ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: hero
                          ? Colors.white.withValues(alpha: 0.80)
                          : scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hero
                ? Colors.white.withValues(alpha: 0.16)
                : scheme.primary.withValues(alpha: isDark ? 0.22 : 0.10),
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: hero ? Colors.white : scheme.primary,
          ),
        ),
      ],
    );

    final decoration = hero
        ? BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                StudentOSColors.deepForest,
                StudentOSColors.forest,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: StudentOSColors.forest.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          )
        : BoxDecoration(
            // Same light surface as every Student OS card — the Assistant
            // stays special through the orb, glow, and status, not the
            // surface.
            borderRadius: radius,
            color: scheme.surface,
            border: Border.all(
              color: (isDark
                      ? StudentOSColors.sageDark
                      : StudentOSColors.forest)
                  .withValues(alpha: 0.30),
            ),
            boxShadow: StudentOSElevation.card(isDark),
          );

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: AppPressable(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: decoration,
            child: content,
          ),
        ),
      ),
    );
  }
}
