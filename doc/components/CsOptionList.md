# CsOptionList

Cloudscape's `OptionList` (`src/option-list`): an always visible list of options to pick one or several from, without a trigger or dropdown.

Cloudscape reference: https://cloudscape.design/components/option-list/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsOptionList(
  ariaLabel: 'Instance type',
  selectionType: CsOptionListSelectionType.single,
  options: const [
    CsOption(value: 't3.micro', label: 't3.micro', description: '2 vCPU, 1 GiB'),
    CsOption(value: 't3.large', label: 't3.large', description: '2 vCPU, 8 GiB'),
  ],
  selectedOptions: selected,
  onChange: (options) => setState(() => selected = options),
)
```

## When to use / when not to

Use an option list inside a panel, popover or custom dropdown where the options are always shown. For a compact field that opens a list, use `CsSelect` or `CsMultiselect`; for a few mutually exclusive choices with more explanation, use `CsTiles` or `CsRadioGroup`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `options` | `List<CsOptionItem>` | required | `CsOption`s and `CsOptionGroup`s (one level of groups) |
| `selectionType` | `CsOptionListSelectionType` | required | `single` (check on the selected row) or `multi` (checkboxes; a group header toggles its group) |
| `selectedOptions` | `List<CsOption>?` | `null` | Selected options, matched by `value`. In `single` only the first is used. `null` lets the list keep its own selection |
| `onChange` | `ValueChanged<List<CsOption>>?` |  | Called with the next selection |
| `ariaLabel` | `String?` |  | Accessible name of the list |
| `renderOption` | `Widget? Function(BuildContext, CsOptionListItem)?` |  | Custom row content; return null for the default |
| `renderHighlightedAriaLive` | `String Function(CsOptionItem, CsOptionGroup?)?` |  | Announcement for a newly highlighted option |
| `i18nStrings` | `CsOptionListI18nStrings` | `selectedAriaLabel: 'Selected'` | Announced with a highlighted option that is selected |
| `empty` | `Widget?` |  | Shown when there are no options |
| `focusNode` | `FocusNode?` |  | The list's focus node |
| `autofocus` | `bool` | `false` | Focus on first build |
| `maxHeight` | `double?` |  | Scrolls the list beyond this height |

`CsOptionListItem` (for `renderOption`): `isGroup`, `index`, `option`, `selected`, `highlighted`, `disabled`, `indeterminate`, `group`, `parent`.

## Examples

### Multi selection with groups

```dart
CsOptionList(
  ariaLabel: 'Regions',
  selectionType: CsOptionListSelectionType.multi,
  options: const [
    CsOptionGroup(
      label: 'North America',
      options: [CsOption(value: 'us-east-1', label: 'US East (N. Virginia)'), CsOption(value: 'us-west-2', label: 'US West (Oregon)')],
    ),
    CsOptionGroup(
      label: 'Europe',
      options: [CsOption(value: 'eu-west-1', label: 'Europe (Ireland)', disabled: true, disabledReason: 'Not enabled for this account')],
    ),
  ],
  selectedOptions: regions,
  onChange: (options) => setState(() => regions = options),
)
```

### Custom rows

```dart
CsOptionList(
  selectionType: CsOptionListSelectionType.single,
  options: const [CsOption(value: 'example-bucket'), CsOption(value: 'logs-bucket')],
  renderOption: (context, item) => item.isGroup ? null : Text('s3://${item.option.value}'),
)
```

## Accessibility

The list is one Tab stop and a labelled semantics container; rows expose selected (single) or checked and mixed (multi) states. Focus highlights the first selected option, or the first option. Up and Down move the highlight and wrap, Home/Page Up and End/Page Down jump, Enter and Space choose, typing letters jumps to the next option starting with them. Every highlight change is announced (label, label tag, description, tags and "Selected"). Disabled options are skipped and show their reason in a tooltip.

## Motion

Highlight and selection colors change instantly. The highlighted option scrolls into view.

## Mobile

Rows are at least 44px tall on touch platforms; long labels, descriptions and tags wrap at 390px and 2x text.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `options` | `options` (`CsOption`, `CsOptionGroup`) |
| `selectionType` | `selectionType` (`CsOptionListSelectionType`) |
| `selectedOptions` / `onChange` | `selectedOptions` / `onChange` |
| `ariaLabel` | `ariaLabel` |
| `renderOption` | `renderOption` (`CsOptionListItem`) |
| `renderHighlightedAriaLive` | `renderHighlightedAriaLive` |
| `i18nStrings.selectedAriaLabel` | `i18nStrings.selectedAriaLabel` |
| `option.icon` (`ReactNode`) | `CsOption.icon` / `CsOption.iconWidget` |
| `option.lang` | not supported |
| `ref.focus()` | `focusNode.requestFocus()` |
| `ariaLabelledby`, `ariaDescribedby` | not supported (web only) |
| (none) | `empty`, `maxHeight` |
