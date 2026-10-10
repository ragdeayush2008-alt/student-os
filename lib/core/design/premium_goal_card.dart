import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding_design_tokens.dart';
import 'goal_icon_mapping.dart';
import '../constants/app_colors.dart';

/// Premium interactive goal card for popular goals section.
/// 
/// Features:
/// - Layered surface with subtle gradient
/// - Icon aura with micro-animations
/// - Hover lift + glow expansion
/// - Press compression feedback
/// - Selection state with pulse animation
/// - Responsive sizing
/// - Reduced motion support
class PremiumGoalCard extends StatefulWidget {
  const PremiumGoalCard({
    super.key,
    required this.title,
    required this.onTap,
    this.isSelected = false,
    this.isPlatform = true,
  });

  final String title;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isPlatform;

  @override
  State<PremiumGoalCard> createState() => _PremiumGoalCardState();
}

class _PremiumGoalCardState extends State<PremiumGoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverElevation;
  late Animation<double> _hoverGlow;
  late Animation<double> _iconAuraScale;
  late Animation<double> _iconScale;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: OnboardingDesignTokens.durationSnappy,
      vsync: this,
    );

    _hoverElevation = Tween<double>(begin: 1, end: 6).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _hoverGlow = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _iconAuraScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _iconScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onEnter() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(() => _isHovered = true);
    _hoverController.forward();
  }

  void _onExit() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(() => _isHovered = false);
    _hoverController.reverse();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final icon = GoalIconMapping.getIconForGoal(widget.title);
    final tint = GoalIconMapping.getTintForGoal(widget.title);

    return Semantics(
      button: true,
      label: widget.title,
      selected: widget.isSelected,
      child: MouseRegion(
        onEnter: (_) => _onEnter(),
        onExit: (_) => _onExit(),
        child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _hoverElevation,
            _hoverGlow,
            _iconAuraScale,
            _iconScale,
          ]),
          builder: (context, child) {
            final elevation =
                _isPressed ? 0.5 : _hoverElevation.value;
            final glowIntensity =
                _isPressed ? 0.3 : _hoverGlow.value;
            final auraScale = _iconAuraScale.value;
            final iScale = _iconScale.value;

            return Transform.translate(
              offset: Offset(0, _isPressed ? 1 : (_isHovered ? -3 : 0)),
              child: Material(
                elevation: elevation,
                shadowColor: scheme.primary.withValues(
                  alpha: 0.15 * glowIntensity,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    OnboardingDesignTokens.radiusCard,
                  ),
                ),
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      OnboardingDesignTokens.radiusCard,
                    ),
                    border: Border.all(
                      color: widget.isSelected
                          ? scheme.primary
                          : AppColors.paleSage.withValues(
                              alpha: _isHovered ? 0.5 : 0.3,
                            ),
                      width: widget.isSelected ? 1.5 : 1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isDark
                            ? scheme.surfaceContainerLow
                            : AppColors.paleSage.withValues(alpha: 0.2),
                        isDark
                            ? scheme.surfaceContainerLow
                            : Colors.white,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tint.withValues(
                          alpha: (0.06 * glowIntensity),
                        ),
                        blurRadius: 16 * glowIntensity,
                        offset: Offset(0, 4 * glowIntensity),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon aura
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Aura glow circle
                            AnimatedContainer(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : OnboardingDesignTokens.durationSnappy,
                              width: 56 * auraScale,
                              height: 56 * auraScale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    tint.withValues(alpha: 0.15),
                                    tint.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                            // Icon
                            Transform.scale(
                              scale: iScale,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tint.withValues(alpha: 0.08),
                                  border: Border.all(
                                    color: tint.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    icon,
                                    color: tint,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Title
                        Text(
                          widget.title,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? scheme.onSurface
                                    : AppColors.deepForest,
                                fontSize: 13,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Category label
                        const SizedBox(height: 4),
                        Text(
                          GoalIconMapping.getCategoryForGoal(widget.title),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        // Selection indicator
                        if (widget.isSelected) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        ),
      ),
    );
  }
}
