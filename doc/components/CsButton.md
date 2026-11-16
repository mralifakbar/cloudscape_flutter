# CsButton

Cloudscape's `Button`: the control for actions, in normal, primary, link and icon variants, with icons, a loading state and a disabled reason.

Cloudscape reference: https://cloudscape.design/components/button/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsButton(text: 'Launch instance', variant: CsButtonVariant.primary, onPress: () {})
```

## When to use / when not to

Use a button for an action on the current page. One `primary` button per view for the main action, `normal` (the default) for the others, `link` for Cancel next to a primary button and for actions in headers and tables, `icon` for compact toolbar actions, `inlineIcon` and `inlineLink` inside text and rows. For navigation inside text use `CsLink`; for a menu of actions use `CsButtonDropdown`; for an on/off state use `CsToggleButton`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `text` | `String?` | | Button text, sentence case, a verb |
| `child` | `Widget?` | | Custom content in place of `text` |
| `onPress` | `VoidCallback?` | | Null renders the button disabled |
| `onLongPress` | `VoidCallback?` | | |
| `variant` | `CsButtonVariant` | `normal` | `normal`, `primary`, `link`, `icon`, `inlineIcon`, `inlineLink`, `modalDismiss`, `flashbarIcon` |
| `icon` | `CsIconData?` | | A `CsIcons` icon (Cloudscape `iconName`) |
| `iconWidget` | `Widget?` | | Any widget in the icon slot (Cloudscape `iconSvg` / `iconUrl`) |
| `iconAlign` | `CsButtonIconAlign` | `left` | `left` or `right` of the text |
| `loading` | `bool` | `false` | Spinner in place of the icon; presses ignored |
| `loadingText` | `String?` | | Announced while loading |
| `disabled` | `bool` | `false` | |
| `disabledReason` | `String?` | | Keeps a disabled button focusable and explains it in a tooltip |
| `fullWidth` | `bool` | `false` | Stretch to the parent's width |
| `wrapText` | `bool` | `true` | False keeps one line with an ellipsis |
| `external` | `bool` | `false` | External-link icon after the text, announced as opening a new tab |
| `isLink` | `bool` | `false` | Announce as a link (a button with `href`) |
| `expanded` | `bool?` | | Disclosure state for buttons that open a menu or panel (`ariaExpanded`) |
| `semanticLabel` | `String?` | | Accessible name; required for icon-only variants (`ariaLabel`) |
| `haptic` | `CsHaptic` | `none` | Haptic on press |
| `focusNode`, `autofocus` | | | |

## Examples

### Variants

```dart
Wrap(spacing: 8, runSpacing: 8, children: [
  CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () {}),
  CsButton(text: 'Edit', onPress: () {}),
  CsButton(text: 'Create distribution', variant: CsButtonVariant.primary, onPress: () {}),
])
```

### Icons

```dart
Wrap(spacing: 8, children: [
  CsButton(text: 'Add item', icon: CsIcons.addPlus, onPress: () {}),
  CsButton(text: 'Actions', icon: CsIcons.caretDownFilled, iconAlign: CsButtonIconAlign.right, onPress: () {}),
  CsButton(icon: CsIcons.refresh, semanticLabel: 'Refresh', onPress: () {}),
  CsButton(icon: CsIcons.settings, variant: CsButtonVariant.icon, semanticLabel: 'Preferences', onPress: () {}),
])
```

### Loading and disabled with a reason

```dart
Wrap(spacing: 8, children: [
  CsButton(text: 'Launching', variant: CsButtonVariant.primary, loading: true, loadingText: 'Launching instance', onPress: () {}),
  CsButton(text: 'Stop', disabled: true, disabledReason: 'The instance is already stopped.', onPress: () {}),
])
```

### Inline link

```dart
CsButton(text: 'Reset filters', variant: CsButtonVariant.inlineLink, onPress: () {})
```

## Accessibility

Announced as a button (or link with `isLink`) with its text and enabled state. Icon-only variants assert a `semanticLabel`. While loading, `loadingText` is the accessible name. A disabled button with `disabledReason` stays in the Tab order and announces the reason as its hint. Tab focuses, Enter and Space activate, keyboard focus shows the 2px focus ring 4px outside the button. On touch the hit area grows to 44x44.

## Motion

- Pointer-down scales the button to 0.98 with a spring; release springs back from wherever it is. Hover and active colors change instantly.
- The icon slot cross-fades between icon and spinner when `loading` changes.
- Reduced or disabled motion removes the scale and the cross-fade.

## Mobile

Visual heights stay Cloudscape's (32px, 28px compact); the touch hit area is padded to 44px. `fullWidth: true` is the usual choice for the main action at the bottom of a phone screen.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `text` / `child` |
| `onClick` | `onPress` |
| `variant="inline-icon"` | `variant: CsButtonVariant.inlineIcon` |
| `iconName="add-plus"` | `icon: CsIcons.addPlus` |
| `iconSvg`, `iconUrl` | `iconWidget` |
| `iconAlign`, `loading`, `loadingText`, `disabled`, `disabledReason`, `fullWidth`, `wrapText`, `external` | same names |
| `ariaLabel` | `semanticLabel` |
| `ariaExpanded` | `expanded` |
| `href`, `onFollow` | `isLink: true` + `onPress` (Flutter has no URLs) |
| `formAction`, `form`, `target`, `rel`, `download`, `nativeButtonAttributes`, `ariaDescribedby`, `ariaControls` | not applicable |
