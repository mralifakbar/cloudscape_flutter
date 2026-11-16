# CsPopupSurface

The floating surface of popovers, tooltips and dropdowns: Cloudscape's popover container (`color-background-popover`, a 2px `color-border-popover` border, 8px radius, `shadow-popover`) with an optional arrow that points at the anchor.

Cloudscape reference: https://cloudscape.design/components/popover/ (a foundation primitive; Cloudscape has no public equivalent)

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsPopupSurface(child: Text('Copied'))
```

## When to use / when not to

Use it as the container inside a `CsAnchoredOverlay.overlayBuilder` for custom floating panels, so they match Cloudscape's popovers. Do not use it for content on the page (use `CsContainer`), and prefer the finished `CsPopover` and `CsTooltip`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | Content |
| `placement` | `CsPopupPlacement?` | | From `overlayBuilder`; needed for the arrow |
| `showArrow` | `bool` | `false` | Draw the 20x10 arrow toward the anchor |
| `borderRadius` | `double` | `CsBorderRadius.popover` (8) | |
| `borderWidth` | `double` | `CsBorderWidth.popover` (2) | Drawn inside the shape |
| `padding` | `EdgeInsetsGeometry` | 16 horizontal, 12 vertical | Cloudscape's popover body padding |
| `shadows` | `List<BoxShadow>?` | `shadow-popover` | |
| `fill` | `Color?` | `color-background-popover` | |
| `outline` | `Color?` | `color-border-popover` | |
| `clip` | `bool` | `true` | Clip content to the rounded shape |

`CsPopupSurface.arrowHeight` (10) is the arrow's height, to add to an overlay's `sideOffset`.

## Examples

### With an arrow

```dart
CsAnchoredOverlay(
  open: true,
  side: CsSide.top,
  sideOffset: CsPopupSurface.arrowHeight + 4,
  overlayBuilder: (context, placement) => CsPopupSurface(
    placement: placement,
    showArrow: true,
    child: const Text('vol-0abc123 is attached to i-0abc123.'),
  ),
  child: const Text('vol-0abc123'),
)
```

## Accessibility

The surface adds no semantics. Give its content a label or a heading, and use `CsAnchoredOverlay.trapFocus` when it holds controls.

## Motion

None of its own; `CsAnchoredOverlay` animates it. The arrow repaints as the popup moves, without rebuilding the content.

## Mobile

The surface takes the constraints its overlay gives it; pass `placement.maxWidth` and `placement.maxHeight` to scrollable content so it fits small screens.

## Cloudscape React mapping

| Cloudscape concept | Flutter parameter |
| --- | --- |
| popover `.container-body` | the surface |
| popover arrow | `showArrow` + `placement` |
