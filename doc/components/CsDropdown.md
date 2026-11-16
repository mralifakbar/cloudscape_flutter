# CsDropdown

The floating container behind selects, multiselects, autosuggests and button dropdowns: Cloudscape's dropdown, anchored under its trigger on wide screens and a bottom sheet on phones.

Cloudscape reference: https://cloudscape.design/components/select/ (the dropdown is internal in Cloudscape)

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsDropdown(
  open: true,
  onDismiss: () {},
  contentBuilder: (context, inSheet) => CsMenuPanel(children: [CsMenuRow(label: 'Edit', onPress: () {})]),
  child: CsButton(text: 'Open', onPress: () {}),
)
```

## When to use / when not to

Use it to build your own picker or menu that should behave like Cloudscape's. Prefer the finished components (`CsSelect`, `CsButtonDropdown`) when they fit. For a popover with arbitrary content and an arrow use `CsAnchoredOverlay` with `CsPopupSurface`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `open` | `bool` | required | Controlled visibility; false also closes the sheet |
| `child` | `Widget` | required | The trigger |
| `contentBuilder` | `Widget Function(BuildContext, bool inSheet)` | required | Rebuilt whenever the dropdown rebuilds, also inside the sheet |
| `onDismiss` | `VoidCallback?` | | Outside tap, Escape, or sheet swiped away |
| `presentation` | `CsPresentation` | `auto` | `auto` (sheet at or below 688px), `popover`, `sheet` |
| `matchTriggerWidth` | `bool` | `true` | At least as wide as the trigger |
| `align` | `CsAlign` | `start` | |
| `preferredHeight` | `double` | `300` | Room wanted below before flipping up |
| `trapFocus` | `bool` | `false` | Move focus into the content (menus) |
| `sheetLabel` | `String?` | | Accessible name of the sheet |
| `tapRegionGroupId` | `Object?` | | Share outside-tap handling with other regions |
| `dismissOnOutsideTap` | `bool` | `true` | False for content with nested dropdowns |

## Examples

### A custom picker that keeps its sheet open

```dart
CsDropdown(
  open: true,
  presentation: CsPresentation.auto,
  sheetLabel: 'Columns',
  onDismiss: () {},
  contentBuilder: (context, inSheet) => CsMenuPanel(children: [
    CsMenuRow(label: 'Name', checked: true, onPress: () {}),
    CsMenuRow(label: 'Status', checked: false, onPress: () {}),
  ]),
  child: CsButton(text: 'Columns', onPress: () {}),
)
```

## Accessibility

With `trapFocus` focus moves into the content and returns to the trigger on close; otherwise focus stays on the trigger and the content is driven from it. Escape closes either way.

## Motion

Anchored: scales from 0.9 and fades from the trigger with a spring, closes along the same path. Sheet: slides up and follows the finger. Reduced motion keeps only fades.

## Mobile

`CsPresentation.auto` switches to a bottom sheet at or below 688px. The sheet content rebuilds with the owner's state, so lists can toggle options while it stays open.

## Cloudscape React mapping

| Cloudscape (internal `Dropdown`) | Flutter parameter |
| --- | --- |
| `open`, `onDropdownClose`, `trigger`, `content` | `open`, `onDismiss`, `child`, `contentBuilder` |
| `stretchWidth` / `minWidth` | `matchTriggerWidth` |
| `expandToViewport` | not applicable (always in the root overlay) |
