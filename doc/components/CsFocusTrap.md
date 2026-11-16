# CsFocusTrap

Keeps keyboard focus inside a subtree while it is on screen and hands focus back to whatever had it before when the subtree goes away. Cloudscape's `FocusLock`, used by modals, sheets and popovers with controls.

Cloudscape reference: https://cloudscape.design/components/modal/ (a foundation primitive; Cloudscape's internal `FocusLock`)

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFocusTrap(
  onEscPress: () {},
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CsButton(text: 'Save', onPress: () {}),
      CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () {}),
    ],
  ),
)
```

## When to use / when not to

Use it for custom overlays that hold controls. `CsModal`, `CsDialog`, `showCsSheet`, `CsDialogRoute` and `CsAnchoredOverlay(trapFocus: true)` already wrap their content in one.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | |
| `onEscPress` | `VoidCallback?` | | Escape pressed while focus is inside |
| `disableFocusTrap` | `bool` | `false` | Let Tab leave at the ends (inline panels such as `CsDialog`) |
| `restoreFocusOnUnmount` | `bool` | `true` | Give focus back to the previously focused widget, if focus is still lost |
| `disableAutoFocus` | `bool` | `false` | Do not move focus in on mount |
| `disableArrowKeyNavigation` | `bool` | `true` | False makes Up and Down move focus like Shift+Tab and Tab |

## Examples

### Arrow keys between actions

```dart
CsFocusTrap(
  disableArrowKeyNavigation: false,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CsButton(text: 'Start instance', variant: CsButtonVariant.link, onPress: () {}),
      CsButton(text: 'Stop instance', variant: CsButtonVariant.link, onPress: () {}),
    ],
  ),
)
```

## Accessibility

Tab and Shift+Tab wrap at the ends instead of escaping to the page behind. Focus returns to the previous widget only when it is still lost when the trap goes away, so an overlay that opened in the meantime keeps its focus.

## Motion

None.

## Mobile

Hardware keyboards on tablets and phones get the same behavior; touch users are unaffected.

## Cloudscape React mapping

| Cloudscape concept | Flutter parameter |
| --- | --- |
| `FocusLock disabled` | `disableFocusTrap` |
| `restoreFocus` | `restoreFocusOnUnmount` |
| `autoFocus` | `disableAutoFocus` (inverted) |
