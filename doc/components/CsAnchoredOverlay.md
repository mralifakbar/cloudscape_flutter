# CsAnchoredOverlay

The positioning primitive behind every popover, tooltip, menu, select and combobox: it places a popup next to its trigger, flips and shifts it to stay on screen, follows the trigger and animates it in and out from the trigger.

Cloudscape reference: https://cloudscape.design/components/popover/ (a foundation primitive; Cloudscape has no public equivalent)

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsAnchoredOverlay(
  open: true,
  onDismiss: () {},
  overlayBuilder: (context, placement) => CsPopupSurface(
    placement: placement,
    showArrow: true,
    child: const Text('Copied'),
  ),
  child: CsButton(text: 'Copy', onPress: () {}),
)
```

## When to use / when not to

Use it to build a custom floating panel attached to a trigger. Reach for the finished components first: `CsPopover` for detail panels, `CsTooltip` for labels, `CsDropdown` for option lists (it also becomes a bottom sheet on phones). For full-screen or blocking UI use `CsModal` or `showCsSheet`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `open` | `bool` | required | Shows the popup; the parent owns it |
| `child` | `Widget` | required | The anchor (trigger) |
| `overlayBuilder` | `CsPopupBuilder` | required | `(context, CsPopupPlacement placement) => Widget` |
| `onDismiss` | `VoidCallback?` | | Outside tap or Escape; set `open` to false |
| `side` | `CsSide` | `bottom` | `top`, `bottom`, `left`, `right`; flips when the side has less than `preferredExtent` and the other side has more |
| `align` | `CsAlign` | `center` | `start`, `center`, `end` along the anchor edge |
| `sideOffset` | `double` | `8` | Gap between anchor and popup |
| `alignOffset` | `double` | `0` | Shift along the edge |
| `collisionPadding` | `double` | `8` | Minimum distance from the screen edges (and the keyboard) |
| `preferredExtent` | `double` | `200` | Room the popup would like before it flips |
| `matchAnchorWidth` | `bool` | `false` | At least as wide as the anchor |
| `dismissOnOutsideTap` | `bool` | `true` | |
| `closeOnEscape` | `bool` | `true` | |
| `trapFocus` | `bool` | `false` | Move focus in, cycle Tab inside, restore on close |
| `restoreFocus` | `bool` | `true` | With `trapFocus`, give focus back to the anchor |
| `useRootOverlay` | `bool` | `true` | Render in the root overlay |
| `animate` | `bool` | `true` | False shows and hides instantly |
| `onClosed` | `VoidCallback?` | | After the exit animation finished |
| `tapRegionGroupId` | `Object?` | | Treat taps inside other widgets of this group as inside |
| `focusPopupWhenUnfocused` | `bool` | `true` | Give the popup focus when nothing had keyboard focus, so Escape reaches it |

`CsPopupPlacement` tells the builder the resolved `side`, `align`, `anchorRect`, the room left (`maxWidth`, `maxHeight`) and, while painting, `popupRect` and `arrowOffset(popup)` for an arrow.

## Examples

### A menu below a button

```dart
CsAnchoredOverlay(
  open: true,
  side: CsSide.bottom,
  align: CsAlign.start,
  matchAnchorWidth: true,
  trapFocus: true,
  onDismiss: () {},
  overlayBuilder: (context, placement) => CsPopupSurface(
    padding: EdgeInsets.zero,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: placement.maxHeight),
      child: const SingleChildScrollView(child: Text('Stop instance\nReboot instance\nTerminate instance')),
    ),
  ),
  child: CsButton(text: 'Instance state', onPress: () {}),
)
```

## Accessibility

Escape and outside taps call `onDismiss`. With `trapFocus` the popup is a focus trap (see `CsFocusTrap`); without it, focus stays on the anchor, and when nothing had focus the popup takes it so Escape works. Give the popup content its own semantics (a label, a header).

## Motion

The popup scales from 0.9 with its transform origin on the anchor and fades over Cloudscape's 115ms responsive motion; closing runs the same path. The scale is a spring, so reopening mid-close turns around from where it is. Reduced motion keeps only the fade.

## Mobile

The popup flips to the side with more room, shifts along the edge to stay `collisionPadding` inside the screen, and treats the on-screen keyboard as an edge. On phones prefer `CsDropdown` with `CsPresentation.auto`, which turns long lists into bottom sheets.

## Cloudscape React mapping

| Cloudscape concept | Flutter parameter |
| --- | --- |
| popover `position` | `side` + `align` |
| `renderWithPortal` | `useRootOverlay` |
| dropdown `expandToViewport`, `stretchWidth` | `useRootOverlay`, `matchAnchorWidth` |
