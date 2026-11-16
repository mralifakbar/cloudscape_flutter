# CsTableHeaderCell

Cloudscape's `TableHeaderCell` (`src/table-header-cell`): a column header with the label, the sorting caret, the divider to the next column and an optional resize handle, styled as `CsTable`'s headers.

Cloudscape reference: https://cloudscape.design/components/table-header-cell/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsTableHeaderCell(
  sortingState: descending ? CsTableSortingState.descending : CsTableSortingState.ascending,
  onSort: () => setState(() => descending = !descending),
  child: const Text('Launch time'),
)
```

## When to use / when not to

Use one per column in the `CsTableRow` of a `CsTableHead`. Leave `sortingState` null for columns that cannot sort.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | The column label |
| `ariaLabel` | `String?` |  | Accessible name |
| `sortingState` | `CsTableSortingState?` | `null` | `sortable` (hollow caret), `ascending` or `descending` (filled caret, `color-text-interactive-active`); null for no sorting |
| `sortingDisabled` | `bool` | `false` | Shows the state, ignores presses, draws the caret disabled |
| `onSort` | `VoidCallback?` |  | Called when a sortable header is pressed; the app flips the direction |
| `disablePaddings` | `bool` | `false` | Removes the cell padding |
| `resizable` | `bool` | `false` | Adds a resize handle on the end edge |
| `onResize` | `ValueChanged<double>?` |  | New width while dragging or on arrow keys (10px a press); store it in a `CsTableGridColumn.fixed` |
| `onResizeEnd` | `VoidCallback?` |  | Called when a resize ends |
| `minWidth` | `double` | `120` | Narrowest width `onResize` reports |
| `editable` | `bool` | `false` | Edit icon after the label, for columns with editable cells |
| `wrapLines` | `bool?` | root's `wrapLines` | Wrap a long label |

## Examples

### Resizable column

```dart
CsTableRoot(
  columnLayout: CsTableColumnLayout.grid([CsTableGridColumn.fixed(nameWidth), const CsTableGridColumn(minWidth: 120)]),
  children: [
    CsTableHead(
      child: CsTableRow(
        children: [
          CsTableHeaderCell(
            resizable: true,
            onResize: (w) => setState(() => nameWidth = w),
            child: const Text('Name'),
          ),
          const CsTableHeaderCell(child: Text('Type')),
        ],
      ),
    ),
  ],
)
```

## Accessibility

A sortable header is a button whose value is the sort state ("sorted ascending", "sorted descending", "not sorted", from `CsTableRoot.i18nStrings`); Enter and Space sort. Other headers are semantic headers. The resize handle is focusable, adjustable with the arrow keys, and announces its width.

## Motion

Hover colors change instantly; the divider turns into a 2px `color-border-divider-active` line while the handle is hovered, focused or dragged.

## Mobile

The label truncates unless `wrapLines`; the resize handle is 16px wide and can be dragged by touch.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `child` |
| `ariaLabel` | `ariaLabel` |
| `ariaSort` | `sortingState` |
| `disablePaddings` | `disablePaddings` |
| (from `Table` columns) | `onSort`, `sortingDisabled`, `resizable`, `onResize`, `editable`, `wrapLines` |
| `ariaLabelledby`, `ariaDescribedby` | not supported (web only) |
