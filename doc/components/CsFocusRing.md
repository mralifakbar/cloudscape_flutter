# CsFocusRing

Cloudscape's keyboard focus ring: 2px of `color-border-item-focused`, drawn outside a control so layout never shifts. `CsPressable` draws it for you; use `CsFocusRing` around focusable widgets that are not built on it.

Cloudscape reference: https://cloudscape.design/foundation/visual-foundation/focus-indicators/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFocusRing(
  visible: true,
  offset: 4,
  borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
  child: const CsBox(text: 'Focused'),
)
```

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `visible` | `bool` | | Show the ring |
| `child` | `Widget` | | |
| `borderRadius` | `BorderRadius` | zero | |
| `color` | `CsColor` | `borderItemFocused` | |
| `width` | `double` | 2 | |
| `offset` | `double` | 0 | Gap between the control and the ring (Cloudscape's focus outline gutter) |

`CsFocusRingPainter` paints the same ring for custom painters.

## Accessibility

Show it only for keyboard focus (use `FocusableActionDetector.onShowFocusHighlight`), never hide it for keyboard users.

## Motion

None.

## Mobile

Visible with a hardware keyboard.

## Cloudscape React mapping

The `focus-visible` styles of every Cloudscape control.
