import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/leaderboard_service.dart';
import '../../core/services/ranking_engine.dart';
import '../../core/services/streak_service.dart';
import '../../core/services/student_service.dart';
import '../../data/models/leaderboard_entry.dart';
import '../notifications/notification_controller.dart';
import 'progression_controller.dart';

/// Sync and network connectivity status for the Leaderboard.
enum LeaderboardSyncStatus {
  /// Initial loading of leaderboard data.
  loading,

  /// Successfully fetched live rankings from cloud.
  live,

  /// Online request failed or unavailable; displaying cached/local rankings.
  offlineFallback,

  /// No data available and cache is empty.
  unavailable,

  /// Remote query failed with a non-network error (schema/RLS/auth).
  remoteError,

  /// Authentication is required to fetch live rankings.
  authRequired,
}

/// Central controller for the Leaderboard ecosystem.
///
/// Responsibilities:
/// - Manages selected period (`thisWeek`, `thisMonth`, `allTime`)
/// - Reuses existing [ProgressionController] as the single source of truth for XP
/// - Derives rankings deterministically via [RankingEngine] and [LeaderboardService]
/// - Provides offline caching, stale indicators, loading, error, and empty states
/// - Maintains strict user isolation across sessions
class LeaderboardController extends ChangeNotifier {
  LeaderboardController._();

  static final LeaderboardController instance = LeaderboardController._();

  LeaderboardPeriod _period = LeaderboardPeriod.thisWeek;
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = false;
  bool _isOffline = false;
  bool _isStale = false;
  String? _errorMessage;
  String? _remoteError;
  DateTime? _lastRefreshed;
  bool _loaded = false;
  bool _disposed = false;
  bool _listeningToUpstream = false;
  bool _authRequired = false;

  // ─── Getters ────────────────────────────────────────────────────────────

  LeaderboardPeriod get period => _period;
  List<LeaderboardEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  bool get isStale => _isStale;
  bool get isLive => !_isOffline && _loaded && !_isLoading;
  String? get errorMessage => _errorMessage;
  String? get remoteError => _remoteError;
  DateTime? get lastRefreshed => _lastRefreshed;
  bool get isLoaded => _loaded;
  bool get hasEntries => _entries.isNotEmpty;
  bool get authRequired => _authRequired;

  /// Honest sync status distinguishing live, offline fallback, loading, and unavailable.
  LeaderboardSyncStatus get syncStatus {
    if (_authRequired && !_loaded) return LeaderboardSyncStatus.authRequired;
    if (_isLoading && !_loaded) return LeaderboardSyncStatus.loading;
    if (_entries.isEmpty) return LeaderboardSyncStatus.unavailable;
    if (_remoteError != null && _remoteError != 'supabase_not_ready') {
      return LeaderboardSyncStatus.remoteError;
    }
    if (!_isOffline) return LeaderboardSyncStatus.live;
    return LeaderboardSyncStatus.offlineFallback;
  }

  /// The entry representing the current active student.
  LeaderboardEntry? get currentUserEntry {
    for (final e in _entries) {
      if (e.isCurrentUser) return e;
    }
    // Fallback: create entry on the fly if not yet populated
    if (_loaded) {
      return LeaderboardService.instance.createCurrentUserEntry(_period);
    }
    return null;
  }

  /// The top 3 podium entries (up to 3).
  List<LeaderboardEntry> get topPodium => _entries.take(3).toList();

  /// Entries beyond the top 3 podium.
  List<LeaderboardEntry> get rankingList =>
      _entries.length > 3 ? _entries.sublist(3) : const [];

  // ─── Upstream Listeners ──────────────────────────────────────────────────

  void _setupUpstreamListeners() {
    if (_listeningToUpstream) return;
    _listeningToUpstream = true;
    ProgressionController.instance.addListener(_onProgressionChanged);
    StudentService.instance.addListener(_onProfileChanged);
    StreakService.instance.addListener(_onStreakChanged);
  }

  void _onProgressionChanged() {
    if (_loaded && !_isLoading) {
      _recomputeLocally();
      // Sync progression change to cloud in background
      LeaderboardService.instance.syncCurrentUserProgression();
    }
  }

  void _onProfileChanged() {
    if (_loaded && !_isLoading) {
      _recomputeLocally();
    }
  }

  void _onStreakChanged() {
    if (_loaded && !_isLoading) {
      _recomputeLocally();
    }
  }

  // ─── Recompute Local User State ──────────────────────────────────────────

  void _recomputeLocally() {
    final userEntry = LeaderboardService.instance.createCurrentUserEntry(
      _period,
      previousRank: currentUserEntry?.previousRank,
    );

    final updated = <LeaderboardEntry>[];
    var found = false;
    for (final e in _entries) {
      if (e.isCurrentUser || e.userId == userEntry.userId) {
        updated.add(userEntry);
        found = true;
      } else {
        updated.add(e);
      }
    }
    if (!found) {
      updated.add(userEntry);
    }

    _entries = RankingEngine.rankEntries(updated);

    if (!_disposed) notifyListeners();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  /// Changes the active period and resolves rankings.
  Future<void> setPeriod(LeaderboardPeriod newPeriod) async {
    if (_period == newPeriod && _loaded) return;
    _period = newPeriod;
    if (!_disposed) notifyListeners();
    await refresh();
  }

  /// Loads initial state from local cache, then triggers a background refresh.
  Future<void> load() async {
    _setupUpstreamListeners();

    // 1. Instant load from local cache
    try {
      final cached = await LeaderboardService.instance.loadCachedEntries(_period);
      if (cached.isNotEmpty) {
        _entries = cached;
        _isStale = true;
      } else {
        // Build initial local user entry
        final local = LeaderboardService.instance.createCurrentUserEntry(_period);
        _entries = [local];
      }
    } catch (_) {
      final local = LeaderboardService.instance.createCurrentUserEntry(_period);
      _entries = [local];
    }

    _loaded = true;
    if (!_disposed) notifyListeners();

    // 2. Fresh resolution
    await refresh();
  }

  /// Refreshes leaderboard rankings from the cloud or local store.
  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _remoteError = null;
    _authRequired = false;
    if (!_disposed) notifyListeners();

    try {
      final oldEntry = currentUserEntry;
      final result = await LeaderboardService.instance.resolveLeaderboard(_period);
      _entries = result.entries;
      final newEntry = currentUserEntry;

      if (oldEntry != null &&
          newEntry != null &&
          oldEntry.rank > newEntry.rank &&
          oldEntry.rank > 0 &&
          newEntry.rank > 0) {
        NotificationController.instance.onLeaderboardRankChanged(
          _period,
          oldEntry.rank,
          newEntry.rank,
        );
      }

      _isOffline = result.isOffline;
      _isStale = result.isStale;
      _remoteError = result.remoteError;
      _authRequired = result.remoteError == 'auth_required';
      _lastRefreshed = DateTime.now();
      _errorMessage = null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LeaderboardController] Refresh error: $e');
      }
      _errorMessage = 'Could not refresh rankings. Showing cached data.';
      _isOffline = true;
    } finally {
      _isLoading = false;
      _loaded = true;
      if (!_disposed) notifyListeners();
    }
  }

  /// Clears in-memory state on session change or logout.
  void clearData() {
    _entries.clear();
    _isLoading = false;
    _isOffline = false;
    _isStale = false;
    _errorMessage = null;
    _remoteError = null;
    _authRequired = false;
    _lastRefreshed = null;
    _loaded = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_listeningToUpstream) {
      ProgressionController.instance.removeListener(_onProgressionChanged);
      StudentService.instance.removeListener(_onProfileChanged);
      StreakService.instance.removeListener(_onStreakChanged);
      _listeningToUpstream = false;
    }
    super.dispose();
  }
}
