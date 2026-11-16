# CsTableRoot

Cloudscape's `TableRoot` (`src/table-root`): the frame of a composable table. You build the head and rows from `CsTableHead`, `CsTableBody`, `CsTableRow`, `CsTableHeaderCell` and `CsTableBodyCell`; the root sizes the columns and draws the table the way `CsTable` does.

Cloudscape reference: https://cloudscape.design/components/table-root/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsTableRoot(
  ariaLabel: 'Instances',
  variant: CsTableVariant.container,
  children: [
    const CsTableHead(
      child: CsTableRow(
        children: [CsTableHeaderCell(child: Text('Name')), CsTableHeaderCell(child: Text('State'))],
      ),
    ),
    CsTableBody(
      children: [
        for (final name in ['web-server-1', 'web-server-2'])
          CsTableRow(
            children: [
              CsTableBodyCell(isRowHeader: true, child: Text(name)),
              const CsTableBodyCell(child: CsStatusIndicator(type: CsStatusType.success, text: 'Running')),
            ],
          ),
      ],
    ),
  ],
)
```

## When to use / when not to

Reach for the parts when `CsTable`'s column definitions do not fit: rows built from different widgets, cells that span columns, summary rows, or a table whose state lives elsewhere. For a data table with selection, sorting, filtering, pagination, inline edit, expandable rows and the card layout on phones, use `CsTable`, which does all of it for you.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` | required | A `CsTableHead` then a `CsTableBody` (only the body when `stickyHeader` is set) |
| `columnLayout` | `CsTableColumnLayout` | `CsTableColumnLayout.auto()` | `auto()`: columns share the width evenly, at least 120px each. `grid([...])`: per-column `CsTableGridColumn` |
| `ariaLabel` | `String?` |  | Accessible name of the table |
| `ariaRowcount` | `int?` |  | Total rows including the header, when the body shows a subset |
| `stickyHeader` | `Widget?` |  | A `CsTableHead` pinned at the top while the body scrolls (needs a bounded height) |
| `stickyHeaderVerticalOffset` | `double` | `0` | Space above the sticky header |
| `variant` | `CsTableVariant` | `borderless` | Frame: `container`, `stacked` and `fullPage` draw `CsTable`'s rounded bordered container with 20px side padding; `borderless` and `embedded` none |
| `stripedRows` | `bool` | `false` | Shades every other body row (unless a row sets `shaded`) and uses the striped cell borders |
| `contentDensity` | `CsDensity` | `comfortable` | `compact` applies `CsDensityTokens.compactTable` |
| `wrapLines` | `bool` | `false` | Default for cells: wrap long text instead of truncating |
| `cellVerticalAlign` | `CsTableVerticalAlign` | `middle` | Default vertical alignment of body cells |
| `stickyColumns` | `CsStickyColumns` | `none` | Columns kept at the start and end while the table scrolls sideways |
| `i18nStrings` | `CsTablePartsI18nStrings` | English | Sort state, resizer and edit icon labels |

`CsTableGridColumn`: `CsTableGridColumn({flex = 1, minWidth, maxWidth})` for a flexible column, `CsTableGridColumn.fixed(size)` for a fixed one. A capped column (`maxWidth`) grows evenly instead of by weight, as in Cloudscape.

## Examples

### Grid columns, striped and compact

```dart
CsTableRoot(
  columnLayout: const CsTableColumnLayout.grid([
    CsTableGridColumn(minWidth: 180, flex: 2),
    CsTableGridColumn.fixed(140),
    CsTableGridColumn(minWidth: 100),
  ]),
  stripedRows: true,
  contentDensity: CsDensity.compact,
  children: const [
    CsTableBody(
      children: [
        CsTableRow(children: [CsTableBodyCell(child: Text('example-bucket')), CsTableBodyCell(child: Text('us-east-1')), CsTableBodyCell(child: Text('2 GiB'))]),
        CsTableRow(children: [CsTableBodyCell(child: Text('logs-bucket')), CsTableBodyCell(child: Text('eu-west-1')), CsTableBodyCell(child: Text('14 GiB'))]),
      ],
    ),
  ],
)
```

### Sticky header

```dart
SizedBox(
  height: 320,
  child: CsTableRoot(
    stickyHeader: const CsTableHead(
      child: CsTableRow(children: [CsTableHeaderCell(child: Text('Event')), CsTableHeaderCell(child: Text('Time'))]),
    ),
    children: [
      CsTableBody(
        children: [
          for (var i = 0; i < 40; i++)
            CsTableRow(children: [CsTableBodyCell(child: Text('Event $i')), const CsTableBodyCell(child: Text('12:00'))]),
        ],
      ),
    ],
  ),
)
```

## Accessibility

The root is a labelled semantics container and a focus traversal group. Header cells are headers (sortable ones are buttons that announce their sort state), row header cells are headers, rows report `selected`. Cloudscape's `selected` row styling is visual only: put a `CsCheckbox` or `CsRadioButton` in a cell for an accessible selection control.

## Motion

None beyond the parts' hover and press states.

## Mobile

The columns keep their minimum widths; when they need more width than the screen the table scrolls sideways and `stickyColumns` stay at the edges (from 148px of free space, as in `CsTable`). There is no card layout; use `CsTable` with `mobileLayout: CsTableMobileLayout.cards` or `CsCards` for that.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `children` |
| `columnLayout: { type: 'auto' }` | `CsTableColumnLayout.auto()` (even shares, 120px minimum; Flutter has no HTML table content sizing) |
| `columnLayout: { type: 'grid', columns }` | `CsTableColumnLayout.grid([CsTableGridColumn ...])` |
| `size: number` / `size: { flex }` / `minWidth` / `maxWidth` | `CsTableGridColumn.fixed(size)` / `flex` / `minWidth` / `maxWidth` |
| `ariaLabel` / `ariaRowcount` | `ariaLabel` / `ariaRowcount` |
| `stickyHeader` / `stickyHeaderVerticalOffset` | `stickyHeader` / `stickyHeaderVerticalOffset` |
| `ariaLabelledby`, `ariaDescribedby` | not supported (web only) |
| (from `Table`) | `variant`, `stripedRows`, `contentDensity`, `wrapLines`, `cellVerticalAlign`, `stickyColumns` |
