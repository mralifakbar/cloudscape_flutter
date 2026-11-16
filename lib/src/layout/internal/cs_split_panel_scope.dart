import 'package:flutter/widgets.dart';

/// Where the split panel docks (Cloudscape `splitPanelPreferences.position`).
enum CsSplitPanelPosition {
  /// Under the content, full content width.
  bottom,

  /// Beside the content, between it and the tools panel.
  side,
}

/// State the app layout hands to the [CsSplitPanel] it hosts. Internal
/// plumbing between `CsAppLayout` and `CsSplitPanel`.
class CsSplitPanelScope extends InheritedWidget {
  const CsSplitPanelScope({
    super.key,
    required this.open,
    required this.position,
    required this.size,
    required this.minSize,
    required this.maxSize,
    required this.sideAvailable,
    required this.narrow,
    required this.onToggle,
    required this.onResize,
    required this.onPositionChange,
    required super.child,
  });

  final bool open;
  final CsSplitPanelPosition position;
  final double size;
  final double minSize;
  final double maxSize;

  /// False when the window is too narrow for a side panel, so the
  /// preferences disable the side option.
  final bool sideAvailable;

  /// Phone layout: the open panel takes the full screen.
  final bool narrow;
  final VoidCallback onToggle;
  final ValueChanged<double> onResize;
  final ValueChanged<CsSplitPanelPosition> onPositionChange;

  static CsSplitPanelScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CsSplitPanelScope>();

  @override
  bool updateShouldNotify(CsSplitPanelScope old) =>
      old.open != open ||
      old.position != position ||
      old.size != size ||
      old.minSize != minSize ||
      old.maxSize != maxSize ||
      old.sideAvailable != sideAvailable ||
      old.narrow != narrow ||
      old.onToggle != onToggle ||
      old.onResize != onResize ||
      old.onPositionChange != onPositionChange;
}
