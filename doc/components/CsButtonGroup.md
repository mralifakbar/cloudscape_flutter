# CsButtonGroup

Cloudscape's `ButtonGroup`: a compact row of icon actions (icon buttons, icon toggles, copy and an overflow menu), with tooltips and click feedback.

Cloudscape reference: https://cloudscape.design/components/button-group/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsButtonGroup(
  ariaLabel: 'Message actions',
  items: const [
    CsButtonGroupIconButton(id: 'refresh', text: 'Refresh', icon: CsIcons.refresh),
    CsButtonGroupMenuDropdown(id: 'more', text: 'More actions', items: [CsButtonDropdownItem(id: 'share', text: 'Share')]),
  ],
  onItemClick: (details) {},
)
```

## When to use / when not to

Use it for small sets of related icon actions, such as under a chat message or in a card header. For text actions use `CsButton`s in a `CsSpaceBetween`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<CsButtonGroupItemOrGroup>` | required | Items and `CsButtonGroupGroup(text, items)` |
| `ariaLabel` | `String?` | | Accessible name of the group |
| `onItemClick` | `ValueChanged<CsButtonGroupItemClickDetails>?` | | `id`, `pressed` (toggles), `checked` (menu checkbox items) |
| `onCopySuccess`, `onCopyFailure` | `ValueChanged<String>?` | | Item id after a copy |

Items: `CsButtonGroupIconButton` (`id`, `text`, `icon`, `iconWidget`, `disabled`, `disabledReason`, `loading`, `loadingText`, `popoverFeedback`), `CsButtonGroupIconToggleButton` (`pressed`, `icon`, `pressedIcon`, `popoverFeedback`, `pressedPopoverFeedback`, ...), `CsButtonGroupMenuDropdown` (`items` as `CsButtonDropdown`), `CsButtonGroupCopyToClipboard` (`textToCopy`, `copySuccessText`, `copyErrorText`).

## Examples

### Feedback group

```dart
CsButtonGroup(
  items: [
    CsButtonGroupGroup(text: 'Vote', items: [
      CsButtonGroupIconToggleButton(id: 'up', text: 'Helpful', icon: CsIcons.thumbsUp, pressedIcon: CsIcons.thumbsUpFilled, pressed: false, pressedPopoverFeedback: 'Thanks for the feedback'),
      CsButtonGroupIconToggleButton(id: 'down', text: 'Not helpful', icon: CsIcons.thumbsDown, pressedIcon: CsIcons.thumbsDownFilled, pressed: false),
    ]),
    const CsButtonGroupCopyToClipboard(id: 'copy', text: 'Copy', textToCopy: 'Sample response', copySuccessText: 'Copied', copyErrorText: 'Failed to copy'),
  ],
  onItemClick: (details) {},
)
```

## Accessibility

Each button is labelled by its `text`, which also shows in a tooltip; toggles announce their pressed state. Feedback text is a live region. Groups are labelled containers separated by a divider.

## Motion

Feedback appears above the button for two seconds, then fades.

## Mobile

Items wrap at 390px; icon buttons have 44px touch targets.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items`, `ariaLabel`, `onItemClick` | same names |
| `type: 'icon-button' / 'icon-toggle-button' / 'menu-dropdown' / 'icon-copy-to-clipboard' / 'group'` | `CsButtonGroupIconButton` / `IconToggleButton` / `MenuDropdown` / `CopyToClipboard` / `Group` |
| `onCopySuccess`, `onCopyFailure` | same names (item id) |
| `variant` | always icon |
| `icon-file-input`, `onFilesChange`, `dropdownExpandToViewport`, `href` | not applicable |
