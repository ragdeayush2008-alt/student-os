import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/streak_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/topic_practice_attempt.dart';
import '../../data/models/xp_event.dart';
import '../auth/auth_service.dart';
import '../progression/progression_controller.dart';

/// Manages topic practice attempts for the Learning Experience.
///
/// Follows the established controller pattern: a ChangeNotifier singleton
/// persisting user-scoped data through [StorageService] with offline-first support,
/// deterministic XP awarding via [ProgressionController], and user isolation.
class TopicPracticeController extends ChangeNotifier {
  TopicPracticeController._();

  static final TopicPracticeController instance = TopicPracticeController._();

  static const _storageKey = 'topic_practice_attempts';

  List<TopicPracticeAttempt> _attempts = [];
  bool _loaded = false;
  bool _disposed = false;

  List<TopicPracticeAttempt> get attempts => List.unmodifiable(_attempts);
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown.
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  void clearData() {
    _attempts.clear();
    _loaded = false;
    notifyListeners();
  }

  List<TopicPracticeAttempt> attemptsForTopic(String topicId) {
    return _attempts
        .where((a) => a.topicId == topicId)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  List<TopicPracticeAttempt> attemptsForSubject(String subjectId) {
    return _attempts
        .where((a) => a.subjectId == subjectId)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  List<TopicPracticeAttempt> attemptsForChapter(String chapterId) {
    return _attempts
        .where((a) => a.chapterId == chapterId)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  int practiceMinutesForTopic(String topicId) {
    final topicAttempts = attemptsForTopic(topicId);
    final totalSec =
        topicAttempts.fold<int>(0, (sum, a) => sum + a.durationSec);
    return totalSec ~/ 60;
  }

  int practiceMinutesForSubject(String subjectId) {
    final subjAttempts = attemptsForSubject(subjectId);
    final totalSec =
        subjAttempts.fold<int>(0, (sum, a) => sum + a.durationSec);
    return totalSec ~/ 60;
  }

  int totalQuestionsAttemptedForTopic(String topicId) {
    final topicAttempts = attemptsForTopic(topicId);
    return topicAttempts.fold<int>(
      0,
      (sum, a) => sum + (a.totalQuestions ?? 0),
    );
  }

  int totalCorrectAnswersForTopic(String topicId) {
    final topicAttempts = attemptsForTopic(topicId);
    return topicAttempts.fold<int>(
      0,
      (sum, a) => sum + (a.correctAnswers ?? 0),
    );
  }

  DateTime? lastPracticedDateForTopic(String topicId) {
    final topicAttempts = attemptsForTopic(topicId);
    return topicAttempts.firstOrNull?.startedAt;
  }

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
      _attempts = [];
      return;
    }
    final list = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _storageKey,
    );
    if (list != null) {
      _attempts = list
          .whereType<Map<String, dynamic>>()
          .map((j) {
            try {
              return TopicPracticeAttempt.fromJson(j);
            } catch (_) {
              return null;
            }
          })
          .whereType<TopicPracticeAttempt>()
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } else {
      _attempts = [];
    }
  }

  Future<void> _saveLocal() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _storageKey,
      list: _attempts.map((a) => a.toJson()).toList(),
    );
  }

  Future<void> _attemptCloudLoad() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      final response = await client
          .from('topic_practice_attempts')
          .select()
          .eq('user_id', uid)
          .order('started_at', ascending: false);
      if (response.isNotEmpty) {
        _attempts = response
            .map((j) => TopicPracticeAttempt.fromJson(j))
            .toList();
        await _saveLocal();
        if (!_disposed) notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TopicPracticeController] Cloud load failed: $e');
      }
    }
  }

  Future<void> _attemptCloudSave() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      await client.from('topic_practice_attempts').upsert(
            _attempts
                .map((a) => {...a.toJson(), 'user_id': uid})
                .toList(),
          );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TopicPracticeController] Cloud save failed: $e');
      }
    }
  }

  /// Records a completed practice attempt, persists it, and awards XP idempotently.
  Future<TopicPracticeAttempt> recordAttempt({
    required String topicId,
    String? subjectId,
    String? chapterId,
    DateTime? startedAt,
    DateTime? completedAt,
    int durationSec = 0,
    int? totalQuestions,
    int? correctAnswers,
    int? incorrectAnswers,
    double? score,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final attempt = TopicPracticeAttempt(
      id: 'prac_${now.millisecondsSinceEpoch}_${_attempts.length + 1}',
      userId: _userId,
      topicId: topicId,
      subjectId: subjectId,
      chapterId: chapterId,
      startedAt: startedAt ?? now.subtract(Duration(seconds: durationSec)),
      completedAt: completedAt ?? now,
      durationSec: durationSec,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      score: score,
      notes: notes,
    );

    _attempts.insert(0, attempt);
    await _saveLocal();
    if (!_disposed) notifyListeners();

    // Deterministic XP award (15-25 XP per completed practice attempt)
    final xpAmount = (durationSec >= 600 || (totalQuestions ?? 0) >= 5) ? 25 : 15;
    await ProgressionController.instance.recordEvent(
      XpEvent(
        id: 'xp_practice_${attempt.id}',
        type: XpEventType.studySessionCompleted,
        amount: xpAmount,
        reason: 'Completed practice session on topic',
        subjectId: subjectId,
        timestamp: now,
      ),
    );

    // Refresh streaks
    StreakService.instance.refresh();

    _attemptCloudSave();
    return attempt;
  }

  Future<void> deleteAttempt(String id) async {
    _attempts.removeWhere((a) => a.id == id);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
