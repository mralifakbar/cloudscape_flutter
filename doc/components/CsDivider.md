# CsDivider

Cloudscape's `Divider` (`src/divider`): a 1px line that separates content, horizontal (optionally labelled) or vertical.

Cloudscape reference: https://cloudscape.design/components/divider/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsDivider()
```

## When to use / when not to

Use a divider to separate groups of content inside a panel, or a label such as "or" between alternatives. Do not use it between containers (they have their own borders) or to separate table rows.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `orientation` | `CsDividerOrientation` | `horizontal` | `horizontal` or `vertical` |
| `label` | `String?` |  | Text in the middle of a horizontal line (Cloudscape `children`) |
| `labelWidget` | `Widget?` |  | Custom label content |
| `dangerouslySetLineColor` | `Color?` |  | Line color override (Cloudscape `style.root.lineColor`) |
| `lineWidth` | `double` | `1` | Line thickness (`border-divider-section-width`) |

## Examples

### Labelled

```dart
const CsDivider(label: 'or')
```

### Vertical between actions

```dart
const SizedBox(
  height: 24,
  child: Row(
    spacing: 12,
    children: [Text('Edit'), CsDivider(orientation: CsDividerOrientation.vertical), Text('Copy')],
  ),
)
```

## Accessibility

The divider is decorative and has no semantics of its own. A label is read as plain text.

## Motion

None.

## Mobile

A horizontal divider takes the full width; a labelled one keeps at least 16px of line on each side of the label and the label wraps at 2x text.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `orientation` | `orientation` (`CsDividerOrientation`) |
| `children` | `label` / `labelWidget` |
| `style.root.lineColor / lineWidth` | `dangerouslySetLineColor` / `lineWidth` |
| `nativeAttributes` | not supported (web only) |
