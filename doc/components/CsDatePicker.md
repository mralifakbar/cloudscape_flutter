# CsDatePicker

A date field with a calendar button that opens a `CsCalendar` in a dropdown, or a bottom sheet on phones; the default way to ask for one date.

Cloudscape reference: https://cloudscape.design/components/date-picker/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFormField(
  label: 'Certificate expiry',
  constraintText: 'Use YYYY/MM/DD format.',
  child: CsDatePicker(
    value: expiry, // ISO '2026-03-15' or ''
    placeholder: 'YYYY/MM/DD',
    onChange: (v) => setState(() => expiry = v),
  ),
)
```

## When to use / when not to

- Use it for a single date that people may type or pick.
- Use `CsDateRangePicker` for ranges, `CsCalendar` for an always-visible calendar, `CsDateInput` when a calendar adds nothing.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | ISO date (`YYYY-MM` for months), partial while typing, or `''`. |
| `onChange` | `ValueChanged<String>?` | `null` | Typed text as it changes, and the picked date. |
| `isDateEnabled` | `bool Function(DateTime)?` | all | Days that can be picked in the calendar. Typed dates are not checked. |
| `dateDisabledReason` | `String? Function(DateTime)?` | `null` | Tooltip for disabled days; keeps them focusable. |
| `startOfWeek` | `int?` | Sunday | 0 Sunday to 6 Saturday. |
| `granularity` | `CsDateGranularity` | `day` | `month` picks `YYYY-MM`. |
| `format` / `inputFormat` | `CsDateFormat` / `CsDateInputFormat` | `slashed` | As in `CsDateInput`. |
| `placeholder` | `String?` | `null` | |
| `disabled` | `bool` | `false` | Disables the field and the button. |
| `readOnly` | `bool` | `false` | Field focusable but not editable; button disabled. |
| `invalid` / `warning` | `bool` | `false` | Field border states. |
| `autoFocus` | `bool` | `false` | |
| `ariaLabel` | `String?` | `null` | Name of the field and the calendar. |
| `onFocus` / `onBlur` | `VoidCallback?` | `null` | |
| `i18nStrings` | `CsDatePickerI18nStrings?` | English | The calendar's strings plus `openCalendarAriaLabel(String? selectedDate)`. |
| `presentation` | `CsPresentation` | `auto` | Dropdown on wide screens, bottom sheet at or below 688px. |
| `focusNode` | `FocusNode?` | `null` | Focus node of the text field. |

## Examples

### Future weekdays only

```dart
CsDatePicker(
  value: launchDate,
  placeholder: 'YYYY/MM/DD',
  isDateEnabled: (d) => d.weekday <= DateTime.friday,
  dateDisabledReason: (d) => 'Launches run on weekdays.',
  onChange: (v) => setState(() => launchDate = v),
)
```

### Month picker with translated button label

```dart
CsDatePicker(
  value: reportMonth,
  granularity: CsDateGranularity.month,
  placeholder: 'YYYY/MM',
  i18nStrings: CsDatePickerI18nStrings(
    openCalendarAriaLabel: (d) => d == null ? 'Pilih bulan' : 'Pilih bulan, terpilih $d',
  ),
  onChange: (v) => setState(() => reportMonth = v),
)
```

## Accessibility

- The calendar button is labeled "Choose date" or "Choose date, selected date is March 15, 2026", and announces whether the calendar is expanded.
- Opening moves focus to the selected day (or today); Tab stays inside the calendar. Picking a day or pressing Escape closes it and returns focus to the button. Focusing the text field closes it.
- See `CsCalendar` for grid keys.

## Motion

The dropdown scales and fades from the field (`CsAnchoredOverlay`); the phone sheet slides up and follows the finger. Reduced motion keeps only the fade.

## Mobile

At or below 688px the calendar opens in a bottom sheet at full width with taller rows; override with `presentation`. The field itself is at most 234px wide, as in Cloudscape.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value`, `onChange` | `value`, `onChange` |
| `isDateEnabled`, `dateDisabledReason` | same names |
| `startOfWeek`, `granularity` | same names |
| `format`, `inputFormat` | `format`, `inputFormat` |
| `placeholder`, `disabled`, `readOnly`, `invalid`, `warning`, `autoFocus` | same names |
| `onFocus`, `onBlur` | same names |
| `openCalendarAriaLabel`, `i18nStrings` | `i18nStrings` (`CsDatePickerI18nStrings`) |
| `todayAriaLabel`, `nextMonthAriaLabel`, `previousMonthAriaLabel` (deprecated) | `i18nStrings` fields |
| `ariaLabel` | `ariaLabel` |
| `expandToViewport` | not applicable (overlays always render above the page) |
| `locale` | not supported: copy comes from `CsStrings` |
| `name`, `controlId`, `ariaDescribedby`, `ariaLabelledby`, `ariaRequired` | not applicable |
| `ref.focus()` | `focusNode` |
| (none) | `presentation` |
