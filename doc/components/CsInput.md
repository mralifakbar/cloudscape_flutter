# CsInput

A single-line text field for names, IDs, numbers, passwords and search queries.

Cloudscape reference: https://cloudscape.design/components/input/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFormField(
  label: 'Bucket name',
  child: CsInput(
    value: name,
    placeholder: 'example-bucket',
    onChange: (v) => setState(() => name = v),
  ),
)
```

## When to use / when not to

- Use for short free-form values: a resource name, a tag value, a number with a unit.
- Use `CsTextarea` for text that spans lines, a select for a fixed list of values, and `CsSlider` when the relative position in a range matters more than the exact number.
- Always give it a label: a `CsFormField`, `inlineLabelText` or `ariaLabel`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | The controlled text. |
| `onChange` | `ValueChanged<String>?` | `null` | Called with the new text on every edit. |
| `onSubmit` | `ValueChanged<String>?` | `null` | Enter or the keyboard action key. |
| `onFocus` / `onBlur` | `VoidCallback?` | `null` | Focus enters or leaves the field. |
| `onKeyEvent` | `FocusOnKeyEventCallback?` | `null` | Key events before the text field handles them (Cloudscape `onKeyDown`). Return `KeyEventResult.handled` to stop a key. |
| `type` | `CsInputType` | `text` | `text`, `password` (obscured), `search` (search icon and clear button), `number`, `email`, `url` (keyboard type). |
| `placeholder` | `String?` | `null` | Italic hint while empty. |
| `disabled` | `bool` | `false` | Not focusable or editable, disabled colors. |
| `readOnly` | `bool` | `false` | Focusable and selectable, not editable. |
| `invalid` | `bool` | `false` | Error border with an 8px start edge. Pair with `CsFormField.errorText`. |
| `warning` | `bool` | `false` | Warning border. Ignored when `invalid`. |
| `prefix` / `suffix` | `Widget?` | `null` | Fixed content before or after the value (`https://`, `GiB`), separated by a divider and colored by the status. Ignored for search inputs. |
| `inlineLabelText` | `String?` | `null` | A small label on the field's top border, for layouts without a form field. |
| `leading` / `trailing` | `Widget?` | `null` | Custom content inside the field before or after the text. |
| `mono` | `bool` | `false` | Monospace text for IDs and ARNs. |
| `autoFocus` | `bool` | `false` | Focus on mount. |
| `autoComplete` | `bool` | `true` | Platform suggestions and autofill. |
| `spellcheck` | `bool` | `true` | Spell checking and autocorrect. |
| `keyboardType` | `TextInputType?` | from `type` | Cloudscape `inputMode`. |
| `textInputAction` | `TextInputAction?` | `search` for search | Keyboard action key. |
| `inputFormatters` | `List<TextInputFormatter>?` | `null` | For example `FilteringTextInputFormatter.digitsOnly`. |
| `autofillHints` | `Iterable<String>?` | `null` | Used when `autoComplete` is true. |
| `ariaLabel` | `String?` | `null` | Accessible name without a visible label. |
| `ariaRequired` | `bool` | `false` | Adds a "Required" hint. |
| `clearAriaLabel` | `String?` | "Clear" | Name of the search clear button. |
| `focusNode` | `FocusNode?` | `null` | |

## Examples

### Search

```dart
CsInput(
  type: CsInputType.search,
  value: query,
  placeholder: 'Find instances',
  ariaLabel: 'Find instances',
  onChange: (v) => setState(() => query = v),
)
```

### Number with a unit suffix

```dart
CsInput(
  type: CsInputType.number,
  value: size,
  suffix: const Text('GiB'),
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  onChange: (v) => setState(() => size = v),
)
```

### Prefix and inline label

```dart
CsInput(
  value: subdomain,
  inlineLabelText: 'Subdomain',
  prefix: const Text('https://'),
  suffix: const Text('.example.com'),
  onChange: (v) => setState(() => subdomain = v),
)
```

### Validation

```dart
CsFormField(
  label: 'Bucket name',
  errorText: error,
  child: CsInput(
    value: name,
    invalid: error != null,
    onChange: (v) => setState(() => name = v),
  ),
)
```

## Accessibility

- Exposed as a text field with its label (from `CsFormField`, `ariaLabel` or `inlineLabelText`), enabled and read-only state, and a "Required" hint with `ariaRequired`.
- Prefix and suffix are decorative to screen readers; put their meaning in the label.
- The search clear button is a labelled button reachable with Tab.

## Motion

Focus switches the border to `color-border-input-focused` and draws a 1px ring (2px when invalid or warning) instantly, as Cloudscape does. Nothing animates.

## Mobile

32px tall (28px compact), with a minimum height so 2x text grows the field instead of clipping. Prefix and suffix are capped at 160px and ellipsize, leaving room to type at 390px. `type` picks the matching on-screen keyboard.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value` / `onChange` | `value` / `onChange` |
| `type` | `type` (`CsInputType`) |
| `placeholder` | `placeholder` |
| `disabled` / `readOnly` | `disabled` / `readOnly` |
| `invalid` / `warning` | `invalid` / `warning` |
| `autoFocus` | `autoFocus` |
| `autoComplete` | `autoComplete` (+ `autofillHints`) |
| `spellcheck`, `disableBrowserAutocorrect` | `spellcheck` |
| `inputMode` | `keyboardType` |
| `step` | not supported; use `inputFormatters` |
| `prefix` / `suffix` | `prefix` / `suffix` |
| `inlineLabelText` | `inlineLabelText` |
| `onKeyDown` / `onKeyUp` | `onKeyEvent` |
| `onFocus` / `onBlur` | `onFocus` / `onBlur` |
| `onDelayedInput` (autosuggest) | not supported; debounce in `onChange` |
| `ariaLabel`, `ariaRequired` | `ariaLabel`, `ariaRequired` |
| `clearAriaLabel` | `clearAriaLabel` |
| `name`, `controlId`, `ariaDescribedby`, `ariaLabelledby`, `nativeInputAttributes`, `style` | web only |
