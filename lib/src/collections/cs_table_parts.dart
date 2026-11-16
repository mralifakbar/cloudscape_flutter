import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_tooltip.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';
import 'cs_collection_types.dart';
import 'cs_table.dart' show CsTableVariant, CsTableVerticalAlign;
import 'cs_table_layout.dart';

/// One column of a [CsTableColumnLayout.grid] (Cloudscape
/// `TableRootProps.ColumnDefinition`).
@immutable
class CsTableGridColumn {
  /// A column that shares the remaining width in proportion to [flex],
  /// between [minWidth] and [maxWidth].
  const CsTableGridColumn({this.flex = 1, this.minWidth, this.maxWidth}) : size = null;

  /// A column exactly [size] pixels wide (Cloudscape `size: number`).
  const CsTableGridColumn.fixed(double this.size) : flex = 0, minWidth = null, maxWidth = null;

  /// Fixed width, or null for a flexible column.
  final double? size;

  /// Weight of a flexible column (Cloudscape `size: { flex }`). A capped
  /// column ([maxWidth]) grows evenly instead.
  final double flex;

  /// The narrowest a flexible column gets. Recommended: without it a column
  /// can shrink until its content clips.
  final double? minWidth;

  /// The widest a flexible column gets.
  final double? maxWidth;
}

/// How a [CsTableRoot] sizes its columns (Cloudscape `columnLayout`).
@immutable
class CsTableColumnLayout {
  /// Every column shares the width evenly, at least
  /// [CsTableColumnLayout.autoMinWidth] wide (Cloudscape `{ type: 'auto' }`,
  /// where an HTML table sizes columns to content).
  const CsTableColumnLayout.auto() : columns = null;

  /// Columns sized by [columns] (Cloudscape `{ type: 'grid', columns }`).
  const CsTableColumnLayout.grid(List<CsTableGridColumn> this.columns);

  /// The grid columns, or null for the automatic layout.
  final List<CsTableGridColumn>? columns;

  /// The minimum width of an automatic column, as `CsTable`'s default.
  static const double autoMinWidth = 120;
}

/// Sorting state of a [CsTableHeaderCell] (Cloudscape
/// `sortingState: 'sortable' | 'ascending' | 'descending'`, `aria-sort`).
enum CsTableSortingState {
  /// Sortable, not sorted: a hollow caret on hover and focus.
  sortable,

  /// Sorted ascending: a filled up caret.
  ascending,

  /// Sorted descending: a filled down caret.
  descending,
}

/// Copy of the composable table parts.
@immutable
class CsTablePartsI18nStrings {
  const CsTablePartsI18nStrings({
    this.sortAscending = 'sorted ascending',
    this.sortDescending = 'sorted descending',
    this.notSorted = 'not sorted',
    this.resizerRoleDescription = 'resize handle',
    this.editIconAriaLabel = 'editable',
  });

  final String sortAscending;
  final String sortDescending;
  final String notSorted;
  final String resizerRoleDescription;
  final String editIconAriaLabel;
}

class _TableScope extends InheritedWidget {
  const _TableScope({
    required this.widths,
    required this.pins,
    required this.controller,
    required this.pad,
    required this.striped,
    required this.wrapLines,
    required this.verticalAlign,
    required this.transparentHeader,
    required this.i18n,
    required super.child,
  });

  final List<double> widths;
  final List<CsTablePin?> pins;
  final ScrollController? controller;
  final double pad;
  final bool striped;
  final bool wrapLines;
  final CsTableVerticalAlign verticalAlign;
  final bool transparentHeader;
  final CsTablePartsI18nStrings i18n;

  static _TableScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_TableScope>();
    assert(scope != null, 'Table parts must be inside a CsTableRoot');
    return scope!;
  }

  @override
  bool updateShouldNotify(_TableScope old) =>
      old.widths != widths ||
      old.pins != pins ||
      old.controller != controller ||
      old.pad != pad ||
      old.striped != striped ||
      old.wrapLines != wrapLines ||
      old.verticalAlign != verticalAlign ||
      old.transparentHeader != transparentHeader ||
      old.i18n != i18n;
}

/// Marks the head section, so rows draw as the header row.
class _HeadScope extends InheritedWidget {
  const _HeadScope({required super.child});

  @override
  bool updateShouldNotify(_HeadScope old) => false;
}

/// A body row's place among its siblings.
class _RowScope extends InheritedWidget {
  const _RowScope({
    required this.index,
    required this.isLast,
    required this.prevSelected,
    required this.nextSelected,
    required super.child,
  });

  final int index;
  final bool isLast;
  final bool prevSelected;
  final bool nextSelected;

  @override
  bool updateShouldNotify(_RowScope old) =>
      old.index != index ||
      old.isLast != isLast ||
      old.prevSelected != prevSelected ||
      old.nextSelected != nextSelected;
}

/// A cell's column position within its row.
class _CellScope extends InheritedWidget {
  const _CellScope({
    required this.column,
    required this.count,
    required this.width,
    required this.selected,
    required super.child,
  });

  final int column;
  final int count;
  final double width;
  final bool selected;

  bool get first => column == 0;
  bool get last => column == count - 1;

  @override
  bool updateShouldNotify(_CellScope old) =>
      old.column != column || old.count != count || old.width != width || old.selected != selected;
}

/// Cloudscape's `$divider-block-gap`: header dividers stop 2 x 8px + 2px
/// short of the cell's height.
const double _dividerGap = 2 * CsSpace.xs + CsSpace.xxxs;

EdgeInsetsDirectional _cellPadding(BuildContext context, _CellScope cell, _TableScope table) {
  final h = CsSpace.s + context.cs.space.scaledXs;
  // The first cell lines up with the selected-row outline (as `CsTable`).
  final start = cell.first ? (table.striped ? CsSpace.xxs : CsSpace.xxxs) + CsBorderWidth.itemSelected : h;
  return EdgeInsetsDirectional.only(start: start, end: h);
}

/// Cloudscape's `TableRoot`: the frame of a composable table. Compose it
/// from a [CsTableHead] and a [CsTableBody] of [CsTableRow]s with
/// [CsTableHeaderCell]s and [CsTableBodyCell]s.
///
/// ```dart
/// CsTableRoot(
///   ariaLabel: 'Instances',
///   columnLayout: const CsTableColumnLayout.grid([
///     CsTableGridColumn(minWidth: 160),
///     CsTableGridColumn.fixed(120),
///   ]),
///   children: [
///     CsTableHead(
///       child: CsTableRow(
///         children: [
///           CsTableHeaderCell(child: const Text('Name'), sortingState: CsTableSortingState.ascending, onSort: sort),
///           const CsTableHeaderCell(child: Text('State')),
///         ],
///       ),
///     ),
///     CsTableBody(
///       children: [
///         for (final i in instances)
///           CsTableRow(children: [CsTableBodyCell(isRowHeader: true, child: Text(i.name)), CsTableBodyCell(child: Text(i.state))]),
///       ],
///     ),
///   ],
/// )
/// ```
///
/// The parts draw exactly what `CsTable` draws (header background and
/// divider, sorting carets, column dividers, row dividers, striped and
/// selected rows, the compact table density), but leave the data, state and
/// behavior to the app: use them when `CsTable`'s column definitions do not
/// fit, such as rows built from different widgets or cells that span columns.
///
/// The root computes the column widths for every row. When the columns need
/// more width than there is, the table scrolls sideways and keeps
/// [stickyColumns] at the edges. With a [stickyHeader] and a bounded height,
/// the head stays at the top while the body scrolls.
class CsTableRoot extends StatefulWidget {
  const CsTableRoot({
    super.key,
    required this.children,
    this.columnLayout = const CsTableColumnLayout.auto(),
    this.ariaLabel,
    this.ariaRowcount,
    this.stickyHeader,
    this.stickyHeaderVerticalOffset = 0,
    this.variant = CsTableVariant.borderless,
    this.stripedRows = false,
    this.contentDensity = CsDensity.comfortable,
    this.wrapLines = false,
    this.cellVerticalAlign = CsTableVerticalAlign.middle,
    this.stickyColumns = CsStickyColumns.none,
    this.i18nStrings = const CsTablePartsI18nStrings(),
  });

  /// A [CsTableHead] followed by a [CsTableBody]. With [stickyHeader], only
  /// the body.
  final List<Widget> children;
  final CsTableColumnLayout columnLayout;

  /// Accessible name of the table.
  final String? ariaLabel;

  /// Total rows including the header row, announced when the body shows a
  /// subset (Cloudscape `ariaRowcount`).
  final int? ariaRowcount;

  /// A [CsTableHead] that stays at the top while the body scrolls. Needs a
  /// bounded height; otherwise it sits above the body.
  final Widget? stickyHeader;

  /// Space above the sticky header (Cloudscape `stickyHeaderVerticalOffset`).
  final double stickyHeaderVerticalOffset;

  /// The frame, as `CsTable`'s [CsTableVariant]. Cloudscape's `TableRoot`
  /// has no frame of its own ([CsTableVariant.borderless]); use
  /// [CsTableVariant.container] for `CsTable`'s rounded, bordered look.
  final CsTableVariant variant;

  /// Shades every other body row whose [CsTableRow.shaded] is not set, and
  /// uses the striped-row cell borders (Cloudscape `stripedRows`).
  final bool stripedRows;

  /// [CsDensity.compact] applies `CsDensityTokens.compactTable` to the table.
  final CsDensity contentDensity;

  /// Default for cells that do not set [CsTableBodyCell.wrapLines]: wrap
  /// long text instead of truncating it.
  final bool wrapLines;

  /// Default vertical alignment of body cells.
  final CsTableVerticalAlign cellVerticalAlign;

  /// Columns kept at the start and end edges while the table scrolls
  /// sideways.
  final CsStickyColumns stickyColumns;
  final CsTablePartsI18nStrings i18nStrings;

  @override
  State<CsTableRoot> createState() => _CsTableRootState();
}

class _CsTableRootState extends State<CsTableRoot> {
  final ScrollController _horizontal = ScrollController();
  bool _stuck = false;

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  bool get _framed =>
      widget.variant == CsTableVariant.container ||
      widget.variant == CsTableVariant.stacked ||
      widget.variant == CsTableVariant.fullPage;

  /// Column count of the automatic layout: the header row's cells, or the
  /// first body row's.
  int _inferColumns() {
    int countRow(Widget? row) {
      if (row is! CsTableRow) return 0;
      return row.children.fold(0, (n, c) => n + (c is CsTableBodyCell ? c.colSpan : 1));
    }

    final head = widget.stickyHeader;
    if (head is CsTableHead) return countRow(head.child);
    for (final c in widget.children) {
      if (c is CsTableHead) return countRow(c.child);
    }
    for (final c in widget.children) {
      if (c is CsTableBody && c.children.isNotEmpty) return countRow(c.children.first);
    }
    return 0;
  }

  List<double> _widths(double available) {
    final grid = widget.columnLayout.columns;
    if (grid == null) {
      final n = _inferColumns();
      if (n == 0) return const [];
      return csTableColumnWidths(
        fixed: List.filled(n, null),
        min: List.filled(n, CsTableColumnLayout.autoMinWidth),
        max: List.filled(n, null),
        available: available,
      );
    }
    final widths = [for (final c in grid) c.size ?? c.minWidth ?? 0.0];
    var extra = available - widths.fold(0.0, (a, b) => a + b);
    var open = [
      for (var i = 0; i < grid.length; i++)
        if (grid[i].size == null && (grid[i].maxWidth == null || widths[i] < grid[i].maxWidth!)) i,
    ];
    // Hand out the extra width by weight; a capped column that fills up
    // drops out and the others share what it could not take.
    while (extra > 0.5 && open.isNotEmpty) {
      double weight(int i) => grid[i].maxWidth != null ? 1 : math.max(grid[i].flex, 0.0);
      final total = open.fold(0.0, (a, i) => a + weight(i));
      if (total <= 0) break;
      final next = <int>[];
      var given = 0.0;
      for (final i in open) {
        final share = extra * weight(i) / total;
        final cap = grid[i].maxWidth;
        final take = cap == null ? share : math.min(share, cap - widths[i]);
        widths[i] += take;
        given += take;
        if (cap == null || widths[i] < cap - 0.01) next.add(i);
      }
      extra -= given;
      if (next.length == open.length) break;
      open = next;
    }
    return widths;
  }

  @override
  Widget build(BuildContext context) {
    Widget table = LayoutBuilder(builder: _build);
    if (widget.contentDensity == CsDensity.compact) {
      final theme = context.cs;
      table = CsTheme(
        data: theme.copyWith(density: CsDensity.compact, densityTokens: CsDensityTokens.compactTable),
        child: table,
      );
    }
    final cs = context.cs;
    if (_framed) {
      final rounded = widget.variant != CsTableVariant.stacked;
      final radius = rounded ? BorderRadius.circular(CsBorderRadius.container) : BorderRadius.zero;
      table = Container(
        decoration: BoxDecoration(color: cs.colors.backgroundContainerContent, borderRadius: radius),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: cs.colors.borderDividerDefault, strokeAlign: BorderSide.strokeAlignInside),
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.only(bottom: CsSpace.tableContentBottom),
        child: table,
      );
    } else if (widget.variant != CsTableVariant.embedded) {
      table = ColoredBox(color: cs.colors.backgroundContainerContent, child: table);
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.ariaLabel,
      value: widget.ariaRowcount == null ? null : '${widget.ariaRowcount}',
      child: FocusTraversalGroup(child: table),
    );
  }

  Widget _build(BuildContext context, BoxConstraints constraints) {
    final cs = context.cs;
    final pad = _framed ? CsSpace.tableHorizontal : 0.0;
    final min = _widths(0);
    final minTotal = min.fold(0.0, (a, b) => a + b) + 2 * pad;
    final viewport = constraints.hasBoundedWidth ? constraints.maxWidth : minTotal;
    final widths = _widths(viewport - 2 * pad);
    final contentWidth = widths.fold(0.0, (a, b) => a + b);
    final tableWidth = math.max(viewport, contentWidth + 2 * pad);
    final scrolls = tableWidth > viewport + 0.5;
    final controller = scrolls ? _horizontal : null;

    final n = widths.length;
    final first = math.min(widget.stickyColumns.first, n);
    final last = math.min(widget.stickyColumns.last, n - first);
    var stickyWidth = 0.0;
    for (var i = 0; i < first; i++) {
      stickyWidth += widths[i];
    }
    for (var i = n - last; i < n; i++) {
      stickyWidth += widths[i];
    }
    // As CsTable: sticky columns only while they leave room to scroll.
    final stickyOn = scrolls && stickyWidth + 148 <= viewport;
    final pins = <CsTablePin?>[
      for (var i = 0; i < n; i++)
        !stickyOn
            ? null
            : i < first
            ? CsTablePin.start
            : i >= n - last
            ? CsTablePin.end
            : null,
    ];

    Widget scoped(Widget child) => _TableScope(
      widths: widths,
      pins: pins,
      controller: controller,
      pad: pad,
      striped: widget.stripedRows,
      wrapLines: widget.wrapLines,
      verticalAlign: widget.cellVerticalAlign,
      transparentHeader: widget.variant == CsTableVariant.embedded || widget.variant == CsTableVariant.borderless,
      i18n: widget.i18nStrings,
      child: child,
    );

    final bounded = constraints.hasBoundedHeight;
    final sticky = widget.stickyHeader;
    Widget body;
    if (sticky != null && bounded) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: widget.stickyHeaderVerticalOffset),
          DecoratedBox(
            decoration: BoxDecoration(boxShadow: _stuck ? cs.shadows.stickyEmbedded : null),
            child: sticky,
          ),
          Expanded(
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (n) {
                if (n.metrics.axis != Axis.vertical) return false;
                final stuck = n.metrics.pixels > 0;
                if (stuck != _stuck) setState(() => _stuck = stuck);
                return false;
              },
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.children,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [?sticky, ...widget.children],
      );
    }
    body = SizedBox(width: tableWidth, height: sticky != null && bounded ? constraints.maxHeight : null, child: body);
    body = scoped(body);
    if (!scrolls) return body;
    return SingleChildScrollView(controller: _horizontal, scrollDirection: Axis.horizontal, child: body);
  }
}

/// Cloudscape's `TableHead`: the header section of a [CsTableRoot], holding
/// one [CsTableRow] of [CsTableHeaderCell]s. Draws
/// `color-background-table-header` (transparent in the borderless and
/// embedded variants) with a `color-border-divider-default` line below.
class CsTableHead extends StatelessWidget {
  const CsTableHead({super.key, required this.child});

  /// The header row.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final table = _TableScope.of(context);
    final c = context.cs.colors;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: table.pad),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: table.transparentHeader ? c.backgroundContainerContent : c.backgroundTableHeader,
          border: Border(
            bottom: BorderSide(color: c.borderDividerDefault, width: CsBorderLine.dividerListWidth),
          ),
        ),
        child: _HeadScope(child: child),
      ),
    );
  }
}

/// Cloudscape's `TableBody`: the rows of a [CsTableRoot]. It tells each
/// [CsTableRow] its position, so striping, row dividers and joined
/// selection outlines come out as in `CsTable`.
class CsTableBody extends StatelessWidget {
  const CsTableBody({super.key, required this.children});

  /// The body rows, usually [CsTableRow]s.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    bool selectedAt(int i) {
      if (i < 0 || i >= children.length) return false;
      final row = children[i];
      return row is CsTableRow && row.selected;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          _RowScope(
            index: i,
            isLast: i == children.length - 1,
            prevSelected: selectedAt(i - 1),
            nextSelected: selectedAt(i + 1),
            child: children[i],
          ),
      ],
    );
  }
}

/// Cloudscape's `TableRow`: one row of cells, in the head or the body.
///
/// In the body a row draws its divider, the striped background ([shaded])
/// and, when [selected], `color-background-item-selected` inside a 2px
/// `color-border-item-selected` outline that joins adjacent selected rows.
/// [onPress] makes the whole row tappable (`CsTable.onRowClick`).
class CsTableRow extends StatelessWidget {
  const CsTableRow({
    super.key,
    required this.children,
    this.selected = false,
    this.shaded,
    this.ariaLabel,
    this.onPress,
  });

  /// One cell per column, in order. A [CsTableBodyCell] with a
  /// [CsTableBodyCell.colSpan] covers several columns.
  final List<Widget> children;

  /// Selected-row styling. Visual only: put a selection control in a cell
  /// to make the state accessible, as Cloudscape does.
  final bool selected;

  /// Shaded background for alternating rows. Defaults to every other row
  /// when [CsTableRoot.stripedRows] is on.
  final bool? shaded;

  /// Accessible name of the row.
  final String? ariaLabel;

  /// Called when the row is tapped.
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final table = _TableScope.of(context);
    final head = context.dependOnInheritedWidgetOfExactType<_HeadScope>() != null;
    final position = context.dependOnInheritedWidgetOfExactType<_RowScope>();

    final n = table.widths.length;
    final widths = <double>[];
    final pins = <CsTablePin?>[];
    final cells = <Widget>[];
    var column = 0;
    for (var i = 0; i < children.length && column < math.max(n, 1); i++) {
      final child = children[i];
      final span = math.max(1, math.min(child is CsTableBodyCell ? child.colSpan : 1, n - column));
      var w = 0.0;
      for (var k = column; k < column + span && k < n; k++) {
        w += table.widths[k];
      }
      widths.add(w);
      pins.add(column < table.pins.length ? table.pins[column] : null);
      cells.add(_CellScope(column: column, count: n, width: w, selected: selected, child: child));
      column += span;
    }

    final isSelected = selected && !head;
    final shaded = !head && (this.shaded ?? (table.striped && (position?.index ?? 0).isOdd));
    final background = head
        ? (table.transparentHeader ? c.backgroundContainerContent : c.backgroundTableHeader)
        : isSelected
        ? c.backgroundItemSelected
        : (shaded ? c.backgroundCellShaded : null);

    Widget row = CsTableRowLayout(
      widths: widths,
      pins: pins,
      controller: table.controller,
      background: background ?? c.backgroundContainerContent,
      textDirection: Directionality.of(context),
      padStart: table.pad,
      shadowFirst: cs.shadows.stickyColumnFirst,
      shadowLast: cs.shadows.stickyColumnLast,
      children: cells,
    );
    if (head) return Semantics(container: true, label: ariaLabel, child: row);

    final prevSelected = isSelected && (position?.prevSelected ?? false);
    final nextSelected = isSelected && (position?.nextSelected ?? false);
    final isLast = position?.isLast ?? false;
    final Color? divider = isLast ? null : (table.striped ? c.borderCellShaded : c.borderDividerSecondary);
    const radius = Radius.circular(CsBorderRadius.item);
    row = Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: isSelected
            ? BorderRadius.only(
                topLeft: prevSelected ? Radius.zero : radius,
                topRight: prevSelected ? Radius.zero : radius,
                bottomLeft: nextSelected ? Radius.zero : radius,
                bottomRight: nextSelected ? Radius.zero : radius,
              )
            : null,
      ),
      child: CustomPaint(
        foregroundPainter: CsTableRowDecorationPainter(
          divider: divider,
          dividerWidth: CsBorderLine.dividerListWidth,
          selected: isSelected,
          prevSelected: prevSelected,
          nextSelected: nextSelected,
          selectedColor: c.borderItemSelected,
          placeholderColor: c.borderItemPlaceholder,
          radius: CsBorderRadius.item,
          selectedWidth: CsBorderWidth.itemSelected,
        ),
        child: row,
      ),
    );
    if (onPress != null) {
      row = CsPressable(
        onPress: onPress,
        scaleOnPress: false,
        isButton: false,
        mergeChildSemantics: false,
        minTapTargetSize: 0,
        focusRingOffset: -2,
        borderRadius: const BorderRadius.all(radius),
        child: row,
      );
    }
    return Semantics(
      container: true,
      selected: selected ? true : null,
      label: ariaLabel,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: table.pad),
        child: row,
      ),
    );
  }
}

/// Cloudscape's `TableHeaderCell`: a column header with the column label,
/// the sorting caret, the divider to the next column and an optional resize
/// handle, styled as `CsTable`'s headers (bold `color-text-column-header`,
/// `color-text-interactive-active` when sorted or hovered).
class CsTableHeaderCell extends StatefulWidget {
  const CsTableHeaderCell({
    super.key,
    required this.child,
    this.ariaLabel,
    this.sortingState,
    this.sortingDisabled = false,
    this.onSort,
    this.disablePaddings = false,
    this.resizable = false,
    this.onResize,
    this.onResizeEnd,
    this.minWidth = CsTableColumnLayout.autoMinWidth,
    this.editable = false,
    this.wrapLines,
  });

  /// The column label, usually a `Text`.
  final Widget child;

  /// Accessible name of the header (Cloudscape `ariaLabel`).
  final String? ariaLabel;

  /// Null for a column that cannot sort. Otherwise the caret shows the state
  /// and the header announces it (Cloudscape `ariaSort`).
  final CsTableSortingState? sortingState;

  /// Shows the sorting state without letting the user change it.
  final bool sortingDisabled;

  /// Called when the user activates a sortable header. The app flips the
  /// direction and passes the new [sortingState].
  final VoidCallback? onSort;

  /// Removes the cell's padding so the content can bring its own.
  final bool disablePaddings;

  /// Adds a resize handle on the end edge (drag, or arrow keys when
  /// focused, 10px a press).
  final bool resizable;

  /// Called with the new width while the handle moves. Store it in the
  /// root's [CsTableColumnLayout.grid] as a fixed column.
  final ValueChanged<double>? onResize;

  /// Called when a resize gesture ends.
  final VoidCallback? onResizeEnd;

  /// The narrowest [onResize] reports.
  final double minWidth;

  /// Adds the edit icon after the label of a column with editable cells.
  final bool editable;

  /// Wrap a long label. Defaults to [CsTableRoot.wrapLines].
  final bool? wrapLines;

  @override
  State<CsTableHeaderCell> createState() => _CsTableHeaderCellState();
}

class _CsTableHeaderCellState extends State<CsTableHeaderCell> {
  bool _resizerActive = false;
  bool _resizerHover = false;
  bool _resizerFocused = false;
  double _dragStart = 0;
  double _dragDistance = 0;

  static const double _keyboardStep = 10;

  void _resize(double width) => widget.onResize?.call(math.max(width, widget.minWidth));

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final table = _TableScope.of(context);
    final cell = context.dependOnInheritedWidgetOfExactType<_CellScope>()!;
    final sorting = widget.sortingState;
    final sorted = sorting == CsTableSortingState.ascending || sorting == CsTableSortingState.descending;
    final interactive = sorting != null && !widget.sortingDisabled && widget.onSort != null;
    final wrap = widget.wrapLines ?? table.wrapLines;
    final sortIcon = switch (sorting) {
      CsTableSortingState.ascending => CsIcons.caretUpFilled,
      CsTableSortingState.descending => CsIcons.caretDownFilled,
      CsTableSortingState.sortable => interactive ? CsIcons.caretDown : null,
      null => null,
    };
    final padding = _cellPadding(context, cell, table);

    Widget content(CsPressState? state) {
      final hot = interactive && (sorted || (state?.hovered ?? false));
      final color = hot ? CsColor.textInteractiveActive : CsColor.textColumnHeader;
      Widget label = DefaultTextStyle.merge(
        style: cs.text(CsTypeScale.headingXs, color: color),
        maxLines: wrap ? null : 1,
        overflow: wrap ? null : TextOverflow.ellipsis,
        softWrap: wrap,
        child: widget.child,
      );
      if (widget.editable) {
        label = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: label),
            Padding(
              padding: EdgeInsetsDirectional.only(start: CsSpace.xxs, top: cs.space.scaledXxs),
              child: CsIcon(
                CsIcons.edit,
                size: CsIconSize.small,
                dangerouslySetColor: cs.color(color),
                semanticLabel: table.i18n.editIconAriaLabel,
              ),
            ),
          ],
        );
      }
      final iconColor = sorted
          ? (interactive ? c.textInteractiveActive : c.textInteractiveDisabled)
          : (hot ? c.textInteractiveActive : c.textColumnSortingIcon);
      final vertical = cs.space.scaledXxs * 2 + CsSpace.xxxs / 2;
      return Padding(
        padding: widget.disablePaddings
            ? EdgeInsets.zero
            : EdgeInsetsDirectional.only(
                start: padding.start,
                end: sortIcon != null ? CsSpace.xs + CsSpace.xxs : padding.end,
                top: vertical,
                bottom: vertical,
              ),
        child: Row(
          children: [
            Expanded(
              child: Align(alignment: AlignmentDirectional.centerStart, child: label),
            ),
            if (sortIcon != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: CsSpace.xxs),
                child: CsIcon(sortIcon, dangerouslySetColor: iconColor),
              ),
          ],
        ),
      );
    }

    final sortValue = switch (sorting) {
      CsTableSortingState.ascending => table.i18n.sortAscending,
      CsTableSortingState.descending => table.i18n.sortDescending,
      CsTableSortingState.sortable => table.i18n.notSorted,
      null => null,
    };
    Widget header;
    if (interactive) {
      header = CsPressable(
        onPress: widget.onSort,
        scaleOnPress: false,
        minTapTargetSize: 0,
        focusRingOffset: -2,
        borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
        semanticLabel: widget.ariaLabel,
        semanticValue: sortValue,
        builder: (context, state) => content(state),
      );
    } else {
      header = Semantics(header: true, label: widget.ariaLabel, value: sortValue, child: content(null));
    }

    final children = <Widget>[header];
    final showActive = _resizerActive || _resizerHover || _resizerFocused;
    if (!cell.last || widget.resizable) {
      children.add(
        PositionedDirectional(
          end: 0,
          top: _dividerGap / 2,
          bottom: _dividerGap / 2,
          child: IgnorePointer(
            child: Container(
              width: showActive ? 2 : CsBorderLine.dividerListWidth,
              color: showActive
                  ? c.borderDividerActive
                  : (widget.resizable ? c.borderDividerInteractiveDefault : c.borderDividerDefault),
            ),
          ),
        ),
      );
    }
    if (widget.resizable) {
      children.add(
        PositionedDirectional(end: 0, top: 0, bottom: 0, width: CsSpace.m, child: _resizer(context, cell.width)),
      );
    }
    return Stack(children: children);
  }

  Widget _resizer(BuildContext context, double width) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final table = _TableScope.of(context);
    Widget handle = MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _resizerHover = true),
      onExit: (_) => setState(() => _resizerHover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: (_) => setState(() {
          _resizerActive = true;
          _dragStart = width;
          _dragDistance = 0;
        }),
        onHorizontalDragUpdate: (d) {
          _dragDistance += rtl ? -d.delta.dx : d.delta.dx;
          _resize(_dragStart + _dragDistance);
        },
        onHorizontalDragEnd: (_) {
          setState(() => _resizerActive = false);
          widget.onResizeEnd?.call();
        },
        onHorizontalDragCancel: () => setState(() => _resizerActive = false),
        child: const SizedBox.expand(),
      ),
    );
    handle = Focus(
      onFocusChange: (f) => setState(() => _resizerFocused = f),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        final grow = rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
        final shrink = rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;
        if (key == grow || key == shrink) {
          _resize(width + (key == grow ? _keyboardStep : -_keyboardStep));
          widget.onResizeEnd?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: handle,
    );
    return Semantics(
      label: widget.ariaLabel,
      hint: table.i18n.resizerRoleDescription,
      value: '${width.round()}',
      increasedValue: '${(width + _keyboardStep).round()}',
      decreasedValue: '${(width - _keyboardStep).round()}',
      onIncrease: () {
        _resize(width + _keyboardStep);
        widget.onResizeEnd?.call();
      },
      onDecrease: () {
        _resize(width - _keyboardStep);
        widget.onResizeEnd?.call();
      },
      child: handle,
    );
  }
}

/// Cloudscape's `TableBodyCell`: a data cell, or the row header with
/// [isRowHeader]. Body text is body-m on `space-scaled-xs` plus 1px
/// vertical padding (`table-cell-vertical`), truncated to one line unless
/// [wrapLines].
///
/// [editable] draws the inline-edit affordance of `CsTable`'s editable
/// columns: on hover or focus the cell fills
/// `color-background-dropdown-item-hover` inside a
/// `color-border-editable-cell-hover` border and shows an edit icon, and
/// [onEdit] runs on tap. With [editDisabledReason] it shows a lock and the
/// reason instead.
class CsTableBodyCell extends StatefulWidget {
  const CsTableBodyCell({
    super.key,
    required this.child,
    this.isRowHeader = false,
    this.disablePaddings = false,
    this.colSpan = 1,
    this.wrapLines,
    this.verticalAlign,
    this.editable = false,
    this.onEdit,
    this.editDisabledReason,
    this.editAriaLabel,
  }) : assert(colSpan >= 1);

  final Widget child;

  /// Announces the cell as the header of its row.
  final bool isRowHeader;

  /// Removes the cell's padding so the content can bring its own.
  final bool disablePaddings;

  /// How many columns the cell covers.
  final int colSpan;

  /// Wrap long text. Defaults to [CsTableRoot.wrapLines].
  final bool? wrapLines;

  /// Defaults to [CsTableRoot.cellVerticalAlign].
  final CsTableVerticalAlign? verticalAlign;

  /// Draws the inline-edit affordance.
  final bool editable;

  /// Called when an [editable] cell is activated. Swap the cell's child for
  /// an editor (a `CsInput`) while editing.
  final VoidCallback? onEdit;

  /// Why the cell cannot be edited, shown in a tooltip with a lock icon.
  final String? editDisabledReason;

  /// Accessible name of the edit action, such as "Edit name".
  final String? editAriaLabel;

  @override
  State<CsTableBodyCell> createState() => _CsTableBodyCellState();
}

class _CsTableBodyCellState extends State<CsTableBodyCell> {
  bool _reasonOpen = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final table = _TableScope.of(context);
    final cell = context.dependOnInheritedWidgetOfExactType<_CellScope>()!;
    final wrap = widget.wrapLines ?? table.wrapLines;
    final align = widget.verticalAlign ?? table.verticalAlign;
    final padding = widget.disablePaddings ? EdgeInsetsDirectional.zero : _cellPadding(context, cell, table);
    final vertical = widget.disablePaddings ? 0.0 : cs.space.tableCellVertical + CsBorderLine.dividerListWidth;

    Widget content = DefaultTextStyle.merge(
      style: cs.body,
      maxLines: wrap ? null : 1,
      overflow: wrap ? null : TextOverflow.ellipsis,
      softWrap: wrap,
      child: widget.child,
    );
    if (widget.isRowHeader) content = Semantics(header: true, child: content);
    content = Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: Align(
        alignment: align == CsTableVerticalAlign.top ? AlignmentDirectional.topStart : AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: content,
      ),
    );
    if (!widget.editable) return Padding(padding: padding, child: content);

    final reason = widget.editDisabledReason;
    return CsPressable(
      onPress: () {
        if (reason != null) {
          setState(() => _reasonOpen = !_reasonOpen);
        } else {
          widget.onEdit?.call();
        }
      },
      scaleOnPress: false,
      minTapTargetSize: 0,
      focusRingOffset: -2,
      borderRadius: BorderRadius.circular(CsBorderRadius.item),
      semanticLabel: widget.editAriaLabel,
      semanticHint: reason,
      mergeChildSemantics: false,
      builder: (context, state) {
        final active = state.hovered || state.focused || _reasonOpen;
        final iconColor = reason != null
            ? c.textDisabledInlineEdit
            : state.pressed
            ? c.textButtonNormalActive
            : state.hovered
            ? c.textButtonNormalHover
            : c.textButtonNormalDefault;
        Widget icon = CsIcon(
          reason != null ? CsIcons.lockPrivate : CsIcons.edit,
          dangerouslySetColor: iconColor,
          semanticLabel: table.i18n.editIconAriaLabel,
        );
        if (reason != null) {
          icon = CsTooltip(
            content: reason,
            open: _reasonOpen ? true : null,
            onOpenChange: (open) {
              if (!open && _reasonOpen) setState(() => _reasonOpen = false);
            },
            child: icon,
          );
        }
        final hoverFill = active && reason == null;
        return Container(
          decoration: hoverFill
              ? BoxDecoration(
                  color: c.backgroundDropdownItemHover,
                  borderRadius: BorderRadius.circular(CsBorderRadius.item),
                )
              : null,
          foregroundDecoration: hoverFill
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(CsBorderRadius.item),
                  border: Border.all(color: c.borderEditableCellHover, strokeAlign: BorderSide.strokeAlignInside),
                )
              : null,
          child: Stack(
            children: [
              Padding(
                padding: padding.copyWith(end: padding.end + CsSpace.l),
                child: content,
              ),
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: CsSpace.xs,
                child: Center(
                  child: Opacity(opacity: active ? 1 : 0, child: icon),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
