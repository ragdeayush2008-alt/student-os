import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/streak_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/revision_record.dart';
import '../../data/models/revision_schedule.dart';
import '../../data/models/xp_event.dart';
import '../auth/auth_service.dart';
import '../progression/progression_controller.dart';

/// Manages spaced revision schedules and completed revision records.
///
/// Follows the established controller pattern: a ChangeNotifier singleton
/// persisting user-isolated data via [StorageService] with offline-first support,
/// deterministic XP awarding, and user isolation.
class RevisionController extends ChangeNotifier {
  RevisionController._();

  static final RevisionController instance = RevisionController._();

  static const _recordsKey = 'academic_revision_records';
  static const _schedulesKey = 'academic_revision_schedules';

  List<RevisionRecord> _records = [];
  List<RevisionSchedule> _schedules = [];
  bool _loaded = false;
  bool _disposed = false;

  List<RevisionRecord> get records => List.unmodifiable(_records);
  List<RevisionSchedule> get schedules => List.unmodifiable(_schedules);
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown.
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  void clearData() {
    _records.clear();
    _schedules.clear();
    _loaded = false;
    notifyListeners();
  }

  List<RevisionRecord> recordsForTopic(String topicId) {
    return _records
        .where((r) => r.topicId == topicId)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<RevisionRecord> recordsForSubject(String subjectId) {
    return _records
        .where((r) => r.subjectId == subjectId)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  RevisionSchedule? scheduleForTopic(String topicId) {
    return _schedules.where((s) => s.topicId == topicId).firstOrNull;
  }

  RevisionRecord? lastRecordForTopic(String topicId) {
    return recordsForTopic(topicId).firstOrNull;
  }

  int get totalRevisionMinutes {
    final sec = _records.fold<int>(0, (sum, r) => sum + r.durationSec);
    return sec ~/ 60;
  }

  int get completedRevisionSessionsCount => _records.length;

  Future<void> load() async {
    if (!AuthService.instance.isAuthenticated &&
        !AuthIsolation.instance.isAuthenticated) {
      return;
    }
    await _loadLocal();
    _loaded = true;
    if (!_disposed) notifyListeners();
    _attemptCloudLoad();
  }

  Future<void> _loadLocal() async {
    final uid = _userId;
    if (uid == null) {
      _records = [];
      _schedules = [];
      return;
    }

    final recList = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _recordsKey,
    );
    if (recList != null) {
      _records = recList
          .whereType<Map<String, dynamic>>()
          .map((j) {
            try {
              return RevisionRecord.fromJson(j);
            } catch (_) {
              return null;
            }
          })
          .whereType<RevisionRecord>()
          .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    } else {
      _records = [];
    }

    final schedList = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _schedulesKey,
    );
    if (schedList != null) {
      _schedules = schedList
          .whereType<Map<String, dynamic>>()
          .map((j) {
            try {
              return RevisionSchedule.fromJson(j);
            } catch (_) {
              return null;
            }
          })
          .whereType<RevisionSchedule>()
          .toList();
    } else {
      _schedules = [];
    }
  }

  Future<void> _saveLocal() async {
    final uid = _userId;
    if (uid == null) return;

    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _recordsKey,
      list: _records.map((r) => r.toJson()).toList(),
    );
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _schedulesKey,
      list: _schedules.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> _attemptCloudLoad() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      final recResponse = await client
          .from('academic_revision_records')
          .select()
          .eq('user_id', uid)
          .order('completed_at', ascending: false);
      if (recResponse.isNotEmpty) {
        _records = recResponse.map((j) => RevisionRecord.fromJson(j)).toList();
      }

      final schedResponse = await client
          .from('academic_revision_schedules')
          .select()
          .eq('user_id', uid);
      if (schedResponse.isNotEmpty) {
        _schedules = schedResponse.map((j) => RevisionSchedule.fromJson(j)).toList();
      }

      await _saveLocal();
      if (!_disposed) notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RevisionController] Cloud load failed: $e');
      }
    }
  }

  /// Records a completed revision session, updates the spaced schedule, and awards XP.
  Future<RevisionRecord> recordRevision({
    required String topicId,
    String? chapterId,
    String? subjectId,
    String? examId,
    DateTime? startedAt,
    DateTime? completedAt,
    int durationSec = 0,
    RevisionRecallOutcome recallOutcome = RevisionRecallOutcome.unassessed,
    String notes = '',
    String source = 'session',
  }) async {
    final now = completedAt ?? DateTime.now();
    final record = RevisionRecord(
      id: 'rev_${now.millisecondsSinceEpoch}_${_records.length + 1}',
      userId: _userId,
      topicId: topicId,
      chapterId: chapterId,
      subjectId: subjectId,
      examId: examId,
      startedAt: startedAt ?? now.subtract(Duration(seconds: durationSec)),
      completedAt: now,
      durationSec: durationSec,
      recallOutcome: recallOutcome,
      notes: notes,
      source: source,
    );

    _records.insert(0, record);

    // Update or create Spaced Schedule
    _updateScheduleOnRevision(
      topicId: topicId,
      chapterId: chapterId,
      subjectId: subjectId,
      examId: examId,
      outcome: recallOutcome,
      completionTime: now,
      durationSec: durationSec,
    );

    await _saveLocal();
    if (!_disposed) notifyListeners();

    // Idempotent XP award (15-25 XP)
    final xpAmount = (durationSec >= 600 || recallOutcome == RevisionRecallOutcome.knew) ? 25 : 15;
    await ProgressionController.instance.recordEvent(
      XpEvent(
        id: 'xp_revision_${record.id}',
        type: XpEventType.studySessionCompleted,
        amount: xpAmount,
        reason: 'Completed spaced revision on topic',
        subjectId: subjectId,
        timestamp: now,
      ),
    );

    // Refresh streak
    StreakService.instance.refresh();

    return record;
  }

  /// Calculates and updates next interval using the Spaced Repetition 2.0 rules.
  void _updateScheduleOnRevision({
    required String topicId,
    String? chapterId,
    String? subjectId,
    String? examId,
    required RevisionRecallOutcome outcome,
    required DateTime completionTime,
    int durationSec = 0,
  }) {
    final existing = scheduleForTopic(topicId);
    int revCount = (existing?.revisionCount ?? 0) + 1;
    int successCount = existing?.successfulRecallCount ?? 0;
    int failCount = existing?.failedRecallCount ?? 0;
    double ease = existing?.easeFactor ?? 2.5;

    int newInterval;
    RevisionState newState;

    if (outcome == RevisionRecallOutcome.forgot) {
      failCount++;
      newInterval = 1;
      ease = math.max(1.3, ease - 0.2);
      newState = RevisionState.learning;
    } else if (outcome == RevisionRecallOutcome.partial) {
      newInterval = math.max(2, (existing?.intervalDays ?? 1));
      ease = math.max(1.3, ease - 0.1);
      newState = RevisionState.learning;
    } else {
      successCount++;
      ease = math.min(3.0, ease + 0.1);
      if (revCount <= 1) {
        newInterval = 3;
        newState = RevisionState.learning;
      } else if (revCount == 2) {
        newInterval = 7;
        newState = RevisionState.stable;
      } else if (revCount == 3) {
        newInterval = 14;
        newState = RevisionState.strong;
      } else {
        newInterval = ((existing?.intervalDays ?? 14) * ease).round().clamp(14, 90);
        newState = RevisionState.mastered;
      }
    }

    final nextRevision = completionTime.add(Duration(days: newInterval));

    final updatedSchedule = (existing ?? RevisionSchedule(
      id: 'rev_sched_$topicId',
      userId: _userId,
      topicId: topicId,
      chapterId: chapterId,
      subjectId: subjectId,
      examId: examId,
    )).copyWith(
      state: newState,
      intervalDays: newInterval,
      lastRevisionAt: completionTime,
      nextRevisionAt: nextRevision,
      revisionCount: revCount,
      successfulRecallCount: successCount,
      failedRecallCount: failCount,
      easeFactor: ease,
    );

    final idx = _schedules.indexWhere((s) => s.topicId == topicId);
    if (idx >= 0) {
      _schedules[idx] = updatedSchedule;
    } else {
      _schedules.add(updatedSchedule);
    }
  }

  /// Sets or updates schedule directly (e.g. from recall evaluation).
  Future<void> updateSchedule(RevisionSchedule schedule) async {
    final idx = _schedules.indexWhere((s) => s.topicId == schedule.topicId);
    if (idx >= 0) {
      _schedules[idx] = schedule;
    } else {
      _schedules.add(schedule);
    }
    await _saveLocal();
    if (!_disposed) notifyListeners();
  }

  /// Deletes a revision record.
  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _saveLocal();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
