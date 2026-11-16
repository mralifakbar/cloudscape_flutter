import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// Calendar, date input, date picker, date range picker and time input.
/// Every name and figure here is sample data.
final CsDemoCategory datesCategory = CsDemoCategory(
  title: 'Dates and time',
  description: 'Calendar, date input, date picker, date range picker and time input.',
  icon: CsIcons.calendar,
  demos: [
    CsDemo(
      title: 'CsCalendar',
      description: 'An inline month or year grid with disabled days, reasons and keyboard navigation.',
      docPath: 'doc/components/CsCalendar.md',
      builder: (_) => const _CalendarDemo(),
    ),
    CsDemo(
      title: 'CsDateInput',
      description: 'A masked YYYY/MM/DD field: slashed, ISO, long-localized and month formats, with every state.',
      docPath: 'doc/components/CsDateInput.md',
      builder: (_) => const _DateInputDemo(),
    ),
    CsDemo(
      title: 'CsDatePicker',
      description: 'A date field with a calendar dropdown that becomes a bottom sheet on phones.',
      docPath: 'doc/components/CsDatePicker.md',
      builder: (_) => const _DatePickerDemo(),
    ),
    CsDemo(
      title: 'CsDateRangePicker',
      description: 'Absolute and relative ranges with validation, times, date-only and month modes.',
      docPath: 'doc/components/CsDateRangePicker.md',
      builder: (_) => const _DateRangePickerDemo(),
    ),
    CsDemo(
      title: 'CsTimeInput',
      description: 'A masked time field in hh:mm:ss, hh:mm and hh formats, 24-hour or 12-hour.',
      docPath: 'doc/components/CsTimeInput.md',
      builder: (_) => const _TimeInputDemo(),
    ),
  ],
);

bool _weekday(DateTime d) => d.weekday != DateTime.saturday && d.weekday != DateTime.sunday;

class _Value extends StatelessWidget {
  const _Value(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: CsSpace.xs),
    child: CsBox(
      variant: CsBoxVariant.small,
      color: CsBoxColor.textBodySecondary,
      text: '$label: ${value.isEmpty ? '(none)' : value}',
    ),
  );
}

class _CalendarDemo extends StatefulWidget {
  const _CalendarDemo();

  @override
  State<_CalendarDemo> createState() => _CalendarDemoState();
}

class _CalendarDemoState extends State<_CalendarDemo> {
  String _date = '';
  String _maintenance = '';
  String _month = '';
  String _monday = '';

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Default',
          caption: 'Today is marked; days of the next month are dimmed but can be picked.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CsCalendar(value: _date, onChange: (v) => setState(() => _date = v), ariaLabel: 'Launch date'),
              _Value('Launch date', _date),
            ],
          ),
        ),
        DemoSection(
          title: 'Disabled days with a reason',
          caption: 'Weekends can not be picked. Hover, focus or long-press one to read why.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CsCalendar(
                value: _maintenance,
                isDateEnabled: _weekday,
                dateDisabledReason: (d) => 'Maintenance for i-0abc123 runs on weekdays only.',
                onChange: (v) => setState(() => _maintenance = v),
              ),
              _Value('Maintenance day', _maintenance),
            ],
          ),
        ),
        DemoSection(
          title: 'Month granularity',
          caption: 'Pick a billing month; pages move by year.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CsCalendar(
                value: _month,
                granularity: CsDateGranularity.month,
                onChange: (v) => setState(() => _month = v),
              ),
              _Value('Billing month', _month),
            ],
          ),
        ),
        DemoSection(
          title: 'Week starts on Monday',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CsCalendar(value: _monday, startOfWeek: 1, onChange: (v) => setState(() => _monday = v)),
              _Value('Selected', _monday),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateInputDemo extends StatefulWidget {
  const _DateInputDemo();

  @override
  State<_DateInputDemo> createState() => _DateInputDemoState();
}

class _DateInputDemoState extends State<_DateInputDemo> {
  String _slashed = '';
  String _iso = '2026-03-15';
  String _long = '2026-01-30';
  String _month = '';
  String _validated = '2026-02-30';

  String? get _error {
    if (_validated.isEmpty) return null;
    final ok = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(_validated);
    return ok ? null : 'Enter a complete date.';
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Slashed (default)',
          caption: 'Type digits; separators are added and out-of-range parts corrected.',
          child: CsFormField(
            label: 'Snapshot date',
            constraintText: 'Use YYYY/MM/DD format.',
            child: CsDateInput(
              value: _slashed,
              placeholder: 'YYYY/MM/DD',
              onChange: (v) => setState(() => _slashed = v),
            ),
          ),
        ),
        DemoSection(
          title: 'ISO',
          child: CsFormField(
            label: 'Retention ends',
            constraintText: 'Use YYYY-MM-DD format.',
            child: CsDateInput(
              value: _iso,
              format: CsDateFormat.iso,
              placeholder: 'YYYY-MM-DD',
              onChange: (v) => setState(() => _iso = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Long-localized',
          caption: 'Shows words until focused, then the typing format.',
          child: CsFormField(
            label: 'Certificate issued',
            child: CsDateInput(
              value: _long,
              format: CsDateFormat.longLocalized,
              onChange: (v) => setState(() => _long = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Month granularity',
          child: CsFormField(
            label: 'Billing month',
            child: CsDateInput(
              value: _month,
              granularity: CsDateGranularity.month,
              placeholder: 'YYYY/MM',
              onChange: (v) => setState(() => _month = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Validation',
          caption: 'The parent validates the value and sets invalid.',
          child: CsFormField(
            label: 'Backup date',
            errorText: _error,
            child: CsDateInput(
              value: _validated,
              invalid: _error != null,
              placeholder: 'YYYY/MM/DD',
              onChange: (v) => setState(() => _validated = v),
            ),
          ),
        ),
        const DemoSection(
          title: 'States',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsFormField(
                label: 'Warning',
                child: CsDateInput(value: '2026-03-15', warning: true),
              ),
              CsFormField(
                label: 'Disabled',
                child: CsDateInput(value: '2026-03-15', disabled: true),
              ),
              CsFormField(
                label: 'Read-only',
                child: CsDateInput(value: '2026-03-15', readOnly: true),
              ),
              CsFormField(
                label: 'Empty',
                child: CsDateInput(value: '', placeholder: 'YYYY/MM/DD'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DatePickerDemo extends StatefulWidget {
  const _DatePickerDemo();

  @override
  State<_DatePickerDemo> createState() => _DatePickerDemoState();
}

class _DatePickerDemoState extends State<_DatePickerDemo> {
  String _expiry = '';
  String _launch = '';
  String _month = '';
  String _long = '2026-03-15';

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Default',
          caption: 'Type a date or pick one from the calendar. On phones the calendar opens in a sheet.',
          child: CsFormField(
            label: 'Certificate expiry',
            constraintText: 'Use YYYY/MM/DD format.',
            child: CsDatePicker(
              value: _expiry,
              placeholder: 'YYYY/MM/DD',
              onChange: (v) => setState(() => _expiry = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Weekdays only',
          child: CsFormField(
            label: 'Launch date for distribution d111111abcdef8',
            child: CsDatePicker(
              value: _launch,
              placeholder: 'YYYY/MM/DD',
              isDateEnabled: _weekday,
              dateDisabledReason: (d) => 'Launches run on weekdays.',
              onChange: (v) => setState(() => _launch = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Month granularity',
          child: CsFormField(
            label: 'Report month',
            child: CsDatePicker(
              value: _month,
              granularity: CsDateGranularity.month,
              placeholder: 'YYYY/MM',
              onChange: (v) => setState(() => _month = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Long-localized display',
          child: CsFormField(
            label: 'Bucket lifecycle starts',
            child: CsDatePicker(
              value: _long,
              format: CsDateFormat.longLocalized,
              onChange: (v) => setState(() => _long = v),
            ),
          ),
        ),
        const DemoSection(
          title: 'States',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsFormField(
                label: 'Invalid',
                errorText: 'Enter a future date.',
                child: CsDatePicker(value: '2020-01-01', invalid: true),
              ),
              CsFormField(
                label: 'Warning',
                child: CsDatePicker(value: '2026-03-15', warning: true),
              ),
              CsFormField(
                label: 'Disabled',
                child: CsDatePicker(value: '2026-03-15', disabled: true),
              ),
              CsFormField(
                label: 'Read-only',
                child: CsDatePicker(value: '2026-03-15', readOnly: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateRangePickerDemo extends StatefulWidget {
  const _DateRangePickerDemo();

  @override
  State<_DateRangePickerDemo> createState() => _DateRangePickerDemoState();
}

class _DateRangePickerDemoState extends State<_DateRangePickerDemo> {
  CsDateRangeValue? _logs = const CsRelativeDateRange(key: 'previous-1-hour', amount: 1, unit: CsTimeUnit.hour);
  CsDateRangeValue? _billing;
  CsDateRangeValue? _relative;
  CsDateRangeValue? _months;
  CsDateRangeValue? _minutes;

  static const _options = [
    CsRelativeDateRange(key: 'previous-5-minutes', amount: 5, unit: CsTimeUnit.minute),
    CsRelativeDateRange(key: 'previous-30-minutes', amount: 30, unit: CsTimeUnit.minute),
    CsRelativeDateRange(key: 'previous-1-hour', amount: 1, unit: CsTimeUnit.hour),
    CsRelativeDateRange(key: 'previous-6-hours', amount: 6, unit: CsTimeUnit.hour),
  ];

  static CsDateRangeValidationResult _validate(CsDateRangeValue? v) {
    if (v == null) return const CsDateRangeValidationResult.invalid('Select a range, or use Clear and dismiss.');
    if (v is CsAbsoluteDateRange && v.end.isBefore(v.start)) {
      return const CsDateRangeValidationResult.invalid('The end date must be after the start date.');
    }
    if (v is CsRelativeDateRange && v.amount <= 0) {
      return const CsDateRangeValidationResult.invalid('Enter a duration greater than 0.');
    }
    return const CsDateRangeValidationResult.valid();
  }

  String _describe(CsDateRangeValue? v) => switch (v) {
    null => '',
    CsRelativeDateRange() => 'relative, ${v.amount} ${v.unit.name} (key ${v.key ?? 'custom'})',
    CsAbsoluteDateRange() => 'absolute, ${v.start} to ${v.end}',
  };

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Relative and absolute',
          caption: 'Filter instance logs. Two month grids on wide screens, one in a sheet on phones.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CsFormField(
                label: 'Log time range',
                child: CsDateRangePicker(
                  value: _logs,
                  placeholder: 'Filter by a date and time range',
                  relativeOptions: _options,
                  isValidRange: _validate,
                  onChange: (v) => setState(() => _logs = v),
                ),
              ),
              _Value('Value', _describe(_logs)),
            ],
          ),
        ),
        DemoSection(
          title: 'Absolute only, dates only',
          caption: 'Weekends disabled with a reason; slashed dates in the trigger.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CsFormField(
                label: 'Billing period',
                child: CsDateRangePicker(
                  value: _billing,
                  dateOnly: true,
                  rangeSelectorMode: CsDateRangeSelectorMode.absoluteOnly,
                  absoluteFormat: CsDateFormat.slashed,
                  isDateEnabled: _weekday,
                  dateDisabledReason: (d) => 'Billing closes on weekends.',
                  placeholder: 'Filter by a date range',
                  isValidRange: _validate,
                  onChange: (v) => setState(() => _billing = v),
                ),
              ),
              _Value('Value', _describe(_billing)),
            ],
          ),
        ),
        DemoSection(
          title: 'Relative only, custom range',
          caption: 'No suggested options: enter a duration and a unit.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CsFormField(
                label: 'Metric window',
                child: CsDateRangePicker(
                  value: _relative,
                  rangeSelectorMode: CsDateRangeSelectorMode.relativeOnly,
                  placeholder: 'Choose a window',
                  isValidRange: _validate,
                  onChange: (v) => setState(() => _relative = v),
                ),
              ),
              _Value('Value', _describe(_relative)),
            ],
          ),
        ),
        DemoSection(
          title: 'Month granularity',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CsFormField(
                label: 'Cost report',
                child: CsDateRangePicker(
                  value: _months,
                  granularity: CsDateGranularity.month,
                  relativeOptions: const [
                    CsRelativeDateRange(key: 'previous-3-months', amount: 3, unit: CsTimeUnit.month),
                    CsRelativeDateRange(key: 'previous-6-months', amount: 6, unit: CsTimeUnit.month),
                    CsRelativeDateRange(key: 'previous-1-year', amount: 1, unit: CsTimeUnit.year),
                  ],
                  absoluteFormat: CsDateFormat.longLocalized,
                  placeholder: 'Filter by a month range',
                  isValidRange: _validate,
                  onChange: (v) => setState(() => _months = v),
                ),
              ),
              _Value('Value', _describe(_months)),
            ],
          ),
        ),
        DemoSection(
          title: 'Hours and minutes, ISO input, no clear button',
          child: CsDateRangePicker(
            value: _minutes,
            rangeSelectorMode: CsDateRangeSelectorMode.absoluteOnly,
            timeInputFormat: CsTimeInputFormat.hhMm,
            dateInputFormat: CsDateInputFormat.iso,
            hideTimeOffset: true,
            showClearButton: false,
            ariaLabel: 'Deployment window',
            placeholder: 'Deployment window',
            isValidRange: _validate,
            onChange: (v) => setState(() => _minutes = v),
          ),
        ),
        DemoSection(
          title: 'States',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsFormField(
                label: 'Invalid',
                errorText: 'Choose a range within the last 90 days.',
                child: CsDateRangePicker(value: _options.first, invalid: true),
              ),
              const CsFormField(
                label: 'Disabled',
                child: CsDateRangePicker(value: null, disabled: true, placeholder: 'Filter by a date and time range'),
              ),
              CsFormField(
                label: 'Read-only',
                child: CsDateRangePicker(value: _options[2], readOnly: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeInputDemo extends StatefulWidget {
  const _TimeInputDemo();

  @override
  State<_TimeInputDemo> createState() => _TimeInputDemoState();
}

class _TimeInputDemoState extends State<_TimeInputDemo> {
  String _full = '';
  String _hm = '02:30';
  String _h = '';
  String _twelve = '';

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'hh:mm:ss (default)',
          caption: 'Type 7 to get 07:, 25 becomes 23. Leave the field to complete a partial time.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CsFormField(
                label: 'Backup window starts',
                constraintText: 'Use 24-hour format.',
                child: CsTimeInput(value: _full, placeholder: 'hh:mm:ss', onChange: (v) => setState(() => _full = v)),
              ),
              _Value('Value', _full),
            ],
          ),
        ),
        DemoSection(
          title: 'hh:mm',
          child: CsFormField(
            label: 'Snapshot cutoff',
            child: CsTimeInput(
              value: _hm,
              format: CsTimeInputFormat.hhMm,
              placeholder: CsTimeInputFormat.hhMm.pattern,
              onChange: (v) => setState(() => _hm = v),
            ),
          ),
        ),
        DemoSection(
          title: 'hh',
          child: CsFormField(
            label: 'Hour of day',
            child: CsTimeInput(
              value: _h,
              format: CsTimeInputFormat.hh,
              placeholder: 'hh',
              onChange: (v) => setState(() => _h = v),
            ),
          ),
        ),
        DemoSection(
          title: '12-hour',
          caption: 'Hours run from 01 to 12; there is no AM/PM part, so the label says which half.',
          child: CsFormField(
            label: 'Morning sync (AM)',
            child: CsTimeInput(
              value: _twelve,
              use24Hour: false,
              format: CsTimeInputFormat.hhMm,
              placeholder: 'hh:mm',
              onChange: (v) => setState(() => _twelve = v),
            ),
          ),
        ),
        const DemoSection(
          title: 'States',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsFormField(
                label: 'Invalid',
                errorText: 'Enter a time.',
                child: CsTimeInput(value: '', invalid: true),
              ),
              CsFormField(
                label: 'Warning',
                child: CsTimeInput(value: '23:59:59', warning: true),
              ),
              CsFormField(
                label: 'Disabled',
                child: CsTimeInput(value: '12:00:00', disabled: true),
              ),
              CsFormField(
                label: 'Read-only',
                child: CsTimeInput(value: '12:00:00', readOnly: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
