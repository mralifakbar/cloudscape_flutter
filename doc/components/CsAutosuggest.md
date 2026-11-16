# CsAutosuggest

Cloudscape's `Autosuggest`: a text input that suggests options while the user types. Any text is a valid value; suggestions only help.

Cloudscape reference: https://cloudscape.design/components/autosuggest/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsAutosuggest(
  value: 'logs',
  placeholder: 'Enter a bucket name',
  options: const [CsOption(value: 'example-bucket'), CsOption(value: 'logs-bucket')],
  onChange: (value) {},
)
```

## When to use / when not to

Use it when users may type a new value but common values help (tags, names, search). When the value must be one of the options, use `CsSelect` with filtering.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | The text |
| `options` | `List<CsOptionItem>` | required | Suggestions and groups |
| `onChange` | `ValueChanged<String>?` | | Every edit, and the picked value |
| `onSelect` | `ValueChanged<CsAutosuggestSelectDetail>?` | | A pick: `value` and `selectedOption` (null for the typed text) |
| `enteredTextLabel` | `String Function(String)?` | `Use: "<value>"` | Label of the row that uses the typed text |
| `hideEnteredTextOption` | `bool` | `false` | |
| `filteringType` | `CsFilteringType` | `auto` | `auto` filters and highlights here; `manual` leaves it to `onLoadItems` |
| `placeholder`, `disabled`, `readOnly`, `invalid`, `warning` | | | |
| `empty` | `Widget?` | | Shown when there are no suggestions |
| `filteringResultsText` | `String Function(int, int)?` | | Footer text |
| `statusType`, `loadingText`, `finishedText`, `errorText`, `recoveryText`, `errorIconAriaLabel`, `onLoadItems` | | | As `CsSelect` |
| `ariaLabel`, `clearAriaLabel`, `selectedAriaLabel` | `String?` | | |
| `autoFocus`, `focusNode`, `onFocus`, `onBlur` | | | |
| `onSubmit` | `ValueChanged<String>?` | | Enter with no highlighted suggestion |
| `presentation` | `CsPresentation` | `popover` | The list stays anchored so the keyboard and text stay in view |
| `renderOption` | builder | | Custom rows |

## Examples

### Async suggestions

```dart
CsAutosuggest(
  value: '',
  options: const [],
  filteringType: CsFilteringType.manual,
  statusType: CsDropdownStatusType.loading,
  loadingText: 'Loading instances',
  onLoadItems: (detail) {},
  onChange: (value) {},
)
```

### Picking reports the option

```dart
CsAutosuggest(
  value: '',
  options: const [CsOption(value: 'i-0abc123', label: 'web-server-1', description: 't3.micro')],
  enteredTextLabel: (v) => 'Use: "$v"',
  onSelect: (detail) {},
  onChange: (value) {},
)
```

## Accessibility

The input is a text field; the list does not take focus. Up and Down open and move the highlight, Enter picks, Escape closes the list and a second Escape clears the text. A clear button with `clearAriaLabel` appears when there is text. The status footer is a live region.

## Motion

The list scales and fades in from the input and closes along the same path; reduced motion keeps only the fade.

## Mobile

The list stays anchored under the field on phones (it flips above when the keyboard leaves no room). Pass `CsPresentation.auto` for a bottom sheet instead.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value`, `options`, `enteredTextLabel`, `hideEnteredTextOption`, `filteringType`, `placeholder`, `disabled`, `readOnly`, `invalid`, `warning`, `empty`, `filteringResultsText` | same names |
| `onChange` (`detail.value`) | `onChange` |
| `onSelect` (`detail.value`, `detail.selectedOption`) | `onSelect` (`CsAutosuggestSelectDetail`) |
| `statusType`, `loadingText`, `finishedText`, `errorText`, `recoveryText`, `onLoadItems` | same names |
| `ariaLabel`, `clearAriaLabel`, `selectedAriaLabel`, `autoFocus`, `onFocus`, `onBlur`, `renderOption` | same names |
| `onKeyDown` (Enter) | `onSubmit` |
| `expandToViewport`, `virtualScroll`, `name`, `controlId`, `autoComplete`, `inputMode` | not applicable |
