# CsScrim

The backdrop behind modals and sheets: Cloudscape's `color-background-modal-overlay`, so the page behind recedes, and a full-screen tap target that closes the overlay.

Cloudscape reference: https://cloudscape.design/components/modal/ (a foundation primitive)

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsScrim(onPress: () {})
```

## When to use / when not to

Use it under a custom blocking overlay you build yourself. `CsModal`, `showCsSheet` and `CsDialogRoute` already draw one.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `onPress` | `VoidCallback?` | | Tap on the backdrop; null makes it inert and hidden from screen readers |
| `opacity` | `double` | `1` | Multiplies the token's own opacity, for drag-driven dimming |
| `semanticLabel` | `String` | `'Close'` | Screen reader name when `onPress` is set |

## Examples

### Dimming with a drag

```dart
Stack(
  children: [
    const Positioned.fill(child: CsScrim(opacity: 0.5)),
    Align(alignment: Alignment.bottomCenter, child: CsContainer(child: const Text('Drag me down'))),
  ],
)
```

## Accessibility

With `onPress`, the scrim is a button named `semanticLabel`, so screen reader users can close the overlay without a gesture. It always absorbs taps, so the page behind stays inert.

## Motion

None of its own; overlays fade it in and out with their content.

## Mobile

Fills the screen it is given, including behind system bars.

## Cloudscape React mapping

| Cloudscape concept | Flutter parameter |
| --- | --- |
| modal `.root` background | the scrim |
| overlay click (`reason: 'overlay'`) | `onPress` |
