import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/practice_session.dart';
import '../../data/models/practice_set.dart';
import '../../data/models/question.dart';
import '../auth/auth_service.dart';

/// Manages interactive practice questions and practice sets.
///
/// Follows the established controller pattern: a ChangeNotifier singleton
/// persisting user-isolated data via [StorageService] with offline-first support.
class PracticeQuestionController extends ChangeNotifier {
  PracticeQuestionController._();

  static final PracticeQuestionController instance =
      PracticeQuestionController._();

  static const _questionsKey = 'academic_questions';
  static const _setsKey = 'academic_practice_sets';

  List<Question> _questions = [];
  List<PracticeSet> _practiceSets = [];
  bool _loaded = false;
  bool _disposed = false;

  List<Question> get questions => List.unmodifiable(_questions);
  List<PracticeSet> get practiceSets => List.unmodifiable(_practiceSets);
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown.
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  void clearData() {
    _questions.clear();
    _practiceSets.clear();
    _loaded = false;
    notifyListeners();
  }

  List<Question> questionsForTopic(String topicId) {
    return _questions
        .where((q) => q.topicId == topicId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<Question> questionsForChapter(String chapterId) {
    return _questions
        .where((q) => q.chapterId == chapterId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<Question> questionsForSubject(String subjectId) {
    return _questions
        .where((q) => q.subjectId == subjectId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<PracticeSet> practiceSetsForTopic(String topicId) {
    return _practiceSets
        .where((s) => s.topicId == topicId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<PracticeSet> practiceSetsForSubject(String subjectId) {
    return _practiceSets
        .where((s) => s.subjectId == subjectId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  bool hasQuestionsForTopic(String topicId) {
    return _questions.any((q) => q.topicId == topicId);
  }

  bool hasQuestionsForSubject(String subjectId) {
    return _questions.any((q) => q.subjectId == subjectId);
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
      _questions = [];
      _practiceSets = [];
      return;
    }

    final qList = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _questionsKey,
    );
    if (qList != null) {
      _questions = qList
          .whereType<Map<String, dynamic>>()
          .map((j) {
            try {
              return Question.fromJson(j);
            } catch (_) {
              return null;
            }
          })
          .whereType<Question>()
          .toList();
    } else {
      _questions = [];
    }

    final sList = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _setsKey,
    );
    if (sList != null) {
      _practiceSets = sList
          .whereType<Map<String, dynamic>>()
          .map((j) {
            try {
              return PracticeSet.fromJson(j);
            } catch (_) {
              return null;
            }
          })
          .whereType<PracticeSet>()
          .toList();
    } else {
      _practiceSets = [];
    }
  }

  Future<void> _saveLocal() async {
    final uid = _userId;
    if (uid == null) return;

    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _questionsKey,
      list: _questions.map((q) => q.toJson()).toList(),
    );
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _setsKey,
      list: _practiceSets.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> _attemptCloudLoad() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      final qResponse = await client
          .from('academic_questions')
          .select()
          .eq('user_id', uid);
      if (qResponse.isNotEmpty) {
        _questions = qResponse.map((j) => Question.fromJson(j)).toList();
      }

      final sResponse = await client
          .from('academic_practice_sets')
          .select()
          .eq('user_id', uid);
      if (sResponse.isNotEmpty) {
        _practiceSets = sResponse.map((j) => PracticeSet.fromJson(j)).toList();
      }

      await _saveLocal();
      if (!_disposed) notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PracticeQuestionController] Cloud load failed: $e');
      }
    }
  }

  Future<Question> addQuestion({
    required String topicId,
    String? chapterId,
    required String subjectId,
    required String questionText,
    QuestionType type = QuestionType.multipleChoice,
    List<String> options = const [],
    required String correctAnswer,
    String? explanation,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
  }) async {
    final now = DateTime.now();
    final question = Question(
      id: 'q_${now.millisecondsSinceEpoch}_${_questions.length + 1}',
      topicId: topicId,
      chapterId: chapterId,
      subjectId: subjectId,
      questionText: questionText.trim(),
      type: type,
      options: options,
      correctAnswer: correctAnswer.trim(),
      explanation: explanation?.trim().isNotEmpty == true ? explanation!.trim() : null,
      difficulty: difficulty,
      userId: _userId,
      createdAt: now,
      updatedAt: now,
    );

    _questions.add(question);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    return question;
  }

  Future<void> updateQuestion(Question updated) async {
    final index = _questions.indexWhere((q) => q.id == updated.id);
    if (index < 0) return;
    _questions[index] = updated;
    await _saveLocal();
    if (!_disposed) notifyListeners();
  }

  Future<void> deleteQuestion(String id) async {
    _questions.removeWhere((q) => q.id == id);
    for (int i = 0; i < _practiceSets.length; i++) {
      if (_practiceSets[i].questionIds.contains(id)) {
        final updatedIds = List<String>.from(_practiceSets[i].questionIds)
          ..remove(id);
        _practiceSets[i] = _practiceSets[i].copyWith(questionIds: updatedIds);
      }
    }
    await _saveLocal();
    if (!_disposed) notifyListeners();
  }

  Future<PracticeSet> createPracticeSet({
    required String title,
    String? topicId,
    String? chapterId,
    String? subjectId,
    List<String> questionIds = const [],
    int estimatedMinutes = 15,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
  }) async {
    final now = DateTime.now();
    final set = PracticeSet(
      id: 'set_${now.millisecondsSinceEpoch}_${_practiceSets.length + 1}',
      title: title.trim(),
      topicId: topicId,
      chapterId: chapterId,
      subjectId: subjectId,
      questionIds: questionIds,
      estimatedMinutes: estimatedMinutes,
      difficulty: difficulty,
      userId: _userId,
      createdAt: now,
      updatedAt: now,
    );

    _practiceSets.add(set);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    return set;
  }

  Future<void> deletePracticeSet(String id) async {
    _practiceSets.removeWhere((s) => s.id == id);
    await _saveLocal();
    if (!_disposed) notifyListeners();
  }

  /// Creates an active [PracticeSession] initialized with available questions.
  PracticeSession createSession({
    required String topicId,
    String? chapterId,
    String? subjectId,
    String? title,
    int? questionLimit,
    PracticeFeedbackMode feedbackMode = PracticeFeedbackMode.learning,
    List<Question>? customQuestions,
  }) {
    List<Question> pool;
    if (customQuestions != null && customQuestions.isNotEmpty) {
      pool = List.from(customQuestions);
    } else {
      pool = questionsForTopic(topicId);
      if (pool.isEmpty && subjectId != null) {
        pool = questionsForSubject(subjectId);
      }
    }

    if (questionLimit != null && questionLimit > 0 && pool.length > questionLimit) {
      pool = pool.take(questionLimit).toList();
    }

    final now = DateTime.now();
    return PracticeSession(
      id: 'psess_${now.millisecondsSinceEpoch}',
      userId: _userId,
      topicId: topicId,
      chapterId: chapterId,
      subjectId: subjectId,
      title: title ?? (pool.isNotEmpty ? 'Practice Session' : 'Empty Practice'),
      questions: pool,
      feedbackMode: feedbackMode,
      startedAt: now,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
