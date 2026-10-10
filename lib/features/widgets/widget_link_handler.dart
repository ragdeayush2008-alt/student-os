import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/app_router.dart';
import 'widget_deep_links.dart';

/// Wires home-screen widget taps into the app.
///
/// Sources (all funnel into [AppRouter.handleWidgetDeepLink]):
/// - Android widget clicks via `home_widget`'s click stream.
/// - `app_links` live stream (custom `studentos://` scheme, both platforms).
/// - Cold-start links (widget tap with the app terminated): parked as
///   pending and consumed once the authenticated shell mounts.
///
/// Non-widget links (e.g. the OAuth `login-callback` host) are ignored here.
class WidgetLinkHandler {
  WidgetLinkHandler._();

  static bool _started = false;

  static void init() {
    if (_started) return;
    _started = true;

    try {
      HomeWidget.widgetClicked.listen((uri) {
        if (uri == null) return;
        _handleRaw(uri.toString());
      });
    } catch (_) {}

    try {
      AppLinks().uriLinkStream.listen(
        (uri) {
          if (uri.scheme == WidgetDeepLinks.scheme &&
              uri.host == WidgetDeepLinks.widgetHost) {
            _handleRaw(uri.toString());
          }
        },
        onError: (_) {},
      );
    } catch (_) {}

    // Cold start: park for post-login consumption (navigator isn't ready
    // during main(), and the user may need to authenticate first).
    _parkInitialLink();
  }

  static void _handleRaw(String raw) {
    try {
      AppRouter.handleWidgetDeepLink(raw);
    } catch (_) {}
  }

  static Future<void> _parkInitialLink() async {
    try {
      final launched = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (launched != null &&
          launched.scheme == WidgetDeepLinks.scheme &&
          launched.host == WidgetDeepLinks.widgetHost) {
        AppRouter.pendingWidgetLink ??= launched.toString();
        return;
      }
    } catch (_) {}
    try {
      final initial = await AppLinks().getInitialLink();
      if (initial != null &&
          initial.scheme == WidgetDeepLinks.scheme &&
          initial.host == WidgetDeepLinks.widgetHost) {
        AppRouter.pendingWidgetLink ??= initial.toString();
      }
    } catch (_) {}
  }

  @visibleForTesting
  static void resetForTesting() {
    _started = false;
  }
}
