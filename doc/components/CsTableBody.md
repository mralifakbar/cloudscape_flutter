# CsTableBody

Cloudscape's `TableBody` (`src/table-body`): the rows of a `CsTableRoot`. It tells each `CsTableRow` its position, so striping, row dividers and joined selection outlines match `CsTable`.

Cloudscape reference: https://cloudscape.design/components/table-body/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsTableBody(
  children: [
    CsTableRow(children: [CsTableBodyCell(child: Text('i-0abc123'))]),
    CsTableRow(children: [CsTableBodyCell(child: Text('i-0abc124'))]),
  ],
)
```

## When to use / when not to

Use one inside every `CsTableRoot`. For long lists, render only the rows in view and set `CsTableRoot.ariaRowcount`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` | required | The body rows, usually `CsTableRow`s |

## Examples

### Selected rows join

```dart
const CsTableBody(
  children: [
    CsTableRow(selected: true, children: [CsTableBodyCell(child: Text('web-server-1'))]),
    CsTableRow(selected: true, children: [CsTableBodyCell(child: Text('web-server-2'))]),
    CsTableRow(children: [CsTableBodyCell(child: Text('batch-worker'))]),
  ],
)
```

## Accessibility

Rows keep their own semantics; the body adds none.

## Motion

None.

## Mobile

Scrolls sideways with the table.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `children` |
| `positionStyle` | not supported (use a scroll view or `Transform` around the root) |
