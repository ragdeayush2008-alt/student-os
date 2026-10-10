import '../../features/notes/student_note_controller.dart';
import '../../features/goals/goal_controller.dart';
import '../../features/planning/controllers/planning_block_controller.dart';
import '../../features/planning/plan_controller.dart';
import '../../features/progression/progression_controller.dart';
import '../../features/progression/achievement_controller.dart';
import '../../features/progression/leaderboard_controller.dart';
import '../../features/preferences/user_preferences_controller.dart';
import '../../features/resources/resource_controller.dart';
import '../../features/rewards/redemption_controller.dart';
import '../../features/subjects/subject_controller.dart';
import '../../features/tasks/task_controller.dart';
import '../../features/study/study_controller.dart';
import '../../features/exams/exam_controller.dart';
import '../../features/focus/controller/focus_controller.dart';
import '../../features/knowledge/academic_knowledge_controller.dart';
import '../../features/knowledge/practice_question_controller.dart';
import '../../features/knowledge/topic_practice_controller.dart';
import '../../features/notifications/notification_controller.dart';
import '../../features/revision/revision_controller.dart';
import '../../features/calendar/academic_schedule_controller.dart';
import '../assistant/student_assistant_controller.dart';
import '../assistant/daily_assistant_controller.dart';
import '../../features/premium/services/entitlement_service.dart';
import '../../core/intelligence/academic_intelligence_controller.dart';
import '../../core/intelligence/daily_os_coordinator.dart';
import '../../core/services/student_service.dart';
import '../../core/services/course_catalog_service.dart';
import '../../features/checklist/checklist_controller.dart';
import '../../features/habits/habit_controller.dart';
import '../../features/widgets/services/widget_data_service.dart';
import '../../features/student_life/student_life_controller.dart';
import '../../features/sleep/sleep_controller.dart';

/// Resets all user-scoped in-memory controllers on session change.
/// Does NOT delete persistent StorageService data.
class ControllerIsolation {
  ControllerIsolation._();
  static final ControllerIsolation instance = ControllerIsolation._();

  bool _cleared = false;

  bool get isCleared => _cleared;

  /// Call when auth session changes (login/logout or user switch).
  void clearAllControllers() {
    _cleared = true;
    // Clear all controller in-memory state
    try {
      TaskController.instance.clearData();
    } catch (_) {}
    try {
      SubjectController.instance.clearData();
    } catch (_) {}
    try {
      AcademicKnowledgeController.instance.clearData();
    } catch (_) {}
    try {
      PracticeQuestionController.instance.clearData();
    } catch (_) {}
    try {
      TopicPracticeController.instance.clearData();
    } catch (_) {}
    try {
      ExamController.instance.clearData();
    } catch (_) {}
    try {
      StudyController.instance.clearData();
    } catch (_) {}
    try {
      FocusController.instance.clearData();
    } catch (_) {}
    try {
      PlanController.instance.clearData();
    } catch (_) {}
    try {
      PlanningBlockController.instance.clearData();
    } catch (_) {}
    try {
      GoalController.instance.clearData();
    } catch (_) {}
    try {
      ProgressionController.instance.clearData();
    } catch (_) {}
    try {
      AchievementController.instance.clearData();
    } catch (_) {}
    try {
      LeaderboardController.instance.clearData();
    } catch (_) {}
    try {
      ResourceController.instance.clearData();
    } catch (_) {}
    try {
      StudentNoteController.instance.clearData();
    } catch (_) {}
    try {
      RedemptionController.instance.clearData();
    } catch (_) {}
    try {
      UserPreferencesController.instance.clearData();
    } catch (_) {}
    try {
      AcademicIntelligenceController.instance.clearData();
    } catch (_) {}
    try {
      StudentService.instance.clearProfile();
    } catch (_) {}
    try {
      DailyOsCoordinator.instance.clearOnLogout();
    } catch (_) {}
    try {
      NotificationController.instance.clearData();
    } catch (_) {}
    try {
      RevisionController.instance.clearData();
    } catch (_) {}
    try {
      AcademicScheduleController.instance.clearData();
    } catch (_) {}
    try {
      StudentAssistantController.instance.clearData();
    } catch (_) {}
    try {
      ChecklistController.instance.clearData();
    } catch (_) {}
    try {
      HabitController.instance.clearData();
    } catch (_) {}
    try {
      StudentLifeController.instance.clearData();
    } catch (_) {}
    try {
      SleepController.instance.clearData();
    } catch (_) {}
    try {
      DailyAssistantController.instance.clearData();
    } catch (_) {}
    try {
      EntitlementService.instance.clearData();
    } catch (_) {}
    try {
      // Widgets must never show the previous user's data. Fire-and-forget:
      // isolation entry points are synchronous by design.
      WidgetDataService.instance.clearForLogout();
    } catch (_) {}
  }

  /// Call after login with new user to reload controllers for that user.
  void reloadAllControllers(String userId) {
    _cleared = false;
    try {
      NotificationController.instance.load();
    } catch (_) {}
    try {
      RevisionController.instance.load();
    } catch (_) {}
    try {
      AcademicScheduleController.instance.load();
    } catch (_) {}
    try {
      TaskController.instance.load();
    } catch (_) {}
    try {
      PlanningBlockController.instance.load();
    } catch (_) {}
    try {
      SubjectController.instance.load();
    } catch (_) {}
    try {
      AcademicKnowledgeController.instance.load();
    } catch (_) {}
    try {
      PracticeQuestionController.instance.load();
    } catch (_) {}
    try {
      TopicPracticeController.instance.load();
    } catch (_) {}
    try {
      ExamController.instance.load();
    } catch (_) {}
    try {
      StudyController.instance.load();
    } catch (_) {}
    try {
      FocusController.instance.load();
    } catch (_) {}
    try {
      GoalController.instance.load();
    } catch (_) {}
    try {
      ProgressionController.instance.load();
    } catch (_) {}
    try {
      AchievementController.instance.load();
    } catch (_) {}
    try {
      LeaderboardController.instance.load();
    } catch (_) {}
    try {
      ResourceController.instance.load();
    } catch (_) {}
    try {
      StudentNoteController.instance.load();
    } catch (_) {}
    try {
      ChecklistController.instance.load();
    } catch (_) {}
    try {
      HabitController.instance.load();
    } catch (_) {}
    try {
      StudentLifeController.instance.load();
    } catch (_) {}
    try {
      SleepController.instance.load();
    } catch (_) {}
    try {
      DailyAssistantController.instance.load();
    } catch (_) {}
    try {
      EntitlementService.instance.load();
    } catch (_) {}
    try {
      WidgetDataService.instance.init();
      WidgetDataService.instance.refreshNow();
    } catch (_) {}    try {
      RedemptionController.instance.load();
    } catch (_) {}
    try {
      UserPreferencesController.instance.load();
    } catch (_) {}
    try {
      StudentService.instance.load();
    } catch (_) {}
    try {
      CourseCatalogService.instance.loadActiveCourse();
    } catch (_) {}
    try {
      StudentAssistantController.instance.clearData();
    } catch (_) {}
    try {
      StudentAssistantController.instance.loadConversation();
    } catch (_) {}
  }
}
