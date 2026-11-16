# CsNavigableGroup

Cloudscape's `NavigableGroup` (`src/navigable-group`): makes a set of buttons, toggle buttons, button dropdowns or links a single Tab stop, with the arrow keys moving focus between them.

Cloudscape reference: https://cloudscape.design/components/navigable-group/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsNavigableGroup(
  semanticLabel: 'Instance actions',
  child: Wrap(
    spacing: 8,
    children: [
      CsButton(text: 'Start', onPress: () {}),
      CsButton(text: 'Stop', onPress: () {}),
      CsButton(text: 'Reboot', onPress: () {}),
    ],
  ),
)
```

## When to use / when not to

Use it for toolbars and other groups of related actions, so keyboard users cross the group with one Tab instead of one per control. Do not use it around form fields (each field needs its own Tab stop) or around a single control.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | Content holding the focusable controls; they do not need to be direct children |
| `navigationDirection` | `CsNavigationDirection` | `horizontal` | Which arrows move focus: `horizontal` (left and right), `vertical` (up and down) or `both` |
| `loop` | `bool` | `false` | Wrap from the last control to the first and back (Cloudscape wraps; set `true` to match it) |
| `semanticLabel` | `String?` |  | Accessible name of the group |

`CsNavigableGroupState` (through a `GlobalKey<CsNavigableGroupState>`): `focus()` focuses the control that had focus last, or the first one (Cloudscape `ref.focus()`); `items` lists the focusable controls in reading order; `tabStop` is the control Tab lands on.

## Examples

### Vertical list of links with wrap-around

```dart
CsNavigableGroup(
  navigationDirection: CsNavigationDirection.vertical,
  loop: true,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CsLink(text: 'Overview', onFollow: () {}),
      CsLink(text: 'Monitoring', onFollow: () {}),
      CsLink(text: 'Tags', onFollow: () {}),
    ],
  ),
)
```

### Focus the group from code

```dart
CsNavigableGroup(
  key: groupKey, // a GlobalKey<CsNavigableGroupState> kept in your State
  child: CsButton(text: 'Start', onPress: () => groupKey.currentState?.focus()),
)
```

## Accessibility

Tab enters the group on the control that had focus last (the first at first) and leaves after one stop; Shift+Tab returns to the same control. Arrow keys follow reading order and mirror in right-to-left layouts; Home and End jump to the first and last control; disabled controls are skipped (a disabled button with a reason stays reachable). Arrow keys with a modifier are left to the app. Page Up and Page Down are claimed without moving focus, as in Cloudscape.

## Motion

None. A control moved to by arrow key scrolls into view if the group is in a scroll view.

## Mobile

Touch is unaffected. Wrap the controls (`Wrap`) so they flow onto more lines at 390px.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `child` |
| `navigationDirection` | `navigationDirection` (`CsNavigationDirection`) |
| `getItemKey` | not needed (focus is tracked by `FocusNode`) |
| `ref.focus()` | `CsNavigableGroupState.focus()` |
| always wraps around | `loop` (off by default) |
