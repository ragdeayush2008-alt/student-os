import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants/app_durations.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/leaderboard_entry.dart';
import 'leaderboard_controller.dart';

/// Complete, production-grade Leaderboard screen for Student OS.
///
/// Follows the strict design system:
/// - Inter font globally
/// - Monochromatic palette: BLACK (#111111), WHITE (#FFFFFF), GREY (#F5F5F7, #E5E5EA, #777777)
/// - ZERO PURPLE across all components and states
/// - Deterministic ranking derived from the authoritative XP engine
/// - Accessible rank movement indicators (icon + text, never color alone)
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardController _controller = LeaderboardController.instance;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.load();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.removeListener(_onChanged);
    super.dispose();
  }

  void _startPolling() {
    // Poll every 30 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _controller.refresh();
      }
    });
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final userEntry = _controller.currentUserEntry;
    final topPodium = _controller.topPodium;
    final rankingList = _controller.rankingList;
    final isLoading = _controller.isLoading && !_controller.isLoaded;
    final isError = _controller.errorMessage != null && !_controller.hasEntries;

    return AppScaffold(
      title: 'Leaderboard',
      body: RefreshIndicator(
        onRefresh: _controller.refresh,
        color: palette.primary,
        backgroundColor: palette.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screen,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Sync Status Banner ─────────────────────────────────────
              _LeaderboardStatusBar(
                status: _controller.syncStatus,
                palette: palette,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Personal Rank Hero Card ────────────────────────────────
              if (userEntry != null) ...[
                _PersonalRankCard(
                  entry: userEntry,
                  period: _controller.period,
                  palette: palette,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── Period Selector (Segmented Bar) ────────────────────────
              _PeriodSelector(
                activePeriod: _controller.period,
                onPeriodSelected: _controller.setPeriod,
                palette: palette,
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Main Content / States ──────────────────────────────────
              if (isLoading) ...[
                const _LeaderboardLoadingSkeleton(),
              ] else if (isError) ...[
                _LeaderboardErrorState(
                  message: _controller.errorMessage!,
                  onRetry: _controller.refresh,
                  palette: palette,
                ),
              ] else if (!_controller.hasEntries) ...[
                _LeaderboardEmptyState(
                  period: _controller.period,
                  palette: palette,
                ),
              ] else ...[
                // ── Top 3 Podium ─────────────────────────────────────────
                if (topPodium.isNotEmpty) ...[
                  _TopPodiumSection(
                    podiumEntries: topPodium,
                    palette: palette,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // ── Main Ranking Table (Ranks 4+) ────────────────────────
                if (rankingList.isNotEmpty) ...[
                  _RankingListSection(
                    entries: rankingList,
                    palette: palette,
                  ),
                ] else if (topPodium.length < 3 && topPodium.length == _controller.entries.length) ...[
                  _SingleUserNotice(palette: palette),
                ],
              ],

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// LEADERBOARD STATUS BAR
// ══════════════════════════════════════════════════════════════════════════

class _LeaderboardStatusBar extends StatelessWidget {
  const _LeaderboardStatusBar({
    required this.status,
    required this.palette,
  });

  final LeaderboardSyncStatus status;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String text, Color color) = switch (status) {
      LeaderboardSyncStatus.live => (
        Icons.cloud_done_rounded,
        'Live rankings',
        palette.primary,
      ),
      LeaderboardSyncStatus.offlineFallback => (
        Icons.cloud_off_rounded,
        'Offline · Showing cached rankings',
        palette.onSurfaceMuted,
      ),
      LeaderboardSyncStatus.loading => (
        Icons.sync_rounded,
        'Loading rankings...',
        palette.onSurfaceMuted,
      ),
      LeaderboardSyncStatus.unavailable => (
        Icons.cloud_off_rounded,
        'Rankings unavailable',
        palette.onSurfaceMuted,
      ),
      LeaderboardSyncStatus.remoteError => (
        Icons.cloud_off_rounded,
        'Rankings unavailable · Showing cached rankings',
        palette.onSurfaceMuted,
      ),
      LeaderboardSyncStatus.authRequired => (
        Icons.lock_rounded,
        'Sign in to view live rankings',
        palette.onSurfaceMuted,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: palette.outline.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: context.text.labelSmall!.copyWith(
                color: palette.onSurfaceMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// PERSONAL RANK HERO CARD
// ══════════════════════════════════════════════════════════════════════════

class _PersonalRankCard extends StatelessWidget {
  const _PersonalRankCard({
    required this.entry,
    required this.period,
    required this.palette,
  });

  final LeaderboardEntry entry;
  final LeaderboardPeriod period;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final movement = entry.movement;
    final streak = entry.streak ?? 0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rank number
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR RANK',
                    style: context.text.labelSmall!.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: palette.onSurfaceMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '#${entry.rank > 0 ? entry.rank : "—"}',
                        style: context.text.displayLarge!.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          color: palette.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _MovementPill(movement: movement, palette: palette),
                    ],
                  ),
                ],
              ),
              const Spacer(),

              // Level & Streak tags
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Level ${entry.level}',
                      style: context.text.labelSmall!.copyWith(
                        color: palette.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (streak > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 14,
                          color: palette.onSurfaceMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$streak day streak',
                          style: context.text.labelSmall!.copyWith(
                            color: palette.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: palette.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),

          // Bottom stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatNumber(entry.xp)} XP',
                    style: context.text.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${period.label} score',
                    style: context.text.labelSmall!.copyWith(
                      color: palette.onSurfaceMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                'Calculated from verified activity',
                style: context.text.labelSmall!.copyWith(
                  color: palette.onSurfaceMuted.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatNumber(int n) {
    if (n < 1000) return '$n';
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// MOVEMENT PILL (Accessible symbol + text)
// ══════════════════════════════════════════════════════════════════════════

class _MovementPill extends StatelessWidget {
  const _MovementPill({required this.movement, required this.palette});

  final RankMovement movement;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final (symbol, text, isUp, isDown) = switch (movement.type) {
      RankMovementType.up => (
          '↑',
          '${movement.delta} places',
          true,
          false
        ),
      RankMovementType.down => (
          '↓',
          '${movement.delta} places',
          false,
          true
        ),
      RankMovementType.same => ('—', 'Unchanged', false, false),
      RankMovementType.neutral => ('—', 'New', false, false),
    };

    return Semantics(
      label: movement.semanticLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: palette.surfaceVariant.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: palette.outline.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isUp
                    ? palette.onSurface
                    : (isDown ? palette.onSurfaceMuted : palette.onSurfaceMuted),
              ),
            ),
            const SizedBox(width: 3),
            Text(
              text,
              style: context.text.labelSmall!.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: palette.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// PERIOD SELECTOR (Segmented Tab Bar)
// ══════════════════════════════════════════════════════════════════════════

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.activePeriod,
    required this.onPeriodSelected,
    required this.palette,
  });

  final LeaderboardPeriod activePeriod;
  final ValueChanged<LeaderboardPeriod> onPeriodSelected;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: palette.outline.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: LeaderboardPeriod.values.map((period) {
          final isSelected = period == activePeriod;
          return Expanded(
            child: AppPressable(
              onTap: () => onPeriodSelected(period),
               semanticLabel: 'Filter by ${period.label}',
               child: AnimatedContainer(
                 duration: reduceMotion
                     ? Duration.zero
                     : const Duration(milliseconds: 150),
                 curve: AppCurves.standard,
                 padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? palette.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    period.label,
                    style: context.text.labelSmall!.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? palette.onPrimary : palette.onSurfaceMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// TOP 3 PODIUM (Architectural, Restrained, Monochromatic)
// ══════════════════════════════════════════════════════════════════════════

class _TopPodiumSection extends StatelessWidget {
  const _TopPodiumSection({
    required this.podiumEntries,
    required this.palette,
  });

  final List<LeaderboardEntry> podiumEntries;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final first = podiumEntries.isNotEmpty ? podiumEntries[0] : null;
    final second = podiumEntries.length > 1 ? podiumEntries[1] : null;
    final third = podiumEntries.length > 2 ? podiumEntries[2] : null;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 2nd Place (Left)
              Expanded(
                child: _PodiumColumn(
                  entry: second,
                  podiumRank: 2,
                  podiumHeight: 80,
                  palette: palette,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // 1st Place (Center — elevated)
              Expanded(
                child: _PodiumColumn(
                  entry: first,
                  podiumRank: 1,
                  podiumHeight: 110,
                  palette: palette,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // 3rd Place (Right)
              Expanded(
                child: _PodiumColumn(
                  entry: third,
                  podiumRank: 3,
                  podiumHeight: 65,
                  palette: palette,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.entry,
    required this.podiumRank,
    required this.podiumHeight,
    required this.palette,
  });

  final LeaderboardEntry? entry;
  final int podiumRank;
  final double podiumHeight;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surfaceVariant.withValues(alpha: 0.3),
              border: Border.all(
                color: palette.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$podiumRank',
                style: context.text.labelSmall!.copyWith(
                  color: palette.onSurfaceMuted.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: podiumHeight,
            decoration: BoxDecoration(
              color: palette.surfaceVariant.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(
              child: Text(
                '—',
                style: TextStyle(
                  color: palette.onSurfaceMuted.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final item = entry!;
    final isFirst = podiumRank == 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar circle
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: isFirst ? 52 : 44,
              height: isFirst ? 52 : 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isCurrentUser
                    ? palette.primary
                    : palette.surfaceVariant,
                border: Border.all(
                  color: item.isCurrentUser
                      ? palette.primary
                      : palette.outline,
                  width: isFirst ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  item.initials,
                  style: TextStyle(
                    fontSize: isFirst ? 18 : 15,
                    fontWeight: FontWeight.w800,
                    color: item.isCurrentUser
                        ? palette.onPrimary
                        : palette.onSurface,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isFirst ? palette.primary : palette.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isFirst ? palette.primary : palette.outline,
                    width: 1,
                  ),
                ),
                child: Text(
                  '#$podiumRank',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isFirst ? palette.onPrimary : palette.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Display Name
        Text(
          item.displayTitle,
          style: context.text.labelSmall!.copyWith(
            fontWeight: item.isCurrentUser ? FontWeight.w800 : FontWeight.w600,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),

        // XP
        Text(
          '${_formatXp(item.xp)} XP',
          style: context.text.labelSmall!.copyWith(
            color: palette.onSurfaceMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
        ),
        const SizedBox(height: 6),

        // Step Pillar
        Container(
          height: podiumHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isFirst
                ? palette.surfaceVariant
                : palette.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(
              color: palette.outline.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              'Lvl ${item.level}',
              style: context.text.labelSmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.onSurfaceMuted,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatXp(int xp) {
    if (xp < 1000) return '$xp';
    return xp.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// RANKING LIST SECTION (Ranks 4+)
// ══════════════════════════════════════════════════════════════════════════

class _RankingListSection extends StatelessWidget {
  const _RankingListSection({
    required this.entries,
    required this.palette,
  });

  final List<LeaderboardEntry> entries;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: AppSpacing.xs),
          child: Row(
            children: [
              Text(
                'RANKINGS',
                style: context.text.labelSmall!.copyWith(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                  color: palette.onSurfaceMuted,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '${entries.length} students',
                style: context.text.labelSmall!.copyWith(
                  color: palette.onSurfaceMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 52,
              color: palette.outline.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final item = entries[index];
              return _LeaderboardRowTile(
                entry: item,
                palette: palette,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRowTile extends StatelessWidget {
  const _LeaderboardRowTile({
    required this.entry,
    required this.palette,
  });

  final LeaderboardEntry entry;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final isCurrent = entry.isCurrentUser;
    final movement = entry.movement;

    return Container(
      color: isCurrent
          ? palette.primary.withValues(alpha: 0.05)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 28,
            child: Text(
              _padRank(entry.rank),
              style: context.text.bodyMedium!.copyWith(
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isCurrent ? palette.primary : palette.onSurfaceMuted,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Avatar circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent
                  ? palette.primary
                  : palette.surfaceVariant,
            ),
            child: Center(
              child: Text(
                entry.initials,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? palette.onPrimary : palette.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Name and Level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayTitle,
                        style: context.text.bodyMedium!.copyWith(
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            color: palette.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Level ${entry.level}',
                  style: context.text.labelSmall!.copyWith(
                    color: palette.onSurfaceMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // XP and Movement
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_formatXp(entry.xp)} XP',
                style: context.text.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Semantics(
                label: movement.semanticLabel,
                child: Text(
                  movement.formatted,
                  style: context.text.labelSmall!.copyWith(
                    color: palette.onSurfaceMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _padRank(int rank) {
    if (rank < 10) return '0$rank';
    return '$rank';
  }

  static String _formatXp(int xp) {
    if (xp < 1000) return '$xp';
    return xp.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SINGLE USER NOTICE
// ══════════════════════════════════════════════════════════════════════════

class _SingleUserNotice extends StatelessWidget {
  const _SingleUserNotice({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: palette.onSurfaceMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Your rankings update automatically as you complete tasks and study sessions.',
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// LOADING SKELETON STATE
// ══════════════════════════════════════════════════════════════════════════

class _LeaderboardLoadingSkeleton extends StatelessWidget {
  const _LeaderboardLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Skeleton card
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: palette.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: palette.outline.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: palette.surfaceVariant.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: palette.outline.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: palette.surfaceVariant.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: palette.outline.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════════════════

class _LeaderboardEmptyState extends StatelessWidget {
  const _LeaderboardEmptyState({
    required this.period,
    required this.palette,
  });

  final LeaderboardPeriod period;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 40,
              color: palette.onSurfaceMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No ${period.label} XP Recorded Yet',
              style: context.text.titleSmall!.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Complete tasks, focus missions, and study sessions to earn XP and climb the leaderboard.',
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ERROR STATE
// ══════════════════════════════════════════════════════════════════════════

class _LeaderboardErrorState extends StatelessWidget {
  const _LeaderboardErrorState({
    required this.message,
    required this.onRetry,
    required this.palette,
  });

  final String message;
  final VoidCallback onRetry;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: palette.onSurfaceMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: context.text.bodyMedium!.copyWith(
                color: palette.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
