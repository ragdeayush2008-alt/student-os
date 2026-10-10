import 'package:flutter/foundation.dart';

import 'question.dart';
import 'topic_practice_attempt.dart';

/// Detailed result for a single question in a completed practice session.
@immutable
class QuestionResultDetail {
  const QuestionResultDetail({
    required this.question,
    this.studentAnswer,
    required this.isAnswered,
    required this.isSkipped,
    required this.isCorrect,
    required this.correctAnswer,
    this.explanation,
  });

  final Question question;
  final String? studentAnswer;
  final bool isAnswered;
  final bool isSkipped;
  final bool isCorrect;
  final String correctAnswer;
  final String? explanation;

  String get questionText => question.questionText;
}

/// Comprehensive outcome of a completed practice session.
@immutable
class PracticeSessionResult {
  const PracticeSessionResult({
    required this.sessionId,
    this.userId,
    this.topicId,
    this.chapterId,
    this.subjectId,
    required this.title,
    required this.totalQuestions,
    required this.answeredCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.accuracyPercentage,
    required this.durationSec,
    required this.completedAt,
    required this.details,
    required this.whatWentWell,
    required this.needsAttention,
    required this.recommendedNextStep,
  });

  final String sessionId;
  final String? userId;
  final String? topicId;
  final String? chapterId;
  final String? subjectId;
  final String title;
  final int totalQuestions;
  final int answeredCount;
  final int correctCount;
  final int incorrectCount;
  final int skippedCount;
  final int accuracyPercentage;
  final int durationSec;
  final DateTime completedAt;
  final List<QuestionResultDetail> details;
  final List<String> whatWentWell;
  final List<String> needsAttention;
  final String recommendedNextStep;

  int get durationMinutes => durationSec ~/ 60;
  bool get isPerfectScore => totalQuestions > 0 && correctCount == totalQuestions;

  /// Converts this session result into an authoritative [TopicPracticeAttempt].
  TopicPracticeAttempt toTopicPracticeAttempt({
    String? attemptId,
    String notes = '',
  }) {
    final now = completedAt;
    final resolvedTopicId = topicId ?? 'general';
    return TopicPracticeAttempt(
      id: attemptId ?? 'prac_${now.millisecondsSinceEpoch}',
      userId: userId,
      topicId: resolvedTopicId,
      subjectId: subjectId,
      chapterId: chapterId,
      startedAt: now.subtract(Duration(seconds: durationSec)),
      completedAt: now,
      durationSec: durationSec,
      totalQuestions: totalQuestions,
      correctAnswers: correctCount,
      incorrectAnswers: incorrectCount,
      score: totalQuestions > 0
          ? ((correctCount / totalQuestions) * 100).clamp(0.0, 100.0)
          : null,
      notes: notes.isNotEmpty
          ? notes
          : 'Completed practice session ($accuracyPercentage% accuracy)',
    );
  }
}
