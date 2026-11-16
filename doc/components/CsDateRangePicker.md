# CsDateRangePicker

A trigger that opens a dropdown for picking an absolute range on a calendar, with optional times, or a relative range such as "Last 5 minutes"; the standard filter for time-based data.

Cloudscape reference: https://cloudscape.design/components/date-range-picker/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsDateRangePicker(
  value: range, // CsDateRangeValue? (absolute, relative or null)
  placeholder: 'Filter by a date and time range',
  relativeOptions: const [
    CsRelativeDateRange(key: 'previous-5-minutes', amount: 5, unit: CsTimeUnit.minute),
    CsRelativeDateRange(key: 'previous-1-hour', amount: 1, unit: CsTimeUnit.hour),
    CsRelativeDateRange(key: 'previous-1-day', amount: 1, unit: CsTimeUnit.day),
  ],
  isValidRange: (v) {
    if (v is CsAbsoluteDateRange && v.end.isBefore(v.start)) {
      return const CsDateRangeValidationResult.invalid('The end date must be after the start date.');
    }
    if (v is CsRelativeDateRange && v.amount <= 0) {
      return const CsDateRangeValidationResult.invalid('Enter a duration greater than 0.');
    }
    return const CsDateRangeValidationResult.valid();
  },
  onChange: (v) => setState(() => range = v),
)
```

## When to use / when not to

- Use it to filter logs, metrics or events by time.
- Use `CsDatePicker` for a single date.
- Use `rangeSelectorMode` to offer only absolute or only relative ranges.

## Value model

| Type | Fields | Notes |
| --- | --- | --- |
| `CsAbsoluteDateRange` | `start`, `end` (`DateTime`, local) | With `dateOnly` both are midnight; with month granularity both are the first of their month. Calendar picks set 00:00:00 and 23:59:59. |
| `CsRelativeDateRange` | `key`, `amount`, `unit` (`CsTimeUnit`) | Options carry a `key`; a custom range has none. An empty custom duration reports `amount: 0`. `startFrom(now)` computes the start. |

`isValidRange` receives the value (null when nothing is picked). An absolute range with a missing or unreadable date never reaches it: the picker shows `i18nStrings.incompleteRangeErrorMessage` instead.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `CsDateRangeValue?` | required | The applied range. |
| `onChange` | `ValueChanged<CsDateRangeValue?>?` | `null` | Fires on Apply (after validation) and with null on Clear. |
| `relativeOptions` | `List<CsRelativeDateRange>` | `[]` | Suggested relative ranges, shown as radio buttons with a "Custom range" option. |
| `isValidRange` | `CsDateRangeValidator?` | valid | Returns `CsDateRangeValidationResult.valid()` or `.invalid(message)`. |
| `isDateEnabled` | `bool Function(DateTime)?` | all | Days that can be picked in the calendar. |
| `dateDisabledReason` | `String? Function(DateTime)?` | `null` | Tooltip for disabled days. |
| `startOfWeek` | `int?` | Sunday | 0 Sunday to 6 Saturday. |
| `i18nStrings` | `CsDateRangePickerI18nStrings` | English | Every label, `formatRelativeRange`, `formatUnit`, constraint texts, placeholders. |
| `dateOnly` | `bool` | `false` | Hide time inputs. |
| `granularity` | `CsDateGranularity` | `day` | `month` shows years of months. |
| `rangeSelectorMode` | `CsDateRangeSelectorMode` | `defaultMode` | `absoluteOnly`, `relativeOnly`. |
| `dateInputFormat` | `CsDateInputFormat` | `slashed` | Typing format of the date inputs. |
| `timeInputFormat` | `CsTimeInputFormat` | `hhMmSs` | Parts of the time inputs. |
| `absoluteFormat` | `CsDateFormat` | `iso` | Trigger text: `iso` (`2026-03-01T00:00:00+07:00`), `slashed`, `longLocalized` (`March 1, 2026, 00:00:00 (UTC+7)`). |
| `hideTimeOffset` | `bool` | `false` | Drop the UTC offset from the trigger text. |
| `placeholder` | `String?` | `null` | Trigger text with no value. |
| `disabled`, `readOnly`, `invalid`, `warning` | `bool` | `false` | Trigger states. |
| `showClearButton` | `bool` | `true` | "Clear and dismiss" in the footer. |
| `customAbsoluteRangeControl` | `CsAbsoluteRangeControlBuilder?` | `null` | Extra content under the calendar; gets the `CsPendingAbsoluteRange` and a setter. |
| `customRelativeRangeUnits` | `List<CsTimeUnit>?` | by mode | Units offered for a custom range. |
| `renderRelativeRangeContent` | `CsRelativeRangeContentBuilder?` | `null` | Replaces the relative tab. |
| `renderTriggerContent` | `CsDateRangeTriggerBuilder?` | `null` | Replaces the trigger content; gets the formatted text. |
| `absoluteMultiGridStartPeriod` | `CsDateRangeStartPeriod` | `auto` | Whether the first of two grids shows the previous or current month. |
| `ariaLabel` | `String?` | `null` | Name of the trigger and dropdown. |
| `onFocus` / `onBlur` | `VoidCallback?` | `null` | Trigger focus. |
| `presentation` | `CsPresentation` | `auto` | Dropdown, or a bottom sheet at or below 688px. |
| `focusNode` | `FocusNode?` | `null` | Trigger focus node. |

## Examples

### Dates only, absolute only

```dart
CsDateRangePicker(
  value: billingRange,
  dateOnly: true,
  rangeSelectorMode: CsDateRangeSelectorMode.absoluteOnly,
  placeholder: 'Filter by a date range',
  onChange: (v) => setState(() => billingRange = v),
)
```

### Month ranges with translated copy

```dart
CsDateRangePicker(
  value: reportRange,
  granularity: CsDateGranularity.month,
  relativeOptions: const [
    CsRelativeDateRange(key: 'previous-3-months', amount: 3, unit: CsTimeUnit.month),
    CsRelativeDateRange(key: 'previous-1-year', amount: 1, unit: CsTimeUnit.year),
  ],
  i18nStrings: CsDateRangePickerI18nStrings(
    applyButtonLabel: 'Terapkan',
    cancelButtonLabel: 'Batal',
    formatRelativeRange: (r) => '${r.amount} ${r.unit.name} terakhir',
  ),
  onChange: (v) => setState(() => reportRange = v),
)
```

### Using a relative value

```dart
DateTime? rangeStart(CsDateRangeValue? value) => switch (value) {
  CsRelativeDateRange() => value.startFrom(), // counts back from clock.now()
  CsAbsoluteDateRange() => value.start,
  null => null,
};
```

## Accessibility

- The trigger is a button whose value is the formatted range; it announces whether the dropdown is expanded.
- Opening focuses the calendar's selected start, today or the first enabled day; Tab stays inside the dropdown; Escape, Cancel, Clear and a successful Apply close it and return focus to the trigger.
- Calendar picks are announced ("Start date, March 3, 2026, Start time, 00:00:00." then "Range selected from March 3, 2026 to March 7, 2026"). Validation errors are announced and shown with an error icon labeled `errorIconAriaLabel`.
- The mode switch and relative options expose selected / checked states in mutually exclusive groups.

## Motion

The dropdown scales and fades from the trigger; the phone sheet slides and follows the finger. Calendar pages fade in (135ms). Reduced motion keeps only fades.

## Mobile

At or below 688px the picker shows one month grid and opens in a bottom sheet at full width, with the start and end fields stacked and the custom duration and unit stacked. The trigger is at most 32em wide (39em for long-localized dates with times).

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value` (absolute or relative object) | `value` (`CsAbsoluteDateRange` / `CsRelativeDateRange`) |
| `onChange` (`detail.value`) | `onChange` |
| `relativeOptions` | `relativeOptions` (`CsRelativeDateRange` with `key`) |
| `isValidRange` | `isValidRange` |
| `isDateEnabled`, `dateDisabledReason`, `startOfWeek` | same names |
| `i18nStrings` | `i18nStrings` |
| `dateOnly`, `granularity`, `rangeSelectorMode` | same names |
| `dateInputFormat`, `timeInputFormat` | same names (enums) |
| `absoluteFormat`, `hideTimeOffset` | same names |
| `placeholder`, `disabled`, `readOnly`, `invalid`, `warning` | same names |
| `showClearButton` | `showClearButton` |
| `customAbsoluteRangeControl`, `customRelativeRangeUnits`, `renderRelativeRangeContent`, `renderTriggerContent` | same names (builders) |
| `absoluteMultiGridStartPeriod` | `absoluteMultiGridStartPeriod` |
| `ariaLabel`, `onFocus`, `onBlur` | same names |
| `timeOffset`, `getTimeOffset` | not applicable: values are local `DateTime`s |
| `expandToViewport` | not applicable |
| `locale` | not supported: copy comes from `CsStrings` / `i18nStrings` |
| `controlId`, `ariaDescribedby`, `ariaLabelledby` | not applicable |
| `ref.focus()` | `focusNode` |
