import 'package:flutter/foundation.dart';

import '../../core/intelligence/academic_knowledge_engine.dart';
import '../../core/time/app_clock.dart';
import '../../data/models/exam.dart';
import '../../data/models/study_session.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../data/models/topic.dart';
import '../exams/exam_controller.dart';
import '../focus/controller/focus_controller.dart';
import '../knowledge/academic_knowledge_controller.dart';
import '../study/study_controller.dart';
import '../subjects/subject_controller.dart';
import '../tasks/task_controller.dart';
import 'controllers/planning_block_controller.dart';
import 'models/planning_block.dart';
import 'plan_controller.dart';
import 'services/planning_engine.dart';

/// Lifecycle of a planned block relative to [now].
enum PlanBlockStatus { completed, active, missed, upcoming }

/// A planned block resolved into display-ready academic context.
///
/// Purely derived: no scheduling, completion or priority decisions are made
/// here. Authority stays with [PlanningBlockController], [TaskController],
/// [PlanningEngine] and [AcademicKnowledgeEngine].
@immutable
class PlanBlockView {
  const PlanBlockView({
    required this.block,
    required this.status,
    required this.title,
    required this.subjectName,
    required this.chapterTitle,
    required this.topicTitle,
    required this.durationMinutes,
    required this.priority,
    required this.remainingMinutes,
    this.taskId,
    this.subjectId,
    this.topicId,
    this.chapterId,
  });

  final PlanningBlock block;
  final PlanBlockStatus status;

  /// Task title when task-linked, else the block's own custom title.
  final String title;

  /// Resolved subject name — never a raw id.
  final String? subjectName;
  final String? chapterTitle;
  final String? topicTitle;
  final int durationMinutes;
  final TaskPriority priority;
  final int remainingMinutes;

  final String? taskId;
  final String? subjectId;
  final String? topicId;
  final String? chapterId;

  bool get isCompleted => status == PlanBlockStatus.completed;
  bool get isActive => status == PlanBlockStatus.active;
  bool get isMissed => status == PlanBlockStatus.missed;
  bool get isUpcoming => status == PlanBlockStatus.upcoming;

  /// True when this block carries any real academic hierarchy context.
  bool get hasAcademicContext => subjectName != null || topicTitle != null;

  /// `09:00` — 24h clock for compact rows.
  String get startLabel =>
      '${block.startAt.hour.toString().padLeft(2, '0')}:'
      '${block.startAt.minute.toString().padLeft(2, '0')}';

  String get endLabel =>
      '${block.endAt.hour.toString().padLeft(2, '0')}:'
      '${block.endAt.minute.toString().padLeft(2, '0')}';
}

/// Everything PLAN renders for the selected day.
@immutable
class PlanDayView {
  const PlanDayView({
    required this.day,
    required this.isToday,
    required this.blocks,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.availableMinutes,
    required this.activeBlock,
    required this.nextBlock,
    required this.missedBlocks,
    required this.hasFocusSession,
    required this.focusObjective,
  });

  final DateTime day;
  final bool isToday;

  /// Ordered chronologically, resolved views.
  final List<PlanBlockView> blocks;

  final int plannedMinutes;
  final int completedMinutes;
  final int availableMinutes;

  /// The block whose window contains "now" (§6).
  final PlanBlockView? activeBlock;

  /// First not-yet-finished future block.
  final PlanBlockView? nextBlock;

  /// Unfinished blocks whose window has already passed (§10).
  final List<PlanBlockView> missedBlocks;

  final bool hasFocusSession;
  final String focusObjective;

  bool get hasPlan => blocks.isNotEmpty;
  bool get hasMissed => missedBlocks.isNotEmpty;
  bool get hasActiveBlock => activeBlock != null;

  int get completedCount => blocks.where((b) => b.isCompleted).length;
  int get remainingBlocks => blocks.where((b) => !b.isCompleted).length;
  int get remainingMinutes =>
      (plannedMinutes - completedMinutes).clamp(0, 1 << 30);

  bool get allCompleted => hasPlan && blocks.every((b) => b.isCompleted);

  /// 0..1 completion across planned minutes, or block count when unknown.
  double get progress {
    if (blocks.isEmpty) return 0;
    if (plannedMinutes <= 0) return blocks.isEmpty ? 0 : completedCount / blocks.length;
    return (completedMinutes / plannedMinutes).clamp(0.0, 1.0);
  }

  String get dayLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return '${weekdays[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}';
  }
}

/// Subject-level distribution produced by the existing PlanningEngine (§9).
@immutable
class SubjectAllocationView {
  const SubjectAllocationView({
    required this.subjectId,
    required this.subjectName,
    required this.minutes,
    required this.itemCount,
  });

  final String? subjectId;
  final String subjectName;
  final int minutes;
  final int itemCount;
}

/// Result of running the existing deterministic allocation over a budget.
@immutable
class SubjectAllocation {
  const SubjectAllocation({
    required this.budgetMinutes,
    required this.entries,
    required this.totalPlannedMinutes,
    required this.isOverloaded,
  });

  final int budgetMinutes;

  /// Ordered by descending minutes — heaviest subject first.
  final List<SubjectAllocationView> entries;
  final int totalPlannedMinutes;
  final bool isOverloaded;

  bool get isEmpty => entries.isEmpty;
  int get freeMinutes =>
      (budgetMinutes - totalPlannedMinutes).clamp(0, 1 << 30);
}

/// Real persisted "continue learning" state (§18).
///
/// Only ever built from completed [StudySession] records — never fabricated.
@immutable
class ContinueLearningView {
  const ContinueLearningView({
    required this.session,
    required this.subjectName,
    required this.topicTitle,
    required this.chapterTitle,
    required this.lastStudiedAt,
    required this.lastStudiedLabel,
  });

  final StudySession session;
  final String subjectName;
  final String? topicTitle;
  final String? chapterTitle;
  final DateTime lastStudiedAt;
  final String lastStudiedLabel;

  String? get topicId => session.topicId;
  String? get subjectId => session.subjectId;
  String? get chapterId => session.chapterId;
}

/// Per-subject academic read-out for STUDY mode (§14).
@immutable
class StudySubjectView {
  const StudySubjectView({
    required this.subject,
    required this.progress,
    required this.recommendedTopicTitle,
    required this.daysUntilNextExam,
    required this.nextExamTitle,
  });

  final Subject subject;
  final SubjectKnowledgeProgress progress;

  /// Real recommended topic from the knowledge engine, or null.
  final String? recommendedTopicTitle;

  final int? daysUntilNextExam;
  final String? nextExamTitle;

  int get syllabusPercentage => progress.syllabusPercentage;
  int get revisionPercentage => progress.revisionPercentage;
  int get needsRevisionTopics => progress.needsRevisionTopics;
  int get totalStudyMinutes => progress.totalStudyMinutes;
  bool get hasSyllabus => progress.hasSyllabus;
  SubjectHealthState get health => progress.health;
}

/// A topic surfaced in STUDY mode with its authoritative derived state.
@immutable
class StudyTopicView {
  const StudyTopicView({
    required this.progress,
    this.chapterTitle,
  });

  final TopicProgress progress;
  final String? chapterTitle;

  Topic get topic => progress.topic;
  TopicStatus get status => progress.status;
  String get title => progress.topic.title;

  /// Engine-derived action label — never re-derived here.
  String get actionLabel => progress.recommendedActionLabel;

  String get reason {
    if (progress.recommendationReason != null &&
        progress.recommendationReason!.trim().isNotEmpty) {
      return progress.recommendationReason!;
    }
    if (progress.isRevisionDue) return 'Revision due now';
    if (progress.isWeakTopic) {
      return progress.weakTopicReason ?? 'Weak topic — needs reinforcement';
    }
    return 'Next step in your syllabus progression';
  }

  bool get isRevisionDue => progress.isRevisionDue;
  bool get isWeak => progress.isWeakTopic;
  bool get isStudied => progress.isStudied;
  bool get hasPractice => progress.practiceAttemptsCount > 0;
}

/// Full STUDY-mode read-out (§13).
@immutable
class StudyOverviewState {
  const StudyOverviewState({
    required this.subjects,
    required this.continueLearning,
    required this.recommended,
    required this.weakTopics,
    required this.revisionDueTopics,
    required this.practiceOpportunities,
    required this.totalTopics,
    required this.studiedTopics,
    required this.hasCourse,
  });

  final List<StudySubjectView> subjects;

  /// Real persisted continuation, or null when nothing was ever studied.
  final ContinueLearningView? continueLearning;

  /// ONE strongest recommendation, or null.
  final StudyTopicView? recommended;

  final List<StudyTopicView> weakTopics;
  final List<StudyTopicView> revisionDueTopics;

  /// Mastered / studied topics with no practice evidence yet.
  final List<StudyTopicView> practiceOpportunities;

  final int totalTopics;
  final int studiedTopics;

  /// False only when the student has no subjects and no curriculum.
  final bool hasCourse;

  bool get hasSubjects => subjects.isNotEmpty;
  bool get hasHistory => continueLearning != null;
  bool get hasRevisionDue => revisionDueTopics.isNotEmpty;

  int get syllabusPercentage =>
      totalTopics == 0 ? 0 : ((studiedTopics / totalTopics) * 100).round();

  int get totalStudyMinutes =>
      subjects.fold(0, (sum, s) => sum + s.totalStudyMinutes);
}

/// Read-only adapter over the authoritative academic systems.
///
/// PLAN & STUDY 3.0 owns no business logic: every value here is read from
/// PlanningBlockController, PlanController, TaskController, StudyController,
/// AcademicKnowledgeController, AcademicKnowledgeEngine, ExamController and
/// SubjectController. Presentation layers render this and nothing more.
abstract final class PlanStudyState {
  /// Canonical completion rule: a block is done when its linked task is done.
  ///
  /// Single source of truth so the timeline, hero and progress can never
  /// disagree — and no duplicate completion record is ever written.
  static bool isBlockCompleted(PlanningBlock block) {
    final taskId = block.taskId;
    if (taskId == null || taskId.isEmpty) return false;
    for (final t in TaskController.instance.tasks) {
      if (t.id == taskId) return t.isCompleted;
    }
    return false;
  }

  /// Derive the PLAN surface for [day].
  static PlanDayView planDay(DateTime day, {int? availableMinutes}) {
    final now = AppClock.current;
    final blocks = PlanningBlockController.instance.blocksForDay(day);
    final fc = FocusController.instance;

    final views = <PlanBlockView>[];
    for (final b in blocks) {
      views.add(_blockView(b, now));
    }
    views.sort((a, b) => a.block.startAt.compareTo(b.block.startAt));

    int planned = 0;
    int completed = 0;
    for (final v in views) {
      planned += v.durationMinutes;
      if (v.isCompleted) completed += v.durationMinutes;
    }

    PlanBlockView? active;
    for (final v in views) {
      if (v.isActive) {
        active = v;
        break;
      }
    }

    PlanBlockView? next;
    for (final v in views) {
      if (!v.isCompleted && v.block.endAt.isAfter(now)) {
        next = v;
        break;
      }
    }
    if (next == null) {
      for (final v in views) {
        if (!v.isCompleted) {
          next = v;
          break;
        }
      }
    }

    return PlanDayView(
      day: day,
      isToday: PlanController.instance.isToday(day),
      blocks: views,
      plannedMinutes: planned,
      completedMinutes: completed,
      availableMinutes: availableMinutes ?? blocks.length * 45,
      activeBlock: active,
      nextBlock: next,
      missedBlocks: views.where((v) => v.isMissed).toList(growable: false),
      hasFocusSession: fc.hasActiveSession,
      focusObjective: fc.activeSession?.objective ?? '',
    );
  }

  /// Run the existing [PlanController.generateDailyPlan] and aggregate the
  /// result per subject. No second allocation engine is introduced.
  static SubjectAllocation allocation({
    required int budgetMinutes,
    DateTime? day,
  }) {
    final plan = PlanController.instance.generateDailyPlan(
      day: day ?? AppClock.current,
      budgetMinutes: budgetMinutes,
    );

    final minutesBySubject = <String?, int>{};
    final countsBySubject = <String?, int>{};
    for (final item in plan.items) {
      final key = item.subjectId;
      minutesBySubject[key] = (minutesBySubject[key] ?? 0) + item.estimatedMinutes;
      countsBySubject[key] = (countsBySubject[key] ?? 0) + 1;
    }

    final entries = <SubjectAllocationView>[];
    minutesBySubject.forEach((subjectId, minutes) {
      final name = subjectId == null
          ? 'Tasks & other'
          : SubjectController.instance.subjectById(subjectId)?.displayName ??
              subjectId;
      entries.add(
        SubjectAllocationView(
          subjectId: subjectId,
          subjectName: name,
          minutes: minutes,
          itemCount: countsBySubject[subjectId] ?? 0,
        ),
      );
    });
    entries.sort((a, b) => b.minutes.compareTo(a.minutes));

    return SubjectAllocation(
      budgetMinutes: budgetMinutes,
      entries: entries,
      totalPlannedMinutes: plan.totalPlannedMinutes,
      isOverloaded: plan.isOverloaded,
    );
  }

  /// Most recent real completed study session that carries topic context.
  ///
  /// Returns null when nothing has actually been studied — a "Continue" card
  /// is never shown for fabricated state.
  static ContinueLearningView? continueLearning() {
    final sessions = StudyController.instance.completedSessions;
    for (final s in sessions) {
      if (s.topicId == null || s.topicId!.isEmpty) continue;
      final subjectName = s.subjectId != null
          ? SubjectController.instance.subjectById(s.subjectId!)?.displayName
              ?? s.subject
          : s.subject;
      final topic = s.topicId == null
          ? null
          : AcademicKnowledgeController.instance
              .topicsForSubject(s.subjectId ?? '')
              .where((t) => t.id == s.topicId)
              .firstOrNull;
      return ContinueLearningView(
        session: s,
        subjectName: subjectName,
        topicTitle: topic?.title,
        chapterTitle: s.chapterId == null
            ? null
            : AcademicKnowledgeController.instance
                .chaptersForSubject(s.subjectId ?? '')
                .where((c) => c.id == s.chapterId)
                .firstOrNull
                ?.title,
        lastStudiedAt: s.startedAt,
        lastStudiedLabel: _relativeDay(s.startedAt),
      );
    }
    return null;
  }

  /// Full STUDY read-out, derived from the academic knowledge engine.
  static StudyOverviewState studyOverview() {
    final sc = SubjectController.instance;
    final kc = AcademicKnowledgeController.instance;
    final stc = StudyController.instance;
    final ec = ExamController.instance;
    final sessions = stc.sessions;
    final chapters = kc.chapters;
    final topics = kc.topics;

    final subjectViews = <StudySubjectView>[];
    for (final subject in sc.activeSubjects) {
      final subjectTopics = topics.where((t) => t.subjectId == subject.id).toList();
      final subjectChapters =
          chapters.where((c) => c.subjectId == subject.id).toList();

      final progress = AcademicKnowledgeEngine.assessSubjectProgress(
        subject,
        chapters: subjectChapters,
        topics: subjectTopics,
        sessions: sessions,
        exams: ec.exams,
      );

      final recommended = AcademicKnowledgeEngine.getRecommendedTopicForSubject(
        subject,
        chapters: subjectChapters,
        topics: subjectTopics,
        sessions: sessions,
        exams: ec.exams,
      );

      final upcoming = _nextExamForSubject(subject, ec.exams);

      subjectViews.add(
        StudySubjectView(
          subject: subject,
          progress: progress,
          recommendedTopicTitle: recommended?.title,
          daysUntilNextExam: upcoming?.daysUntilExam,
          nextExamTitle: upcoming?.title,
        ),
      );
    }

    // One strongest recommendation across the whole curriculum.
    final candidateProgresses = <TopicProgress>[];
    for (final t in topics) {
      candidateProgresses.add(
        AcademicKnowledgeEngine.assessTopicProgress(
          t,
          sessions: sessions,
          referenceTime: AppClock.current,
        ),
      );
    }
    candidateProgresses.sort(
      (a, b) => _topicScore(b).compareTo(_topicScore(a)),
    );

    StudyTopicView? recommendedView;
    for (final p in candidateProgresses) {
      if (_topicScore(p) <= 0) continue;
      recommendedView = StudyTopicView(
        progress: p,
        chapterTitle: _chapterTitle(p.topic.chapterId),
      );
      break;
    }

    final weak = candidateProgresses
        .where((p) => p.isWeakTopic)
        .take(3)
        .map((p) => StudyTopicView(progress: p, chapterTitle: _chapterTitle(p.topic.chapterId)))
        .toList();

    final revisionDue = candidateProgresses
        .where((p) => p.isRevisionDue || p.status == TopicStatus.needsRevision)
        .take(3)
        .map((p) => StudyTopicView(progress: p, chapterTitle: _chapterTitle(p.topic.chapterId)))
        .toList();

    final practice = candidateProgresses
        .where(
          (p) =>
              (p.status == TopicStatus.mastered || p.status == TopicStatus.studied) &&
              p.practiceAttemptsCount == 0,
        )
        .take(3)
        .map((p) => StudyTopicView(progress: p, chapterTitle: _chapterTitle(p.topic.chapterId)))
        .toList();

    final studied = candidateProgresses.where((p) => p.isStudied).length;

    return StudyOverviewState(
      subjects: subjectViews,
      continueLearning: continueLearning(),
      recommended: recommendedView,
      weakTopics: weak,
      revisionDueTopics: revisionDue,
      practiceOpportunities: practice,
      totalTopics: topics.length,
      studiedTopics: studied,
      hasCourse: sc.activeSubjects.isNotEmpty || topics.isNotEmpty,
    );
  }

  // ── internals ────────────────────────────────────────────────────────────

  static PlanBlockView _blockView(PlanningBlock block, DateTime now) {
    final task = block.taskId == null
        ? null
        : TaskController.instance.tasks
            .where((t) => t.id == block.taskId)
            .firstOrNull;

    final completed = isBlockCompleted(block);
    final started = block.startAt.isBefore(now);
    final ended = block.endAt.isBefore(now);

    final PlanBlockStatus status;
    if (completed) {
      status = PlanBlockStatus.completed;
    } else if (started && !ended) {
      status = PlanBlockStatus.active;
    } else if (ended) {
      status = PlanBlockStatus.missed;
    } else {
      status = PlanBlockStatus.upcoming;
    }

    final subjectName = block.subjectId == null
        ? null
        : SubjectController.instance.subjectById(block.subjectId!)?.displayName;

    final topic = block.topicId == null
        ? null
        : AcademicKnowledgeController.instance.topics
            .where((t) => t.id == block.topicId)
            .firstOrNull;

    final chapterTitle = block.chapterId == null
        ? null
        : AcademicKnowledgeController.instance.chapters
            .where((c) => c.id == block.chapterId)
            .firstOrNull
            ?.title;

    final remaining = block.endAt.difference(now).inMinutes.clamp(0, 1 << 30);

    return PlanBlockView(
      block: block,
      status: status,
      title: task?.title ??
          block.customTitle ??
          subjectName ??
          topic?.title ??
          'Study block',
      subjectName: subjectName,
      chapterTitle: chapterTitle,
      topicTitle: topic?.title,
      durationMinutes: block.endAt.difference(block.startAt).inMinutes,
      priority: _priorityFor(block, task),
      remainingMinutes: remaining,
      taskId: block.taskId,
      subjectId: block.subjectId,
      topicId: block.topicId,
      chapterId: block.chapterId,
    );
  }

  /// Task priority for task blocks; exam proximity for subject blocks;
  /// engine-assessed importance for topic blocks. No new scoring.
  static TaskPriority _priorityFor(PlanningBlock block, StudentTask? task) {
    if (task != null) return task.priority;
    if (block.topicId != null) {
      final topic = AcademicKnowledgeController.instance.topics
          .where((t) => t.id == block.topicId)
          .firstOrNull;
      if (topic != null) {
        final level = AcademicKnowledgeEngine.assessTopicPriority(
          topic,
          exams: ExamController.instance.exams,
          sessions: StudyController.instance.sessions,
          referenceTime: AppClock.current,
        ).level;
        return switch (level) {
          AcademicPriorityLevel.critical => TaskPriority.critical,
          AcademicPriorityLevel.high => TaskPriority.high,
          AcademicPriorityLevel.medium => TaskPriority.medium,
          AcademicPriorityLevel.low => TaskPriority.low,
        };
      }
    }
    final days = _nextExamForBlock(block);
    if (days == null) return TaskPriority.medium;
    if (days <= 7) return TaskPriority.critical;
    if (days <= 14) return TaskPriority.high;
    if (days <= 30) return TaskPriority.medium;
    return TaskPriority.low;
  }

  static int? _nextExamForBlock(PlanningBlock block) {
    final exams = ExamController.instance.exams;
    if (block.examId != null) {
      for (final e in exams) {
        if (e.id == block.examId) return e.daysUntilExam;
      }
    }
    final subjectName = block.subjectId == null
        ? null
        : SubjectController.instance.subjectById(block.subjectId!)?.displayName;
    final match = _nextExamForName(subjectName, exams);
    return match?.daysUntilExam;
  }

  static StudentExam? _nextExamForSubject(Subject subject, List<StudentExam> exams) =>
      _nextExamForName(subject.displayName, exams);

  static StudentExam? _nextExamForName(String? name, List<StudentExam> exams) {
    if (name == null || name.isEmpty) return null;
    StudentExam? best;
    for (final e in exams) {
      if (!e.isUpcoming) continue;
      if (!_matches(e, name)) continue;
      final d = e.daysUntilExam;
      if (d == null || d < 0) continue;
      if (best == null || d < (best.daysUntilExam ?? 1 << 30)) best = e;
    }
    return best;
  }

  static bool _matches(StudentExam exam, String subjectName) {
    final target = subjectName.toLowerCase();
    return exam.subject.toLowerCase().contains(target) ||
        exam.title.toLowerCase().contains(target);
  }

  static String? _chapterTitle(String? chapterId) {
    if (chapterId == null) return null;
    for (final c in AcademicKnowledgeController.instance.chapters) {
      if (c.id == chapterId) return c.title;
    }
    return null;
  }

  /// Ranking used ONLY to choose which single topic to surface first.
  /// It reads the engine's own flags and adds no academic judgement.
  static int _topicScore(TopicProgress p) {
    var score = 0;
    if (p.isRevisionDue || p.status == TopicStatus.needsRevision) score += 60;
    if (p.isWeakTopic) score += 45;
    if (p.status == TopicStatus.inProgress) score += 35;
    if (p.status == TopicStatus.notStarted) score += 20;
    if (p.practiceAttemptsCount == 0 && p.isStudied) score += 8;
    if (p.daysSinceStudied > 14) score += 10;
    return score;
  }

  static String _relativeDay(DateTime when) {
    final now = AppClock.current;
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(when.year, when.month, when.day);
    final diff = b.difference(a).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    if (diff < 0) return '${-diff} days ago';
    if (diff == 1) return 'Tomorrow';
    return '$diff days ago';
  }
}
