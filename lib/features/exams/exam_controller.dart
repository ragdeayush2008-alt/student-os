import 'package:flutter/material.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/constants/app_colors.dart';
import '../../core/intelligence/academic_intelligence_engine.dart';
import '../../core/intelligence/academic_knowledge_engine.dart';
import '../../core/services/notification_coordinator.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/exam.dart';
import '../auth/auth_service.dart';
import '../knowledge/academic_knowledge_controller.dart';
import '../knowledge/topic_practice_controller.dart';
import '../progression/progression_controller.dart';
import '../resources/resource_controller.dart';
import '../revision/revision_controller.dart';
import '../study/study_controller.dart';
import '../subjects/subject_controller.dart';
import '../tasks/task_controller.dart';
import '../notifications/notification_controller.dart';

import 'package:flutter/foundation.dart';

/// Manages the student's exam list with local persistence and optional
/// Supabase cloud sync.
class ExamController extends ChangeNotifier {
  ExamController._();

  /// Clears in-memory state without touching persistent storage.
  void clearData() {
    _exams.clear();
    notifyListeners();
  }

  static final ExamController instance = ExamController._();

  static const _examsKey = 'exams';

  List<StudentExam> _exams = [];
  bool _loaded = false;
  bool _disposed = false;

  List<StudentExam> get exams => List.unmodifiable(_exams);
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  // ─── Derived queries ────────────────────────────────────────────────

  List<StudentExam> get upcomingExams =>
      _exams.where((e) => e.isUpcoming).toList()..sort((a, b) {
        if (a.examDateTime == null) return 1;
        if (b.examDateTime == null) return -1;
        return a.examDateTime!.compareTo(b.examDateTime!);
      });

  List<StudentExam> get completedExams =>
      _exams.where((e) => e.isCompleted).toList()..sort((a, b) {
        if (a.examDateTime == null) return 1;
        if (b.examDateTime == null) return -1;
        return b.examDateTime!.compareTo(a.examDateTime!);
      });

  List<StudentExam> get cancelledExams =>
      _exams.where((e) => e.isCancelled).toList();

  /// Upcoming exams linked to a subject by name.
  ///
  /// Exams carry a free-text [StudentExam.subject] (no subjectId), so this
  /// matches case-insensitively and trims whitespace. Centralizes the lookup
  /// previously duplicated across detail screens so renames/casing cannot
  /// silently break one workspace while another keeps working.
  List<StudentExam> examsForSubjectName(String subjectName) {
    final needle = subjectName.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return upcomingExams
        .where((e) => e.subject.trim().toLowerCase() == needle)
        .toList();
  }

  /// The next upcoming exam (closest to now with a future date).
  StudentExam? get nextExam {
    final now = DateTime.now();
    final upcoming = upcomingExams.where((e) {
      if (e.examDateTime == null) return false;
      return e.examDateTime!.isAfter(now);
    }).toList();
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  /// Exams within the next N days.
  List<StudentExam> examsWithin(int days) {
    final cutoff = DateTime.now().add(Duration(days: days));
    return upcomingExams.where((e) {
      if (e.examDateTime == null) return false;
      return e.examDateTime!.isBefore(cutoff);
    }).toList();
  }

  int get totalExamCount => _exams.length;
  int get upcomingCount => upcomingExams.length;

  /// Total syllabus items across all upcoming exams.
  int get totalSyllabusItems =>
      upcomingExams.fold<int>(0, (sum, e) => sum + e.syllabusTotal);

  /// Completed syllabus items across all upcoming exams.
  int get completedSyllabusItems =>
      upcomingExams.fold<int>(0, (sum, e) => sum + e.syllabusCompleted);

  // ─── Loading / persistence ──────────────────────────────────────────

  Future<void> load() async {
    // Local-first: load as soon as ANY identity is known (AuthService or
    // isolation session) so cached local data never waits on the network.
    if (!AuthService.instance.isAuthenticated &&
        !AuthIsolation.instance.isAuthenticated) {
      return;
    }
    try {
      await _loadLocal();
    } catch (_) {
      // A corrupt cache entry must never leave the controller permanently
      // "not loaded" (Home gates on [isLoaded] and would spin forever).
      // Start empty; cloud sync heals from the server when available.
      _exams = [];
    } finally {
      _loaded = true;
      if (!_disposed) notifyListeners();
    }
    _attemptCloudLoad();
  }

  Future<void> _loadLocal() async {
    final uid = _userId;
    if (uid == null) return;
    final list = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _examsKey,
    );
    if (list != null) {
      _exams = list.map((j) => StudentExam.fromJson(j)).toList();
    }
  }

  Future<void> _attemptCloudLoad() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;

    try {
      final response = await client
          .from('exams')
          .select()
          .eq('user_id', uid)
          .order('exam_date_time');
      if (response.isNotEmpty) {
        _exams = response.map((j) => StudentExam.fromJson(j)).toList();
        await _saveLocal();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ExamController] Cloud load failed: $e');
    }
  }

  Future<void> _saveLocal() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _examsKey,
      list: _exams.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> _attemptCloudSave() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;

    try {
      await client
          .from('exams')
          .upsert(
            _exams.map((e) => {...e.toJson(), 'user_id': uid}).toList(),
          );
    } catch (e) {
      if (kDebugMode) debugPrint('[ExamController] Cloud save failed: $e');
    }
  }

  // ─── CRUD ───────────────────────────────────────────────────────────

  Future<StudentExam> createExam({
    required String title,
    String subject = '',
    DateTime? examDateTime,
    String notes = '',
    List<SyllabusItem> syllabusItems = const [],
    bool reminder7Days = false,
    bool reminder3Days = false,
    bool reminder1Day = false,
  }) async {
    final exam = StudentExam(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      subject: subject.trim(),
      examDateTime: examDateTime,
      notes: notes.trim(),
      syllabusItems: syllabusItems,
      reminder7Days: reminder7Days,
      reminder3Days: reminder3Days,
      reminder1Day: reminder1Day,
    );
    _exams.add(exam);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();

    // Schedule exam reminders.
    await NotificationCoordinator.instance.reconcileExamReminders(exam);

    return exam;
  }

  Future<void> updateExam(StudentExam updated) async {
    final index = _exams.indexWhere((e) => e.id == updated.id);
    if (index < 0) return;
    _exams[index] = updated;
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();

    // Reconcile reminders (cancel old, schedule new).
    await NotificationCoordinator.instance.reconcileExamReminders(updated);
  }

  Future<void> deleteExam(String examId) async {
    _exams.removeWhere((e) => e.id == examId);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();

    // Cancel all reminders for this exam.
    await NotificationCoordinator.instance.cancelExamReminders(examId);

    // Clear exam references from linked tasks.
    await TaskController.instance.clearExamReference(examId);

    // Clear exam references from linked resources — never delete study material.
    await ResourceController.instance.clearExamReference(examId);
  }

  Future<void> completeExam(String examId) async {
    final index = _exams.indexWhere((e) => e.id == examId);
    if (index < 0) return;
    _exams[index] = _exams[index].copyWith(status: ExamStatus.completed);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();

    // Cancel all reminders for completed exam.
    await NotificationCoordinator.instance.cancelExamReminders(examId);

    // Award XP for completing exam
    await ProgressionController.instance.awardExamCompletion(
      examId: examId,
      examTitle: _exams[index].title,
    );
    await NotificationController.instance.onExamCompleted(_exams[index]);
  }

  Future<void> cancelExam(String examId) async {
    final index = _exams.indexWhere((e) => e.id == examId);
    if (index < 0) return;
    _exams[index] = _exams[index].copyWith(status: ExamStatus.cancelled);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();

    // Cancel all reminders for cancelled exam.
    await NotificationCoordinator.instance.cancelExamReminders(examId);
  }

  /// Reopens a completed or cancelled exam back to upcoming status and
  /// reconciles its reminders.
  Future<void> reopenExam(String examId) async {
    final index = _exams.indexWhere((e) => e.id == examId);
    if (index < 0) return;
    _exams[index] = _exams[index].copyWith(status: ExamStatus.upcoming);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();

    // Reconcile reminders on reopen.
    await NotificationCoordinator.instance.reconcileExamReminders(exams[index]);
  }

  // ─── Syllabus management ────────────────────────────────────────────

  Future<void> addSyllabusItem(String examId, String title) async {
    final index = _exams.indexWhere((e) => e.id == examId);
    if (index < 0) return;
    final exam = _exams[index];
    final item = SyllabusItem(
      id: 'syll_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
    );
    _exams[index] = exam.copyWith(syllabusItems: [...exam.syllabusItems, item]);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> toggleSyllabusItem(String examId, String itemId) async {
    final index = _exams.indexWhere((e) => e.id == examId);
    if (index < 0) return;
    final exam = _exams[index];
    final itemIndex = exam.syllabusItems.indexWhere((s) => s.id == itemId);
    if (itemIndex < 0) return;

    final item = exam.syllabusItems[itemIndex];
    final updated = item.copyWith(
      completed: !item.completed,
      completedAt: !item.completed ? DateTime.now() : null,
      clearCompletedAt: item.completed,
    );

    final newItems = List<SyllabusItem>.from(exam.syllabusItems);
    newItems[itemIndex] = updated;
    _exams[index] = exam.copyWith(syllabusItems: newItems);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();

    // Award XP if topic was completed
    if (updated.completed) {
      await ProgressionController.instance.awardSyllabusTopic(
        examId: examId,
        topicIndex: itemIndex,
        topicTitle: updated.title,
        examTitle: exam.title,
      );
    }
  }

  Future<void> deleteSyllabusItem(String examId, String itemId) async {
    final index = _exams.indexWhere((e) => e.id == examId);
    if (index < 0) return;
    final exam = _exams[index];
    _exams[index] = exam.copyWith(
      syllabusItems: exam.syllabusItems.where((s) => s.id != itemId).toList(),
    );
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  // ─── Academic intelligence ──────────────────────────────────────────

  /// Returns true if the exam has any explicitly linked preparation tasks.
  bool hasLinkedTasks(StudentExam exam) =>
      TaskController.instance.tasks.any((t) => t.examId == exam.id);

  /// Returns the linked preparation task completion ratio (0.0–1.0).
  ///
  /// Returns 0 when there are no linked tasks.
  double linkedTaskCompletion(StudentExam exam) {
    final linked = TaskController.instance.tasksForExam(exam.id);
    if (linked.isEmpty) return 0;
    final completed = linked.where((t) => t.isCompleted).length;
    return completed / linked.length;
  }

  /// Computes a deterministic readiness assessment for an exam.
  ///
  /// Pure and testable — factors in syllabus completion, linked preparation
  /// task completion, revision status, practice performance, recent study
  /// activity, and overdue work. Uses explainable labels rather
  /// than fake percentage scores. When insufficient data exists, reports
  /// that readiness cannot yet be determined reliably.
  ReadinessResult readiness(StudentExam exam, {DateTime? referenceTime}) {
    final now = referenceTime ?? DateTime.now();
    final reasons = <String>[];
    final days = exam.daysUntilExam;

    // Derive additional signals when data is available
    final linked = TaskController.instance.tasksForExam(exam.id);
    final linkedOverdue = linked.where((t) => t.isOverdue && !t.isCompleted).length;
    final recentStudyMins = AcademicIntelligenceEngine.studyMinutesForSubject(
      exam.subject,
      StudyController.instance.sessions,
      days: 7,
      referenceTime: now,
    );

    // Revision queue signal: count topics with overdue/due revision linked to this subject
    int revisionDueCount = 0;
    int weakTopicCount = 0;
    try {
      final topics = AcademicKnowledgeController.instance.topics
          .where((t) => t.subjectId.toLowerCase() == exam.subject.toLowerCase())
          .toList();
      if (topics.isNotEmpty) {
        final practices = TopicPracticeController.instance.attempts;
        final schedules = RevisionController.instance.schedules;
        final records = RevisionController.instance.records;
        for (final topic in topics) {
          final prog = AcademicKnowledgeEngine.assessTopicProgress(
            topic,
            sessions: StudyController.instance.sessions,
            practiceAttempts: practices,
            revisionRecords: records,
            revisionSchedules: schedules,
            referenceTime: now,
          );
          if (prog.isRevisionDue || prog.isRevisionOverdue) revisionDueCount++;
          if (prog.isWeakTopic) weakTopicCount++;
        }
      }
    } catch (_) {}

    int? practiceAccuracy;
    try {
      final attempts = TopicPracticeController.instance.attempts
          .where((a) => a.subjectId?.toLowerCase() == exam.subject.toLowerCase())
          .toList();
      if (attempts.isNotEmpty) {
        int totalQ = 0;
        int totalCorrect = 0;
        for (final at in attempts) {
          if (at.totalQuestions != null && at.totalQuestions! > 0) {
            totalQ += at.totalQuestions!;
            totalCorrect += at.correctAnswers ?? 0;
          }
        }
        if (totalQ > 0) {
          practiceAccuracy = ((totalCorrect / totalQ) * 100).round();
        }
      }
    } catch (_) {}

    // No date → cannot assess proximity reliably
    if (days == null) {
      if (!exam.hasSyllabus && !hasLinkedTasks(exam)) {
        return const ReadinessResult(
          label: 'No preparation',
          reasons: ['No syllabus or preparation tasks yet'],
        );
      }
      final progress = ExamReadiness.combinedProgress(
        syllabus: exam.syllabusProgress,
        linkedTasks: linkedTaskCompletion(exam),
      );
      if (progress >= 0.7 && recentStudyMins >= 30 && revisionDueCount == 0) {
        reasons.add(
          '${(exam.syllabusProgress * 100).round()}% syllabus complete',
        );
        if (recentStudyMins > 0) reasons.add('$recentStudyMins minutes studied this week');
        return ReadinessResult(label: 'On track', reasons: reasons);
      }
      if (exam.hasSyllabus) {
        reasons.add(
          '${exam.syllabusCompleted} of ${exam.syllabusTotal} topics complete',
        );
      }
      if (recentStudyMins == 0) {
        reasons.add('No study recorded in the past 7 days');
      } else {
        reasons.add('$recentStudyMins minutes studied this week');
      }
      if (revisionDueCount > 0) reasons.add('$revisionDueCount topic(s) due for revision');
      if (weakTopicCount > 0) reasons.add('$weakTopicCount weak topic(s) need practice');
      return ReadinessResult(label: 'In progress', reasons: reasons);
    }

    final combined = ExamReadiness.combinedProgress(
      syllabus: exam.syllabusProgress,
      linkedTasks: linkedTaskCompletion(exam),
    );

    reasons.add('$days day${days == 1 ? '' : 's'} until the exam');

    if (exam.hasSyllabus) {
      reasons.add(
        '${exam.syllabusCompleted} of ${exam.syllabusTotal} topics complete',
      );
    }
    if (linked.isNotEmpty) {
      reasons.add(
        '${linked.where((t) => t.isCompleted).length} of ${linked.length} '
        'preparation tasks complete',
      );
    }
    if (recentStudyMins == 0 && days <= 7) {
      reasons.add('No study recorded in the past 7 days');
    } else if (recentStudyMins < 30 && days <= 7) {
      reasons.add('Only ${recentStudyMins}m studied this week');
    } else if (recentStudyMins > 0) {
      reasons.add('$recentStudyMins minutes studied this week');
    }
    if (linkedOverdue > 0) {
      reasons.add('$linkedOverdue overdue preparation task(s)');
    }
    if (revisionDueCount > 0) {
      reasons.add('$revisionDueCount topic(s) due for revision');
    }
    if (weakTopicCount > 0) {
      reasons.add('$weakTopicCount weak topic(s) need practice');
    }
    if (practiceAccuracy != null && practiceAccuracy < 65) {
      reasons.add('Practice accuracy $practiceAccuracy% — needs improvement');
    } else if (practiceAccuracy != null) {
      reasons.add('Practice accuracy $practiceAccuracy%');
    }

    // Close deadline with incomplete work → needs attention.
    if (days <= 3 && combined < 0.5) {
      reasons.add('Most preparation is still incomplete');
      return ReadinessResult(label: 'Needs attention', reasons: reasons);
    }
    if (days <= 7 && combined < 0.7) {
      if (days <= 5) {
        reasons.add('A lot of work remains with limited time');
        return ReadinessResult(label: 'Needs attention', reasons: reasons);
      }
      reasons.add('Some preparation is still outstanding');
      return ReadinessResult(label: 'In progress', reasons: reasons);
    }
    // Additional risk: critical revision or overdue despite moderate syllabus progress
    if (days <= 7 && (revisionDueCount > 2 || linkedOverdue > 0 || (practiceAccuracy != null && practiceAccuracy < 60))) {
      if (combined >= 0.5) {
        reasons.add('Syllabus on track but retention/practice needs attention');
        return ReadinessResult(label: 'Needs attention', reasons: reasons);
      }
    }
    if (combined >= 0.7 && revisionDueCount == 0 && linkedOverdue == 0) {
      reasons.add('You are largely prepared');
      return ReadinessResult(label: 'On track', reasons: reasons);
    }
    if (combined >= 0.3) {
      reasons.add('Preparation is underway');
      return ReadinessResult(label: 'Getting there', reasons: reasons);
    }
    if (exam.hasSyllabus || linked.isNotEmpty) {
      reasons.add('Early in the preparation cycle');
      return ReadinessResult(label: 'Early stage', reasons: reasons);
    }
    if (recentStudyMins == 0 && !exam.hasSyllabus && linked.isEmpty) {
      return const ReadinessResult(
        label: 'Insufficient data',
        reasons: ['Readiness cannot yet be determined reliably — add syllabus, tasks, or study activity'],
      );
    }
    return ReadinessResult(
      label: 'No preparation',
      reasons: ['No syllabus or preparation tasks yet'],
    );
  }

  /// Returns a readiness label for an exam.
  String readinessLabel(StudentExam exam) => readiness(exam).label;

  /// Returns the deterministic exam pressure assessment for an exam.
  ExamPressureAssessment examPressure(StudentExam exam) {
    return AcademicIntelligenceEngine.assessExamPressure(
      exam,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      subjects: SubjectController.instance.subjects,
    );
  }

  /// Returns the user-facing exam pressure label (e.g. "High exam pressure").
  String examPressureLabel(StudentExam exam) => examPressure(exam).level.label;

  /// Returns preparation insights for upcoming exams.
  List<ExamInsight> getInsights() {
    final insights = <ExamInsight>[];
    final upcoming = upcomingExams;

    // Multiple exams in same week.
    if (upcoming.length >= 2) {
      for (var i = 0; i < upcoming.length - 1; i++) {
        for (var j = i + 1; j < upcoming.length; j++) {
          final a = upcoming[i];
          final b = upcoming[j];
          if (a.examDateTime == null || b.examDateTime == null) continue;
          final diff = (a.examDateTime!.difference(b.examDateTime!)).inDays
              .abs();
          if (diff <= 7) {
            insights.add(
              ExamInsight(
                icon: Icons.event_repeat_rounded,
                title: 'Concentrated exam period',
                detail:
                    '${a.title} and ${b.title} are within $diff days of each other.',
                tint: AppColors.warning,
              ),
            );
          }
        }
      }
    }

    // Exam with low preparation and close deadline.
    for (final exam in upcoming) {
      final days = exam.daysUntilExam;
      if (days == null) continue;
      final combined = ExamReadiness.combinedProgress(
        syllabus: exam.syllabusProgress,
        linkedTasks: linkedTaskCompletion(exam),
      );
      if (days <= 5 && combined < 0.5) {
        insights.add(
          ExamInsight(
            icon: Icons.warning_amber_rounded,
            title: '${exam.title} needs attention',
            detail:
                '${(combined * 100).round()}% prepared with $days days remaining.',
            tint: AppColors.error,
          ),
        );
      }
    }

    // Exams with no linked preparation tasks.
    for (final exam in upcoming) {
      if (hasLinkedTasks(exam)) continue;
      final days = exam.daysUntilExam;
      if (days == null || days > 7) continue;
      if (!exam.hasSyllabus && days <= 3) {
        insights.add(
          ExamInsight(
            icon: Icons.assignment_outlined,
            title: 'No preparation plan for ${exam.title}',
            detail: 'Add topics or link preparation tasks.',
            tint: AppColors.secondary,
          ),
        );
        continue;
      }
      if (exam.hasSyllabus && exam.syllabusProgress < 0.5) {
        insights.add(
          ExamInsight(
            icon: Icons.assignment_outlined,
            title:
                'No preparation tasks for ${exam.subject.isEmpty ? exam.title : exam.subject}',
            detail: 'Link study tasks to this exam to track preparation.',
            tint: AppColors.secondary,
          ),
        );
      }
    }

    return insights;
  }

  /// Returns academic milestones derived from real exam activity.
  List<ExamMilestone> getMilestones() {
    final milestones = <ExamMilestone>[];

    milestones.add(
      ExamMilestone(
        id: 'first_exam',
        title: 'First exam created',
        detail: 'Start organizing your academic calendar',
        earned: _exams.isNotEmpty,
        icon: Icons.school_rounded,
      ),
    );

    milestones.add(
      ExamMilestone(
        id: 'first_syllabus',
        title: 'First syllabus item completed',
        detail: 'Begin tracking your preparation progress',
        earned: _exams.any((e) => e.syllabusCompleted > 0),
        icon: Icons.check_circle_outline_rounded,
      ),
    );

    milestones.add(
      ExamMilestone(
        id: 'full_syllabus',
        title: 'Complete a syllabus',
        detail: 'Fully prepare for an exam by completing all topics',
        earned: _exams.any((e) => e.allSyllabusComplete),
        icon: Icons.emoji_events_rounded,
      ),
    );

    milestones.add(
      ExamMilestone(
        id: 'first_exam_completed',
        title: 'First exam completed',
        detail: 'You completed your first exam',
        earned: completedExams.isNotEmpty,
        icon: Icons.done_all_rounded,
      ),
    );

    milestones.add(
      ExamMilestone(
        id: 'five_exams',
        title: '5 exams tracked',
        detail: 'Organize your academic workload',
        earned: _exams.length >= 5,
        icon: Icons.calendar_month_rounded,
      ),
    );

    return milestones;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// A deterministic insight about academic preparation.
@immutable
class ExamInsight {
  const ExamInsight({
    required this.icon,
    required this.title,
    required this.detail,
    this.tint,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color? tint;
}

/// A milestone derived from real exam activity.
@immutable
class ExamMilestone {
  const ExamMilestone({
    required this.id,
    required this.title,
    required this.detail,
    required this.earned,
    required this.icon,
  });

  final String id;
  final String title;
  final String detail;
  final bool earned;
  final IconData icon;
}

/// A deterministic, explainable readiness assessment for an exam.
@immutable
class ReadinessResult {
  const ReadinessResult({required this.label, required this.reasons});

  final String label;
  final List<String> reasons;
}

/// Pure helpers for combining preparation signals into a single progress
/// figure. Kept separate from [ExamController] for unit testing.
abstract final class ExamReadiness {
  /// Combines syllabus completion and linked-task completion into a weighted
  /// progress figure (0.0–1.0).
  ///
  /// Both contribute equally when both exist. When only one exists, it is
  /// used alone.
  static double combinedProgress({
    required double syllabus,
    required double linkedTasks,
  }) {
    if (syllabus > 0 && linkedTasks > 0) {
      return (syllabus + linkedTasks) / 2;
    }
    if (syllabus > 0) return syllabus;
    return linkedTasks;
  }
}
