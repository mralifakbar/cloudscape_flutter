# CsTimeInput

A masked text field for typing a time of day as `hh:mm:ss`, `hh:mm` or `hh`.

Cloudscape reference: https://cloudscape.design/components/time-input/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFormField(
  label: 'Backup window starts',
  constraintText: 'Use 24-hour format.',
  child: CsTimeInput(
    value: start, // '02:30:00'
    placeholder: 'hh:mm:ss',
    onChange: (v) => setState(() => start = v),
  ),
)
```

## When to use / when not to

- Use it for a time without a date, such as a maintenance window.
- With a date, put it next to a `CsDatePicker`, or use `CsDateRangePicker`, which already has time inputs.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | Time as typed, partial while typing, or `''`. |
| `onChange` | `ValueChanged<String>?` | `null` | Text on every edit. |
| `onBlur` / `onFocus` | `VoidCallback?` | `null` | Blur first completes a partial time. |
| `onSubmit` | `ValueChanged<String>?` | `null` | Enter pressed; receives the completed time. |
| `format` | `CsTimeInputFormat` | `hhMmSs` | `hh`, `hhMm` or `hhMmSs`. `format.pattern` gives the placeholder text. |
| `use24Hour` | `bool` | `true` | False limits hours to 01-12 (no AM/PM part, as in Cloudscape). |
| `placeholder` | `String?` | `null` | Such as `hh:mm:ss`. |
| `disabled`, `readOnly`, `invalid`, `warning`, `autoFocus` | `bool` | `false` | Field states. |
| `autoComplete` | `bool` | `true` | Platform autofill and suggestions. |
| `ariaLabel` | `String?` | `null` | Accessible name without a visible label. |
| `focusNode` | `FocusNode?` | `null` | |

## Examples

### Masking rules

Typing `7` gives `07:`; `25` becomes `23:` (24-hour) and `13` becomes `12:` with `use24Hour: false`. On blur or Enter, `10:1` becomes `10:01:00`.

### Hours and minutes

```dart
CsTimeInput(
  value: cutoff,
  format: CsTimeInputFormat.hhMm,
  placeholder: CsTimeInputFormat.hhMm.pattern,
  onChange: (v) => setState(() => cutoff = v),
)
```

## Accessibility

A text field labeled by its `CsFormField` or `ariaLabel`. Say the format in the constraint text.

## Motion

None beyond the field's focus ring.

## Mobile

Fills its parent's width with a 32px minimum height that grows with text.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value`, `onChange` | `value`, `onChange` |
| `format` (`hh`, `hh:mm`, `hh:mm:ss`) | `format` (`CsTimeInputFormat.hh`, `.hhMm`, `.hhMmSs`) |
| `use24Hour` | `use24Hour` |
| `autoComplete` | `autoComplete` |
| `placeholder`, `disabled`, `readOnly`, `invalid`, `warning`, `autoFocus` | same names |
| `onBlur`, `onFocus` | `onBlur`, `onFocus` |
| `ariaLabel` | `ariaLabel` |
| `name`, `controlId`, `ariaDescribedby`, `ariaLabelledby`, `ariaRequired`, `disableBrowserAutocorrect`, `nativeInputAttributes` | not applicable |
| `ref.focus()` | `focusNode` |
