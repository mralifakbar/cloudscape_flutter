# CsToggleButton

Cloudscape's `ToggleButton`: a button that stays pressed until pressed again.

Cloudscape reference: https://cloudscape.design/components/toggle-button/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsToggleButton(
  text: 'Favorite',
  icon: CsIcons.star,
  pressedIcon: CsIcons.starFilled,
  pressed: true,
  onChange: (pressed) {},
)
```

## When to use / when not to

Use it for a two-state action (bookmark, mute, show grid). For a setting that takes effect like a switch, use a toggle; for one of several modes, a segmented control.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `pressed` | `bool` | required | On or off |
| `onChange` | `ValueChanged<bool>?` | | Next state; null disables |
| `text` | `String?` | | Button text |
| `variant` | `CsToggleButtonVariant` | `normal` | `normal` or `icon` |
| `icon`, `pressedIcon` | `CsIconData?` | | Icons for off and on |
| `iconWidget`, `pressedIconWidget` | `Widget?` | | Custom icons |
| `disabled` | `bool` | `false` | |
| `disabledReason` | `String?` | | Tooltip; keeps it focusable |
| `loading`, `loadingText` | | | Spinner, presses ignored |
| `ariaLabel` | `String?` | | Required for the icon variant; shown as its tooltip |
| `focusNode`, `autofocus` | | | |

## Examples

### Icon toggle

```dart
CsToggleButton(
  variant: CsToggleButtonVariant.icon,
  icon: CsIcons.thumbsUp,
  pressedIcon: CsIcons.thumbsUpFilled,
  ariaLabel: 'Helpful',
  pressed: false,
  onChange: (pressed) {},
)
```

## Accessibility

Announced as a toggle button with its pressed state. Enter and Space toggle. A selection haptic plays on touch devices.

## Motion

Press feedback scales to 0.98 with a spring; colors switch instantly. Reduced motion removes the scale.

## Mobile

32px tall (28px compact) with a 44px touch target.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `pressed`, `variant`, `disabled`, `disabledReason`, `loading`, `loadingText`, `ariaLabel` | same names |
| `onChange` (`detail.pressed`) | `onChange` (bool) |
| `children` | `text` |
| `iconName`, `pressedIconName` | `icon`, `pressedIcon` |
| `iconSvg`/`iconUrl`, `pressedIconSvg`/`pressedIconUrl` | `iconWidget`, `pressedIconWidget` |
| `nativeButtonAttributes`, `ariaControls` | not applicable |
