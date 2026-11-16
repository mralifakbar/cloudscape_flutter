# CsCalendar

An inline month grid (or a year of months) for picking one date; reach for it when the calendar should stay on the page, and for `CsDatePicker` when it belongs behind a field.

Cloudscape reference: https://cloudscape.design/components/calendar/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsCalendar(
  value: date, // '2026-03-15', or '' for none
  onChange: (v) => setState(() => date = v),
)
```

## When to use / when not to

- Use it to pick a single date that should be visible at all times, such as a scheduling side panel.
- Use `CsDatePicker` when the date also needs to be typed, or space is tight.
- Use `CsDateRangePicker` for a start and end date.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | Selected date, `YYYY-MM-DD` (`YYYY-MM` with month granularity), or `''`. |
| `onChange` | `ValueChanged<String>?` | `null` | Called with the picked date in the same format. Null makes the days read-only. |
| `isDateEnabled` | `bool Function(DateTime)?` | all enabled | Days (or months) that can be picked. |
| `dateDisabledReason` | `String? Function(DateTime)?` | `null` | Why a disabled day can not be picked. A reason keeps the day focusable and shows a tooltip. |
| `startOfWeek` | `int?` | `CsStrings.firstDayOfWeek` (Sunday) | First column, 0 Sunday to 6 Saturday. |
| `granularity` | `CsDateGranularity` | `day` | `day` shows a month of days; `month` shows the months of a year. |
| `ariaLabel` | `String?` | `null` | Accessible name of the calendar. |
| `i18nStrings` | `CsCalendarI18nStrings?` | English | `todayAriaLabel`, `nextMonthAriaLabel`, `previousMonthAriaLabel`, `currentMonthAriaLabel`, `nextYearAriaLabel`, `previousYearAriaLabel`, `weekdayNamesShort`. |
| `autofocus` | `bool` | `false` | Focus the selected day (or today) when shown. |
| `stretch` | `bool` | `false` | Fill the available width instead of the 238px grid. |

Month and weekday names come from `context.csStrings` (`CsLocale`).

## Examples

### Weekdays only, with a reason

```dart
CsCalendar(
  value: maintenanceDay,
  isDateEnabled: (d) => d.weekday != DateTime.saturday && d.weekday != DateTime.sunday,
  dateDisabledReason: (d) => 'Maintenance runs on weekdays only.',
  onChange: (v) => setState(() => maintenanceDay = v),
)
```

### Month picker

```dart
CsCalendar(
  value: billingMonth, // '2026-03'
  granularity: CsDateGranularity.month,
  onChange: (v) => setState(() => billingMonth = v),
)
```

### Week starting on Monday, translated labels

```dart
CsCalendar(
  value: date,
  startOfWeek: 1,
  i18nStrings: const CsCalendarI18nStrings(todayAriaLabel: 'Hari ini', nextMonthAriaLabel: 'Bulan berikutnya'),
  onChange: (v) => setState(() => date = v),
)
```

## Accessibility

- Each day is a button labeled like "March 15, 2026", with ". Today" appended for today, and the selected state. Disabled days are announced as disabled; a disabled reason is their hint.
- The grid is one Tab stop: the selected day, else today, else the first enabled day.
- Arrows move by day and week (month and quarter in a month calendar), Page Up and Page Down by month (Shift for a year), Home and End to the start and end of the row, Enter and Space pick. Disabled days are skipped; days with a reason can be focused.
- The previous and next buttons are labeled; the month heading is a live region.

## Motion

Each page fades in with Cloudscape's `motion-duration-show-quick` (135ms). Reduced motion swaps pages instantly. On touch, a horizontal swipe changes the month with a selection haptic.

## Mobile

The calendar keeps Cloudscape's 238px width (scaled with text up to 1.6x) and never exceeds its parent. With `stretch` it fills the parent and, on touch, rows grow to 40px. Day cells do not pad their hit areas to 44px because they tile edge to edge.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value` | `value` |
| `onChange` (`detail.value`) | `onChange` |
| `isDateEnabled` | `isDateEnabled` |
| `dateDisabledReason` (ReactNode) | `dateDisabledReason` (String) |
| `startOfWeek` | `startOfWeek` |
| `granularity` | `granularity` |
| `locale` | not supported: copy comes from `CsStrings` / `i18nStrings` |
| `ariaLabel` | `ariaLabel` |
| `ariaLabelledby`, `ariaDescribedby` | not applicable |
| `i18nStrings` | `i18nStrings` |
| `todayAriaLabel`, `nextMonthAriaLabel`, `previousMonthAriaLabel` (deprecated) | `i18nStrings` fields |
| (none) | `autofocus`, `stretch` |
