# CsMultiselect

Cloudscape's `Multiselect`: pick any number of options from a dropdown list; the choice shows as dismissible tokens under the trigger.

Cloudscape reference: https://cloudscape.design/components/multiselect/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsMultiselect(
  selectedOptions: const [CsOption(value: 'us-east-1a')],
  placeholder: 'Choose availability zones',
  options: const [CsOption(value: 'us-east-1a'), CsOption(value: 'us-east-1b'), CsOption(value: 'us-east-1c')],
  onChange: (options) {},
)
```

## When to use / when not to

Use a multiselect to pick several items from a long list. For a handful of options that should stay visible, use checkboxes or tiles. For one choice use `CsSelect`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `options` | `List<CsOptionItem>` | required | Options and option groups |
| `selectedOptions` | `List<CsOption>` | required | The chosen options (matched by `value`) |
| `onChange` | `ValueChanged<List<CsOption>>?` | | Called with the next list |
| `placeholder` | `String?` | | Always shown in the trigger |
| `keepOpen` | `bool` | `true` | Keep the list open after each toggle |
| `tokenLimit` | `int?` | | Tokens shown before "Show more" |
| `hideTokens` | `bool` | `false` | Hide the tokens |
| `inlineTokens` | `bool` | `false` | Draw inline tokens inside the trigger |
| `enableSelectAll` | `bool` | `false` | "Select all" option acting on the shown options |
| `deselectAriaLabel` | `String Function(CsOption)?` | | Token dismiss label |
| `i18nStrings` | `CsMultiselectI18nStrings` | English | `selectAllText`, `tokenLimitShowMore`, `tokenLimitShowFewer` |
| `tokenLimitShowMoreAriaLabel`, `tokenLimitShowFewerAriaLabel` | `String?` | | |
| `disabled`, `readOnly`, `invalid`, `warning` | `bool` | `false` | |
| filtering, status, `onLoadItems`, `inlineLabelText`, `ariaLabel`, `ariaRequired`, `autoFocus`, `focusNode`, `onFocus`, `onBlur`, `presentation`, `dropdownHeader`, `dropdownFooter`, `renderOption` | | | As `CsSelect` |

## Examples

### Groups and select all

```dart
CsMultiselect(
  selectedOptions: const [],
  placeholder: 'Choose buckets',
  enableSelectAll: true,
  options: const [
    CsOptionGroup(label: 'us-east-1', options: [CsOption(value: 'example-bucket'), CsOption(value: 'logs-bucket')]),
    CsOptionGroup(label: 'eu-west-1', options: [CsOption(value: 'archive-bucket', disabled: true)]),
  ],
  onChange: (options) {},
)
```

### Token limit and filtering

```dart
CsMultiselect(
  selectedOptions: const [CsOption(value: 'web'), CsOption(value: 'api'), CsOption(value: 'db')],
  tokenLimit: 2,
  filteringType: CsFilteringType.auto,
  options: const [CsOption(value: 'web'), CsOption(value: 'api'), CsOption(value: 'db'), CsOption(value: 'cache')],
  onChange: (options) {},
)
```

### Inline tokens

```dart
CsMultiselect(
  selectedOptions: const [CsOption(value: 'Running'), CsOption(value: 'Pending')],
  inlineTokens: true,
  inlineLabelText: 'State',
  options: const [CsOption(value: 'Running'), CsOption(value: 'Pending'), CsOption(value: 'Stopped')],
  onChange: (options) {},
)
```

## Accessibility

As `CsSelect`, with checkbox rows that announce their checked state (group rows announce mixed when partly selected). Space or Enter toggles the highlighted option and the list stays open. Token dismiss buttons are labelled "Remove <option>" by default.

## Motion

As `CsSelect`; checkboxes draw their check mark (reduced motion: instant).

## Mobile

At or below 688px the list opens in a bottom sheet that stays open while options are toggled; swipe it down or tap outside to finish. Tokens wrap under the trigger.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `selectedOptions`, `keepOpen`, `tokenLimit`, `hideTokens`, `inlineTokens`, `enableSelectAll`, `deselectAriaLabel` | same names |
| `onChange` (`detail.selectedOptions`) | `onChange` (the list) |
| `i18nStrings.selectAllText`, `tokenLimitShowMore`, `tokenLimitShowFewer` | `i18nStrings` |
| other props | as `CsSelect` |
| `expandToViewport`, `virtualScroll`, `name`, `controlId` | not applicable |
