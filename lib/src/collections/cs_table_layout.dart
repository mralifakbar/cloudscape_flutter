// Layout primitives for CsTable. Not exported from the package.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Which edge a sticky cell sticks to.
enum CsTablePin { start, end }

/// Computes column widths: fixed columns keep their width, flexible ones
/// share the rest above their minimum and stop at their maximum.
List<double> csTableColumnWidths({
  required List<double?> fixed,
  required List<double> min,
  required List<double?> max,
  required double available,
}) {
  final n = fixed.length;
  final widths = List<double>.filled(n, 0);
  final flexible = <int>[];
  var used = 0.0;
  for (var i = 0; i < n; i++) {
    final f = fixed[i];
    if (f != null) {
      widths[i] = f;
      used += f;
    } else {
      widths[i] = min[i];
      used += min[i];
      flexible.add(i);
    }
  }
  var extra = available - used;
  // Hand out the extra space evenly; a column that reaches its maximum
  // drops out and the rest share what it could not take.
  var open = flexible.where((i) => max[i] == null || widths[i] < max[i]!).toList();
  while (extra > 0.5 && open.isNotEmpty) {
    final share = extra / open.length;
    final next = <int>[];
    for (final i in open) {
      final cap = max[i];
      final room = cap == null ? double.infinity : cap - widths[i];
      final take = math.min(share, room);
      widths[i] += take;
      extra -= take;
      if (cap == null || widths[i] < cap - 0.01) next.add(i);
    }
    if (next.length == open.length) break;
    open = next;
  }
  return widths;
}

/// Lays out one row's cells at fixed widths, stretches them to the tallest
/// cell, and paints sticky cells last, shifted by the horizontal scroll
/// offset so they stay at the viewport's edge (CSS `position: sticky`). A
/// scroll only repaints; it never relayouts.
class CsTableRowLayout extends MultiChildRenderObjectWidget {
  const CsTableRowLayout({
    super.key,
    required this.widths,
    required this.pins,
    required this.controller,
    required this.background,
    required this.textDirection,
    required this.padStart,
    required this.shadowFirst,
    required this.shadowLast,
    required super.children,
    this.minHeight = 0,
  });

  final double minHeight;
  final List<double> widths;
  final List<CsTablePin?> pins;
  final ScrollController? controller;

  /// Painted behind sticky cells so scrolled content does not show through.
  final Color background;
  final TextDirection textDirection;

  /// Horizontal padding before the first cell in the scroll content.
  final double padStart;
  final List<BoxShadow> shadowFirst;
  final List<BoxShadow> shadowLast;

  @override
  RenderObject createRenderObject(BuildContext context) => CsRenderTableRow(
    widths: widths,
    pins: pins,
    controller: controller,
    background: background,
    textDirection: textDirection,
    minHeight: minHeight,
    padStart: padStart,
    shadowFirst: shadowFirst,
    shadowLast: shadowLast,
  );

  @override
  void updateRenderObject(BuildContext context, CsRenderTableRow renderObject) {
    renderObject
      ..minHeight = minHeight
      ..widths = widths
      ..pins = pins
      ..controller = controller
      ..background = background
      ..textDirection = textDirection
      ..padStart = padStart
      ..shadowFirst = shadowFirst
      ..shadowLast = shadowLast;
  }
}

class _RowParentData extends ContainerBoxParentData<RenderBox> {}

class CsRenderTableRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RowParentData> {
  CsRenderTableRow({
    required List<double> widths,
    required List<CsTablePin?> pins,
    required ScrollController? controller,
    required Color background,
    required TextDirection textDirection,
    required double minHeight,
    required double padStart,
    required List<BoxShadow> shadowFirst,
    required List<BoxShadow> shadowLast,
  }) : _minHeight = minHeight,
       _widths = widths,
       _pins = pins,
       _controller = controller,
       _background = background,
       _textDirection = textDirection,
       _padStart = padStart,
       _shadowFirst = shadowFirst,
       _shadowLast = shadowLast;

  double _minHeight;
  set minHeight(double value) {
    if (value == _minHeight) return;
    _minHeight = value;
    markNeedsLayout();
  }

  List<double> _widths;
  set widths(List<double> value) {
    if (listEquals(value, _widths)) return;
    _widths = value;
    markNeedsLayout();
  }

  List<CsTablePin?> _pins;
  set pins(List<CsTablePin?> value) {
    if (listEquals(value, _pins)) return;
    _pins = value;
    markNeedsPaint();
  }

  ScrollController? _controller;
  set controller(ScrollController? value) {
    if (value == _controller) return;
    if (attached) _controller?.removeListener(markNeedsPaint);
    _controller = value;
    if (attached) _controller?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  Color _background;
  set background(Color value) {
    if (value == _background) return;
    _background = value;
    markNeedsPaint();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  double _padStart;
  set padStart(double value) {
    if (value == _padStart) return;
    _padStart = value;
    markNeedsPaint();
  }

  List<BoxShadow> _shadowFirst;
  set shadowFirst(List<BoxShadow> value) {
    if (listEquals(value, _shadowFirst)) return;
    _shadowFirst = value;
    markNeedsPaint();
  }

  List<BoxShadow> _shadowLast;
  set shadowLast(List<BoxShadow> value) {
    if (listEquals(value, _shadowLast)) return;
    _shadowLast = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _controller?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RowParentData) child.parentData = _RowParentData();
  }

  List<RenderBox> get _children {
    final list = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      list.add(child);
      child = childAfter(child);
    }
    return list;
  }

  double get _total => _widths.fold(0.0, (a, b) => a + b);

  @override
  void performLayout() {
    final kids = _children;
    var height = _minHeight;
    for (var i = 0; i < kids.length; i++) {
      final w = i < _widths.length ? _widths[i] : 0.0;
      kids[i].layout(BoxConstraints.tightFor(width: w), parentUsesSize: true);
      height = math.max(height, kids[i].size.height);
    }
    var x = 0.0;
    final total = _total;
    for (var i = 0; i < kids.length; i++) {
      final w = i < _widths.length ? _widths[i] : 0.0;
      if (kids[i].size.height != height) {
        kids[i].layout(BoxConstraints.tightFor(width: w, height: height), parentUsesSize: true);
      }
      final dx = _textDirection == TextDirection.rtl ? total - x - w : x;
      (kids[i].parentData! as _RowParentData).offset = Offset(dx, 0);
      x += w;
    }
    size = constraints.constrain(Size(total, height));
  }

  @override
  double computeMinIntrinsicWidth(double height) => _total;

  @override
  double computeMaxIntrinsicWidth(double height) => _total;

  @override
  double computeMinIntrinsicHeight(double width) {
    var h = _minHeight;
    final kids = _children;
    for (var i = 0; i < kids.length && i < _widths.length; i++) {
      h = math.max(h, kids[i].getMinIntrinsicHeight(_widths[i]));
    }
    return h;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    var h = _minHeight;
    final kids = _children;
    for (var i = 0; i < kids.length && i < _widths.length; i++) {
      h = math.max(h, kids[i].getMaxIntrinsicHeight(_widths[i]));
    }
    return h;
  }

  /// Horizontal shift for a cell stuck to [pin] at the current scroll.
  double _shift(CsTablePin? pin) {
    final c = _controller;
    if (pin == null || c == null || !c.hasClients || !c.position.hasContentDimensions) return 0;
    final max = c.position.maxScrollExtent;
    if (max <= 0) return 0;
    final offset = c.offset.clamp(0.0, max);
    final ltr = _textDirection == TextDirection.ltr;
    final double logical = switch (pin) {
      CsTablePin.start => math.max(0, offset - _padStart),
      CsTablePin.end => math.min(0, offset - max + _padStart),
    };
    return ltr ? logical : -logical;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final kids = _children;
    for (var i = 0; i < kids.length; i++) {
      if (i < _pins.length && _pins[i] != null) continue;
      context.paintChild(kids[i], offset + (kids[i].parentData! as _RowParentData).offset);
    }
    final ltr = _textDirection == TextDirection.ltr;
    for (final pin in CsTablePin.values) {
      final shift = _shift(pin);
      Rect? group;
      final rects = <(int, Offset)>[];
      for (var i = 0; i < kids.length && i < _pins.length; i++) {
        if (_pins[i] != pin) continue;
        final at = offset + (kids[i].parentData! as _RowParentData).offset + Offset(shift, 0);
        final rect = at & kids[i].size;
        group = group == null ? rect : group.expandToInclude(rect);
        rects.add((i, at));
      }
      if (group == null) continue;
      if (shift != 0) {
        // Cloudscape's `shadow-sticky-column-first/last`, clipped so it only
        // falls on the scrolled content side.
        final outerRight = (pin == CsTablePin.start) == ltr;
        final shadows = pin == CsTablePin.start ? _shadowFirst : _shadowLast;
        final clip = outerRight
            ? Rect.fromLTRB(group.right, group.top, group.right + 24, group.bottom)
            : Rect.fromLTRB(group.left - 24, group.top, group.left, group.bottom);
        context.canvas.save();
        context.canvas.clipRect(clip);
        for (final s in shadows) {
          final dx = outerRight ? s.offset.dx.abs() : -s.offset.dx.abs();
          final r = group.shift(Offset(dx, 0)).inflate(s.spreadRadius);
          context.canvas.drawRect(r, s.toPaint());
        }
        context.canvas.restore();
      }
      context.canvas.drawRect(group, Paint()..color = _background);
      for (final (i, at) in rects) {
        context.paintChild(kids[i], at);
      }
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final kids = _children;
    for (var i = kids.length - 1; i >= 0; i--) {
      final pinned = i < _pins.length && _pins[i] != null;
      if (!pinned) continue;
      final at = (kids[i].parentData! as _RowParentData).offset + Offset(_shift(_pins[i]), 0);
      final hit = result.addWithPaintOffset(
        offset: at,
        position: position,
        hitTest: (result, transformed) => kids[i].hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    for (var i = kids.length - 1; i >= 0; i--) {
      final pinned = i < _pins.length && _pins[i] != null;
      if (pinned) continue;
      final at = (kids[i].parentData! as _RowParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: at,
        position: position,
        hitTest: (result, transformed) => kids[i].hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final i = _children.indexOf(child);
    final pinned = i >= 0 && i < _pins.length && _pins[i] != null;
    final at = (child.parentData! as _RowParentData).offset + Offset(pinned ? _shift(_pins[i]) : 0, 0);
    transform.translateByDouble(at.dx, at.dy, 0, 1);
  }
}

/// Keeps [child] at the viewport's width and position while the content
/// around it scrolls sideways (Cloudscape's sticky merged cells: the empty
/// state, the loading row, the header and footer).
class CsTableViewportPin extends StatelessWidget {
  const CsTableViewportPin({
    super.key,
    required this.controller,
    required this.viewportWidth,
    required this.contentWidth,
    required this.child,
  });

  final ScrollController? controller;
  final double viewportWidth;
  final double contentWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sized = SizedBox(width: viewportWidth, child: child);
    final c = controller;
    if (c == null || contentWidth <= viewportWidth + 0.5) {
      return SizedBox(width: contentWidth, child: sized);
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      width: contentWidth,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: AnimatedBuilder(
          animation: c,
          builder: (context, child) {
            final offset = c.hasClients ? c.offset.clamp(0.0, contentWidth - viewportWidth) : 0.0;
            return Transform.translate(offset: Offset(rtl ? -offset : offset, 0), child: child);
          },
          child: sized,
        ),
      ),
    );
  }
}

/// Paints a body row's divider and, for a selected row, Cloudscape's 2px
/// outline. Adjacent selected rows read as one block: the line between
/// them is a 1px placeholder and only the outer corners are rounded.
class CsTableRowDecorationPainter extends CustomPainter {
  const CsTableRowDecorationPainter({
    required this.divider,
    required this.dividerWidth,
    required this.selected,
    required this.prevSelected,
    required this.nextSelected,
    required this.selectedColor,
    required this.placeholderColor,
    required this.radius,
    required this.selectedWidth,
  });

  final Color? divider;
  final double dividerWidth;
  final bool selected;
  final bool prevSelected;
  final bool nextSelected;
  final Color selectedColor;
  final Color placeholderColor;
  final double radius;
  final double selectedWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (!selected) {
      final d = divider;
      if (d != null) {
        canvas.drawRect(Rect.fromLTWH(0, size.height - dividerWidth, size.width, dividerWidth), Paint()..color = d);
      }
      return;
    }
    final w = selectedWidth;
    final r = Radius.circular(radius);
    // Extend the outline past the edge that joins another selected row, so
    // the clip drops that edge and the sides run through.
    final outline = Rect.fromLTRB(
      rect.left + w / 2,
      prevSelected ? rect.top - w : rect.top + w / 2,
      rect.right - w / 2,
      nextSelected ? rect.bottom + w : rect.bottom - w / 2,
    );
    final rrect = RRect.fromRectAndCorners(
      outline,
      topLeft: prevSelected ? Radius.zero : r,
      topRight: prevSelected ? Radius.zero : r,
      bottomLeft: nextSelected ? Radius.zero : r,
      bottomRight: nextSelected ? Radius.zero : r,
    );
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = selectedColor,
    );
    canvas.restore();
    if (prevSelected) {
      canvas.drawRect(Rect.fromLTWH(w, 0, size.width - 2 * w, dividerWidth), Paint()..color = placeholderColor);
    }
  }

  @override
  bool shouldRepaint(CsTableRowDecorationPainter old) =>
      old.divider != divider ||
      old.dividerWidth != dividerWidth ||
      old.selected != selected ||
      old.prevSelected != prevSelected ||
      old.nextSelected != nextSelected ||
      old.selectedColor != selectedColor ||
      old.placeholderColor != placeholderColor ||
      old.radius != radius ||
      old.selectedWidth != selectedWidth;
}
