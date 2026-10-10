import 'package:flutter/material.dart';

import '../design/tokens/student_os_tokens.dart';
import 'student_os_card.dart';
import 'student_os_icon_glow.dart';

/// Clean Student OS selection card — solid surfaces, clear selected state.
///
/// Selected: primary border + very subtle primary background + check icon
/// with a calm (onboarding-level) glow behind the icon circle.
/// Unselected: surface + neutral border + subtle press state, no glow.
/// No glass, no neon, no oversized shadows.
class StudentOSSelectionTile extends StatelessWidget {
  const StudentOSSelectionTile({
    super.key,
    required this.title,
    this.description,
    this.icon,
    required this.selected,
    required this.onTap,
    this.semanticLabel,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final bg = selected
        ? scheme.primaryContainer.withValues(alpha: isDark ? 0.45 : 0.55)
        : scheme.surface;
    final border = selected ? scheme.primary : scheme.outline;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? title,
      child: StudentOSCard(
        padding: const EdgeInsets.all(16),
        backgroundColor: bg,
        borderColor: border,
        onTap: onTap,
        child: AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : StudentOSMotion.fast,
          curve: StudentOSMotion.easeOut,
          child: Row(
            children: [
              if (icon != null)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? scheme.primary
                        : scheme.surfaceContainerHighest.withValues(
                            alpha: isDark ? 0.6 : 0.5,
                          ),
                    boxShadow: StudentOSGlow.tone(
                      tone: StudentOSGlowTone.primary,
                      intensity: StudentOSGlowIntensity.minimal,
                      radius: StudentOSGlowRadius.small,
                      enabled: selected,
                      isDark: isDark,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                    size: 22,
                    semanticLabel: '$title icon',
                  ),
                ),
              if (icon != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    if (description != null &&
                        description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: scheme.primary,
                  size: 22,
                  semanticLabel: '$title selected',
                )
              else
                Icon(
                  Icons.radio_button_unchecked_outlined,
                  color: scheme.outline,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
