# CsDateInput

A masked text field for typing a date as `YYYY/MM/DD`; reach for it when users know the date and a calendar would slow them down.

Cloudscape reference: https://cloudscape.design/components/date-input/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFormField(
  label: 'Snapshot date',
  constraintText: 'Use YYYY/MM/DD format.',
  child: CsDateInput(
    value: snapshotDate, // ISO: '2026-03-15'
    placeholder: 'YYYY/MM/DD',
    onChange: (v) => setState(() => snapshotDate = v),
  ),
)
```

## When to use / when not to

- Use it for dates people type from memory or copy from elsewhere (birth dates, known deadlines).
- Use `CsDatePicker` when a calendar helps (relative to today, weekdays only).
- Validate the value yourself; the input only enforces the shape.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | ISO date `YYYY-MM-DD` (`YYYY-MM` for months), partial while typing, or `''`. |
| `onChange` | `ValueChanged<String>?` | `null` | ISO text on every edit, including partial dates such as `2026-0`. |
| `onBlur` / `onFocus` | `VoidCallback?` | `null` | Focus changes. Blur first completes a partial date. |
| `onSubmit` | `ValueChanged<String>?` | `null` | Enter pressed; receives the completed ISO value. |
| `granularity` | `CsDateGranularity` | `day` | `month` masks `YYYY/MM`. |
| `format` | `CsDateFormat` | `slashed` | `iso` (`2026-03-15`), `slashed` (`2026/03/15`) or `longLocalized` (`March 15, 2026` until focused). |
| `inputFormat` | `CsDateInputFormat` | `slashed` | Typing format while a `longLocalized` field is focused. |
| `placeholder` | `String?` | `null` | Such as `YYYY/MM/DD`. |
| `disabled` | `bool` | `false` | Not focusable, disabled fill. |
| `readOnly` | `bool` | `false` | Focusable, not editable. |
| `invalid` / `warning` | `bool` | `false` | Red or yellow border with an 8px start edge. |
| `autoFocus` | `bool` | `false` | |
| `ariaLabel` | `String?` | `null` | Accessible name without a visible label. |
| `focusNode` | `FocusNode?` | `null` | For moving focus programmatically. |
| `trailing` | `Widget?` | `null` | Content at the end of the field. |

## Examples

### Masking rules

Typing `2026` shows `2026/`; a 13th month becomes `12`; a first day digit above 3 is padded (`4` becomes `04`). Backspace right after a separator removes the digit before it. Pasting `20260115` gives `2026/01/15`. On blur or Enter, `2026/1` becomes `2026/01/01`.

### ISO display with an error

```dart
CsFormField(
  label: 'Retention ends',
  errorText: error,
  child: CsDateInput(
    value: retentionEnd,
    format: CsDateFormat.iso,
    invalid: error != null,
    onChange: (v) => setState(() => retentionEnd = v),
  ),
)
```

### Month only, long display

```dart
CsDateInput(
  value: billingMonth, // '2026-03' shows "March 2026" until focused
  granularity: CsDateGranularity.month,
  format: CsDateFormat.longLocalized,
  onChange: (v) => setState(() => billingMonth = v),
)
```

## Accessibility

It is a text field labeled by its `CsFormField` or `ariaLabel`. Pair errors with `CsFormField.errorText`, which is announced. The keyboard is the platform's date/time keyboard.

## Motion

None beyond the field's focus ring.

## Mobile

The field fills its parent's width, keeps a minimum 32px height (28px compact) and grows with text scale.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value` | `value` |
| `onChange` (`detail.value`) | `onChange` |
| `onBlur`, `onFocus` | `onBlur`, `onFocus` |
| `granularity` | `granularity` |
| `format` (`iso`, `slashed`, `long-localized`) | `format` (`CsDateFormat`) |
| `inputFormat` | `inputFormat` (`CsDateInputFormat`) |
| `placeholder`, `disabled`, `readOnly`, `invalid`, `warning`, `autoFocus` | same names (`autoFocus`) |
| `ariaLabel` | `ariaLabel` |
| `locale` | not supported: long dates use `CsStrings` month names |
| `name`, `controlId`, `ariaDescribedby`, `ariaLabelledby`, `ariaRequired`, `nativeInputAttributes` | not applicable |
| `ref.focus()` | `focusNode` |
