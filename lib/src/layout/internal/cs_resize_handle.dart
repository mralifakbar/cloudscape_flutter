import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../system/cs_focus_ring.dart';
import '../../theme/theme.dart';

/// Which way a [CsResizeHandle] drags.
enum CsResizeAxis {
  /// Drags left and right; resizes a side panel.
  horizontal,

  /// Drags up and down; resizes a bottom panel.
  vertical,
}

/// The drag handle Cloudscape puts on resizable panels
/// (`internal/components/panel-resize-handle`): split panels, drawers and
/// the panel layout.
///
/// Dragging reports deltas in logical pixels along [axis]. Arrow keys resize
/// in 10px steps and Page Up / Page Down in 60px steps
/// (`app-layout/utils/use-keyboard-events.ts`), Home and End jump to the
/// limits. [growDirection] is the drag direction that makes the panel larger
/// (+1 for right or down, -1 for left or up), so keyboard arrows grow and
/// shrink the panel the way Cloudscape does.
///
/// This is an internal part of the layout components and is not exported.
class CsResizeHandle extends StatefulWidget {
  const CsResizeHandle({
    super.key,
    required this.axis,
    required this.onDrag,
    required this.size,
    this.growDirection = 1,
    this.min = 0,
    this.max = double.infinity,
    this.onResizeTo,
    this.onDragEnd,
    this.semanticLabel = 'Resize panel',
    this.tooltip,
  });

  final CsResizeAxis axis;

  /// Raw pointer delta along [axis], in logical pixels.
  final ValueChanged<double> onDrag;

  /// Current panel size, used for keyboard steps and the semantic value.
  final double size;
  final double growDirection;
  final double min;
  final double max;

  /// Requested absolute size from the keyboard. Falls back to [onDrag].
  final ValueChanged<double>? onResizeTo;
  final VoidCallback? onDragEnd;
  final String semanticLabel;
  final String? tooltip;

  @override
  State<CsResizeHandle> createState() => _CsResizeHandleState();
}

class _CsResizeHandleState extends State<CsResizeHandle> {
  late final FocusNode _focus;
  bool _focusVisible = false;
  bool _hovered = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode(debugLabel: 'CsResizeHandle');
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    final visible = _focus.hasFocus && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (visible != _focusVisible) setState(() => _focusVisible = visible);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  void _resizeTo(double next) {
    final clamped = next.clamp(widget.min, widget.max < widget.min ? widget.min : widget.max).toDouble();
    if (widget.onResizeTo != null) {
      widget.onResizeTo!(clamped);
    } else {
      widget.onDrag((clamped - widget.size) * widget.growDirection);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    final horizontal = widget.axis == CsResizeAxis.horizontal;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    double? step;
    if (horizontal && (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.arrowLeft)) {
      var dir = k == LogicalKeyboardKey.arrowRight ? 1.0 : -1.0;
      if (rtl) dir = -dir;
      step = 10 * dir * widget.growDirection;
    } else if (!horizontal && (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowUp)) {
      final dir = k == LogicalKeyboardKey.arrowDown ? 1.0 : -1.0;
      step = 10 * dir * widget.growDirection;
    } else if (k == LogicalKeyboardKey.pageUp) {
      step = 60;
    } else if (k == LogicalKeyboardKey.pageDown) {
      step = -60;
    } else if (k == LogicalKeyboardKey.home) {
      _resizeTo(widget.min);
      return KeyEventResult.handled;
    } else if (k == LogicalKeyboardKey.end) {
      if (widget.max.isFinite) _resizeTo(widget.max);
      return KeyEventResult.handled;
    }
    if (step == null) return KeyEventResult.ignored;
    _resizeTo(widget.size + step);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cs.colors;
    final horizontal = widget.axis == CsResizeAxis.horizontal;
    final active = _hovered || _dragging || _focusVisible;
    final color = active ? c.textInteractiveHover : c.textInteractiveDefault;
    // `panel-resize-handle`: an 18px hit strip with the drag handle glyph.
    Widget handle = SizedBox(
      width: horizontal ? 18 : 40,
      height: horizontal ? 40 : 18,
      child: CustomPaint(
        painter: _HandlePainter(color: color, horizontal: horizontal),
      ),
    );
    handle = CsFocusRing(visible: _focusVisible, borderRadius: BorderRadius.circular(4), child: handle);

    final drag = horizontal
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => setState(() => _dragging = true),
            onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
            onHorizontalDragEnd: (_) {
              setState(() => _dragging = false);
              widget.onDragEnd?.call();
            },
            onHorizontalDragCancel: () => setState(() => _dragging = false),
            child: Center(child: handle),
          )
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (_) => setState(() => _dragging = true),
            onVerticalDragUpdate: (d) => widget.onDrag(d.delta.dy),
            onVerticalDragEnd: (_) {
              setState(() => _dragging = false);
              widget.onDragEnd?.call();
            },
            onVerticalDragCancel: () => setState(() => _dragging = false),
            child: Center(child: handle),
          );

    return Semantics(
      label: widget.semanticLabel,
      hint: widget.tooltip,
      value: '${widget.size.round()}',
      slider: true,
      focusable: true,
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        child: MouseRegion(
          cursor: horizontal ? SystemMouseCursors.resizeColumn : SystemMouseCursors.resizeRow,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _focus.requestFocus(),
            child: SizedBox(width: horizontal ? 24 : null, height: horizontal ? null : 24, child: drag),
          ),
        ),
      ),
    );
  }
}

/// Two short parallel lines: Cloudscape's `resize-horizontal` / `resize-vertical` drag handle.
class _HandlePainter extends CustomPainter {
  const _HandlePainter({required this.color, required this.horizontal});

  final Color color;
  final bool horizontal;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    if (horizontal) {
      for (final dx in [-2.5, 2.5]) {
        canvas.drawLine(c + Offset(dx, -7), c + Offset(dx, 7), p);
      }
    } else {
      for (final dy in [-2.5, 2.5]) {
        canvas.drawLine(c + Offset(-7, dy), c + Offset(7, dy), p);
      }
    }
  }

  @override
  bool shouldRepaint(_HandlePainter old) => old.color != color || old.horizontal != horizontal;
}
