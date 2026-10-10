import 'guide_registry.dart';

/// Assistant ↔ Guide bridge (learning layer only).
///
/// Matches explicit "teach me" phrasing to a guide WITHOUT touching the
/// Assistant engine: [matchGuide] is a pure function consulted by
/// [StudentAssistantController.ask] before normal processing. Only explicit
/// guide phrasing matches — real questions always flow to the engine.
abstract final class GuideAssistantBridge {
  /// Returns the guide title for an explicit guide request, or null.
  static String? matchGuideTitle(String query) {
    final id = GuideRegistry.matchQuery(query);
    if (id == null) {
      return null;
    }
    final def = GuideRegistry.byId(id);
    return def?.title;
  }

  /// Returns the guide id for an explicit guide request, or null.
  static String? matchGuideId(String query) =>
      GuideRegistry.matchQuery(query);

  /// Honest launch message — promises a guide, never a completed action.
  static String launchMessage(String guideTitle) =>
      'I\u2019ll show you. Opening the interactive guide for $guideTitle now — '
      'it will walk you through the real screen, step by step.';
}
