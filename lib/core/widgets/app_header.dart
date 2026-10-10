import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../services/course_catalog_service.dart';
import '../services/streak_service.dart';
import '../services/student_service.dart';
import '../theme/app_theme.dart';
import '../../features/progression/progression_controller.dart';
import 'student_os_menu_icon.dart';
import '../../features/notifications/notification_controller.dart';

/// Contextual action model for the header three-dot overflow popup menu.
class HeaderContextAction {
  const HeaderContextAction({
    required this.title,
    this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String title;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDestructive;
}

/// Premium top-level header for Student OS.
///
/// Anchors the workspace with:
/// - Top action row: Hamburger, Rewards, Streak, XP, Leaderboard, Notifications, Overflow
/// - Education / Course context: Dynamic student course with selector affordance
/// - Full reactivity across existing controllers (StudentService, ProgressionController,
///   StreakService, NotificationController)
/// - Adaptive responsive layout with zero overflow at all standard phone widths
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title,
    this.showCourseContext = true,
    this.contextualActions,
    this.showOverflow = true,
    this.onCourseTap,
    this.onMenuTap,
  });

  /// Optional contextual title overriding the course name.
  final String? title;

  /// Whether to show the course / education context row. Defaults to `true`.
  final bool showCourseContext;

  /// Optional custom actions for the three-dot overflow popup menu.
  final List<HeaderContextAction>? contextualActions;

  /// Whether to show the contextual three-dot overflow button.
  final bool showOverflow;

  /// Callback when tapping the course context row.
  final VoidCallback? onCourseTap;

  /// Callback when tapping the hamburger menu button.
  final VoidCallback? onMenuTap;

  @override
  Size get preferredSize => Size.fromHeight(
        title != null || showCourseContext ? 98.0 : 54.0,
      );

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactAppBar = constraints.maxHeight < 75;

        if (isCompactAppBar) {
          return Container(
            height: constraints.maxHeight,
            padding: EdgeInsets.only(
              top: topInset,
              left: 12,
              right: 12,
            ),
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(
                bottom: BorderSide(
                  color: colors.outline.withValues(alpha: 0.35),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                _HamburgerButton(
                  colors: colors,
                  onPressed: onMenuTap ?? () => AppRouter.openHamburger(context),
                ),
                if (title != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const SizedBox(width: 4),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: _HeaderActionsRow(
                        colors: colors,
                        contextualActions: contextualActions,
                        showOverflow: showOverflow,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Full spacious two-row workspace header
        return Container(
          padding: EdgeInsets.only(
            top: topInset + 4,
            left: 14,
            right: 14,
            bottom: (title != null || showCourseContext) ? 10 : 6,
          ),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(
              bottom: BorderSide(
                color: colors.outline.withValues(alpha: 0.35),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Action Row ─────────────────────────────────────────────
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _HamburgerButton(
                      colors: colors,
                      onPressed: onMenuTap ?? () => AppRouter.openHamburger(context),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: _HeaderActionsRow(
                            colors: colors,
                            contextualActions: contextualActions,
                            showOverflow: showOverflow,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Education Context / Title Row ──────────────────────────────
              if (title != null || showCourseContext) ...[
                const SizedBox(height: 6),
                _CourseContextRow(
                  title: title,
                  colors: colors,
                  onCourseTap: onCourseTap,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Header Actions Row ──────────────────────────────────────────────────────

class _HeaderActionsRow extends StatelessWidget {
  const _HeaderActionsRow({
    required this.colors,
    this.contextualActions,
    required this.showOverflow,
  });

  final AppPalette colors;
  final List<HeaderContextAction>? contextualActions;
  final bool showOverflow;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _NotificationBell(colors: colors),
        const SizedBox(width: 4),
        _StreakBadge(colors: colors),
        const SizedBox(width: 4),
        _XpBadge(colors: colors),
        if (showOverflow) ...[
          const SizedBox(width: 2),
          _ContextualOverflowButton(
            colors: colors,
            contextualActions: contextualActions,
          ),
        ],
      ],
    );
  }
}

// ─── Hamburger Button ────────────────────────────────────────────────────────

class _HamburgerButton extends StatelessWidget {
  const _HamburgerButton({
    required this.colors,
    required this.onPressed,
  });

  final AppPalette colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Open navigation menu',
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: StudentOSMenuIcon(
                color: colors.onSurface,
                semanticLabel: 'Open navigation menu',
                excludeSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Streak Badge ────────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.colors});

  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StreakService.instance,
      builder: (context, _) {
        final streak = StreakService.instance.currentStreak;
        final isZero = streak == 0;

        return Semantics(
          label: streak > 0
              ? '$streak day streak. Open streak details'
              : 'Start your streak',
          button: true,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => AppRouter.openStreak(context),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? const Color(0xFF242426)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 23,
                        color: isZero
                            ? colors.onSurfaceMuted
                            : const Color(0xFFFF6B00),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$streak',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isZero
                              ? colors.onSurfaceMuted
                              : colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── XP Badge ────────────────────────────────────────────────────────────────

class _XpBadge extends StatelessWidget {
  const _XpBadge({required this.colors});

  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressionController.instance,
      builder: (context, _) {
        final xp = ProgressionController.instance.totalXp;

        return Semantics(
          label: '$xp XP. Open rewards',
          button: true,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => AppRouter.openRewards(context),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? const Color(0xFF242426)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 23,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$xp',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'XP',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Notification Bell ───────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.colors});

  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationController.instance,
      builder: (context, _) {
        final unreadCount = NotificationController.instance.unreadCount;

        return Semantics(
          label: unreadCount > 0
              ? 'Notifications, $unreadCount unread'
              : 'Notifications',
          button: true,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => AppRouter.openNotifications(context),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        unreadCount > 0
                            ? Icons.notifications_outlined
                            : Icons.notifications_none,
                        color: unreadCount > 0
                            ? colors.onSurface
                            : colors.onSurfaceMuted,
                        size: 24,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -2,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: colors.onPrimary,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Contextual Overflow Button ──────────────────────────────────────────────

class _ContextualOverflowButton extends StatelessWidget {
  const _ContextualOverflowButton({
    required this.colors,
    this.contextualActions,
  });

  final AppPalette colors;
  final List<HeaderContextAction>? contextualActions;

  @override
  Widget build(BuildContext context) {
    final actions = contextualActions ?? _defaultActions(context);
    if (actions.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: 'More options',
      button: true,
      child: Theme(
        data: Theme.of(context).copyWith(
          popupMenuTheme: PopupMenuThemeData(
            color: colors.isDark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colors.outline.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
        ),
        child: SizedBox(
          width: 44,
          height: 44,
          child: PopupMenuButton<HeaderContextAction>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 24,
              color: colors.onSurface,
            ),
            tooltip: 'More options',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onSelected: (action) => action.onTap(),
            itemBuilder: (context) {
              return actions.map((action) {
                return PopupMenuItem<HeaderContextAction>(
                  value: action,
                  height: 40,
                  child: Row(
                    children: [
                      if (action.icon != null) ...[
                        Icon(
                          action.icon,
                          size: 18,
                          color: action.isDestructive
                              ? colors.error
                              : colors.onSurface,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        action.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: action.isDestructive
                              ? colors.error
                              : colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<HeaderContextAction> _defaultActions(BuildContext context) {
    return [
      HeaderContextAction(
        title: 'Edit Course & Profile',
        icon: Icons.school_outlined,
        onTap: () => AppRouter.openEducationSetup(context),
      ),
      HeaderContextAction(
        title: 'Profile & Account',
        icon: Icons.person_outline_rounded,
        onTap: () => AppRouter.openProfile(context),
      ),
      HeaderContextAction(
        title: 'Rewards Marketplace',
        icon: Icons.card_giftcard_outlined,
        onTap: () => AppRouter.openRewards(context),
      ),
      HeaderContextAction(
        title: 'Student Rankings',
        icon: Icons.emoji_events_outlined,
        onTap: () => AppRouter.openLeaderboard(context),
      ),
    ];
  }
}

// ─── Education Context / Title Row ───────────────────────────────────────────

class _CourseContextRow extends StatelessWidget {
  const _CourseContextRow({
    required this.title,
    required this.colors,
    this.onCourseTap,
  });

  final String? title;
  final AppPalette colors;
  final VoidCallback? onCourseTap;

  @override
  Widget build(BuildContext context) {
    if (title != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'STUDENT OS',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: colors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title!,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return ListenableBuilder(
      listenable: StudentService.instance,
      builder: (context, _) {
        final profile = StudentService.instance.profile;
        final courseName = _resolveCourseDisplayName(profile);

        return Semantics(
          label: 'Current course: $courseName. Tap to change education context',
          button: true,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onCourseTap ?? () => AppRouter.openEducationSetup(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'YOUR COURSE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            courseName,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: colors.onSurfaceMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _resolveCourseDisplayName(dynamic profile) {
    final activeCourse = CourseCatalogService.instance.getActiveCourse();
    if (activeCourse != null && activeCourse.isNotEmpty) {
      return activeCourse;
    }
    if (profile.course.isNotEmpty) {
      return profile.course as String;
    }
    if (profile.hasCatalogCourse == true && profile.catalogCourseId != null) {
      final course = CourseCatalogService.instance.getCourseById(
        profile.catalogCourseId as String,
      );
      if (course != null && course.name.isNotEmpty) {
        return course.name;
      }
      return profile.catalogCourseId as String;
    }
    if (profile.academicSummary.isNotEmpty) {
      return profile.academicSummary as String;
    }
    if (profile.educationLevel != null) {
      return profile.educationLevel.label as String;
    }
    return 'General Studies';
  }
}
