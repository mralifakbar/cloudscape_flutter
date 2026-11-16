# CsTableRow

Cloudscape's `TableRow` (`src/table-row`): one row of cells in a `CsTableHead` or `CsTableBody`.

Cloudscape reference: https://cloudscape.design/components/table-row/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsTableRow(
  selected: true,
  onPress: () {},
  children: const [CsTableBodyCell(child: Text('web-server-1')), CsTableBodyCell(child: Text('t3.micro'))],
)
```

## When to use / when not to

Use one per row of a composable table. Give it one cell per column, or cells with `colSpan` that add up to the column count.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` | required | Cells in column order |
| `selected` | `bool` | `false` | `color-background-item-selected` inside a 2px `color-border-item-selected` outline; adjacent selected rows join. Visual only |
| `shaded` | `bool?` | every other row with `stripedRows` | `color-background-cell-shaded` background |
| `ariaLabel` | `String?` |  | Accessible name of the row |
| `onPress` | `VoidCallback?` |  | Makes the row tappable (`CsTable.onRowClick`) |

## Examples

### Shaded summary row

```dart
const CsTableRow(
  shaded: true,
  children: [CsTableBodyCell(child: Text('Total')), CsTableBodyCell(child: Text('16 GiB'))],
)
```

## Accessibility

A body row is a semantics container that reports `selected`. Pair `selected` with a checkbox or radio button in a cell, as Cloudscape recommends.

## Motion

None. Hover and press of a tappable row show the focus ring only when focused from the keyboard.

## Mobile

A tappable row is the full row height; it scrolls sideways with the table.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `selected` | `selected` |
| `shaded` | `shaded` |
| `ariaLabel` | `ariaLabel` |
| `children` | `children` |
| `ariaRowindex`, `positionStyle`, `ariaLabelledby`, `ariaDescribedby` | not supported (web only) |
| (from `Table.onRowClick`) | `onPress` |
