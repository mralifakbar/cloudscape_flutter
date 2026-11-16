import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'cs_collection_types.dart';

/// How a property filter query combines its tokens.
enum CsCollectionFilterOperation { and, or }

/// One condition of a property filter query (Cloudscape property filter
/// `Token`). A token without a [propertyKey] is free text and matches any
/// filtering property.
@immutable
class CsCollectionFilterToken {
  const CsCollectionFilterToken({this.propertyKey, this.operator = ':', required this.value});

  final String? propertyKey;

  /// One of `=`, `!=`, `:`, `!:`, `^`, `!^`, `<`, `<=`, `>`, `>=`.
  final String operator;
  final Object? value;

  @override
  bool operator ==(Object other) =>
      other is CsCollectionFilterToken &&
      other.propertyKey == propertyKey &&
      other.operator == operator &&
      other.value == value;

  @override
  int get hashCode => Object.hash(propertyKey, operator, value);
}

/// A property filter query (Cloudscape property filter `Query`).
@immutable
class CsCollectionFilterQuery {
  const CsCollectionFilterQuery({this.tokens = const [], this.operation = CsCollectionFilterOperation.and});

  static const CsCollectionFilterQuery empty = CsCollectionFilterQuery();

  final List<CsCollectionFilterToken> tokens;
  final CsCollectionFilterOperation operation;

  @override
  bool operator ==(Object other) =>
      other is CsCollectionFilterQuery && other.operation == operation && listEquals(other.tokens, tokens);

  @override
  int get hashCode => Object.hash(operation, Object.hashAll(tokens));
}

/// A property the property filter can match (Cloudscape
/// `FilteringProperty`).
@immutable
class CsCollectionFilterProperty {
  const CsCollectionFilterProperty({
    required this.key,
    required this.propertyLabel,
    this.groupValuesLabel,
    this.operators = const ['=', '!=', ':', '!:', '^', '!^'],
    this.defaultOperator = '=',
  });

  /// Field name read with the collection's [CsFieldGetter].
  final String key;
  final String propertyLabel;
  final String? groupValuesLabel;
  final List<String> operators;
  final String defaultOperator;
}

/// Text filtering settings (collection hooks `filtering`).
@immutable
class CsCollectionFiltering<T> {
  const CsCollectionFiltering({
    this.fields,
    this.filteringFunction,
    this.defaultFilteringText = '',
    this.empty,
    this.noMatch,
  });

  /// Fields searched by the default filter. Without them, map items are
  /// searched in every value and other items by `toString()`.
  final List<String>? fields;

  /// Replaces the default case-insensitive "contains" match.
  final bool Function(T item, String filteringText)? filteringFunction;
  final String defaultFilteringText;

  /// Shown by [CsCollection.emptyState] when there are no items at all.
  final Widget? empty;

  /// Shown by [CsCollection.emptyState] when the filter matches nothing.
  final Widget? noMatch;
}

/// Property filtering settings (collection hooks `propertyFiltering`).
@immutable
class CsCollectionPropertyFiltering<T> {
  const CsCollectionPropertyFiltering({
    required this.filteringProperties,
    this.filteringFunction,
    this.defaultQuery = CsCollectionFilterQuery.empty,
    this.empty,
    this.noMatch,
  });

  final List<CsCollectionFilterProperty> filteringProperties;

  /// Replaces the default token matching.
  final bool Function(T item, CsCollectionFilterQuery query)? filteringFunction;
  final CsCollectionFilterQuery defaultQuery;
  final Widget? empty;
  final Widget? noMatch;
}

/// Sorting settings (collection hooks `sorting`).
@immutable
class CsCollectionSorting<T> {
  const CsCollectionSorting({this.defaultState});

  final CsSortingState<T>? defaultState;
}

/// Pagination settings (collection hooks `pagination`).
@immutable
class CsCollectionPagination {
  const CsCollectionPagination({this.pageSize = 10, this.defaultPage = 1}) : assert(pageSize > 0);

  final int pageSize;
  final int defaultPage;
}

/// Selection settings (collection hooks `selection`).
@immutable
class CsCollectionSelection<T> {
  const CsCollectionSelection({this.defaultSelectedItems = const [], this.keepSelection = false, this.trackBy});

  final List<T> defaultSelectedItems;

  /// Keep the selection when the filter, sort or page changes. Off by
  /// default: changing what is shown clears the selection.
  final bool keepSelection;
  final CsTrackBy<T>? trackBy;
}

/// The in-memory collection logic of Cloudscape's `useCollection` hook
/// (`@cloudscape-design/collection-hooks`): text and property filtering,
/// sorting, pagination and selection over a list, with the counts a table,
/// filter and pagination need.
///
/// ```dart
/// final collection = CsCollection<Instance>(
///   instances,
///   getField: (item, field) => item.toJson()[field],
///   filtering: const CsCollectionFiltering(fields: ['id', 'name']),
///   sorting: const CsCollectionSorting(),
///   pagination: const CsCollectionPagination(pageSize: 20),
///   selection: CsCollectionSelection(trackBy: (i) => i.id),
/// );
///
/// ListenableBuilder(
///   listenable: collection,
///   builder: (context, _) => CsTable<Instance>(
///     items: collection.items,
///     columnDefinitions: columns,
///     sortingColumn: collection.sortingColumn,
///     sortingDescending: collection.sortingDescending,
///     onSortingChange: collection.setSorting,
///     selectionType: CsSelectionType.multi,
///     selectedItems: collection.selectedItems,
///     onSelectionChange: collection.setSelectedItems,
///     trackBy: collection.trackBy,
///     empty: collection.emptyState,
///     firstIndex: collection.firstIndex,
///     totalItemsCount: collection.filteredItemsCount,
///   ),
/// )
/// ```
///
/// It is a [ChangeNotifier]: every action notifies listeners. Dispose it
/// with its owner.
class CsCollection<T> extends ChangeNotifier {
  CsCollection(
    List<T> allItems, {
    CsFieldGetter<T>? getField,
    this.filtering,
    this.propertyFiltering,
    this.sorting,
    this.pagination,
    this.selection,
  }) : _allItems = List.unmodifiable(allItems),
       getField = getField ?? csDefaultFieldGetter<T>,
       _filteringText = filtering?.defaultFilteringText ?? '',
       _query = propertyFiltering?.defaultQuery ?? CsCollectionFilterQuery.empty,
       _sorting = sorting?.defaultState,
       _page = pagination?.defaultPage ?? 1,
       _selected = List.unmodifiable(selection?.defaultSelectedItems ?? const []) {
    _recompute();
  }

  /// Reads a named field from an item for sorting and filtering.
  final CsFieldGetter<T> getField;
  final CsCollectionFiltering<T>? filtering;
  final CsCollectionPropertyFiltering<T>? propertyFiltering;
  final CsCollectionSorting<T>? sorting;
  final CsCollectionPagination? pagination;
  final CsCollectionSelection<T>? selection;

  List<T> _allItems;
  String _filteringText;
  CsCollectionFilterQuery _query;
  CsSortingState<T>? _sorting;
  int _page;
  List<T> _selected;

  late List<T> _processed;
  late List<T> _pageItems;

  /// The source list, before filtering.
  List<T> get allItems => _allItems;

  /// Replaces the source list (after a fetch), keeping filter, sort and page.
  set allItems(List<T> value) {
    _allItems = List.unmodifiable(value);
    _recompute();
    notifyListeners();
  }

  /// Items on the current page, filtered and sorted. Pass to `items`.
  List<T> get items => _pageItems;

  /// All filtered and sorted items across pages.
  List<T> get allPageItems => _processed;

  /// Number of items that pass the filters.
  int get filteredItemsCount => _processed.length;

  String get filteringText => _filteringText;
  CsCollectionFilterQuery get propertyFilteringQuery => _query;
  CsSortingState<T>? get sortingState => _sorting;

  /// For `CsTable.sortingColumn`.
  CsSortingColumn<T>? get sortingColumn => _sorting?.sortingColumn;

  /// For `CsTable.sortingDescending`.
  bool get sortingDescending => _sorting?.isDescending ?? false;

  /// One-based index of the current page.
  int get currentPageIndex => _page;

  /// Number of pages; 1 when pagination is off or there are no items.
  int get pagesCount {
    final p = pagination;
    if (p == null) return 1;
    return math.max(1, (_processed.length / p.pageSize).ceil());
  }

  List<T> get selectedItems => _selected;

  /// For `trackBy`.
  CsTrackBy<T>? get trackBy => selection?.trackBy;

  /// One-based index of the first item on the page, for `firstIndex`.
  int get firstIndex => pagination == null ? 1 : (_page - 1) * pagination!.pageSize + 1;

  /// Whether a text or property filter is active.
  bool get isFiltered => _filteringText.isNotEmpty || _query.tokens.isNotEmpty;

  /// The `empty` widget when there are no items at all, the `noMatch`
  /// widget when filters hide everything, otherwise null.
  Widget? get emptyState {
    if (_processed.isNotEmpty) return null;
    if (_allItems.isEmpty) return filtering?.empty ?? propertyFiltering?.empty;
    if (_query.tokens.isNotEmpty) return propertyFiltering?.noMatch ?? filtering?.noMatch;
    return filtering?.noMatch ?? propertyFiltering?.noMatch;
  }

  /// Sets the text filter, returns to the first page and, unless
  /// [CsCollectionSelection.keepSelection], clears the selection.
  void setFiltering(String text) {
    if (text == _filteringText) return;
    _filteringText = text;
    _page = 1;
    _resetSelection();
    _recompute();
    notifyListeners();
  }

  /// Sets the property filter query.
  void setPropertyFiltering(CsCollectionFilterQuery query) {
    if (query == _query) return;
    _query = query;
    _page = 1;
    _resetSelection();
    _recompute();
    notifyListeners();
  }

  /// Sets the sort. Matches `CsTable.onSortingChange`.
  void setSorting(CsSortingState<T>? state) {
    _sorting = state;
    _resetSelection();
    _recompute();
    notifyListeners();
  }

  /// Moves to a one-based page, clamped to the available pages.
  void setCurrentPage(int pageIndex) {
    final next = pageIndex.clamp(1, pagesCount);
    if (next == _page) return;
    _page = next;
    _resetSelection();
    _recompute();
    notifyListeners();
  }

  /// Sets the selection. Matches `CsTable.onSelectionChange`.
  void setSelectedItems(List<T> items) {
    _selected = List.unmodifiable(items);
    notifyListeners();
  }

  void _resetSelection() {
    if (selection?.keepSelection ?? false) return;
    _selected = const [];
  }

  void _recompute() {
    final list = _allItems.where(_matchesText).where(_matchesQuery).toList();
    final s = _sorting;
    if (s != null && s.sortingColumn.isSortable) {
      final column = s.sortingColumn;
      int compare(T a, T b) {
        final r = column.sortingComparator != null
            ? column.sortingComparator!(a, b)
            : csCompareValues(getField(a, column.sortingField!), getField(b, column.sortingField!));
        return s.isDescending ? -r : r;
      }

      mergeSort<T>(list, compare: compare);
    }
    _processed = List.unmodifiable(list);
    final p = pagination;
    if (p == null) {
      _pageItems = _processed;
      return;
    }
    _page = _page.clamp(1, pagesCount);
    final start = (_page - 1) * p.pageSize;
    _pageItems = List.unmodifiable(_processed.skip(start).take(p.pageSize));
  }

  bool _matchesText(T item) {
    final f = filtering;
    final text = _filteringText;
    if (f == null || text.isEmpty) return true;
    if (f.filteringFunction != null) return f.filteringFunction!(item, text);
    final needle = text.toLowerCase();
    final fields = f.fields;
    if (fields != null) {
      return fields.any((k) => _string(getField(item, k)).toLowerCase().contains(needle));
    }
    final Object? value = item;
    if (value is Map) return value.values.any((v) => _string(v).toLowerCase().contains(needle));
    return _string(item).toLowerCase().contains(needle);
  }

  bool _matchesQuery(T item) {
    final pf = propertyFiltering;
    final q = _query;
    if (pf == null || q.tokens.isEmpty) return true;
    if (pf.filteringFunction != null) return pf.filteringFunction!(item, q);
    bool matches(CsCollectionFilterToken t) {
      if (t.propertyKey == null) {
        // Free text matches any filtering property; a negated operator
        // must hold for all of them.
        final negated = t.operator.startsWith('!');
        final keys = pf.filteringProperties.map((p) => p.key);
        return negated
            ? keys.every((k) => csCollectionMatchOperator(getField(item, k), t.operator, t.value))
            : keys.any((k) => csCollectionMatchOperator(getField(item, k), t.operator, t.value));
      }
      return csCollectionMatchOperator(getField(item, t.propertyKey!), t.operator, t.value);
    }

    return q.operation == CsCollectionFilterOperation.and ? q.tokens.every(matches) : q.tokens.any(matches);
  }
}

String _string(Object? v) => v == null ? '' : v.toString();

/// Matches [itemValue] against [tokenValue] with a property filter
/// [operator], the way collection hooks do: text operators are
/// case-insensitive, comparisons are numeric when both sides are numbers.
bool csCollectionMatchOperator(Object? itemValue, String operator, Object? tokenValue) {
  num? asNum(Object? v) => v is num ? v : (v is String ? num.tryParse(v.trim()) : null);
  String asText(Object? v) => _string(v).toLowerCase();
  int compare() {
    final a = asNum(itemValue);
    final b = asNum(tokenValue);
    if (a != null && b != null) return a.compareTo(b);
    if (itemValue is DateTime && tokenValue is DateTime) return itemValue.compareTo(tokenValue);
    return _string(itemValue).compareTo(_string(tokenValue));
  }

  bool equal() {
    final a = asNum(itemValue);
    final b = asNum(tokenValue);
    if (a != null && b != null) return a == b;
    return _string(itemValue) == _string(tokenValue);
  }

  return switch (operator) {
    '=' => equal(),
    '!=' => !equal(),
    ':' => asText(itemValue).contains(asText(tokenValue)),
    '!:' => !asText(itemValue).contains(asText(tokenValue)),
    '^' => asText(itemValue).startsWith(asText(tokenValue)),
    '!^' => !asText(itemValue).startsWith(asText(tokenValue)),
    '<' => compare() < 0,
    '<=' => compare() <= 0,
    '>' => compare() > 0,
    '>=' => compare() >= 0,
    _ => false,
  };
}
