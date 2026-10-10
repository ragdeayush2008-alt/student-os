import '../../core/auth/auth_isolation.dart';
import '../auth/auth_service.dart';

import '../../core/services/storage_service.dart';

import 'package:flutter/foundation.dart';

/// A derived progress snapshot for a single goal, pairing [current] activity
/// against a user-defined [target]. Purely computed — never persisted directly.
@immutable
class GoalProgress {
  const GoalProgress({
    required this.current,
    required this.target,
    required this.label,
    required this.unit,
  });

  final double current;
  final double target;
  final String label;
  final String unit;

  /// Clamped fraction 0.0–1.0.
  double get fraction => target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

  /// Remaining amount before the target is hit (floored at 0).
  double get remaining =>
      (target - current).clamp(0.0, 1.7976931348623157e+308);

  bool get isComplete => target > 0 && current >= target;
  bool get hasData => current > 0;
  bool get hasTarget => target > 0;

  /// A human-readable progress summary, e.g. "6h 40m / 10h" or "7 / 10 tasks".
  String get summary {
    final cur = _formatAmount(current, unit);
    final tgt = _formatAmount(target, unit);
    // For countable units like "tasks", omit the unit from the current value.
    if (unit != 'h' && unit != 'm' && unit.isNotEmpty) {
      return '${current.round()} / $tgt';
    }
    return '$cur / $tgt';
  }

  static String _formatAmount(double value, String unit) {
    if (unit == 'h') {
      final hours = value.floor();
      final mins = ((value - hours) * 60).round();
      if (hours == 0) return '${mins}m';
      return mins == 0 ? '${hours}h' : '${hours}h ${mins}m';
    }
    if (unit == 'm') {
      final mins = value.round();
      if (mins >= 60) {
        final h = mins ~/ 60;
        final m = mins % 60;
        return m == 0 ? '${h}h' : '${h}h ${m}m';
      }
      return '${mins}m';
    }
    return '${value.round()} $unit';
  }
}

/// Manages user-defined study and productivity targets.
///
/// A thin, user-scoped [ChangeNotifier] singleton that persists via
/// [StorageService]. Progress toward these targets is derived at call-site
/// from [StudyController] and [TaskController] — this controller stores only
/// the targets, never duplicating activity data.
class GoalController extends ChangeNotifier {
  GoalController._();

  /// Clears in-memory state without touching persistent storage.
  void clearData() {
    _weeklyStudyTarget = Duration.zero;
    _weeklyTaskTarget = 0;
    _dailyStudyTarget = Duration.zero;
    _personalGoal = '';
    notifyListeners();
  }

  static final GoalController instance = GoalController._();

  static const _goalsKey = 'user_goals';

  Duration _dailyStudyTarget = const Duration(minutes: 120);
  Duration _weeklyStudyTarget = const Duration(hours: 10);
  int _weeklyTaskTarget = 10;
  String _personalGoal = '';

  bool _loaded = false;
  bool _disposed = false;

  Duration get dailyStudyTarget => _dailyStudyTarget;
  Duration get weeklyStudyTarget => _weeklyStudyTarget;
  int get weeklyTaskTarget => _weeklyTaskTarget;
  String get personalGoal => _personalGoal;
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  // ─── Loading / persistence ───────────────────────────────────────────

  Future<void> load() async {
    // Local-first: load as soon as ANY identity is known (AuthService or
    // isolation session) so cached local data never waits on the network.
    if (!AuthService.instance.isAuthenticated &&
        !AuthIsolation.instance.isAuthenticated) {
      return;
    }
    final uid = _userId;
    if (uid == null) return;
    final json = await StorageService.instance.loadJson(
      userId: uid,
      key: _goalsKey,
    );
    if (json != null) {
      _dailyStudyTarget = Duration(
        minutes: (json['dailyStudyMinutes'] as int?) ?? 120,
      );
      _weeklyStudyTarget = Duration(
        minutes: (json['weeklyStudyMinutes'] as int?) ?? 600,
      );
      _weeklyTaskTarget = (json['weeklyTaskTarget'] as int?) ?? 10;
      _personalGoal = (json['personalGoal'] as String?) ?? '';
    }
    _loaded = true;
    if (!_disposed) notifyListeners();
  }

  Future<void> _save() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJson(
      userId: uid,
      key: _goalsKey,
      json: {
        'dailyStudyMinutes': _dailyStudyTarget.inMinutes,
        'weeklyStudyMinutes': _weeklyStudyTarget.inMinutes,
        'weeklyTaskTarget': _weeklyTaskTarget,
        'personalGoal': _personalGoal,
      },
    );
  }

  // ─── Mutations ───────────────────────────────────────────────────────

  Future<void> setDailyStudyTarget(Duration target) async {
    if (target == _dailyStudyTarget) return;
    _dailyStudyTarget = target;
    notifyListeners();
    await _save();
  }

  Future<void> setWeeklyStudyTarget(Duration target) async {
    if (target == _weeklyStudyTarget) return;
    _weeklyStudyTarget = target;
    notifyListeners();
    await _save();
  }

  Future<void> setWeeklyTaskTarget(int target) async {
    final clamped = target.clamp(0, 100);
    if (clamped == _weeklyTaskTarget) return;
    _weeklyTaskTarget = clamped;
    notifyListeners();
    await _save();
  }

  Future<void> setPersonalGoal(String goal) async {
    final trimmed = goal.trim();
    if (trimmed == _personalGoal) return;
    _personalGoal = trimmed;
    notifyListeners();
    await _save();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
