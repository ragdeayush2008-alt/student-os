import 'package:flutter/material.dart';

import '../design/tokens/student_os_tokens.dart';
import 'app_pressable.dart';
import 'student_os_page_header.dart';

/// Canonical Student OS action + insight components.
///
/// One design language, different personality per surface:
/// - [StudentOSFeaturedAction]: primary actions (Focus / Plan Day / Study).
/// - [StudentOSStandardAction]: compact secondary launcher.
/// - [StudentOSInsightCard]: information + status + optional CTA + WHY.
/// - [StudentOSProgressCard]: progress visualization + next action.
/// - [StudentOSListRow]: compact navigation row.
///
/// All share: radius family, border treatment, elevation language, motion
/// ([StudentOSMotion] 120–450ms, easeOutCubic), icon treatment and semantic
/// labels. Hover lift applies on web/desktop; press scale everywhere.
/// Reduced-motion preferences disable both.
class StudentOSHoverLift extends StatefulWidget {
  const StudentOSHoverLift({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.lift = 3,
    this.radius = StudentOSRadius.standard,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double lift;
  final double radius;

  @override
  State<StudentOSHoverLift> createState() => _StudentOSHoverLiftState();
}

class _StudentOSHoverLiftState extends State<StudentOSHoverLift> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final hover = _hovering && !reduceMotion;

    Widget surface = AnimatedContainer(
      duration: StudentOSMotion.fast,
      curve: StudentOSMotion.easeOut,
      transform: Matrix4.translationValues(0, hover ? -widget.lift : 0, 0),
      child: widget.child,
    );

    if (widget.onTap == null) return surface;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AppPressable(
          onTap: widget.onTap!,
          semanticLabel: widget.semanticLabel,
          child: surface,
        ),
      ),
    );
  }
}

/// Primary action: same light card language as [StudentOSStandardAction],
/// hierarchy comes from SIZE only (larger padding, icon, and type) — never
/// from a darker surface. Setup/Onboarding card family.
///
/// Example: Focus → "Start a focused session" + live duration/status.
class StudentOSFeaturedAction extends StatelessWidget {
  const StudentOSFeaturedAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.detail,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? detail;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = (detail != null && detail!.isNotEmpty) ? detail : subtitle;

    return StudentOSHoverLift(
      onTap: onTap,
      semanticLabel: '$title. $sub',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(StudentOSRadius.large),
          color: scheme.surface,
          border:
              Border.all(color: scheme.outline.withValues(alpha: 0.7)),
          boxShadow: StudentOSElevation.card(isDark),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StudentOSIconTreatment(
              icon: icon,
              color: isDark
                  ? Color.lerp(color, Colors.white, 0.35) ?? color
                  : color,
              size: 52,
              iconSize: 23,
              semanticLabel: null,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                    color: scheme.onSurface,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            if (badge != null && badge!.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: StudentOSColors.forest,
                  borderRadius:
                      BorderRadius.circular(StudentOSRadius.pill),
                ),
                child: Text(
                  badge!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                ),
              )
            else
              Text(
                sub!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact secondary launcher: clean icon capsule + label + optional detail.
class StudentOSStandardAction extends StatelessWidget {
  const StudentOSStandardAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.detail,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? detail;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final narrow = MediaQuery.sizeOf(context).width < 380;

    return StudentOSHoverLift(
      onTap: onTap,
      lift: 2,
      semanticLabel:
          (detail != null && detail!.isNotEmpty) ? '$label, $detail' : label,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: narrow ? 10 : 12,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(StudentOSRadius.standard),
          border:
              Border.all(color: scheme.outline.withValues(alpha: 0.7)),
          boxShadow: StudentOSElevation.card(isDark),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(narrow ? 7 : 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius:
                    BorderRadius.circular(StudentOSRadius.small + 2),
              ),
              child: Icon(
                icon,
                size: narrow ? 18 : 20,
                color: isDark
                    ? Color.lerp(color, Colors.white, 0.35) ?? color
                    : color,
              ),
            ),
            SizedBox(height: narrow ? 5 : 7),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: narrow ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.2,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if ((detail != null && detail!.isNotEmpty) ||
                (badge != null && badge!.isNotEmpty)) ...[
              const SizedBox(height: 2),
              if (badge != null && badge!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: StudentOSColors.forest,
                    borderRadius:
                        BorderRadius.circular(StudentOSRadius.pill),
                  ),
                  child: Text(
                    badge!,
                    style:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 8,
                              letterSpacing: 0.4,
                            ),
                  ),
                )
              else
                Text(
                  detail!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: narrow ? 9 : 10,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Insight card: useful information + status + optional CTA.
///
/// [whyText] explains WHY something is recommended — never a bare metric.
class StudentOSInsightCard extends StatelessWidget {
  const StudentOSInsightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.whyText,
    this.actionLabel,
    this.onAction,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final String? whyText;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Container(
      padding: const EdgeInsets.all(StudentOSSpacing.s16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(StudentOSRadius.standard),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.7)),
        boxShadow: StudentOSElevation.card(isDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentOSIconTreatment(
              icon: icon, color: color, size: 44, iconSize: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
                if (whyText != null && whyText!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.16 : 0.10),
                      borderRadius: BorderRadius.circular(
                          StudentOSRadius.small + 2),
                    ),
                    child: Text(
                      whyText!,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? Color.lerp(
                                            color, Colors.white, 0.4) ??
                                        color
                                    : color,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onAction,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        actionLabel!,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return StudentOSHoverLift(
        onTap: onTap, semanticLabel: title, child: card);
  }
}

/// Progress card: visualization + current state + next action.
class StudentOSProgressCard extends StatelessWidget {
  const StudentOSProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    this.progressLabel,
    this.actionLabel,
    this.onAction,
    this.color,
  });

  final String title;
  final String subtitle;
  final double progress;
  final String? progressLabel;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color ?? scheme.primary;
    final clamped = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(StudentOSSpacing.s16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(StudentOSRadius.standard),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.7)),
        boxShadow: StudentOSElevation.card(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (progressLabel != null) ...[
                const SizedBox(width: 8),
                Text(
                  progressLabel!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(StudentOSRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clamped),
              duration: StudentOSMotion.standard,
              curve: StudentOSMotion.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: accent.withValues(
                    alpha: isDark ? 0.22 : 0.14),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onAction,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  actionLabel!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact navigation row — same DNA on Home, Tools, Workspace.
class StudentOSListRow extends StatelessWidget {
  const StudentOSListRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.trailingLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StudentOSHoverLift(
      onTap: onTap,
      lift: 2,
      semanticLabel: '$title. $subtitle',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(StudentOSRadius.standard),
          border:
              Border.all(color: scheme.outline.withValues(alpha: 0.7)),
          boxShadow: StudentOSElevation.card(isDark),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius:
                    BorderRadius.circular(StudentOSRadius.small + 2),
              ),
              child: Icon(
                icon,
                size: 17,
                color: isDark
                    ? Color.lerp(color, Colors.white, 0.35) ?? color
                    : color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailingLabel != null) ...[
              Text(
                trailingLabel!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right_rounded,
                size: 19, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
