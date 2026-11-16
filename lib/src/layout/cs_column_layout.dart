import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'internal/cs_grid_render.dart';

/// Column layout styles (Cloudscape `variant`).
enum CsColumnLayoutVariant {
  /// Columns separated by gutters.
  defaultVariant,

  /// Columns of text (key-value pairs, summaries) separated by vertical
  /// lines, with wider gutters. [CsColumnLayout.borders] and
  /// [CsColumnLayout.disableGutters] do not apply.
  textGrid,
}

/// Divider lines between columns and rows (Cloudscape `borders`).
enum CsColumnLayoutBorders { none, vertical, horizontal, all }

/// Cloudscape's `ColumnLayout`: lays children out in 1 to 4 equal columns
/// that collapse responsively.
///
/// ```dart
/// const CsColumnLayout(
///   columns: 3,
///   variant: CsColumnLayoutVariant.textGrid,
///   children: [Text('Instance ID'), Text('Status'), Text('Type')],
/// )
/// ```
///
/// Columns follow the layout's own width (Cloudscape container query):
/// under 465px every child takes the full row; from 465px two, three and
/// four columns show two per row; from 688px all [columns] show. With
/// [minColumnWidth] set the count instead fits as many columns of at least
/// that width as possible, up to [columns], keeping the count even when it
/// has to drop below [columns].
class CsColumnLayout extends StatelessWidget {
  const CsColumnLayout({
    super.key,
    required this.children,
    this.columns = 1,
    this.variant = CsColumnLayoutVariant.defaultVariant,
    this.borders = CsColumnLayoutBorders.none,
    this.disableGutters = false,
    this.minColumnWidth,
  }) : assert(minColumnWidth != null || (columns >= 1 && columns <= 4), 'columns is 1 to 4 without minColumnWidth');

  /// Number of columns at full width: 1 to 4, or any positive number with
  /// [minColumnWidth].
  final int columns;
  final CsColumnLayoutVariant variant;
  final CsColumnLayoutBorders borders;
  final bool disableGutters;

  /// Minimum width of each column in logical pixels. Turns on the flexible
  /// layout, which allows more than 4 columns.
  final double? minColumnWidth;
  final List<Widget> children;

  /// Columns that fit in [width] with the flexible layout
  /// (`calculcateCssColumnCount` in Cloudscape).
  static int flexibleColumnCount(int columns, double minColumnWidth, double width) {
    if (minColumnWidth <= 0) return columns;
    final target = math.min(columns, (width / minColumnWidth).floor());
    final even = target < columns && target.isOdd ? target - 1 : target;
    return math.max(1, even);
  }

  /// Columns per row for the fixed layout at [width].
  static int fixedColumnCount(int columns, double width) {
    if (width <= CsBreakpoint.xxs.minWidth) return 1;
    if (width <= CsBreakpoint.xs.minWidth) return columns == 1 ? 1 : 2;
    return columns;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final textGrid = variant == CsColumnLayoutVariant.textGrid;
    final gutter = cs.space.gridGutter;
    final noGutters = !textGrid && disableGutters;
    final vertical = !textGrid && (borders == CsColumnLayoutBorders.vertical || borders == CsColumnLayoutBorders.all);
    final horizontal =
        !textGrid && (borders == CsColumnLayoutBorders.horizontal || borders == CsColumnLayoutBorders.all);
    return CsGridLayout(
      // text-grid: items padded by a full gutter on each side, so columns sit
      // two gutters apart with the line in the middle.
      hGap: noGutters ? 0 : (textGrid ? gutter * 2 : gutter),
      vGap: noGutters ? 0 : gutter,
      verticalLines: textGrid || vertical,
      horizontalLines: horizontal,
      lineColor: cs.colors.borderDividerDefault,
      lineWidth: CsBorderLine.dividerSectionWidth,
      resolver: (width) {
        final perRow = minColumnWidth != null
            ? flexibleColumnCount(columns, minColumnWidth!, width)
            : fixedColumnCount(columns, width);
        return CsGridSpec([for (final _ in children) const CsGridCell(span: 1)], units: perRow);
      },
      children: [for (final child in children) DefaultTextStyle.merge(style: cs.body, child: child)],
    );
  }
}
