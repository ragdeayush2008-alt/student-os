import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../features/auth/auth_service.dart';
import 'models/guide_models.dart';

/// User-scoped persistence for the guide system (learning layer only).
///
/// Keys are namespaced (`guide_*_v1`) and never touch other features' keys.
/// Storage is keyed by resolved user id; logged-out state is memory-only.
class GuideProgressStore extends ChangeNotifier {
  GuideProgressStore._();

  static final GuideProgressStore instance = GuideProgressStore._();

  static const _progressKey = 'guide_progress_v1';
  static const _tourKey = 'guide_tour_v1';
  static const _tourOfferKey = 'guide_tour_offer_v1';

  Map<String, GuideProgress> _progress = {};
  bool _loaded = false;
  final bool _disposed = false;
  String? _tourState;
  bool _tourOfferPending = false;

  bool get isLoaded => _loaded;

  /// 'completed' | 'skipped' | null.
  String? get tourState => _tourState;

  /// True when onboarding just finished and Home should offer the tour once.
  bool get tourOfferPending => _tourOfferPending;

  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  GuideProgress progressOf(String guideId) =>
      _progress[guideId] ?? const GuideProgress();

  Map<String, GuideProgress> get all => Map.unmodifiable(_progress);

  void clearData() {
    _progress = {};
    _tourState = null;
    _tourOfferPending = false;
    _loaded = false;
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      _progress = {};
      _tourState = null;
      _loaded = true;
      if (!_disposed) {
        notifyListeners();
      }
      return;
    }
    try {
      final json = await StorageService.instance.loadJson(
        userId: uid,
        key: _progressKey,
      );
      final map = <String, GuideProgress>{};
      if (json != null) {
        for (final entry in json.entries) {
          if (entry.value is Map<String, dynamic>) {
            try {
              map[entry.key] = GuideProgress.fromJson(
                Map<String, dynamic>.from(entry.value as Map),
              );
            } catch (_) {
              // Tolerant: skip corrupt entries, keep the rest.
            }
          }
        }
      }
      _progress = map;
      _tourState = await StorageService.instance.loadString(
        userId: uid,
        key: _tourKey,
      );
      _tourOfferPending = await StorageService.instance.loadBool(
        userId: uid,
        key: _tourOfferKey,
      );
    } catch (_) {
      _progress = {};
      _tourState = null;
    } finally {
      _loaded = true;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<void> _persist() async {
    final uid = _userId;
    if (uid == null) {
      return;
    }
    try {
      await StorageService.instance.saveJson(
        userId: uid,
        key: _progressKey,
        json: _progress.map((k, v) => MapEntry(k, v.toJson())),
      );
      if (_tourState != null) {
        await StorageService.instance.saveString(
          userId: uid,
          key: _tourKey,
          value: _tourState!,
        );
      }
    } catch (_) {
      // Best-effort; in-memory state still applies.
    }
  }

  Future<void> saveProgress(String guideId, GuideProgress progress) async {
    _progress[guideId] = progress;
    if (!_disposed) {
      notifyListeners();
    }
    await _persist();
  }

  Future<void> setTourState(String state) async {
    _tourState = state;
    if (!_disposed) {
      notifyListeners();
    }
    await _persist();
  }

  Future<void> setTourOfferPending(bool pending) async {
    _tourOfferPending = pending;
    if (!_disposed) {
      notifyListeners();
    }
    final uid = _userId;
    if (uid == null) {
      return;
    }
    try {
      await StorageService.instance.saveBool(
        userId: uid,
        key: _tourOfferKey,
        value: pending,
      );
    } catch (_) {}
  }
}
