import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'practice_session_result.dart';
import 'question.dart';

/// Interactive feedback mode during a practice session.
enum PracticeFeedbackMode {
  /// Learning Mode: reveals correctness and explanation immediately after answering.
  learning('Learning Mode'),

  /// Assessment Mode: preserves student answers quietly until full submission.
  assessment('Assessment Mode');

  const PracticeFeedbackMode(this.label);
  final String label;

  static PracticeFeedbackMode fromString(String? val) {
    if (val == null || val.isEmpty) return PracticeFeedbackMode.learning;
    for (final m in PracticeFeedbackMode.values) {
      if (m.name.toLowerCase() == val.toLowerCase()) return m;
    }
    return PracticeFeedbackMode.learning;
  }
}

/// Represents an in-progress or completed question-solving practice session.
class PracticeSession extends ChangeNotifier {
  PracticeSession({
    required this.id,
    this.userId,
    this.practiceSetId,
    this.topicId,
    this.chapterId,
    this.subjectId,
    required this.title,
    required List<Question> questions,
    int currentQuestionIndex = 0,
    Map<String, String>? answers,
    Set<String>? skippedQuestionIds,
    DateTime? startedAt,
    this.completedAt,
    this.elapsedSeconds = 0,
    this.feedbackMode = PracticeFeedbackMode.learning,
    this.isCompleted = false,
  })  : _questions = List.unmodifiable(questions),
        _currentQuestionIndex = currentQuestionIndex.clamp(
          0,
          questions.isEmpty ? 0 : questions.length - 1,
        ),
        _answers = Map<String, String>.from(answers ?? {}),
        _skippedQuestionIds = Set<String>.from(skippedQuestionIds ?? {}),
        startedAt = startedAt ?? DateTime.now();

  final String id;
  final String? userId;
  final String? practiceSetId;
  final String? topicId;
  final String? chapterId;
  final String? subjectId;
  final String title;
  final List<Question> _questions;
  final PracticeFeedbackMode feedbackMode;
  final DateTime startedAt;

  int _currentQuestionIndex;
  final Map<String, String> _answers;
  final Set<String> _skippedQuestionIds;
  int elapsedSeconds;
  DateTime? completedAt;
  bool isCompleted;

  List<Question> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<String, String> get answers => Map.unmodifiable(_answers);
  Set<String> get skippedQuestionIds => Set.unmodifiable(_skippedQuestionIds);

  int get totalQuestions => _questions.length;
  bool get isEmpty => _questions.isEmpty;
  bool get isNotEmpty => _questions.isNotEmpty;

  Question? get currentQuestion {
    if (_questions.isEmpty ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= _questions.length) {
      return null;
    }
    return _questions[_currentQuestionIndex];
  }

  bool get hasPrevious => _currentQuestionIndex > 0;
  bool get hasNext => _currentQuestionIndex < _questions.length - 1;

  bool isAnswered(String questionId) => _answers.containsKey(questionId);
  bool isSkipped(String questionId) => _skippedQuestionIds.contains(questionId);
  String? selectedAnswerFor(String questionId) => _answers[questionId];

  bool get isCurrentAnswered {
    final q = currentQuestion;
    return q != null && isAnswered(q.id);
  }

  bool get isCurrentSkipped {
    final q = currentQuestion;
    return q != null && isSkipped(q.id);
  }

  /// Total count of answered questions.
  int get answeredCount => _answers.length;

  /// Total count of skipped questions.
  int get skippedCount => _skippedQuestionIds.length;

  /// Selects or answers the current question.
  void selectAnswer(String option) {
    final q = currentQuestion;
    if (q == null || isCompleted) return;

    _answers[q.id] = option;
    _skippedQuestionIds.remove(q.id);
    notifyListeners();
  }

  /// Skips the current question.
  void skipCurrent() {
    final q = currentQuestion;
    if (q == null || isCompleted) return;

    _answers.remove(q.id);
    _skippedQuestionIds.add(q.id);
    if (hasNext) {
      _currentQuestionIndex++;
    }
    notifyListeners();
  }

  /// Moves to the next question.
  bool next() {
    if (hasNext) {
      _currentQuestionIndex++;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Moves to the previous question.
  bool previous() {
    if (hasPrevious) {
      _currentQuestionIndex--;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Jumps to a specific question index.
  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  /// Updates elapsed practice time safely.
  void updateElapsedSeconds(int seconds) {
    elapsedSeconds = math.max(0, seconds);
  }

  /// Marks the session complete and produces a deterministic [PracticeSessionResult].
  PracticeSessionResult complete({DateTime? completionTime}) {
    isCompleted = true;
    completedAt = completionTime ?? DateTime.now();

    final result = computeResult(now: completedAt);
    notifyListeners();
    return result;
  }

  /// Computes the detailed result based on current state.
  PracticeSessionResult computeResult({DateTime? now}) {
    final finishedAt = now ?? completedAt ?? DateTime.now();

    int correct = 0;
    int incorrect = 0;
    final details = <QuestionResultDetail>[];

    for (final q in _questions) {
      final ans = _answers[q.id];
      final isAns = ans != null;
      final isSkp = _skippedQuestionIds.contains(q.id);
      final isCorr = isAns && q.isOptionCorrect(ans);

      if (isCorr) {
        correct++;
      } else if (isAns) {
        incorrect++;
      }

      details.add(
        QuestionResultDetail(
          question: q,
          studentAnswer: ans,
          isAnswered: isAns,
          isSkipped: isSkp,
          isCorrect: isCorr,
          correctAnswer: q.correctAnswer,
          explanation: q.explanation,
        ),
      );
    }

    final total = _questions.length;
    final int accuracy = total > 0
        ? ((correct / total) * 100).round().clamp(0, 100)
        : 0;

    final whatWentWell = <String>[];
    final needsAttention = <String>[];

    if (total == 0) {
      whatWentWell.add('Session recorded');
    } else if (correct == total) {
      whatWentWell.add('Perfect accuracy: $correct of $total correct!');
      whatWentWell.add('Strong mastery of all tested concepts.');
    } else {
      if (correct > 0) {
        whatWentWell.add('$correct of $total questions answered correctly.');
      }
      if (accuracy >= 80) {
        whatWentWell.add('Strong conceptual recall.');
      }

      if (incorrect > 0) {
        needsAttention.add('$incorrect questions missed.');
      }
      if (_skippedQuestionIds.isNotEmpty) {
        needsAttention.add('${_skippedQuestionIds.length} questions skipped.');
      }
    }

    String nextStep;
    if (accuracy >= 85) {
      nextStep = 'Strong result! Ready to advance or maintain spaced practice.';
    } else if (accuracy >= 60) {
      nextStep = 'Review mistakes and reinforce weaker concepts with a short revision.';
    } else {
      nextStep = 'Consider revising the core topic before attempting another quiz.';
    }

    return PracticeSessionResult(
      sessionId: id,
      userId: userId,
      topicId: topicId,
      chapterId: chapterId,
      subjectId: subjectId,
      title: title,
      totalQuestions: total,
      answeredCount: _answers.length,
      correctCount: correct,
      incorrectCount: incorrect,
      skippedCount: _skippedQuestionIds.length,
      accuracyPercentage: accuracy,
      durationSec: elapsedSeconds > 0
          ? elapsedSeconds
          : math.max(1, finishedAt.difference(startedAt).inSeconds),
      completedAt: finishedAt,
      details: details,
      whatWentWell: whatWentWell,
      needsAttention: needsAttention,
      recommendedNextStep: nextStep,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'userId': userId,
        if (practiceSetId != null) 'practiceSetId': practiceSetId,
        if (topicId != null) 'topicId': topicId,
        if (chapterId != null) 'chapterId': chapterId,
        if (subjectId != null) 'subjectId': subjectId,
        'title': title,
        'questions': _questions.map((q) => q.toJson()).toList(),
        'currentQuestionIndex': _currentQuestionIndex,
        'answers': _answers,
        'skippedQuestionIds': _skippedQuestionIds.toList(),
        'startedAt': startedAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'elapsedSeconds': elapsedSeconds,
        'feedbackMode': feedbackMode.name,
        'isCompleted': isCompleted,
      };

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    List<Question> parsedQuestions = const [];
    if (rawQuestions is List) {
      parsedQuestions = rawQuestions
          .whereType<Map<String, dynamic>>()
          .map((q) => Question.fromJson(q))
          .toList();
    }

    final rawAnswers = json['answers'];
    final parsedAnswers = <String, String>{};
    if (rawAnswers is Map) {
      for (final entry in rawAnswers.entries) {
        parsedAnswers[entry.key.toString()] = entry.value.toString();
      }
    }

    final rawSkipped = json['skippedQuestionIds'];
    final parsedSkipped = <String>{};
    if (rawSkipped is List) {
      for (final s in rawSkipped) {
        parsedSkipped.add(s.toString());
      }
    }

    final startedAt = json['startedAt'] != null
        ? DateTime.parse(json['startedAt'] as String)
        : null;
    final completedAt = json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null;

    return PracticeSession(
      id: (json['id'] as String?) ?? '',
      userId: json['userId'] as String?,
      practiceSetId: json['practiceSetId'] as String?,
      topicId: json['topicId'] as String?,
      chapterId: json['chapterId'] as String?,
      subjectId: json['subjectId'] as String?,
      title: (json['title'] as String?) ?? 'Practice Session',
      questions: parsedQuestions,
      currentQuestionIndex: (json['currentQuestionIndex'] as int?) ?? 0,
      answers: parsedAnswers,
      skippedQuestionIds: parsedSkipped,
      startedAt: startedAt,
      completedAt: completedAt,
      elapsedSeconds: (json['elapsedSeconds'] as int?) ?? 0,
      feedbackMode: PracticeFeedbackMode.fromString(
        json['feedbackMode'] as String?,
      ),
      isCompleted: (json['isCompleted'] as bool?) ?? false,
    );
  }
}
