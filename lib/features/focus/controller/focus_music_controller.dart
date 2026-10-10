import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_isolation.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/auth_service.dart';
import '../data/models/focus_music_track.dart';
import '../services/focus_music_service.dart';
import 'focus_controller.dart';

class FocusMusicController extends ChangeNotifier {
  FocusMusicController({FocusMusicService? service})
      : _service = service ?? FocusMusicService.instance {
    FocusController.instance.addListener(_syncToSession);
    load();
  }

  static FocusMusicController instance = FocusMusicController();

  final FocusMusicService _service;

  static const _selectionKey = 'focus_music_selection';

  int _selectedIndex = -1;
  bool _playing = false;
  bool _disposed = false;

  /// Track currently loaded in the single player (playing or paused).
  /// Null when the player holds nothing, so resume never plays stale audio.
  String? _loadedAssetPath;

  /// Track paused mid-session, eligible for position resume.
  FocusMusicTrack? _pausedTrack;

  int get selectedTrackIndex => _selectedIndex;

  bool get isEnabled => _selectedIndex >= 0;

  bool get isPlaying => _playing;

  FocusMusicTrack? get selectedTrack =>
      (_selectedIndex >= 0 && _selectedIndex < FocusMusicTrack.tracks.length)
          ? FocusMusicTrack.tracks[_selectedIndex]
          : null;

  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  Future<void> load() async {
    final uid = _userId;
    if (uid != null) {
      try {
        final raw = await StorageService.instance.loadJson(
          userId: uid,
          key: _selectionKey,
        );
        final idx = raw?['trackIndex'] as int? ?? -1;
        _selectedIndex =
            (idx >= 0 && idx < FocusMusicTrack.tracks.length) ? idx : -1;
      } catch (_) {
        _selectedIndex = -1;
      }
    }
    _syncToSession();
    _notifySafely();
  }

  Future<void> cycleTrack() async {
    if (_selectedIndex < 0) {
      await setTrack(0);
    } else if (_selectedIndex >= FocusMusicTrack.tracks.length - 1) {
      await setTrack(-1);
    } else {
      await setTrack(_selectedIndex + 1);
    }
  }

  Future<void> setTrack(int index) async {
    final clamped = (index >= 0 && index < FocusMusicTrack.tracks.length)
        ? index
        : -1;
    if (_selectedIndex == clamped) return;
    _selectedIndex = clamped;

    final uid = _userId;
    if (uid != null) {
      try {
        await StorageService.instance.saveJson(
          userId: uid,
          key: _selectionKey,
          json: {'trackIndex': clamped},
        );
      } catch (_) {}
    }

    // A new selection invalidates any paused position: the player must never
    // resume stale audio after a switch.
    if (_pausedTrack != null) {
      _pausedTrack = null;
      _loadedAssetPath = null;
      _service.stop();
    }

    _syncToSession();
    _notifySafely();
  }

  void _syncToSession() {
    final active = FocusController.instance.activeSession;
    final track = selectedTrack;

    // Running session with a selection → play (or resume/switch).
    if (active != null && active.isRunning && !active.isPaused) {
      if (track == null) {
        _stopPlaying();
        return;
      }
      _playTrack(track);
      return;
    }

    // Paused session with a selection → pause, keeping the position so
    // resume continues instead of restarting.
    if (active != null && active.isPaused && track != null) {
      _pausePlaying(track);
      return;
    }

    // Ended session, no session, or OFF → full stop, nothing loaded.
    _stopPlaying();
  }

  void _playTrack(FocusMusicTrack track) {
    // Resume a paused track in place when it is still the loaded one.
    if (_pausedTrack == track && _loadedAssetPath == track.assetPath) {
      _pausedTrack = null;
      _service.resume().then((ok) {
        if (_disposed) return;
        _playing = ok;
        if (!ok) {
          // Resume failed: drop the selection instead of faking playback.
          _revertToOff();
          return;
        }
        _notifySafely();
      }).catchError((_) {
        if (!_disposed) _revertToOff();
      });
      return;
    }
    // Already playing this exact asset → nothing to do (no duplicate player).
    if (_playing && _loadedAssetPath == track.assetPath) return;
    _service.play(track.assetPath).then((ok) {
      if (_disposed) return;
      if (!ok) {
        // Missing/unplayable asset: revert to OFF instead of faking ON.
        _revertToOff();
        return;
      }
      _playing = true;
      _pausedTrack = null;
      _loadedAssetPath = track.assetPath;
      _notifySafely();
    }).catchError((_) {
      if (!_disposed) _revertToOff();
    });
  }

  void _pausePlaying(FocusMusicTrack track) {
    // Only pause what is actually loaded; otherwise leave the player alone.
    if (!_playing || _loadedAssetPath != track.assetPath) return;
    _playing = false;
    _pausedTrack = track;
    _service.pause();
    _notifySafely();
  }

  void _stopPlaying() {
    _playing = false;
    _pausedTrack = null;
    _loadedAssetPath = null;
    _service.stop();
  }

  /// Drops a failed/unplayable selection back to OFF (persisted) so the UI
  /// can never claim playback that is not happening.
  void _revertToOff() {
    _playing = false;
    _pausedTrack = null;
    _loadedAssetPath = null;
    _selectedIndex = -1;
    final uid = _userId;
    if (uid != null) {
      StorageService.instance
          .saveJson(
            userId: uid,
            key: _selectionKey,
            json: {'trackIndex': -1},
          )
          .catchError((_) {});
    }
    _service.stop();
    _notifySafely();
  }

  void clearData() {
    _selectedIndex = -1;
    _stopPlaying();
    _notifySafely();
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    FocusController.instance.removeListener(_syncToSession);
    _service.stop();
    super.dispose();
  }
}
