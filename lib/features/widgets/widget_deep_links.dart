import 'package:flutter/foundation.dart';

/// Widget deep-link targets. URIs look like `studentos://widget/tasks` or
/// `studentos://widget/exam?id=abc`. The `studentos` scheme carries no
/// underscore so platform URI parsers accept it (unlike the legacy
/// underscore variant); it never collides with the `login-callback`
/// OAuth host.
enum WidgetDeepLinkTarget {
  home,
  assistant,
  tasks,
  planning,
  focus,
  exam,
  sleep,
  progress,
  addTask,
  addExam,
  customFocus,
  premium,
  unknown,
}

@immutable
class WidgetDeepLink {
  const WidgetDeepLink({required this.target, this.id, this.minutes, this.feature});

  final WidgetDeepLinkTarget target;
  final String? id;
  final int? minutes;

  /// Premium feature id for [WidgetDeepLinkTarget.premium] taps.
  final String? feature;

  bool get isKnown => target != WidgetDeepLinkTarget.unknown;
}

/// Parses widget tap URIs. Never throws: unparseable input yields
/// [WidgetDeepLinkTarget.unknown] so callers fall back to Home.
abstract final class WidgetDeepLinks {
  static const String scheme = 'studentos';
  static const String widgetHost = 'widget';

  static WidgetDeepLink parse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const WidgetDeepLink(target: WidgetDeepLinkTarget.unknown);
    }
    try {
      final uri = Uri.tryParse(raw);
      if (uri == null || uri.scheme != scheme) {
        return const WidgetDeepLink(target: WidgetDeepLinkTarget.unknown);
      }
      // Accept `studentos://widget/tasks` (host form).
      final segments = uri.pathSegments;
      final first = segments.isEmpty ? '' : segments.first.toLowerCase();
      final id = uri.queryParameters['id'];
      final feature = uri.queryParameters['feature'];
      var minutes = int.tryParse(uri.queryParameters['minutes'] ?? '');
      if (minutes != null && (minutes < 1 || minutes > 360)) {
        minutes = null;
      }
      return WidgetDeepLink(
        target: _targetFor(first),
        id: (id != null && id.isNotEmpty) ? id : null,
        minutes: minutes,
        feature: (feature != null && feature.isNotEmpty) ? feature : null,
      );
    } catch (_) {
      return const WidgetDeepLink(target: WidgetDeepLinkTarget.unknown);
    }
  }

  static WidgetDeepLinkTarget _targetFor(String segment) {
    return switch (segment) {
      'home' => WidgetDeepLinkTarget.home,
      'assistant' => WidgetDeepLinkTarget.assistant,
      'tasks' => WidgetDeepLinkTarget.tasks,
      'planning' => WidgetDeepLinkTarget.planning,
      'focus' => WidgetDeepLinkTarget.focus,
      'exam' => WidgetDeepLinkTarget.exam,
      'sleep' => WidgetDeepLinkTarget.sleep,
      'progress' => WidgetDeepLinkTarget.progress,
      'add-task' => WidgetDeepLinkTarget.addTask,
      'add-exam' => WidgetDeepLinkTarget.addExam,
      'custom-focus' => WidgetDeepLinkTarget.customFocus,
      'premium' => WidgetDeepLinkTarget.premium,
      _ => WidgetDeepLinkTarget.unknown,
    };
  }

  /// Canonical deep link for a catalog widget entry.
  static String linkFor(String deepLink) => deepLink;
}
