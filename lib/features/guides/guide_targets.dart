import 'package:flutter/material.dart';

/// Stable semantic target registration for guide spotlights.
///
/// Screens wrap real controls in [GuideTargetAnchor] with a stable id
/// (e.g. `'sprintx.startTimer'`). The overlay resolves the id to a screen
/// rect at show time — no coordinates are stored, so responsive layouts,
/// scrolling and rebuilds are tolerated. Missing anchors degrade to a
/// fallback coach card, never a crash.
class GuideTargetRegistry {
  GuideTargetRegistry._();

  static final GuideTargetRegistry instance = GuideTargetRegistry._();

  final Map<String, GlobalKey> _keys = {};

  void register(String id, GlobalKey key) {
    _keys[id] = key;
  }

  void unregister(String id, GlobalKey key) {
    if (_keys[id] == key) {
      _keys.remove(id);
    }
  }

  /// Screen rect of the anchor, or null when absent/offstage.
  Rect? rectOf(String id) {
    final key = _keys[id];
    final context = key?.currentContext;
    if (context == null) {
      return null;
    }
    try {
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) {
        return null;
      }
      final topLeft = box.localToGlobal(Offset.zero);
      return topLeft & box.size;
    } catch (_) {
      return null;
    }
  }

  bool contains(String id) => _keys.containsKey(id);

  @visibleForTesting
  void debugReset() => _keys.clear();
}

/// Wraps a REAL control so guides can spotlight it by stable id.
class GuideTargetAnchor extends StatefulWidget {
  const GuideTargetAnchor({
    super.key,
    required this.id,
    required this.child,
  });

  final String id;
  final Widget child;

  @override
  State<GuideTargetAnchor> createState() => _GuideTargetAnchorState();
}

class _GuideTargetAnchorState extends State<GuideTargetAnchor> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    GuideTargetRegistry.instance.register(widget.id, _key);
  }

  @override
  void didUpdateWidget(covariant GuideTargetAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      GuideTargetRegistry.instance.unregister(oldWidget.id, _key);
      GuideTargetRegistry.instance.register(widget.id, _key);
    }
  }

  @override
  void dispose() {
    GuideTargetRegistry.instance.unregister(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(key: _key, child: widget.child);
  }
}
