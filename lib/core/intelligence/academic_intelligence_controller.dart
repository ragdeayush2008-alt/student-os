import 'package:flutter/material.dart' hide PrioritizedAction;

import '../../data/models/exam.dart';
import '../../features/calendar/academic_schedule_controller.dart';
import '../../features/exams/exam_controller.dart';
import '../../features/focus/controller/focus_controller.dart';
import '../../features/goals/goal_controller.dart';
import '../../features/knowledge/academic_knowledge_controller.dart';
import '../../features/knowledge/topic_practice_controller.dart';
import '../../features/planning/controllers/planning_block_controller.dart';
import '../../features/planning/models/planning_block.dart';
import '../../features/planning/services/planning_engine.dart';
import '../../features/preferences/user_preferences_controller.dart';
import '../../features/resources/resource_controller.dart';
import '../../features/revision/revision_controller.dart';
import '../../features/study/study_controller.dart';
import '../../features/subjects/subject_controller.dart';
import '../../features/tasks/task_controller.dart';
import '../navigation/universal_action_executor.dart';
import 'academic_context.dart';
import 'academic_intelligence_engine.dart';
import 'adaptive_priority_engine.dart';
import 'autopilot_engine.dart';
import 'student_os_intelligence_engine.dart';
import 'student_state.dart';
import 'today_plan_engine.dart';

/// Central controller providing real-time academic intelligence, today's plan,
/// unified study recommendations, Autopilot, and Next Best Action across the Student OS app.
class AcademicIntelligenceController extends ChangeNotifier {
  AcademicIntelligenceController._() {
    _attachDerivedStateListeners();
  }

  /// Clears intelligence state for new session.
  void clearData() {
    _selectedBudget = AvailableTimeBudget.oneHour;
    _gentleRecoveryMode = false;
    _isDoneForToday = false;
    _cachedState = null;
    _cachedStateTime = null;
    notifyListeners();
  }

  static final AcademicIntelligenceController instance =
      AcademicIntelligenceController._();

  final AdaptivePriorityEngine _priorityEngine = const AdaptivePriorityEngine();
  final TodayPlanEngine _planEngine = const TodayPlanEngine();

  AvailableTimeBudget _selectedBudget = AvailableTimeBudget.oneHour;
  bool _gentleRecoveryMode = false;
  bool _isDoneForToday = false;
  bool _disposed = false;

  // ─── Derived state cache (P3 performance: avoid full recalc on every build) ───
  StudentStateSnapshot? _cachedState;
  DateTime? _cachedStateTime;
  bool _listenersAttached = false;

  void _attachDerivedStateListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;
    void inv() {
      _cachedState = null; // invalidate cache on any source mutation
      // notifyListeners is debounced to next microtask to coalesce rapid mutations
      if (!_disposed) {
        Future.microtask(() {
          if (!_disposed) notifyListeners();
        });
      }
    }

    // Attach to all source controllers — targeted invalidation, no polling
    try { TaskController.instance.addListener(inv); } catch (_) {}
    try { PlanningBlockController.instance.addListener(inv); } catch (_) {}
    try { StudyController.instance.addListener(inv); } catch (_) {}
    try { SubjectController.instance.addListener(inv); } catch (_) {}
    try { AcademicKnowledgeController.instance.addListener(inv); } catch (_) {}
    try { TopicPracticeController.instance.addListener(inv); } catch (_) {}
    try { RevisionController.instance.addListener(inv); } catch (_) {}
    try { ExamController.instance.addListener(inv); } catch (_) {}
    try { FocusController.instance.addListener(inv); } catch (_) {}
    try { GoalController.instance.addListener(inv); } catch (_) {}
    try { AcademicScheduleController.instance.addListener(inv); } catch (_) {}
    try { UserPreferencesController.instance.addListener(inv); } catch (_) {}
  }

  AvailableTimeBudget get selectedBudget => _selectedBudget;
  bool get isGentleRecoveryMode => _gentleRecoveryMode;
  bool get isDoneForToday => _isDoneForToday;

  /// Current academic context derived from all active controllers.
  AcademicContext get currentContext => AcademicContext.fromControllers();

  /// Ranked academic actions derived from current context.
  List<PrioritizedAction> get rankedActions =>
      _priorityEngine.derivePrioritizedActions(currentContext);

  /// The highest priority single action right now (Next Best Action).
  PrioritizedAction? get nextBestAction {
    final actions = rankedActions;
    return actions.isNotEmpty ? actions.first : null;
  }

  /// Central Student OS "What Should I Do Now?" action.
  StudentOSAction get studentOSAction {
    final fc = FocusController.instance;
    return StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.upcomingExams,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      resources: ResourceController.instance.resources,
      blocks: PlanningBlockController.instance.blocks,
      personalGoal: GoalController.instance.personalGoal,
      hasActiveFocus: fc.hasActiveSession,
      activeFocusObjective: fc.activeSession?.objective,
      activeFocusRemaining: fc.activeRemaining,
      activeFocusElapsed: fc.activeElapsed,
      isDoneForToday: _isDoneForToday,
    );
  }

  /// Real-time compact Daily Student State.
  DailyStudentState get dailyStudentState {
    final fc = FocusController.instance;
    return StudentOSIntelligenceEngine.computeDailyStudentState(
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.upcomingExams,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      blocks: PlanningBlockController.instance.blocks,
      resources: ResourceController.instance.resources,
      availableBudgetMinutes: _selectedBudget.minutes,
      hasActiveFocus: fc.hasActiveSession,
      activeFocusObjective: fc.activeSession?.objective,
      isDoneForToday: _isDoneForToday,
    );
  }

  /// Real-time Autopilot 2.0 Day State.
  AutopilotDayState get autopilotDayState {
    final mode = UserPreferencesController.instance.autopilotMode;
    return StudentOSAutopilotEngine.computeAutopilotDayState(
      targetDay: DateTime.now(),
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.upcomingExams,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      blocks: PlanningBlockController.instance.blocks,
      resources: ResourceController.instance.resources,
      availableBudgetMinutes: _selectedBudget.minutes,
      isDoneForToday: _isDoneForToday,
      mode: mode,
    );
  }

  /// Executes "Start My Day" by launching the first actionable item directly into Focus.
  void startMyDay(BuildContext context) {
    final state = autopilotDayState;
    UniversalActionExecutor.executeAction(context, state.startMyDayAction);
  }

  /// Executes "Continue My Day" by launching the next actionable item into Focus.
  void continueMyDay(BuildContext context) {
    final state = autopilotDayState;
    if (state.continueMyDayAction != null) {
      UniversalActionExecutor.executeAction(context, state.continueMyDayAction!);
    } else {
      UniversalActionExecutor.executeAction(context, state.nextAction);
    }
  }

  /// Rebalances overloaded day safely via PlanningEngine.
  Future<int> rebalanceDay({DateTime? targetDay}) async {
    final day = targetDay ?? DateTime.now();
    final count = await PlanningEngine.rebalanceOverloadedDay(
      day,
      tasks: TaskController.instance.tasks,
      availableMinutes: _selectedBudget.minutes,
    );
    notifyListeners();
    return count;
  }

  /// Recovers a missed session safely into next available slot today.
  Future<PlanningBlock?> recoverMissedSession(MissedSession session, {DateTime? newStartTime}) async {
    final block = await PlanningEngine.rescheduleMissedSession(session, newStartTime: newStartTime);
    notifyListeners();
    return block;
  }

  /// Morning / Daily Briefing summary.
  DailyBriefing get dailyBriefing {
    return StudentOSIntelligenceEngine.generateDailyBriefing(
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.upcomingExams,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      blocks: PlanningBlockController.instance.blocks,
      resources: ResourceController.instance.resources,
      isDoneForToday: _isDoneForToday,
    );
  }

  /// Detected academic risk signals.
  List<AcademicRisk> get academicRisks {
    return StudentOSIntelligenceEngine.detectAcademicRisks(
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.upcomingExams,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      blocks: PlanningBlockController.instance.blocks,
      resources: ResourceController.instance.resources,
      availableBudgetMinutes: _selectedBudget.minutes,
    );
  }

  /// Goal progress and workload intelligence summary.
  GoalIntelligenceSummary? get goalIntelligence {
    return StudentOSIntelligenceEngine.assessGoalIntelligence(
      goalController: GoalController.instance,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
    );
  }

  /// Previews an Autopilot plan for [targetDay].
  AutopilotPlanPreview generateAutopilotPlan({
    DateTime? targetDay,
    int? budgetMinutes,
    DateTime? baseStartTime,
  }) {
    final day = targetDay ?? DateTime.now();
    final budget = budgetMinutes ?? _selectedBudget.minutes;
    final mode = UserPreferencesController.instance.autopilotMode;

    return StudentOSIntelligenceEngine.generateAutopilotPlan(
      targetDay: day,
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.upcomingExams,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      blocks: PlanningBlockController.instance.blocks,
      availableBudgetMinutes: budget,
      mode: mode,
      baseStartTime: baseStartTime,
    );
  }

  /// Safely applies an Autopilot plan via the PlanningEngine without duplicating blocks.
  Future<List<PlanningBlock>> applyAutopilotPlan(AutopilotPlanPreview preview, {DateTime? targetDay}) async {
    final day = targetDay ?? DateTime.now();
    final planResult = PlanningEngine.generateDailyPlan(
      day,
      tasks: TaskController.instance.tasks,
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.upcomingExams,
      blocks: PlanningBlockController.instance.blocks,
      availableBudgetMinutes: preview.availableBudgetMinutes,
    );

    final appliedBlocks = await PlanningEngine.applyDailyPlan(planResult);
    notifyListeners();
    return appliedBlocks;
  }

  /// Generates the best 30-minute academic burst action.
  StudentOSAction get thirtyMinuteBurstAction {
    return StudentOSIntelligenceEngine.generateThirtyMinuteBurst(
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.upcomingExams,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      resources: ResourceController.instance.resources,
    );
  }

  /// Current tailored TodayPlan based on selected time budget.
  TodayPlan get currentPlan {
    return _planEngine.generatePlan(
      context: currentContext,
      budget: _selectedBudget,
      gentleRecoveryMode: _gentleRecoveryMode,
    );
  }

  /// Unified study & academic recommendation combining Subjects, Exams, Study History, Revision & Tasks.
  UnifiedRecommendationResult get unifiedRecommendation {
    final subjects = SubjectController.instance.activeSubjects;
    final exams = ExamController.instance.upcomingExams;
    final sessions = StudyController.instance.sessions;
    final tasks = TaskController.instance.tasks;
    final resources = ResourceController.instance.resources;

    return AcademicIntelligenceEngine.generateUnifiedRecommendation(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      resources: resources,
    );
  }

  /// The single primary study recommendation for "What Should I Study Now?".
  StudyRecommendation? get primaryStudyRecommendation =>
      unifiedRecommendation.primary;

  /// Alternative study recommendations.
  List<StudyRecommendation> get alternativeStudyRecommendations =>
      unifiedRecommendation.alternatives;

  /// Active revision recommendations.
  List<RevisionRecommendation> get revisionRecommendations =>
      unifiedRecommendation.revisionItems;

  /// Assesses the exam pressure for a specific exam.
  ExamPressureAssessment examPressure(StudentExam exam) {
    return AcademicIntelligenceEngine.assessExamPressure(
      exam,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      subjects: SubjectController.instance.subjects,
    );
  }

  /// Detailed preparation breakdown for an exam.
  ExamPreparationBreakdown examPreparationBreakdown(StudentExam exam) {
    return AcademicIntelligenceEngine.getExamPreparationBreakdown(
      exam,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      subjects: SubjectController.instance.subjects,
    );
  }

  /// Generates a study time allocation schedule for [minutes] available.
  StudyTimeAllocation allocateStudyTime({int? minutes}) {
    final availableMinutes = minutes ?? _selectedBudget.minutes;
    return AcademicIntelligenceEngine.allocateStudyTime(
      availableMinutes: availableMinutes,
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.upcomingExams,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
    );
  }

  /// Sets the student's available study time budget for today.
  void setTimeBudget(AvailableTimeBudget budget) {
    if (_selectedBudget != budget) {
      _selectedBudget = budget;
      _cachedState = null;
      _cachedStateTime = null;
      notifyListeners();
    }
  }

  /// Toggles gentle recovery mode (reducing plan pressure to top 2 actions).
  void setGentleRecoveryMode(bool enabled) {
    if (_gentleRecoveryMode != enabled) {
      _gentleRecoveryMode = enabled;
      _cachedState = null;
      _cachedStateTime = null;
      notifyListeners();
    }
  }

  /// Sets the "Done for Today" state.
  void setDoneForToday(bool done) {
    if (_isDoneForToday != done) {
      _isDoneForToday = done;
      _cachedState = null;
      _cachedStateTime = null;
      notifyListeners();
    }
  }

  // ─── P3: Authoritative derived StudentState snapshot (single pipeline) ───
  StudentStateSnapshot get studentStateSnapshot {
    // Cache for 30s or until source invalidation
    final now = DateTime.now();
    if (_cachedState != null && _cachedStateTime != null && now.difference(_cachedStateTime!).inSeconds < 30) {
      return _cachedState!;
    }
    final snap = StudentStateSnapshot.fromControllers(
      referenceTime: now,
      availableMinutes: _selectedBudget.minutes,
    );
    _cachedState = snap;
    _cachedStateTime = now;
    return snap;
  }

  // ─── Learning debt (P3: consolidate if already implemented) ───
  int get learningDebtCount => studentStateSnapshot.incompleteSyllabusCount + studentStateSnapshot.dueRevisionCount + studentStateSnapshot.weakTopics.length;

  // ─── Why This? helper ───
  List<String> whyThisForAction(StudentOSAction action) => action.bulletReasons;

  /// Refreshes intelligence calculations and invalidates snapshot cache.
  void refresh() {
    _cachedState = null;
    _cachedStateTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}


