# CsMenuPanel

The surface and rows of dropdown menus: `CsMenuPanel` (the container), `CsMenuRow` (an option), `CsMenuGroupLabel` (a group heading), `CsMenuSeparator` (a divider) and `CsMenuKeyboard` (arrow-key movement).

Cloudscape reference: https://cloudscape.design/components/button-dropdown/ (menu items are internal in Cloudscape)

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsMenuPanel(children: [
  CsMenuRow(label: 'Edit', icon: CsIcons.edit, onPress: () {}),
  CsMenuRow(label: 'Delete', icon: CsIcons.remove, destructive: true, onPress: () {}),
])
```

## When to use / when not to

Use these to build custom menus inside `CsDropdown` or `CsAnchoredOverlay`. For a ready menu button use `CsButtonDropdown`.

## Parameters

### CsMenuPanel

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` | required | Rows, labels, separators |
| `minWidth` | `double` | `144` | |
| `maxHeight` | `double?` | | Scrolls beyond it |
| `padding` | `EdgeInsetsGeometry` | 4px vertical | |
| `scrollController` | `ScrollController?` | | |
| `semanticLabel` | `String?` | | |

### CsMenuRow

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String` | required | |
| `onPress` | `VoidCallback?` | | |
| `icon` / `leading` | `CsIconData?` / `Widget?` | | Leading content |
| `description` | `String?` | | Small text under the label |
| `trailing` | `Widget?` | | Caret, check, badge |
| `shortcut` | `String?` | | Shortcut hint |
| `selected`, `checked`, `expanded`, `inMutuallyExclusiveGroup` | `bool?` | | Announced states |
| `highlighted` | `bool` | `false` | Force the highlight (lists driven from a text field) |
| `disabled`, `destructive`, `inset`, `isLink` | `bool` | `false` | |
| `focusNode`, `autofocus`, `canRequestFocus` | | | |
| `onHover` | `ValueChanged<bool>?` | | |
| `semanticLabel` | `String?` | | |

`CsMenuGroupLabel(text)`, `const CsMenuSeparator()`, `CsMenuKeyboard(child:)` take no other options.

## Examples

### Grouped menu

```dart
CsMenuPanel(maxHeight: 320, children: [
  const CsMenuGroupLabel('Instance'),
  CsMenuRow(label: 'Start', onPress: () {}),
  CsMenuRow(label: 'Stop', disabled: true, onPress: () {}),
  const CsMenuSeparator(),
  CsMenuRow(label: 'View logs', shortcut: 'L', onPress: () {}),
])
```

## Accessibility

Rows are buttons announcing their label and state; group labels are headers. Inside a panel (or `CsMenuKeyboard`), Up and Down move focus between rows and Home and End jump to the ends.

## Motion

Rows change colors instantly on hover and focus; no animation.

## Mobile

Rows are at least 40px tall on touch devices. In a sheet, pass the rows without the panel surface if the sheet already provides one.

## Cloudscape React mapping

| Cloudscape (internal) | Flutter |
| --- | --- |
| dropdown container | `CsMenuPanel` |
| `selectable-item` / menu item | `CsMenuRow` |
| option group label | `CsMenuGroupLabel` |
| group divider | `CsMenuSeparator` |
