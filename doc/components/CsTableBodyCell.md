# CsTableBodyCell

Cloudscape's `TableBodyCell` (`src/table-body-cell`): a data cell, or the header of its row, styled as `CsTable`'s cells.

Cloudscape reference: https://cloudscape.design/components/table-body-cell/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsTableBodyCell(isRowHeader: true, child: Text('web-server-1'))
```

## When to use / when not to

Use one per column in a body `CsTableRow`. Put interactive content (a link, a button, a checkbox) inside it as needed.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | Cell content; text is body-m |
| `isRowHeader` | `bool` | `false` | Announces the cell as its row's header |
| `disablePaddings` | `bool` | `false` | Removes the cell padding |
| `colSpan` | `int` | `1` | Columns the cell covers |
| `wrapLines` | `bool?` | root's `wrapLines` | Wrap long text instead of truncating |
| `verticalAlign` | `CsTableVerticalAlign?` | root's `cellVerticalAlign` | `middle` or `top` |
| `editable` | `bool` | `false` | Inline-edit look: hover or focus fills `color-background-dropdown-item-hover` inside a `color-border-editable-cell-hover` border with an edit icon |
| `onEdit` | `VoidCallback?` |  | Called when an editable cell is activated |
| `editDisabledReason` | `String?` |  | Lock icon and the reason in a tooltip instead of editing |
| `editAriaLabel` | `String?` |  | Accessible name of the edit action |

## Examples

### Editable cell

```dart
editing
    ? CsTableBodyCell(child: CsInput(value: name, autoFocus: true, onChange: (v) => setState(() => name = v)))
    : CsTableBodyCell(
        editable: true,
        editAriaLabel: 'Edit name',
        onEdit: () => setState(() => editing = true),
        child: Text(name),
      )
```

### Spanning cell

```dart
const CsTableRow(
  children: [CsTableBodyCell(colSpan: 3, child: Text('No instances match the filter.'))],
)
```

## Accessibility

Row header cells are semantic headers. An editable cell is a button labelled `editAriaLabel`, with the disabled reason as its hint.

## Motion

None; the edit affordance appears instantly on hover and focus.

## Mobile

Text truncates to one line by default; set `wrapLines` for long values at 390px.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `child` |
| `isRowHeader` | `isRowHeader` |
| `disablePaddings` | `disablePaddings` |
| `colSpan` | `colSpan` |
| (from `Table`) | `wrapLines`, `verticalAlign`, `editable`, `onEdit`, `editDisabledReason`, `editAriaLabel` |
