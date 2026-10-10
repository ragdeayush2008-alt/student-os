import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../widgets/focus_palette.dart';
import '../../controller/focus_guard_controller.dart';
import '../../controller/focus_music_controller.dart';
import '../../controller/focus_screen_sleep_controller.dart';
import '../../data/models/focus_guard_models.dart';
import '../../data/models/focus_music_track.dart';
import '../screens/focus_guard_settings_screen.dart';

class DirectBgMusicControl extends StatefulWidget {
  const DirectBgMusicControl({super.key});

  @override
  State<DirectBgMusicControl> createState() => _DirectBgMusicControlState();
}

class _DirectBgMusicControlState extends State<DirectBgMusicControl> {
  int _lastTrackIndex = 0;

  @override
  void initState() {
    super.initState();
    final idx = FocusMusicController.instance.selectedTrackIndex;
    if (idx >= 0) _lastTrackIndex = idx;
    FocusMusicController.instance.addListener(_onMusicChanged);
  }

  void _onMusicChanged() {
    final idx = FocusMusicController.instance.selectedTrackIndex;
    if (idx >= 0) _lastTrackIndex = idx;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FocusMusicController.instance.removeListener(_onMusicChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    return ListenableBuilder(
      listenable: FocusMusicController.instance,
      builder: (context, _) {
        final music = FocusMusicController.instance;
        final isOn = music.isEnabled;
        final selectedIdx = music.selectedTrackIndex;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: fp.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: fp.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _MusicToggleChip(
                    label: 'OFF',
                    selected: !isOn,
                    onTap: () => music.setTrack(-1),
                    fp: fp,
                  ),
                  Expanded(
                    child: Text(
                      'Background Music',
                      style: TextStyle(
                        color: fp.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _MusicToggleChip(
                    label: 'ON',
                    selected: isOn,
                    onTap: () {
                      if (!isOn) {
                        final restore = _lastTrackIndex >= 0 ? _lastTrackIndex : 0;
                        music.setTrack(restore);
                      }
                    },
                    fp: fp,
                  ),
                ],
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: isOn
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final entry in FocusMusicTrack.tracks.indexed)
                                _TrackChip(
                                  label: entry.$2.title,
                                  selected: selectedIdx == entry.$1,
                                  onTap: () => music.setTrack(entry.$1),
                                  fp: fp,
                                ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MusicToggleChip extends StatelessWidget {
  const _MusicToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.fp,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final FocusPalette fp;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? fp.primary : fp.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? fp.primary : fp.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? fp.onPrimary : fp.textSecondary,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _TrackChip extends StatelessWidget {
  const _TrackChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.fp,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final FocusPalette fp;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? fp.primary : fp.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? fp.primary : fp.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? fp.onPrimary : fp.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class DirectScreenSleepControl extends StatelessWidget {
  const DirectScreenSleepControl({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    return ListenableBuilder(
      listenable: FocusScreenSleepController.instance,
      builder: (context, _) {
        final c = FocusScreenSleepController.instance;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: fp.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: fp.border),
          ),
          child: Row(
            children: [
              Icon(Icons.brightness_auto_rounded, color: fp.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Prevent Screen Sleep',
                  style: TextStyle(
                    color: fp.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Switch(
                value: c.isEnabled,
                onChanged: (v) => c.setEnabled(v),
                activeThumbColor: fp.primary,
              ),
            ],
          ),
        );
      },
    );
  }
}

class DirectFocusGuardControl extends StatelessWidget {
  const DirectFocusGuardControl({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    return ListenableBuilder(
      listenable: FocusGuardController.instance,
      builder: (context, _) {
        final guard = FocusGuardController.instance;
        final status = guard.permissionStatus;
        final isReady = status == FocusGuardPermissionStatus.ready && guard.isGuardEnabled;
        final blockedCount = guard.blockedPackages.length;
        final isUnsupported = status == FocusGuardPermissionStatus.unsupported;

        if (isUnsupported) return const SizedBox.shrink();

        final title = isReady
            ? 'Focus Guard • $blockedCount app(s)'
            : 'Focus Guard Needs Setup';
        final subtitle = isReady
            ? 'Blocking active during focus'
            : 'Tap to configure blocking';
        final iconColor = isReady ? fp.success : fp.warning;
        final titleColor = isReady ? fp.text : fp.warning;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: fp.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isReady ? fp.border : fp.warning.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isReady ? Icons.shield_rounded : Icons.shield_outlined,
                color: iconColor,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppPressable(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FocusGuardSettingsScreen()),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: fp.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              Switch(
                value: guard.isGuardEnabled,
                onChanged: (v) => guard.setGuardEnabled(v),
                activeThumbColor: fp.primary,
              ),
              AppPressable(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FocusGuardSettingsScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.chevron_right_rounded, color: fp.textMuted, size: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
