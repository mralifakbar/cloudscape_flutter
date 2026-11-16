import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'internal/cs_resize_handle.dart';

/// Which side the panel sits on (Cloudscape `panelPosition`).
enum CsPanelPosition { sideStart, sideEnd }

/// What a [CsPanelLayout] shows (Cloudscape `display`).
enum CsPanelLayoutDisplay {
  /// Panel and main content side by side.
  all,

  /// Only the panel, full width.
  panelOnly,

  /// Only the main content.
  mainOnly,
}

/// Sizes reported by [CsPanelLayout.onPanelResize] and
/// [CsPanelLayout.onLayoutChange].
@immutable
class CsPanelResizeDetail {
  const CsPanelResizeDetail({required this.totalSize, required this.panelSize});

  /// Width of the whole layout.
  final double totalSize;

  /// Width of the panel.
  final double panelSize;

  @override
  bool operator ==(Object other) =>
      other is CsPanelResizeDetail && other.totalSize == totalSize && other.panelSize == panelSize;

  @override
  int get hashCode => Object.hash(totalSize, panelSize);
}

/// Copy for [CsPanelLayout].
@immutable
class CsPanelLayoutI18nStrings {
  const CsPanelLayoutI18nStrings({this.resizeHandleAriaLabel, this.resizeHandleTooltipText});

  /// Defaults to "Resize panel".
  final String? resizeHandleAriaLabel;
  final String? resizeHandleTooltipText;
}

/// Cloudscape's `PanelLayout`: a side panel next to main content, with a
/// draggable divider between them.
///
/// ```dart
/// CsPanelLayout(
///   panelContent: const Text('Filters'),
///   mainContent: const Text('Results'),
///   resizable: true,
/// )
/// ```
///
/// The panel starts at [defaultPanelSize] (200px) and the layout keeps the
/// size itself; pass [panelSize] and [onPanelResize] to control it. The size
/// is clamped between [minPanelSize] and the smaller of [maxPanelSize] and
/// the layout width. Drag the handle, or focus it and use the arrow keys
/// (10px), Page Up / Page Down (60px), Home and End. Use [display] to show
/// one side at a time on phones.
class CsPanelLayout extends StatefulWidget {
  const CsPanelLayout({
    super.key,
    required this.panelContent,
    required this.mainContent,
    this.panelPosition = CsPanelPosition.sideStart,
    this.defaultPanelSize,
    this.panelSize,
    this.minPanelSize,
    this.maxPanelSize,
    this.resizable = false,
    this.display = CsPanelLayoutDisplay.all,
    this.scrollable = false,
    this.panelSemanticLabel,
    this.mainSemanticLabel,
    this.i18nStrings = const CsPanelLayoutI18nStrings(),
    this.onPanelResize,
    this.onLayoutChange,
  });

  final Widget panelContent;
  final Widget mainContent;
  final CsPanelPosition panelPosition;

  /// Starting width when uncontrolled. Defaults to [minPanelSize] or 200.
  final double? defaultPanelSize;

  /// Controlled panel width.
  final double? panelSize;
  final double? minPanelSize;
  final double? maxPanelSize;

  /// Shows the drag handle.
  final bool resizable;
  final CsPanelLayoutDisplay display;

  /// Lets each side scroll on its own. Needs a bounded height.
  final bool scrollable;

  /// Names the panel region (Cloudscape `panelFocusable.ariaLabel`).
  final String? panelSemanticLabel;

  /// Names the main region (Cloudscape `mainFocusable.ariaLabel`).
  final String? mainSemanticLabel;
  final CsPanelLayoutI18nStrings i18nStrings;

  /// The user resized the panel.
  final ValueChanged<CsPanelResizeDetail>? onPanelResize;

  /// The rendered sizes changed, from a resize or a new layout width.
  final ValueChanged<CsPanelResizeDetail>? onLayoutChange;

  @override
  State<CsPanelLayout> createState() => _CsPanelLayoutState();
}

class _CsPanelLayoutState extends State<CsPanelLayout> {
  late double _own;
  CsPanelResizeDetail? _lastLayout;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _own = widget.defaultPanelSize ?? widget.minPanelSize ?? 200;
  }

  double get _requested => widget.panelSize ?? _own;

  double _clamp(double v, double total) {
    final maxSize = math.min(widget.maxPanelSize ?? total, total);
    final minSize = widget.minPanelSize ?? 0;
    return math.max(math.min(v, maxSize), minSize);
  }

  void _resizeTo(double next) {
    final clamped = _clamp(next, _total);
    if (widget.panelSize == null) setState(() => _own = clamped);
    widget.onPanelResize?.call(CsPanelResizeDetail(totalSize: _total, panelSize: clamped));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxWidth;
        _total = total;
        final size = _clamp(_requested, total);
        final detail = CsPanelResizeDetail(totalSize: total, panelSize: size);
        if (detail != _lastLayout) {
          _lastLayout = detail;
          if (widget.onLayoutChange != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onLayoutChange?.call(detail);
            });
          }
        }

        Widget wrap(Widget child, String? label) {
          Widget w = DefaultTextStyle.merge(style: context.cs.body, child: child);
          if (widget.scrollable) w = SingleChildScrollView(child: w);
          return Semantics(container: true, label: label, explicitChildNodes: true, child: w);
        }

        final panel = wrap(widget.panelContent, widget.panelSemanticLabel);
        final main = wrap(widget.mainContent, widget.mainSemanticLabel);
        switch (widget.display) {
          case CsPanelLayoutDisplay.panelOnly:
            return panel;
          case CsPanelLayoutDisplay.mainOnly:
            return main;
          case CsPanelLayoutDisplay.all:
            break;
        }
        final start = widget.panelPosition == CsPanelPosition.sideStart;
        final handle = widget.resizable
            ? CsResizeHandle(
                axis: CsResizeAxis.horizontal,
                size: size,
                min: widget.minPanelSize ?? 0,
                max: math.min(widget.maxPanelSize ?? total, total),
                growDirection: start ? 1 : -1,
                semanticLabel: widget.i18nStrings.resizeHandleAriaLabel ?? 'Resize panel',
                tooltip: widget.i18nStrings.resizeHandleTooltipText,
                onResizeTo: _resizeTo,
                onDrag: (dx) {
                  final rtl = Directionality.of(context) == TextDirection.rtl;
                  final d = (rtl ? -dx : dx) * (start ? 1 : -1);
                  _resizeTo(_requested + d);
                },
              )
            : null;
        final panelBox = SizedBox(
          width: size,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: start ? [Expanded(child: panel), ?handle] : [?handle, Expanded(child: panel)],
          ),
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: start ? [panelBox, Expanded(child: main)] : [Expanded(child: main), panelBox],
        );
      },
    );
  }
}
