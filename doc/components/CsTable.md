# CsTable

Cloudscape's `Table`: a collection of items in rows and columns, with sorting, selection, inline editing, expandable rows, resizable and sticky columns, and the header, filter, pagination and preferences slots of a collection.

Cloudscape reference: https://cloudscape.design/components/table/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsTable<Map<String, Object?>>(
  header: const CsHeader(title: 'Instances', counter: '(2)'),
  items: const [
    {'id': 'i-0abc123', 'state': 'Running'},
    {'id': 'i-0abc124', 'state': 'Stopped'},
  ],
  trackBy: (item) => item['id'],
  columnDefinitions: [
    CsTableColumn(id: 'id', header: 'Instance ID', isRowHeader: true, cell: (context, item) => Text('${item['id']}')),
    CsTableColumn(id: 'state', header: 'State', cell: (context, item) => Text('${item['state']}')),
  ],
)
```

## When to use / when not to

Use a table to compare many items across the same attributes and to act on one or more of them. Use `CsCards` when each item needs a richer, visual summary, `CsKeyValuePairs` for the attributes of one item, and a list for a few items with one attribute each.

The table is controlled: it renders `items` in the order given and reports sorting, selection and expansion through callbacks. Use `CsCollection` to filter, sort and paginate a list in memory.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `columnDefinitions` | `List<CsTableColumn<T>>` | required | The columns, see below |
| `items` | `List<T>` | required | Rows, in display order |
| `header` | `Widget?` |  | Usually a `CsHeader` with a counter and actions |
| `filter` | `Widget?` |  | Text or property filter, at the start of the tools row |
| `pagination` | `Widget?` |  | At the end of the tools row |
| `preferences` | `Widget?` |  | A `CsCollectionPreferences`, after the pagination with a divider |
| `footer` | `Widget?` |  | Under the rows |
| `empty` | `Widget?` |  | Shown when `items` is empty and not loading |
| `loading` / `loadingText` | `bool` / `String?` | `false` | Replaces the rows with a loading status |
| `trackBy` | `Object? Function(T)?` |  | Item identity for selection, expansion and edits |
| `variant` | `CsTableVariant` | `container` | `container`, `embedded`, `borderless`, `stacked`, `fullPage` |
| `selectionType` | `CsSelectionType?` |  | `single` (radios) or `multi` (checkboxes and select all) |
| `selectedItems` / `onSelectionChange` | `List<T>` / `ValueChanged<List<T>>?` | `[]` | Controlled selection; Shift extends a multi selection |
| `isItemDisabled` | `bool Function(T)?` |  | Disabled items cannot be selected |
| `sortingColumn` / `sortingDescending` | `CsSortingColumn<T>?` / `bool` | `null` / `false` | The current sort |
| `onSortingChange` | `ValueChanged<CsSortingState<T>>?` |  | Pressing a header: same column flips, another column sorts ascending |
| `sortingDisabled` | `bool` | `false` | Disables the sort buttons |
| `cellVerticalAlign` | `CsTableVerticalAlign` | `middle` | `middle` or `top` |
| `wrapLines` | `bool` | `false` | Wrap cell text instead of an ellipsis |
| `stripedRows` | `bool` | `false` | Shade every other row |
| `contentDensity` | `CsDensity` | `comfortable` | `compact` applies `CsDensityTokens.compactTable` |
| `resizableColumns` | `bool` | `false` | Drag handles between header cells; the last column fills |
| `onColumnWidthsChange` | `ValueChanged<List<double>>?` |  | All column widths after a resize, in definition order |
| `stickyColumns` | `CsStickyColumns` | `none` | `first` and `last` columns that stay while scrolling sideways |
| `columnDisplay` | `List<CsColumnDisplay>?` |  | Column order and visibility (from preferences) |
| `visibleColumns` | `List<String>?` |  | Deprecated in Cloudscape; ids of visible columns |
| `stickyHeader` | `bool` | `false` | Keeps header, tools and column headers in place (bounded height) |
| `stickyHeaderVerticalOffset` | `double` | `0` | Space above the stuck header |
| `onRowClick` | `ValueChanged<CsTableRowClickDetail<T>>?` |  | Row press (row index and item) |
| `onRowContextMenu` | `ValueChanged<CsTableRowContextMenuDetail<T>>?` |  | Secondary click or long press, with the position |
| `totalItemsCount` / `firstIndex` | `int?` |  | Counts for screen readers |
| `renderAriaLive` | `String Function(CsLiveAnnouncement)?` |  | Announced when the page of items changes |
| `submitEdit` | `FutureOr<void> Function(T, CsTableColumn<T>, Object?)?` |  | Saves an inline edit; throw to keep the editor open |
| `onEditCancel` | `VoidCallback?` |  | An inline edit was canceled |
| `enableKeyboardNavigation` | `bool?` | on with expandable rows | Arrow keys move focus between cells |
| `expandableRows` | `CsTableExpandableRows<T>?` |  | Nested rows, see below |
| `getLoadingStatus` | `CsTableLoadingStatus Function(T?)?` |  | Progressive loading for the list (`null`) and each expanded item |
| `renderLoaderPending` / `Loading` / `Error` | `Widget Function(T?)?` |  | Loader row content per status |
| `renderLoaderEmpty` | `Widget Function(T)?` |  | Shown under an expanded item without children |
| `ariaLabels` | `CsTableAriaLabels<T>?` |  | Selection, edit, expand and table labels |
| `i18nStrings` | `CsTableI18nStrings` | English | Fixed copy |
| `mobileLayout` | `CsTableMobileLayout` | `scroll` | Phones: `scroll` sideways or `cards` |
| `mobileStickyFirstColumn` | `bool` | `true` | With `scroll` on phones, stick the first column |
| `scrollController` | `ScrollController?` |  | Vertical scroll of lazily built rows |

`CsTableColumn<T>`: `id` (required), `header` or `headerWidget`, `cell(context, item)`, `width`, `minWidth` (default 120), `maxWidth`, `sortingField`, `sortingComparator`, `ariaLabel(CsTableLabelData)`, `counter(CsTableItemCounterData)`, `editConfig`, `isRowHeader`, `verticalAlign`, `cardLabel`.

`CsTableEditConfig<T>`: `editingCell(context, item, CsTableCellContext)`, `ariaLabel`, `errorIconAriaLabel`, `editIconAriaLabel`, `constraintText`, `validation(item, value)`, `disabledReason(item)`.

`CsTableExpandableRows<T>`: `getItemChildren`, `isItemExpandable`, `expandedItems`, `onExpandableItemToggle(item, expanded)`, `getItemsCount`, `totalItemsCount`, `getSelectedItemsCount`, `totalSelectedItemsCount`.

`CsTableState<T>` (through a `GlobalKey`): `scrollToTop()`, `cancelEdit()`.

## Examples

### Sorting and selection with a collection

```dart
ListenableBuilder(
  listenable: collection,
  builder: (context, _) => CsTable<Map<String, Object?>>(
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
  ),
)
```

### Inline editing

```dart
CsTable<Map<String, Object?>>(
  items: items,
  submitEdit: (item, column, value) async => save(item, value),
  columnDefinitions: [
    CsTableColumn(
      id: 'name',
      header: 'Name',
      cell: (context, item) => Text('${item['name']}'),
      editConfig: CsTableEditConfig(
        ariaLabel: 'Name',
        validation: (item, value) => (value as String?)?.isEmpty ?? false ? 'Enter a name.' : null,
        editingCell: (context, item, ctx) => CsInput(
          value: ctx.currentValue as String? ?? '${item['name']}',
          autoFocus: true,
          onChange: ctx.setValue,
          onSubmit: (_) => ctx.submitValue(),
        ),
      ),
    ),
  ],
)
```

Pressing an editable cell opens the editor. Enter or the check button submits, Escape, the close button or a tap outside cancels. Validation runs as the value changes. After a save the cell shows a success icon and announces "Edit successful".

### Expandable rows

```dart
CsTable<Map<String, Object?>>(
  items: groups,
  columnDefinitions: columns,
  trackBy: (item) => item['id'],
  expandableRows: CsTableExpandableRows(
    getItemChildren: (item) => children[item['id']] ?? const [],
    isItemExpandable: (item) => children.containsKey(item['id']),
    expandedItems: expanded,
    onExpandableItemToggle: (item, open) => setState(() => open ? expanded.add(item) : expanded.remove(item)),
  ),
)
```

### Resizable, sticky, striped and compact

```dart
CsTable<Map<String, Object?>>(
  items: items,
  columnDefinitions: columns,
  resizableColumns: true,
  stickyColumns: const CsStickyColumns(first: 1, last: 1),
  stripedRows: true,
  contentDensity: CsDensity.compact,
  wrapLines: true,
)
```

### Sticky header in a bounded height

```dart
SizedBox(
  height: 480,
  child: CsTable<Map<String, Object?>>(items: items, columnDefinitions: columns, stickyHeader: true),
)
```

### Progressive loading

```dart
CsTable<Map<String, Object?>>(
  items: items,
  columnDefinitions: columns,
  getLoadingStatus: (item) => hasMore ? CsTableLoadingStatus.pending : CsTableLoadingStatus.finished,
  renderLoaderPending: (item) => CsButton(text: 'Load more', variant: CsButtonVariant.inlineLink, onPress: loadMore),
)
```

## Accessibility

- The table is a semantics container named by `ariaLabels.tableLabel`; `totalItemsCount` is its value.
- Sortable headers are buttons whose value is "ascending", "descending" or "not sorted"; `CsTableColumn.ariaLabel` overrides the name.
- Selection controls are checkboxes (multi, with a mixed select-all) or radios (single), labeled by `itemSelectionLabel` and `allItemsSelectionLabel`. Rows expose their selected state.
- Row-header columns (`isRowHeader`) mark their cells as headers.
- Resize handles are focusable: Left and Right arrows change the width by 10px; screen readers can increase or decrease it.
- Inline editors trap Tab inside the cell; Escape cancels. Submitting and success are announced.
- With expandable rows (or `enableKeyboardNavigation`) the arrow keys move focus between cells.
- `renderAriaLive` messages are announced when the page changes.

## Motion

Expand toggles turn over `CsDurations.rotate90`. Hover colors on editable cells switch at once. Reduced motion removes the rotation. Selecting a checkbox draws its mark with the checkbox's own animation.

## Mobile

At 688px and below:

- `mobileLayout: CsTableMobileLayout.scroll` (default): the table keeps its columns and scrolls sideways; the first column (and the selection column) sticks to the start edge with Cloudscape's sticky shadow. Sticky columns are released when fewer than 148px would remain to scroll.
- `mobileLayout: CsTableMobileLayout.cards`: each row becomes a `CsItemCard` with the row-header (or first) column as its title, a selection control in the corner and the other visible columns as label and value pairs. A "Select all" checkbox sits above multi-selection cards.

The tools row stacks the filter above pagination and preferences below 600px.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `columnDefinitions[].cell(item)` | `CsTableColumn.cell(context, item)` |
| `columnDefinitions[].header` | `header` (String) or `headerWidget` |
| `trackBy` (string or function) | `trackBy` (function) |
| `sortingColumn`, `sortingDescending`, `onSortingChange` | same; detail is `CsSortingState<T>` |
| `onSelectionChange` detail `selectedItems` | `ValueChanged<List<T>>` |
| `contentDensity: 'compact'` | `contentDensity: CsDensity.compact` |
| `variant: 'full-page'` | `CsTableVariant.fullPage` |
| `onRowClick` / `onRowContextMenu` | same, detail classes |
| `ref.scrollToTop()` / `ref.cancelEdit()` | `CsTableState.scrollToTop()` / `cancelEdit()` |
| `expandableRows.groupSelection`, `multiColumnSort`, `groupDefinitions`, `skeleton` | not supported yet |
| `editConfig.disableNativeForm` | not needed: call `ctx.submitValue` |
| `hasDynamicContent`, `analyticsMetadata` | web only, not ported |
