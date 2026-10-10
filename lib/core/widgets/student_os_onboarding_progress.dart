import 'package:flutter/material.dart';

import '../design/tokens/student_os_tokens.dart';

/// Consistent onboarding progress — compact, accessible, Command Center aligned.
///
/// Shows "STEP X OF Y" with a thin animated progress bar.
/// Uses actual onboarding state (step/total passed in, never hard-coded).
class StudentOSOnboardingProgress extends StatelessWidget {
  const StudentOSOnboardingProgress({
    super.key,
    required this.step,
    required this.total,
  });

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final clamped = step.clamp(0, total - 1);
    final value = total <= 1 ? 1.0 : (clamped + 1) / total;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: 'Step ${clamped + 1} of $total',
      value: '${((value) * 100).round()} percent complete',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'STEP ${clamped + 1} OF $total',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(StudentOSRadius.pill),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth * value.clamp(0.0, 1.0);
                return Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: reduceMotion
                        ? Duration.zero
                        : StudentOSMotion.standard,
                    curve: StudentOSMotion.easeOut,
                    width: width,
                    height: 6,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius:
                          BorderRadius.circular(StudentOSRadius.pill),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
