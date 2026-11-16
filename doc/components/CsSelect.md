# CsSelect

Cloudscape's `Select`: pick one option from a dropdown list, with optional filtering, option groups, rich options and asynchronous loading states.

Cloudscape reference: https://cloudscape.design/components/select/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsSelect(
  selectedOption: const CsOption(value: 't3.micro'),
  placeholder: 'Choose an instance type',
  options: const [
    CsOption(value: 't3.micro', description: '2 vCPU, 1 GiB'),
    CsOption(value: 't3.small', description: '2 vCPU, 2 GiB'),
  ],
  onChange: (option) {},
)
```

## When to use / when not to

Use a select for one choice from a list of more than about five options. For two to five options that should all stay visible, use radio buttons or a segmented control. For many choices use `CsMultiselect`; when any typed value is valid and options only help, use `CsAutosuggest`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `options` | `List<CsOptionItem>` | required | `CsOption`s and `CsOptionGroup`s, in display order |
| `selectedOption` | `CsOption?` | required | The chosen option (matched by `value`), or null for the placeholder |
| `onChange` | `ValueChanged<CsOption>?` | | Called with the picked option |
| `placeholder` | `String?` | | Shown while nothing is chosen |
| `disabled` | `bool` | `false` | |
| `readOnly` | `bool` | `false` | Focusable, cannot open |
| `invalid` / `warning` | `bool` | `false` | Status border with a thick start edge |
| `filteringType` | `CsFilteringType` | `none` | `none`, `auto` (filters label, value, description, label tag, tags, filtering tags) or `manual` (filter in `onLoadItems`) |
| `filteringPlaceholder`, `filteringAriaLabel`, `filteringClearAriaLabel` | `String?` | | Filter input copy |
| `filteringResultsText` | `String Function(int matches, int total)?` | | Footer while filtering |
| `noMatch` | `Widget?` | | Shown when the filter matches nothing |
| `empty` | `Widget?` | | Shown when there are no options |
| `statusType` | `CsDropdownStatusType` | `finished` | `pending`, `loading`, `finished`, `error` |
| `loadingText`, `finishedText`, `errorText`, `recoveryText`, `errorIconAriaLabel` | `String?` | | Status footer copy; `recoveryText` is a retry link |
| `onLoadItems` | `ValueChanged<CsLoadItemsDetail>?` | | Open, filter change, scroll to end (while `pending`) and retry |
| `triggerVariant` | `CsSelectTriggerVariant` | `label` | `label` (icon and label) or `option` (the whole option) |
| `inlineLabelText` | `String?` | | Label drawn on the trigger's top border |
| `ariaLabel` | `String?` | | Accessible name without a visible label |
| `ariaRequired` | `bool` | `false` | |
| `selectedAriaLabel` | `String?` | | Announced with the selected option |
| `autoFocus`, `focusNode`, `onFocus`, `onBlur` | | | |
| `presentation` | `CsPresentation` | `auto` | Anchored list, or a bottom sheet at or below 688px |
| `dropdownHeader`, `dropdownFooter` | `Widget?` | | Content above and below the options |
| `renderOption` | `Widget Function(BuildContext, CsOption, bool highlighted, bool selected)?` | | Custom row content |

`CsOption` fields: `value` (required), `label`, `description`, `labelTag`, `tags`, `filteringTags`, `icon`, `iconWidget`, `iconAriaLabel`, `disabled`, `disabledReason`, `labelContent`. `CsOptionGroup`: `label`, `options`, `description`, `icon`, `disabled`, `disabledReason`, `labelTag`, `tags`.

## Examples

### Groups, label tags and disabled options

```dart
CsSelect(
  selectedOption: null,
  placeholder: 'Choose an instance type',
  options: const [
    CsOptionGroup(label: 'General purpose', options: [
      CsOption(value: 't3.micro', labelTag: 'Free tier', tags: ['2 vCPU', '1 GiB']),
      CsOption(value: 't3.xlarge', disabled: true, disabledReason: 'Service quota reached'),
    ]),
    CsOptionGroup(label: 'Compute optimized', options: [CsOption(value: 'c6i.large')]),
  ],
  onChange: (option) {},
)
```

### Filtering

```dart
CsSelect(
  selectedOption: null,
  options: const [CsOption(value: 'us-east-1', label: 'US East (N. Virginia)'), CsOption(value: 'eu-west-1', label: 'Europe (Ireland)')],
  filteringType: CsFilteringType.auto,
  filteringPlaceholder: 'Find region',
  noMatch: const Text('No regions match'),
  filteringResultsText: (matches, total) => '$matches of $total regions',
  onChange: (option) {},
)
```

### Loading from a server

```dart
CsSelect(
  selectedOption: null,
  options: const [],
  statusType: CsDropdownStatusType.error,
  loadingText: 'Loading buckets',
  errorText: 'Could not load buckets',
  recoveryText: 'Retry',
  onLoadItems: (detail) {},
  onChange: (option) {},
)
```

### Option trigger and inline label

```dart
CsSelect(
  selectedOption: const CsOption(value: 'vpc-0abc', label: 'main-vpc', description: '10.0.0.0/16'),
  options: const [CsOption(value: 'vpc-0abc', label: 'main-vpc', description: '10.0.0.0/16')],
  triggerVariant: CsSelectTriggerVariant.option,
  inlineLabelText: 'VPC',
  onChange: (option) {},
)
```

## Accessibility

The trigger is a button announcing its label, the selected option as its value, and its expanded state. Focus stays on the trigger (or the filter input) while the list is open; Up and Down move the highlight (wrapping and skipping disabled options and group headers), Home and End jump, Enter or Space picks, typing letters jumps to a matching option, Escape closes and Tab closes and moves on. Options announce their selected state; disabled options announce their reason. The status footer is a live region.

## Motion

The caret turns over (135ms) while the list is open. The list scales and fades in from the trigger and closes along the same path; on phones the sheet follows the finger. Reduced motion removes the rotation and scale.

## Mobile

At or below 688px (`CsPresentation.auto`) the list opens in a bottom sheet with 44px rows and closes after a pick. Pass `CsPresentation.popover` to keep the anchored list everywhere.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `options`, `selectedOption`, `placeholder`, `disabled`, `readOnly`, `invalid`, `warning` | same names |
| `onChange` (`detail.selectedOption`) | `onChange` (the option) |
| `filteringType`, `filteringPlaceholder`, `filteringAriaLabel`, `filteringClearAriaLabel`, `filteringResultsText`, `noMatch`, `empty` | same names |
| `statusType`, `loadingText`, `finishedText`, `errorText`, `recoveryText`, `errorIconAriaLabel`, `onLoadItems` | same names |
| `triggerVariant`, `inlineLabelText`, `ariaLabel`, `ariaRequired`, `selectedAriaLabel`, `autoFocus`, `onFocus`, `onBlur`, `renderOption` | same names |
| `renderDropdownHeader`, `renderDropdownFooter` | `dropdownHeader`, `dropdownFooter` |
| `option.iconName` / `iconUrl` / `iconSvg` | `icon` / `iconWidget` |
| `expandToViewport`, `virtualScroll`, `name`, `controlId`, `ariaLabelledby`, `dropdownRole`, `renderHighlightedAriaLive` | not applicable (the overlay always escapes clipping; lists build all rows) |
