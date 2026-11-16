# CsSpaceBetween

Cloudscape's `SpaceBetween`: a vertical stack or a wrapping horizontal row with a token-sized gap between its children.

Cloudscape reference: https://cloudscape.design/components/space-between/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsSpaceBetween(
  direction: CsSpaceBetweenDirection.horizontal,
  size: CsSpacingSize.xs,
  children: [
    CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () {}),
    CsButton(text: 'Create', variant: CsButtonVariant.primary, onPress: () {}),
  ],
)
```

## When to use / when not to

Use it for consistent gaps between form fields (`l`), containers (`l`), buttons (`xs`) and text blocks. Use `CsColumnLayout` or `CsGrid` for columns.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` | | `SizedBox.shrink()` children are skipped, like Cloudscape skips null |
| `size` | `CsSpacingSize` | `m` | `n`, `xxxs` (2) to `xxxl` (40) |
| `direction` | `CsSpaceBetweenDirection` | `vertical` | `horizontal` wraps onto new rows |
| `alignItems` | `CsSpaceBetweenAlign?` | | `start`, `center`, `end`; vertical stacks stretch by default |

## Examples

### Form fields

```dart
CsSpaceBetween(size: CsSpacingSize.l, children: [
  CsFormField(label: 'Name', child: CsInput(value: '', onChange: (_) {})),
  CsFormField(label: 'Description', child: CsInput(value: '', onChange: (_) {})),
])
```

## Accessibility

Layout only.

## Motion

None.

## Mobile

Horizontal rows wrap, so they never overflow at 390px.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `size`, `direction`, `alignItems` | same names |
