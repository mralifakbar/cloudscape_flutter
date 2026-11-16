# CsCollection

A pure-Dart port of Cloudscape's `useCollection` hook (`@cloudscape-design/collection-hooks`): text and property filtering, sorting, pagination and selection over an in-memory list, with the values `CsTable`, `CsCards`, a text filter and a pagination control need.

Cloudscape reference: https://cloudscape.design/get-started/dev-guides/collection-hooks/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
final collection = CsCollection<Map<String, Object?>>(
  instances,
  filtering: const CsCollectionFiltering(
    fields: ['id', 'name'],
    empty: Text('No instances'),
    noMatch: Text('No matches'),
  ),
  sorting: const CsCollectionSorting(),
  pagination: const CsCollectionPagination(pageSize: 20),
  selection: CsCollectionSelection(trackBy: (item) => item['id']),
);
```

Wire it to a table with a `ListenableBuilder`:

```dart
ListenableBuilder(
  listenable: collection,
  builder: (context, _) => CsTable<Map<String, Object?>>(
    header: CsHeader(title: 'Instances', counter: '(${collection.filteredItemsCount})'),
    filter: CsInput(
      value: collection.filteringText,
      type: CsInputType.search,
      placeholder: 'Find instances',
      onChange: collection.setFiltering,
    ),
    pagination: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CsButton(icon: CsIcons.angleLeft, variant: CsButtonVariant.icon, semanticLabel: 'Previous page',
            onPress: () => collection.setCurrentPage(collection.currentPageIndex - 1)),
        Text('${collection.currentPageIndex} / ${collection.pagesCount}'),
        CsButton(icon: CsIcons.angleRight, variant: CsButtonVariant.icon, semanticLabel: 'Next page',
            onPress: () => collection.setCurrentPage(collection.currentPageIndex + 1)),
      ],
    ),
    items: collection.items,
    columnDefinitions: columns,
    trackBy: collection.trackBy,
    sortingColumn: collection.sortingColumn,
    sortingDescending: collection.sortingDescending,
    onSortingChange: collection.setSorting,
    selectionType: CsSelectionType.multi,
    selectedItems: collection.selectedItems,
    onSelectionChange: collection.setSelectedItems,
    empty: collection.emptyState,
    firstIndex: collection.firstIndex,
    totalItemsCount: collection.filteredItemsCount,
  ),
)
```

Create it in `initState` and `dispose()` it with its owner. Assign `allItems` after a fetch.

## When to use / when not to

Use it when the whole list is in memory. For server-side filtering, sorting and paging, keep that state yourself and pass the page of items to the table.

## API

| Member | Type | Description |
| --- | --- | --- |
| `CsCollection(allItems, {getField, filtering, propertyFiltering, sorting, pagination, selection})` |  | `getField(item, field)` reads named fields; maps work without it |
| `items` | `List<T>` | Current page, filtered and sorted |
| `allPageItems` | `List<T>` | All filtered and sorted items |
| `filteredItemsCount` | `int` | Items that pass the filters |
| `pagesCount`, `currentPageIndex`, `firstIndex` | `int` | One-based paging values |
| `filteringText`, `propertyFilteringQuery`, `sortingState` |  | Current state |
| `sortingColumn`, `sortingDescending` |  | For `CsTable` |
| `selectedItems`, `trackBy` |  | For selection |
| `emptyState` | `Widget?` | `empty` with no items, `noMatch` when filters hide all |
| `isFiltered` | `bool` | A filter is active |
| `allItems` (setter) | `List<T>` | Replace the source list |
| `setFiltering(text)` |  | Resets to page 1 |
| `setPropertyFiltering(query)` |  | Resets to page 1 |
| `setSorting(state)` |  | Matches `onSortingChange` |
| `setCurrentPage(index)` |  | Clamped to the pages |
| `setSelectedItems(items)` |  | Matches `onSelectionChange` |

Options:

- `CsCollectionFiltering<T>`: `fields`, `filteringFunction(item, text)`, `defaultFilteringText`, `empty`, `noMatch`. The default match is case-insensitive "contains" over `fields` (all map values without them).
- `CsCollectionPropertyFiltering<T>`: `filteringProperties` (`CsCollectionFilterProperty`: `key`, `propertyLabel`, `operators`, `defaultOperator`), `filteringFunction(item, query)`, `defaultQuery`, `empty`, `noMatch`.
- `CsCollectionFilterQuery`: `tokens` (`CsCollectionFilterToken`: `propertyKey`, `operator`, `value`) and `operation` (`and`, `or`). Operators: `=`, `!=`, `:`, `!:`, `^`, `!^`, `<`, `<=`, `>`, `>=`. A token without `propertyKey` is free text across all filtering properties. `csCollectionMatchOperator` exposes the matching.
- `CsCollectionSorting<T>`: `defaultState`. Sorting uses the column's `sortingComparator`, else `sortingField` through `getField`; it is stable.
- `CsCollectionPagination`: `pageSize` (10), `defaultPage` (1).
- `CsCollectionSelection<T>`: `defaultSelectedItems`, `keepSelection` (false clears the selection when filter, sort or page change), `trackBy`.

## Examples

### Property filtering

```dart
collection.setPropertyFiltering(
  const CsCollectionFilterQuery(
    tokens: [
      CsCollectionFilterToken(propertyKey: 'state', operator: '=', value: 'Running'),
      CsCollectionFilterToken(propertyKey: 'cpu', operator: '>=', value: 4),
    ],
  ),
);
```

### Typed items

```dart
final collection = CsCollection<Instance>(
  instances,
  getField: (item, field) => switch (field) {
    'id' => item.id,
    'name' => item.name,
    _ => null,
  },
  filtering: const CsCollectionFiltering(fields: ['id', 'name']),
);
```

## Accessibility

Pass `firstIndex` and `filteredItemsCount` to the table's `firstIndex` and `totalItemsCount`, and a `renderAriaLive` builder, so page changes are announced.

## Motion

None: it holds no UI.

## Mobile

Nothing specific; the table and cards it drives handle phones.

## Cloudscape React mapping

| collection-hooks | Flutter |
| --- | --- |
| `useCollection(allItems, options)` | `CsCollection<T>(allItems, ...)` (a `ChangeNotifier`) |
| `items`, `filteredItemsCount`, `allPageItems` | same |
| `actions.setFiltering` etc. | `setFiltering` etc. |
| `collectionProps` spread | individual getters (`sortingColumn`, `selectedItems`, `emptyState`...) |
| `filterProps`, `paginationProps`, `propertyFilterProps` | `filteringText`, `currentPageIndex`, `pagesCount`, `propertyFilteringQuery` |
| `expandableRows` option, `tokenGroups`, custom operator `match` | not supported yet; use `filteringFunction` |
