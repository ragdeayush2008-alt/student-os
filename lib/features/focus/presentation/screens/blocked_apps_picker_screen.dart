import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_states.dart';
import '../../controller/focus_guard_controller.dart';
import '../../data/models/focus_guard_models.dart';

class BlockedAppsPickerScreen extends StatefulWidget {
  const BlockedAppsPickerScreen({super.key});

  @override
  State<BlockedAppsPickerScreen> createState() => _BlockedAppsPickerScreenState();
}

class _BlockedAppsPickerScreenState extends State<BlockedAppsPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static final List<DetectedApp> _commonDistractions = [
    DetectedApp(packageName: 'com.instagram.android', label: 'Instagram'),
    DetectedApp(packageName: 'com.google.android.youtube', label: 'YouTube'),
    DetectedApp(packageName: 'com.zhiliaoapp.musically', label: 'TikTok'),
    DetectedApp(packageName: 'com.snapchat.android', label: 'Snapchat'),
    DetectedApp(packageName: 'com.twitter.android', label: 'X (Twitter)'),
    DetectedApp(packageName: 'com.reddit.frontpage', label: 'Reddit'),
    DetectedApp(packageName: 'com.discord', label: 'Discord'),
    DetectedApp(packageName: 'com.netflix.mediaclient', label: 'Netflix'),
    DetectedApp(packageName: 'com.spotify.music', label: 'Spotify'),
  ];

  @override
  void initState() {
    super.initState();
    FocusGuardController.instance.loadInstalledApps();
    FocusGuardController.instance.addListener(_onGuardChanged);
  }

  void _onGuardChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FocusGuardController.instance.removeListener(_onGuardChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guard = FocusGuardController.instance;
    final palette = AppTheme.colorsOf(context);

    // If installed apps are available, use them. Otherwise fallback to common distractions.
    final availableApps = guard.installedApps.isNotEmpty
        ? guard.installedApps
        : _commonDistractions;

    final filteredApps = availableApps.where((app) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return app.displayName.toLowerCase().contains(q) ||
          app.packageName.toLowerCase().contains(q);
    }).toList();

    return AppScaffold(
      title: 'Apps to Block',
      onBack: () => Navigator.of(context).pop(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.sm,
            ),
            child: AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: context.text.bodyMedium,
                decoration: InputDecoration(
                  icon: Icon(
                    Icons.search_rounded,
                    color: palette.onSurfaceMuted,
                    size: 20,
                  ),
                  hintText: 'Search apps...',
                  hintStyle: context.text.bodyMedium?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          if (guard.isLoadingApps)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
          Expanded(
            child: filteredApps.isEmpty
                ? const AppEmptyState(
                    title: 'No apps found',
                    icon: Icons.apps_rounded,
                    compact: true,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = filteredApps[index];
                      final isBlocked = guard.blockedPackages.contains(app.packageName);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: AppPressable(
                          onTap: () => guard.toggleAppBlocked(app.packageName),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: palette.primaryContainer.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Icon(
                                    Icons.apps_rounded,
                                    color: palette.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        app.displayName,
                                        style: context.text.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        app.packageName,
                                        style: context.text.labelSmall?.copyWith(
                                          color: palette.onSurfaceMuted,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IgnorePointer(
                                  child: Checkbox(
                                    value: isBlocked,
                                    activeColor: palette.primary,
                                    onChanged: null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.screen),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(top: BorderSide(color: palette.outline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${guard.blockedPackages.length} app(s) selected',
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppPressable(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Done',
                      style: context.text.labelMedium?.copyWith(
                        color: palette.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
