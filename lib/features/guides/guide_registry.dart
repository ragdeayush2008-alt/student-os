import 'guides_catalog.dart';
import 'models/guide_models.dart';

/// Static registry of all interactive guides (learning layer only).
///
/// Guides are data: id, metadata, ordered steps. The engine interprets them,
/// so adding a guide never requires a new tutorial implementation.
abstract final class GuideRegistry {
  static List<GuideDefinition> get all => GuidesCatalog.all;

  static GuideDefinition? byId(String id) {
    for (final g in all) {
      if (g.id == id) {
        return g;
      }
    }
    return null;
  }

  static List<GuideDefinition> inCategory(GuideCategory category) =>
      all.where((g) => g.category == category).toList();

  /// Progressive discovery: advanced guides unlock after their basics.
  static bool isUnlocked(
    GuideDefinition guide,
    Map<String, GuideProgress> progress,
  ) {
    for (final pre in guide.unlockAfter) {
      if (progress[pre]?.status != GuideStatus.completed) {
        return false;
      }
    }
    return true;
  }

  /// Keyword match for Assistant "how do I use X" queries. Returns the best
  /// guide id, or null. Pure function — safe to unit test.
  static String? matchQuery(String query) {
    final q = query.toLowerCase();
    final hasGuidePhrasing = q.contains('how do i use') ||
        q.contains('how to use') ||
        q.contains('show me how') ||
        q.contains('teach me') ||
        q.contains('guide for') ||
        q.contains('guide to') ||
        q.contains('walk me through') ||
        q.contains('how does') ||
        (q.contains('what can') && q.contains('assistant'));
    if (!hasGuidePhrasing) {
      return null;
    }
    if (q.contains('deep focus')) {
      return 'deep_focus';
    }
    if (q.contains('custom focus') || q.contains('custom duration')) {
      return 'custom_focus';
    }
    if (q.contains('sprintx') ||
        (q.contains('focus') && !q.contains('deep'))) {
      return 'sprintx';
    }
    if (q.contains('sleep') || q.contains('bedtime')) {
      return 'sleep';
    }
    if ((q.contains('exam plan')) ||
        (q.contains('prepare') && q.contains('exam'))) {
      return 'exam_planning';
    }
    if (q.contains('exam')) {
      return 'add_exam';
    }
    if (q.contains('task')) {
      return 'tasks';
    }
    if (q.contains('revision')) {
      return 'revision';
    }
    if (q.contains('plan') && !q.contains('exam')) {
      return 'planning';
    }
    if (q.contains('tool') ||
        q.contains('calculator') ||
        q.contains('checklist') ||
        q.contains('habit') ||
        (q.contains('note') && !q.contains('notebook'))) {
      return 'tools';
    }
    if (q.contains('reward') || q.contains('xp')) {
      return 'rewards';
    }
    if (q.contains('progress') || q.contains('momentum')) {
      return 'progress';
    }
    if (q.contains('assistant')) {
      return 'assistant';
    }
    if (q.contains('home')) {
      return 'home';
    }
    // Generic "how does this work" with no feature keyword → basics.
    if (q.contains('how does this work')) {
      return 'basics';
    }
    return null;
  }
}
