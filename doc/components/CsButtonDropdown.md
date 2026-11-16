# CsButtonDropdown

Cloudscape's `ButtonDropdown`: a button that opens a menu of actions, with groups, checkbox items, expandable groups, disabled reasons, external links and a split-button main action.

Cloudscape reference: https://cloudscape.design/components/button-dropdown/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsButtonDropdown(
  text: 'Actions',
  items: const [
    CsButtonDropdownItem(id: 'start', text: 'Start instance'),
    CsButtonDropdownItem(id: 'stop', text: 'Stop instance', disabled: true, disabledReason: 'Already stopped'),
  ],
  onItemClick: (details) {},
)
```

## When to use / when not to

Use it to group related secondary actions. For a single action use `CsButton`; for a choice that is a value, use `CsSelect`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<CsButtonDropdownItemOrGroup>` | required | `CsButtonDropdownItem`, `CsButtonDropdownCheckboxItem`, `CsButtonDropdownGroup` |
| `text` | `String?` | | Trigger text |
| `variant` | `CsButtonDropdownVariant` | `normal` | `normal`, `primary`, `icon`, `inlineIcon` |
| `icon`, `iconWidget` | | ellipsis for icon variants | |
| `disabled`, `disabledReason` | | | |
| `loading`, `loadingText` | | | Spinner, cannot open |
| `expandableGroups` | `bool` | `false` | Groups collapse behind their heading and expand in place |
| `ariaLabel` | `String?` | | Required for icon variants |
| `onItemClick` | `ValueChanged<CsButtonDropdownItemClickDetails>?` | | `id`, `checked` (next state of a checkbox item) |
| `onItemFollow` | same | | Links (`isLink`) and `external` items |
| `mainAction` | `CsButtonDropdownMainAction?` | | Split button: `text`, `onPress`, `disabled`, `disabledReason`, `loading`, `loadingText`, `icon`, `external`, `ariaLabel` |
| `fullWidth` | `bool` | `false` | |
| `filteringType` | `bool` | `false` | Filter input above the items |
| `filteringPlaceholder`, `filteringAriaLabel`, `noMatch` | | | |
| `presentation` | `CsPresentation` | `auto` | Bottom sheet at or below 688px |

Item fields: `id`, `text`, `secondaryText`, `description` (tooltip), `labelTag`, `icon`, `iconWidget`, `disabled`, `disabledReason`, `external`, `externalIconAriaLabel`, `isLink`, `ariaLabel`. Checkbox items add `checked`. Groups: `items`, `text`, `id`, `icon`, `disabled`, `disabledReason`, `expandable`.

## Examples

### Groups, checkboxes and external links

```dart
CsButtonDropdown(
  text: 'Instance actions',
  items: const [
    CsButtonDropdownGroup(text: 'State', items: [
      CsButtonDropdownItem(id: 'start', text: 'Start'),
      CsButtonDropdownItem(id: 'reboot', text: 'Reboot', labelTag: 'R'),
    ]),
    CsButtonDropdownCheckboxItem(id: 'monitoring', text: 'Detailed monitoring', checked: true),
    CsButtonDropdownItem(id: 'docs', text: 'Documentation', external: true),
  ],
  onItemClick: (details) {},
  onItemFollow: (details) {},
)
```

### Split button

```dart
CsButtonDropdown(
  variant: CsButtonDropdownVariant.primary,
  ariaLabel: 'More launch options',
  mainAction: CsButtonDropdownMainAction(text: 'Launch instance', onPress: () {}),
  items: const [CsButtonDropdownItem(id: 'template', text: 'Launch from template')],
)
```

### Icon variant with expandable groups

```dart
const CsButtonDropdown(
  variant: CsButtonDropdownVariant.icon,
  ariaLabel: 'More actions',
  expandableGroups: true,
  items: [
    CsButtonDropdownGroup(text: 'Networking', items: [CsButtonDropdownItem(id: 'ip', text: 'Associate IP address')]),
  ],
)
```

## Accessibility

The trigger announces its expanded state. The menu takes focus (first enabled item); Up and Down move, Home and End jump, Enter and Space activate, Escape closes and focus returns to the trigger. Checkbox items announce checked state; external items announce that they open in a new window; disabled items explain themselves in a tooltip.

## Motion

The menu scales and fades from the trigger; expandable group carets rotate. Reduced motion removes the scale and rotation.

## Mobile

At or below 688px the menu opens as a bottom sheet with 40px rows; expandable groups expand inside it.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items`, `variant`, `disabled`, `disabledReason`, `loading`, `loadingText`, `expandableGroups`, `ariaLabel`, `onItemClick`, `onItemFollow`, `mainAction`, `fullWidth`, `filteringPlaceholder`, `filteringAriaLabel`, `noMatch` | same names |
| `children` | `text` |
| `iconName` / `iconSvg` / `iconUrl` | `icon` / `iconWidget` |
| `filteringType: 'auto'` | `filteringType: true` |
| `item.href` | `isLink: true` + `onItemFollow` |
| `expandToViewport`, `renderItem`, `asyncLoadingProps`, `onLoadItems`, `nativeTriggerAttributes` | not applicable / not implemented |
| nested side flyouts on desktop | groups expand in place on every screen size |
