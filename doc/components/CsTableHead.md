# CsTableHead

Cloudscape's `TableHead` (`src/table-head`): the header section of a `CsTableRoot`, holding one `CsTableRow` of `CsTableHeaderCell`s.

Cloudscape reference: https://cloudscape.design/components/table-head/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsTableHead(
  child: CsTableRow(
    children: [CsTableHeaderCell(child: Text('Name')), CsTableHeaderCell(child: Text('Type'))],
  ),
)
```

## When to use / when not to

Use one as the first child of `CsTableRoot`, or as its `stickyHeader`. It only works inside a `CsTableRoot`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | The header row, a `CsTableRow` of `CsTableHeaderCell`s |

## Examples

### As a sticky header

```dart
SizedBox(
  height: 240,
  child: CsTableRoot(
    stickyHeader: const CsTableHead(child: CsTableRow(children: [CsTableHeaderCell(child: Text('Name'))])),
    children: const [CsTableBody(children: [CsTableRow(children: [CsTableBodyCell(child: Text('example-bucket'))])])],
  ),
)
```

## Accessibility

The header row is a semantics container; its cells are headers.

## Motion

None. As a sticky header it gains `shadow-sticky-embedded` once the body scrolls under it.

## Mobile

Scrolls sideways with the body.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `child` |
| (visuals) | `color-background-table-header` (container content in `borderless` and `embedded`), 1px `color-border-divider-default` below |
