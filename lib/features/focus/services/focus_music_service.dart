import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models/focus_music_track.dart';

class FocusMusicService {
  FocusMusicService({AudioPlayer? player, bool isTest = false}) {
    _player = player;
    _isTest = isTest;
  }

  static FocusMusicService instance = FocusMusicService();

  AudioPlayer? _player;
  bool _isTest = false;
  bool _disposed = false;
  bool _mockPlaying = false;

  AudioPlayer get _audioPlayer => _player ??= AudioPlayer();

  bool get isPlaying => _isTest ? _mockPlaying : (_player?.playing ?? false);
  FocusMusicTrack? _currentTrack;

  FocusMusicTrack? get currentTrack => _currentTrack;

  Future<bool> play(String assetPath) async {
    if (_disposed) return false;
    if (_isTest) {
      _mockPlaying = true;
      _currentTrack = FocusMusicTrack.tracks.firstWhere(
        (t) => t.assetPath == assetPath,
        orElse: () => FocusMusicTrack.tracks.first,
      );
      return true;
    }
    try {
      final p = _audioPlayer;
      await p.stop();
      await p.setAsset(assetPath);
      await p.setLoopMode(LoopMode.all);
      await p.play();
      _currentTrack = FocusMusicTrack.tracks.firstWhere(
        (t) => t.assetPath == assetPath,
        orElse: () => FocusMusicTrack.tracks.first,
      );
      return true;
    } on FileSystemException {
      return false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pause() async {
    if (_disposed) return false;
    if (_isTest) {
      _mockPlaying = false;
      return true;
    }
    try {
      await _player?.pause();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resume() async {
    if (_disposed) return false;
    if (_isTest) {
      _mockPlaying = true;
      return true;
    }
    try {
      await _player?.play();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stop() async {
    if (_disposed) return false;
    if (_isTest) {
      _mockPlaying = false;
      _currentTrack = null;
      return true;
    }
    try {
      await _player?.stop();
      _currentTrack = null;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isPlayingTrack() async {
    if (_disposed) return false;
    if (_isTest) return _mockPlaying;
    try {
      return _player?.playing ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> dispose() async {
    _disposed = true;
    if (_isTest) {
      _mockPlaying = false;
      return true;
    }
    try {
      await _player?.dispose();
      return true;
    } catch (_) {
      return false;
    }
  }
}
