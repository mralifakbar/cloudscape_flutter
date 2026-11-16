import 'package:flutter/foundation.dart';

/// How items in a table or cards collection are selected (Cloudscape
/// `selectionType`).
enum CsSelectionType {
  /// One item at a time, with radio buttons.
  single,

  /// Any number of items, with checkboxes and a select-all control.
  multi,
}

/// Returns a stable identity for [item] (Cloudscape `trackBy`). It connects
/// `items` with `selectedItems` and `expandedItems` when they are different
/// object instances, and keeps row state (editing, focus) attached to the
/// right item when the list is re-sorted.
typedef CsTrackBy<T> = Object? Function(T item);

/// Reads a named field from an item. Used where Cloudscape reads a property by
/// name (`sortingField`, text filtering fields, property filter keys). Items
/// that are `Map<String, Object?>` are read by key without one.
typedef CsFieldGetter<T> = Object? Function(T item, String field);

/// The sorting part of a column definition (Cloudscape `SortingColumn`).
///
/// [CsTableColumn] extends it, so a column can be passed wherever a sorting
/// column is expected:
///
/// ```dart
/// const CsSortingColumn<Instance>(sortingField: 'name')
/// ```
@immutable
class CsSortingColumn<T> {
  const CsSortingColumn({this.id, this.sortingField, this.sortingComparator});

  /// The column id, used to match the column across rebuilds.
  final String? id;

  /// Name of the item field to sort by (Cloudscape `sortingField`). Read with
  /// the collection's [CsFieldGetter].
  final String? sortingField;

  /// Ascending comparator (Cloudscape `sortingComparator`). Takes precedence
  /// over [sortingField]; descending order inverts it.
  final int Function(T a, T b)? sortingComparator;

  /// The column can be sorted: it has a [sortingField] or a [sortingComparator].
  bool get isSortable => sortingField != null || sortingComparator != null;

  /// Whether this column and [other] describe the same sort. Cloudscape
  /// compares the column object, then `sortingField`, then the comparator;
  /// the id is checked as well because Dart column lists are often rebuilt.
  bool sameSortAs(CsSortingColumn<T>? other) {
    if (other == null) return false;
    if (identical(this, other)) return true;
    if (id != null && id == other.id) return true;
    if (sortingField != null && sortingField == other.sortingField) return true;
    if (sortingComparator != null && sortingComparator == other.sortingComparator) return true;
    return false;
  }
}

/// The current sort (Cloudscape `SortingState`).
@immutable
class CsSortingState<T> {
  const CsSortingState({required this.sortingColumn, this.isDescending = false});

  final CsSortingColumn<T> sortingColumn;
  final bool isDescending;

  @override
  bool operator ==(Object other) =>
      other is CsSortingState<T> && other.isDescending == isDescending && other.sortingColumn.sameSortAs(sortingColumn);

  @override
  int get hashCode => Object.hash(sortingColumn.id ?? sortingColumn.sortingField, isDescending);

  @override
  String toString() =>
      'CsSortingState(${sortingColumn.id ?? sortingColumn.sortingField}, ${isDescending ? 'descending' : 'ascending'})';
}

/// How many leading and trailing columns stay in place while the table
/// scrolls sideways (Cloudscape `stickyColumns`).
@immutable
class CsStickyColumns {
  const CsStickyColumns({this.first = 0, this.last = 0}) : assert(first >= 0 && last >= 0);

  /// No sticky columns.
  static const CsStickyColumns none = CsStickyColumns();

  final int first;
  final int last;

  @override
  bool operator ==(Object other) => other is CsStickyColumns && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);

  @override
  String toString() => 'CsStickyColumns(first: $first, last: $last)';
}

/// The order and visibility of one column (Cloudscape `ColumnDisplay` and the
/// collection preferences `ContentDisplayItem`).
@immutable
class CsColumnDisplay {
  const CsColumnDisplay({required this.id, this.visible = true});

  /// The column id from the table's column definitions.
  final String id;
  final bool visible;

  CsColumnDisplay copyWith({bool? visible}) => CsColumnDisplay(id: id, visible: visible ?? this.visible);

  @override
  bool operator ==(Object other) => other is CsColumnDisplay && other.id == id && other.visible == visible;

  @override
  int get hashCode => Object.hash(id, visible);

  @override
  String toString() => 'CsColumnDisplay($id, ${visible ? 'visible' : 'hidden'})';
}

/// What a collection reports to screen readers when its page changes
/// (Cloudscape `LiveAnnouncement`).
@immutable
class CsLiveAnnouncement {
  const CsLiveAnnouncement({
    required this.firstIndex,
    required this.lastIndex,
    required this.visibleItemsCount,
    this.totalItemsCount,
  });

  /// One-based index of the first rendered item.
  final int firstIndex;

  /// One-based index of the last rendered item.
  final int lastIndex;
  final int visibleItemsCount;
  final int? totalItemsCount;
}

/// Reads [field] from [item] when it is a map; otherwise returns null.
Object? csDefaultFieldGetter<T>(T item, String field) {
  final Object? value = item;
  if (value is Map) return value[field];
  return null;
}

/// Compares two field values the way JavaScript's `<` does for the types a
/// collection holds: nulls first, numbers numerically, strings by code unit,
/// booleans false before true, and anything else by its string form.
int csCompareValues(Object? a, Object? b) {
  if (a == null && b == null) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  if (a is num && b is num) return a.compareTo(b);
  if (a is bool && b is bool) return a == b ? 0 : (a ? 1 : -1);
  if (a is DateTime && b is DateTime) return a.compareTo(b);
  if (a is Comparable && b is Comparable && a.runtimeType == b.runtimeType) {
    return a.compareTo(b);
  }
  return a.toString().compareTo(b.toString());
}
