# CsPressable

The interaction primitive under every tappable Cloudscape component. Use it for custom rows, tiles and cards that need press feedback, hover, keyboard focus, a 44px touch target and semantics.

Cloudscape reference: https://cloudscape.design/foundation/core-principles/accessibility/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsPressable(
  onPress: () {},
  semanticLabel: 'Open bucket',
  builder: (context, state) => Container(
    color: state.active ? context.cs.colors.backgroundDropdownItemHover : null,
    padding: const EdgeInsets.all(CsSpace.s),
    child: const CsBox(text: 'example-bucket'),
  ),
)
```

## When to use / when not to

Whenever you build a tappable surface that no component covers. Do not use `GestureDetector` or `InkWell` for buttons, rows, chips or tabs.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `builder` | `CsPressableBuilder?` | | Builds visuals from `CsPressState` (`hovered`, `pressed`, `focused`, `disabled`, `active`) |
| `child` | `Widget?` | | Static content |
| `onPress`, `onLongPress`, `onPressIn`, `onPressOut` | | | |
| `disabled`, `loading` | `bool` | `false` | |
| `borderRadius` | `BorderRadius` | zero | Shape of the focus ring |
| `focusRingColor`, `focusRingWidth`, `focusRingOffset`, `showFocusRing` | | `borderItemFocused`, 2, 0, true | |
| `scaleOnPress`, `pressScale` | | true, 0.98 | |
| `haptic` | `CsHaptic` | `none` | |
| `debounce` | `Duration` | zero | Ignore repeat presses inside this window |
| `minTapTargetSize` | `double?` | theme | 44 on touch, 0 with a mouse |
| `semanticLabel`, `semanticHint`, `semanticValue`, `selected`, `toggled`, `checked`, `mixed`, `expanded`, `isButton`, `isLink` | | | Semantics |
| `focusNode`, `autofocus`, `canRequestFocus` | | | |
| `excludeChildSemantics`, `mergeChildSemantics` | `bool` | false, true | |

## Accessibility

Exposes role, label and state; Enter and Space activate; the focus ring shows only for keyboard focus.

## Motion

Pointer-down scales to 0.98 on a spring that starts from wherever the surface is; hover and pressed colors switch instantly. Reduced motion keeps colors and drops the scale.

## Mobile

Pads the hit area to 44x44 on touch platforms without changing the visual.

## Cloudscape React mapping

No direct counterpart: it is the shared behavior of Cloudscape's buttons, links, options and cards.
