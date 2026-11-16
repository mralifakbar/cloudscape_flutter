import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Size rules for a board item (Cloudscape `BoardProps.Item.definition`).
@immutable
class CsBoardItemDefinition {
  const CsBoardItemDefinition({this.minRowSpan, this.minColumnSpan, this.defaultRowSpan, this.defaultColumnSpan});

  /// Fewest rows the item may take. Never below [CsBoardLayout.minRowSpan] (2).
  final int? minRowSpan;

  /// Fewest columns the item may take. Never below 1.
  final int? minColumnSpan;

  /// Rows the item takes when it has no `rowSpan` (and when inserted).
  final int? defaultRowSpan;

  /// Columns the item takes when it has no `columnSpan` (and when inserted).
  final int? defaultColumnSpan;

  @override
  bool operator ==(Object other) =>
      other is CsBoardItemDefinition &&
      other.minRowSpan == minRowSpan &&
      other.minColumnSpan == minColumnSpan &&
      other.defaultRowSpan == defaultRowSpan &&
      other.defaultColumnSpan == defaultColumnSpan;

  @override
  int get hashCode => Object.hash(minRowSpan, minColumnSpan, defaultRowSpan, defaultColumnSpan);
}

/// One item on a board and its position (Cloudscape `BoardProps.Item`).
///
/// Positions are stored per column count, so a board that switches between
/// its 1, 2, 4 and 6 column layouts keeps each arrangement. [CsBoard]
/// updates [columnOffset], [rowSpan] and [columnSpan] through
/// `onItemsChange`; you only provide [id], [data] and, optionally,
/// [definition] and initial spans.
@immutable
class CsBoardEntry<T> {
  const CsBoardEntry({
    required this.id,
    required this.data,
    this.definition,
    this.columnOffset,
    this.rowSpan,
    this.columnSpan,
  });

  /// Unique on the page.
  final String id;

  /// Your item data, such as a widget type and its title.
  final T data;
  final CsBoardItemDefinition? definition;

  /// Column the item starts at, keyed by the layout's column count
  /// (`{4: 2}` puts it in the third column of the 4 column layout).
  final Map<int, int>? columnOffset;

  /// Rows the item takes, 2 or more.
  final int? rowSpan;

  /// Columns the item takes, 1 or more (capped to the column count).
  final int? columnSpan;

  /// A copy with the given fields replaced. Pass `clearColumnOffset` to
  /// drop every stored offset.
  CsBoardEntry<T> copyWith({
    T? data,
    CsBoardItemDefinition? definition,
    Map<int, int>? columnOffset,
    bool clearColumnOffset = false,
    int? rowSpan,
    int? columnSpan,
  }) => CsBoardEntry<T>(
    id: id,
    data: data ?? this.data,
    definition: definition ?? this.definition,
    columnOffset: clearColumnOffset ? columnOffset : (columnOffset ?? this.columnOffset),
    rowSpan: rowSpan ?? this.rowSpan,
    columnSpan: columnSpan ?? this.columnSpan,
  );

  @override
  bool operator ==(Object other) =>
      other is CsBoardEntry<T> &&
      other.id == id &&
      other.data == data &&
      other.definition == definition &&
      mapEquals(other.columnOffset, columnOffset) &&
      other.rowSpan == rowSpan &&
      other.columnSpan == columnSpan;

  @override
  int get hashCode => Object.hash(
    id,
    data,
    definition,
    columnOffset == null
        ? null
        : Object.hashAllUnordered(columnOffset!.entries.map((e) => Object.hash(e.key, e.value))),
    rowSpan,
    columnSpan,
  );

  @override
  String toString() => 'CsBoardEntry($id, offset: $columnOffset, ${columnSpan}x$rowSpan)';
}

/// Where an item sits in a grid layout, in cells (Cloudscape
/// `BoardProps.ItemPlacement`).
@immutable
class CsBoardPlacement {
  const CsBoardPlacement({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String id;

  /// First column, from 0.
  final int x;

  /// First row, from 0.
  final int y;

  /// Columns taken.
  final int width;

  /// Rows taken.
  final int height;

  /// Whether this placement shares a cell with [other].
  bool overlaps(CsBoardPlacement other) =>
      x < other.x + other.width && other.x < x + width && y < other.y + other.height && other.y < y + height;

  @override
  bool operator ==(Object other) =>
      other is CsBoardPlacement &&
      other.id == id &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(id, x, y, width, height);

  @override
  String toString() => 'CsBoardPlacement($id, $x,$y ${width}x$height)';
}

/// A whole board laid out for one column count.
@immutable
class CsBoardGrid {
  const CsBoardGrid({required this.items, required this.columns, required this.rows});

  /// Placements in reading order (top to bottom, then start to end).
  final List<CsBoardPlacement> items;
  final int columns;

  /// Rows used by the lowest item.
  final int rows;

  CsBoardPlacement? operator [](String id) {
    for (final p in items) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// The board's grid math, ported from Cloudscape's board components
/// (`internal/utils/layout.ts`). Pure functions on [CsBoardEntry] lists; the
/// board widget calls them, and so can tests or app code that needs to add
/// an item at a spot.
///
/// Items pack like a skyline: each one, in list order, lands at its stored
/// column (or the first column where it fits without raising the board) and
/// as high as the items above it allow. A layout therefore never has
/// overlaps or holes that items could float into.
abstract final class CsBoardLayout {
  /// Smallest row span (Cloudscape `MIN_ROW_SPAN`).
  static const int minRowSpan = 2;

  /// Smallest column span (Cloudscape `MIN_COL_SPAN`).
  static const int minColumnSpan = 1;

  /// Column count for a board [width] (Cloudscape `useContainerColumns`):
  /// 1 below 688px, 2 below 912px, 4 below 2100px, else 6.
  static int columnsForWidth(double width) {
    if (width < 688) return 1;
    if (width < 912) return 2;
    if (width < 2100) return 4;
    return 6;
  }

  static int minColumns(CsBoardItemDefinition? d, int columns) =>
      math.min(columns, math.max(minColumnSpan, d?.minColumnSpan ?? 0));

  static int defaultColumns(CsBoardItemDefinition? d, int columns) =>
      math.min(columns, math.max(minColumns(d, columns), d?.defaultColumnSpan ?? 0));

  static int minRows(CsBoardItemDefinition? d) => math.max(minRowSpan, d?.minRowSpan ?? 0);

  static int defaultRows(CsBoardItemDefinition? d) => math.max(minRows(d), d?.defaultRowSpan ?? 0);

  /// Lays out [items] in [columns] columns (Cloudscape `interpretItems`).
  static CsBoardGrid interpret<T>(List<CsBoardEntry<T>> items, int columns) {
    final heights = List<int>.filled(columns, 0);
    final placed = <CsBoardPlacement>[];

    int rowOffset(int from, int span) {
      var r = 0;
      for (var c = from; c < from + span; c++) {
        r = math.max(r, heights[c]);
      }
      return r;
    }

    int spanOf(CsBoardEntry<T> item) => math.min(
      columns,
      math.max(minColumns(item.definition, columns), item.columnSpan ?? defaultColumns(item.definition, columns)),
    );
    int rowsOf(CsBoardEntry<T> item) =>
        math.max(minRows(item.definition), item.rowSpan ?? defaultRows(item.definition));

    int optimalOffset(int current, int span, int rows) {
      for (var c = current; c + span <= columns; c++) {
        if (rowOffset(c, span) + rows <= rowOffset(0, columns)) return c;
      }
      for (var c = 0; c + span <= columns; c++) {
        if (rowOffset(c, span) + rows <= rowOffset(0, columns)) return c;
      }
      return current;
    }

    var columnOffset = 0;
    for (final item in items) {
      final span = spanOf(item);
      final rows = rowsOf(item);
      var x = item.columnOffset?[columns] ?? optimalOffset(columnOffset, span, rows);
      if (x + span > columns || x < 0) x = 0;
      final y = rowOffset(x, span);
      placed.add(CsBoardPlacement(id: item.id, x: x, y: y, width: span, height: rows));
      for (var c = x; c < x + span; c++) {
        heights[c] = y + rows;
      }
      columnOffset = x + span;
    }
    placed.sort(_compare);
    return CsBoardGrid(items: placed, columns: columns, rows: heights.isEmpty ? 0 : heights.reduce(math.max));
  }

  static int _compare(CsBoardPlacement a, CsBoardPlacement b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x);

  /// Writes [grid] back into [items] (Cloudscape `transformItems`): items
  /// come back in reading order with this column count's offset stored.
  /// Offsets for other column counts are dropped from the first item whose
  /// position changed, so those layouts reflow. [resized] also takes its
  /// spans from the grid.
  ///
  /// [previous] is the list before the change (defaults to [items]); the
  /// first position where the order differs from it starts the reflow.
  static List<CsBoardEntry<T>> apply<T>(
    List<CsBoardEntry<T>> items,
    CsBoardGrid grid, {
    String? resized,
    List<CsBoardEntry<T>>? previous,
  }) {
    final byId = {for (final i in items) i.id: i};
    final before = previous ?? items;
    final sorted = [...grid.items]..sort(_compare);
    var changeFrom = -1;
    for (var i = 0; i < sorted.length; i++) {
      if (i >= before.length || sorted[i].id != before[i].id || sorted[i].id == resized) {
        changeFrom = i;
        break;
      }
    }
    if (changeFrom < 0) changeFrom = sorted.length;
    return [
      for (var i = 0; i < sorted.length; i++)
        () {
          final p = sorted[i];
          final item = byId[p.id]!;
          final offsets = <int, int>{if (i < changeFrom) ...?item.columnOffset, grid.columns: p.x};
          return CsBoardEntry<T>(
            id: item.id,
            data: item.data,
            definition: item.definition,
            columnOffset: offsets,
            rowSpan: p.id == resized ? p.height : item.rowSpan,
            columnSpan: p.id == resized ? p.width : item.columnSpan,
          );
        }(),
    ];
  }

  /// [items] with [entry] placed at column [x], row [y] in the [columns]
  /// layout. Used for moving an item ([entry] already in [items]) and for
  /// inserting one (it is not). Other items keep their columns and are
  /// pushed down where they would overlap.
  static List<CsBoardEntry<T>> place<T>(List<CsBoardEntry<T>> items, CsBoardEntry<T> entry, int x, int y, int columns) {
    final current = interpret(items, columns);
    final span = math.min(
      columns,
      math.max(minColumns(entry.definition, columns), entry.columnSpan ?? defaultColumns(entry.definition, columns)),
    );
    final tx = x.clamp(0, columns - span);
    final ty = math.max(0, y);
    final rows = math.max(minRows(entry.definition), entry.rowSpan ?? defaultRows(entry.definition));
    final target = CsBoardPlacement(id: entry.id, x: tx, y: ty, width: span, height: rows);
    // Every remaining item keeps its current column so only the moved one
    // changes column. Items the target overlaps go right after the moved
    // item, so they are pushed below it; the rest keep reading order.
    final before = <CsBoardEntry<T>>[];
    final pushed = <CsBoardEntry<T>>[];
    final after = <CsBoardEntry<T>>[];
    for (final p in current.items) {
      if (p.id == entry.id) continue;
      final item = items.firstWhere((i) => i.id == p.id);
      final pinned = item.copyWith(columnOffset: {...?item.columnOffset, columns: p.x});
      if (p.overlaps(target)) {
        pushed.add(pinned);
      } else if (p.y < ty || (p.y == ty && p.x < tx)) {
        before.add(pinned);
      } else {
        after.add(pinned);
      }
    }
    final moved = entry.copyWith(columnOffset: {...?entry.columnOffset, columns: tx});
    final ordered = [...before, moved, ...pushed, ...after];
    return apply(ordered, interpret(ordered, columns), previous: items);
  }

  /// [items] with [id] resized to [width] columns and [height] rows in the
  /// [columns] layout, clamped to the item's minimums and to the columns
  /// left after its offset.
  static List<CsBoardEntry<T>> resize<T>(List<CsBoardEntry<T>> items, String id, int width, int height, int columns) {
    final grid = interpret(items, columns);
    final p = grid[id];
    if (p == null) return items;
    final item = items.firstWhere((i) => i.id == id);
    final w = width.clamp(minColumns(item.definition, columns), columns - p.x);
    final h = math.max(minRows(item.definition), height);
    final pinned = [
      for (final i in items)
        i.id == id
            ? i.copyWith(columnSpan: w, rowSpan: h, columnOffset: {...?i.columnOffset, columns: p.x})
            : i.copyWith(columnOffset: {...?i.columnOffset, columns: grid[i.id]!.x}),
    ];
    // Keep reading order by the original positions.
    pinned.sort((a, b) => _compare(grid[a.id]!, grid[b.id]!));
    return apply(pinned, interpret(pinned, columns), resized: id, previous: items);
  }

  /// [items] without [id]; the items below float up.
  static List<CsBoardEntry<T>> remove<T>(List<CsBoardEntry<T>> items, String id, int columns) {
    final rest = [
      for (final i in items)
        if (i.id != id) i,
    ];
    return apply(rest, interpret(rest, columns), previous: items);
  }

  /// Ids of items whose placement differs between [before] and [after].
  static List<String> disturbed(CsBoardGrid before, CsBoardGrid after, {String? except}) => [
    for (final p in after.items)
      if (p.id != except && before[p.id] != null && before[p.id] != p) p.id,
  ];
}
