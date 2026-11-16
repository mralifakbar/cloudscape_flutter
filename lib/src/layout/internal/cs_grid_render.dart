import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Placement of one child on a 12-column row, already resolved for a width.
@immutable
class CsGridCell {
  const CsGridCell({this.span = 12, this.offset = 0, this.push = 0, this.pull = 0});

  final int span;
  final int offset;
  final int push;
  final int pull;
}

/// Cells for every child plus the number of columns per row.
@immutable
class CsGridSpec {
  const CsGridSpec(this.cells, {this.units = 12});

  final List<CsGridCell> cells;

  /// Columns in a row: 12 for `CsGrid`, the column count for the flexible
  /// column layout.
  final int units;
}

/// Resolves every child's placement for the available width.
typedef CsGridResolver = CsGridSpec Function(double width);

/// The 12-column flex-wrap engine shared by `CsGrid` and `CsColumnLayout`.
///
/// Cells sit on rows of 12 units; a cell that does not fit on the current
/// row starts the next one, like CSS `flex-wrap: wrap`. Cells in a row
/// stretch to the tallest one (`align-items: stretch`). Gaps reproduce
/// Cloudscape's padding plus negative margin gutters: a cell starting at
/// column `c` sits at `(W + hGap) * c / 12` and is `(W + hGap) * span / 12 - hGap`
/// wide. Optional divider lines are drawn in the middle of the gaps.
class CsGridLayout extends MultiChildRenderObjectWidget {
  const CsGridLayout({
    super.key,
    required this.resolver,
    required super.children,
    this.hGap = 0,
    this.vGap = 0,
    this.verticalLines = false,
    this.horizontalLines = false,
    this.lineColor = const Color(0x00000000),
    this.lineWidth = 1,
    this.stretch = true,
  });

  final CsGridResolver resolver;
  final double hGap;
  final double vGap;

  /// Lines between neighbouring cells of a row.
  final bool verticalLines;

  /// Lines between rows.
  final bool horizontalLines;
  final Color lineColor;
  final double lineWidth;
  final bool stretch;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderCsGridLayout(
    resolver: resolver,
    hGap: hGap,
    vGap: vGap,
    verticalLines: verticalLines,
    horizontalLines: horizontalLines,
    lineColor: lineColor,
    lineWidth: lineWidth,
    stretch: stretch,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderCsGridLayout renderObject) {
    renderObject
      ..resolver = resolver
      ..hGap = hGap
      ..vGap = vGap
      ..verticalLines = verticalLines
      ..horizontalLines = horizontalLines
      ..lineColor = lineColor
      ..lineWidth = lineWidth
      ..stretch = stretch
      ..textDirection = Directionality.of(context);
  }
}

class _GridParentData extends ContainerBoxParentData<RenderBox> {}

class _Placed {
  _Placed(this.child, this.x, this.width, this.row);
  final RenderBox child;
  final double x;
  final double width;
  final int row;
}

/// Render object behind [CsGridLayout].
class RenderCsGridLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GridParentData> {
  RenderCsGridLayout({
    required CsGridResolver resolver,
    required double hGap,
    required double vGap,
    required bool verticalLines,
    required bool horizontalLines,
    required Color lineColor,
    required double lineWidth,
    required bool stretch,
    required TextDirection textDirection,
  }) : _resolver = resolver,
       _hGap = hGap,
       _vGap = vGap,
       _verticalLines = verticalLines,
       _horizontalLines = horizontalLines,
       _lineColor = lineColor,
       _lineWidth = lineWidth,
       _stretch = stretch,
       _textDirection = textDirection;

  CsGridResolver _resolver;
  set resolver(CsGridResolver v) {
    _resolver = v;
    markNeedsLayout();
  }

  double _hGap;
  set hGap(double v) {
    if (v == _hGap) return;
    _hGap = v;
    markNeedsLayout();
  }

  double _vGap;
  set vGap(double v) {
    if (v == _vGap) return;
    _vGap = v;
    markNeedsLayout();
  }

  bool _verticalLines;
  set verticalLines(bool v) {
    if (v == _verticalLines) return;
    _verticalLines = v;
    markNeedsPaint();
  }

  bool _horizontalLines;
  set horizontalLines(bool v) {
    if (v == _horizontalLines) return;
    _horizontalLines = v;
    markNeedsPaint();
  }

  Color _lineColor;
  set lineColor(Color v) {
    if (v == _lineColor) return;
    _lineColor = v;
    markNeedsPaint();
  }

  double _lineWidth;
  set lineWidth(double v) {
    if (v == _lineWidth) return;
    _lineWidth = v;
    markNeedsPaint();
  }

  bool _stretch;
  set stretch(bool v) {
    if (v == _stretch) return;
    _stretch = v;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  // Paint data from the last layout.
  final List<Rect> _vLines = [];
  final List<Rect> _hLines = [];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GridParentData) child.parentData = _GridParentData();
  }

  List<_Placed> _place(double width) {
    final spec = _resolver(width);
    final cells = spec.cells;
    final units = spec.units;
    final unit = (width + _hGap) / units;
    final placed = <_Placed>[];
    var row = 0;
    var used = 0;
    var i = 0;
    var child = firstChild;
    while (child != null) {
      final cell = i < cells.length ? cells[i] : const CsGridCell();
      final span = cell.span.clamp(1, units);
      final offset = cell.offset.clamp(0, units - 1);
      if (used > 0 && used + offset + span > units) {
        row++;
        used = 0;
      }
      final start = used + offset;
      final shift = cell.push - cell.pull;
      final x = unit * (start + shift);
      placed.add(_Placed(child, x, math.max(0, unit * span - _hGap), row));
      used = start + span;
      i++;
      child = childAfter(child);
    }
    return placed;
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) {
    var w = 0.0;
    var child = firstChild;
    while (child != null) {
      w = math.max(w, child.getMaxIntrinsicWidth(height));
      child = childAfter(child);
    }
    return w;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _measure(width, (c, w) => c.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) => _measure(width, (c, w) => c.getMaxIntrinsicHeight(w));

  double _measure(double width, double Function(RenderBox, double) h) {
    if (!width.isFinite) return 0;
    final placed = _place(width);
    final rows = <int, double>{};
    for (final p in placed) {
      rows[p.row] = math.max(rows[p.row] ?? 0, h(p.child, p.width));
    }
    if (rows.isEmpty) return 0;
    return rows.values.fold<double>(0, (a, b) => a + b) + _vGap * (rows.length - 1);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    if (!width.isFinite) return constraints.smallest;
    final placed = _place(width);
    final rows = <int, double>{};
    for (final p in placed) {
      rows[p.row] = math.max(rows[p.row] ?? 0, p.child.getDryLayout(BoxConstraints(maxWidth: p.width)).height);
    }
    final h = rows.isEmpty ? 0.0 : rows.values.fold<double>(0, (a, b) => a + b) + _vGap * (rows.length - 1);
    return constraints.constrain(Size(width, h));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    assert(width.isFinite, 'CsGrid and CsColumnLayout need a bounded width.');
    final placed = _place(width);
    final rowHeights = <int, double>{};
    for (final p in placed) {
      p.child.layout(BoxConstraints(minWidth: p.width, maxWidth: p.width), parentUsesSize: true);
      rowHeights[p.row] = math.max(rowHeights[p.row] ?? 0, p.child.size.height);
    }
    final rowTops = <int, double>{};
    var y = 0.0;
    final rowCount = rowHeights.isEmpty ? 0 : rowHeights.keys.reduce(math.max) + 1;
    for (var r = 0; r < rowCount; r++) {
      rowTops[r] = y;
      y += (rowHeights[r] ?? 0) + (r < rowCount - 1 ? _vGap : 0);
    }
    final rtl = _textDirection == TextDirection.rtl;
    _vLines.clear();
    _hLines.clear();
    for (var i = 0; i < placed.length; i++) {
      final p = placed[i];
      final rh = rowHeights[p.row]!;
      if (_stretch && p.child.size.height != rh) {
        p.child.layout(BoxConstraints.tightFor(width: p.width, height: rh), parentUsesSize: true);
      }
      final x = rtl ? width - p.x - p.width : p.x;
      (p.child.parentData! as _GridParentData).offset = Offset(x, rowTops[p.row]!);
      final next = i + 1 < placed.length ? placed[i + 1] : null;
      if (next != null && next.row == p.row) {
        final mid = rtl ? x - _hGap / 2 : x + p.width + _hGap / 2;
        _vLines.add(Rect.fromLTWH(mid - _lineWidth / 2, rowTops[p.row]!, _lineWidth, rh));
      }
    }
    for (var r = 0; r < rowCount - 1; r++) {
      final lineY = rowTops[r]! + rowHeights[r]! + _vGap / 2;
      _hLines.add(Rect.fromLTWH(0, lineY - _lineWidth / 2, width, _lineWidth));
    }
    size = constraints.constrain(Size(width, y));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
    if (!_verticalLines && !_horizontalLines) return;
    final paint = Paint()..color = _lineColor;
    if (_verticalLines) {
      for (final r in _vLines) {
        context.canvas.drawRect(r.shift(offset), paint);
      }
    }
    if (_horizontalLines) {
      for (final r in _hLines) {
        context.canvas.drawRect(r.shift(offset), paint);
      }
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
