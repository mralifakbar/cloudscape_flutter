# CsColumnLayout

Cloudscape's `ColumnLayout`: lays content out in 1 to 4 equal columns (more with a minimum column width) that collapse on narrow widths.

Cloudscape reference: https://cloudscape.design/components/column-layout/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsColumnLayout(
  columns: 3,
  variant: CsColumnLayoutVariant.textGrid,
  children: [Text('Instance ID'), Text('Status'), Text('Type')],
)
```

## When to use / when not to

Use a column layout for key-value summaries and equal blocks of content. Use `CsGrid` when columns need different widths, and `CsKeyValuePairs` for labelled values.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` |  | One child per cell |
| `columns` | `int` | `1` | 1 to 4, or any count with `minColumnWidth` |
| `variant` | `CsColumnLayoutVariant` | `defaultVariant` | `defaultVariant` or `textGrid` (lines between columns, wider gutters) |
| `borders` | `CsColumnLayoutBorders` | `none` | `none`, `vertical`, `horizontal`, `all` (default variant only) |
| `disableGutters` | `bool` | `false` | Default variant only |
| `minColumnWidth` | `double?` |  | Fits as many columns of at least this width as possible, up to `columns` |

## Examples

### Borders

```dart
const CsColumnLayout(
  columns: 2,
  borders: CsColumnLayoutBorders.all,
  children: [Text('A'), Text('B'), Text('C'), Text('D')],
)
```

### Flexible columns

```dart
const CsColumnLayout(
  columns: 6,
  minColumnWidth: 160,
  children: [Text('1'), Text('2'), Text('3'), Text('4'), Text('5'), Text('6')],
)
```

## Accessibility

The layout adds no semantics; children read in order, row by row.

## Motion

None.

## Mobile

Columns follow the layout's own width: one per row under 465px, two per row up to 688px (for 2 to 4 columns), all columns above. The flexible layout keeps an even column count when it drops below `columns`. Cells in a row share the tallest height.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `columns` | `columns` |
| `variant` | `variant` |
| `borders` | `borders` |
| `disableGutters` | `disableGutters` |
| `minColumnWidth` | `minColumnWidth` |
| `children` | `children` |
