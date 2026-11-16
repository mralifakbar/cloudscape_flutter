# CsGrid

Cloudscape's `Grid`: a 12-column responsive grid where each child sets its span, offset, push and pull per breakpoint.

Cloudscape reference: https://cloudscape.design/components/grid/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsGrid(
  gridDefinition: [
    CsGridDefinition(colspan: {CsBreakpoint.base: 12, CsBreakpoint.xs: 8}),
    CsGridDefinition(colspan: {CsBreakpoint.base: 12, CsBreakpoint.xs: 4}),
  ],
  children: [Text('Main'), Text('Aside')],
)
```

## When to use / when not to

Use the grid for page-level layouts with unequal columns. Use `CsColumnLayout` for equal columns and `CsSpaceBetween` for simple stacks.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` |  |  |
| `gridDefinition` | `List<CsGridDefinition>` | `[]` | One per child; children without one span 12 |
| `disableGutters` | `bool` | `false` | Removes `space-grid-gutter` between cells |

## Examples

### Same values at every breakpoint

```dart
const CsGrid(
  gridDefinition: [CsGridDefinition.all(colspan: 6, offset: 3)],
  children: [Text('Centered')],
)
```

### Reorder with push and pull

```dart
const CsGrid(
  gridDefinition: [
    CsGridDefinition.all(colspan: 6, push: 6),
    CsGridDefinition.all(colspan: 6, pull: 6),
  ],
  children: [Text('First in order'), Text('Second in order')],
)
```

## Accessibility

Children are read in source order regardless of push and pull, so keep the source order meaningful.

## Motion

None.

## Mobile

Breakpoints follow the grid's own width (Cloudscape container query): `base` under 465, `xxs` 465, `xs` 688, `s` 912, `m` 1120, `l` 1320, `xl` 1840. A missing breakpoint falls back to the nearest smaller one. Cells that do not fit wrap to a new row; cells in a row stretch to the tallest.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `gridDefinition` | `gridDefinition: [CsGridDefinition(...)]` |
| `colspan / offset / push / pull (number)` | `CsGridDefinition.all(colspan:, offset:, push:, pull:)` |
| `colspan / offset / push / pull (mapping)` | `Map<CsBreakpoint, int>`; `default` is `CsBreakpoint.base` |
| `disableGutters` | `disableGutters` |
