import 'package:clock/clock.dart';
import 'package:cloudscape_flutter/src/dates/dates.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

Future<void> _withToday(Future<void> Function() body) => withClock(Clock.fixed(DateTime(2026, 3, 10, 12)), body);

const _options = [
  CsRelativeDateRange(key: 'previous-5-minutes', amount: 5, unit: CsTimeUnit.minute),
  CsRelativeDateRange(key: 'previous-1-hour', amount: 1, unit: CsTimeUnit.hour),
  CsRelativeDateRange(key: 'previous-6-hours', amount: 6, unit: CsTimeUnit.hour),
];

class _Host extends StatefulWidget {
  const _Host({
    super.key,
    required this.log,
    this.initial,
    this.options = _options,
    this.dateOnly = false,
    this.mode = CsDateRangeSelectorMode.defaultMode,
    this.granularity = CsDateGranularity.day,
    this.isValidRange,
  });

  final List<CsDateRangeValue?> log;
  final CsDateRangeValue? initial;
  final List<CsRelativeDateRange> options;
  final bool dateOnly;
  final CsDateRangeSelectorMode mode;
  final CsDateGranularity granularity;
  final CsDateRangeValidator? isValidRange;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late CsDateRangeValue? value = widget.initial;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 340,
        child: CsDateRangePicker(
          value: value,
          placeholder: 'Filter by a date and time range',
          relativeOptions: widget.options,
          dateOnly: widget.dateOnly,
          rangeSelectorMode: widget.mode,
          granularity: widget.granularity,
          hideTimeOffset: true,
          isValidRange: widget.isValidRange,
          onChange: (v) {
            widget.log.add(v);
            setState(() => value = v);
          },
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(CsDateRangePicker));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders every state in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CsDateRangePicker(value: null, placeholder: 'Filter by a date and time range'),
              CsDateRangePicker(value: _options.first),
              CsDateRangePicker(
                value: CsAbsoluteDateRange(start: DateTime(2026, 3, 1), end: DateTime(2026, 3, 5, 23, 59, 59)),
                invalid: true,
              ),
              const CsDateRangePicker(value: null, disabled: true, placeholder: 'Disabled'),
              const CsDateRangePicker(value: null, readOnly: true, placeholder: 'Read-only'),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('trigger shows the placeholder, a relative range or an absolute range', (tester) async {
    await pumpCs(tester, const CsDateRangePicker(value: null, placeholder: 'Filter by a date and time range'));
    expect(find.text('Filter by a date and time range'), findsOneWidget);
    await pumpCs(tester, CsDateRangePicker(value: _options[1]));
    expect(find.text('Last 1 hour'), findsOneWidget);
    await pumpCs(
      tester,
      CsDateRangePicker(
        value: CsAbsoluteDateRange(start: DateTime(2026, 3, 1), end: DateTime(2026, 3, 5, 23, 59, 59)),
        hideTimeOffset: true,
      ),
    );
    expect(find.text('2026-03-01T00:00:00 – 2026-03-05T23:59:59'), findsOneWidget);
    await pumpCs(
      tester,
      CsDateRangePicker(
        value: CsAbsoluteDateRange(start: DateTime(2026, 3, 1), end: DateTime(2026, 3, 5)),
        dateOnly: true,
        absoluteFormat: CsDateFormat.slashed,
      ),
    );
    expect(find.text('2026/03/01 – 2026/03/05'), findsOneWidget);
    await pumpCs(
      tester,
      CsDateRangePicker(
        value: CsAbsoluteDateRange(start: DateTime(2026, 3, 1), end: DateTime(2026, 3, 5)),
        dateOnly: true,
        absoluteFormat: CsDateFormat.longLocalized,
      ),
    );
    expect(find.text('March 1, 2026 – March 5, 2026'), findsOneWidget);
  });

  testWidgets('desktop: two grids, pick a start and end on the calendar, Apply', (tester) async {
    await _withToday(() async {
      final log = <CsDateRangeValue?>[];
      await pumpCs(
        tester,
        _Host(log: log, mode: CsDateRangeSelectorMode.absoluteOnly),
        size: csDesktopSize,
        center: false,
      );
      await _open(tester);
      expect(find.text('February 2026'), findsOneWidget);
      expect(find.text('March 2026'), findsOneWidget);
      await tester.tap(find.text('7').at(1));
      await tester.pump();
      await tester.tap(find.text('3').at(1));
      await tester.pumpAndSettle();
      // Picking an earlier second day swaps the ends.
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(log.single, CsAbsoluteDateRange(start: DateTime(2026, 3, 3), end: DateTime(2026, 3, 7, 23, 59, 59)));
      expect(find.text('Apply'), findsNothing);
      expect(find.text('2026-03-03T00:00:00 – 2026-03-07T23:59:59'), findsOneWidget);
    });
  });

  testWidgets('typed dates and times are applied', (tester) async {
    await _withToday(() async {
      final log = <CsDateRangeValue?>[];
      await pumpCs(
        tester,
        _Host(log: log, mode: CsDateRangeSelectorMode.absoluteOnly),
        size: csDesktopSize,
        center: false,
      );
      await _open(tester);
      final fields = find.byType(EditableText);
      expect(fields, findsNWidgets(4));
      await tester.enterText(fields.at(0), '20260102');
      await tester.enterText(fields.at(1), '083000');
      await tester.enterText(fields.at(2), '20260104');
      await tester.enterText(fields.at(3), '170000');
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(log.single, CsAbsoluteDateRange(start: DateTime(2026, 1, 2, 8, 30), end: DateTime(2026, 1, 4, 17)));
    });
  });

  testWidgets('an incomplete range shows an error and keeps the dropdown open', (tester) async {
    await _withToday(() async {
      final log = <CsDateRangeValue?>[];
      await pumpCs(
        tester,
        _Host(log: log, mode: CsDateRangeSelectorMode.absoluteOnly),
        size: csDesktopSize,
        center: false,
      );
      await _open(tester);
      await tester.tap(find.text('12').at(1));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      expect(find.textContaining('The selected date range is incomplete'), findsOneWidget);
      // Completing the range clears the error.
      await tester.tap(find.text('14').at(1));
      await tester.pumpAndSettle();
      expect(find.textContaining('The selected date range is incomplete'), findsNothing);
    });
  });

  testWidgets('isValidRange errors block Apply', (tester) async {
    await _withToday(() async {
      final log = <CsDateRangeValue?>[];
      await pumpCs(
        tester,
        _Host(
          log: log,
          isValidRange: (v) => v == null
              ? const CsDateRangeValidationResult.invalid('Choose a range.')
              : const CsDateRangeValidationResult.valid(),
        ),
        size: csDesktopSize,
        center: false,
      );
      await _open(tester);
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a range.'), findsOneWidget);
      expect(log, isEmpty);
    });
  });

  testWidgets('relative options are radio buttons and apply a relative value', (tester) async {
    await _withToday(() async {
      final log = <CsDateRangeValue?>[];
      await pumpCs(tester, _Host(log: log), size: csDesktopSize, center: false);
      await _open(tester);
      expect(find.text('Choose a range'), findsOneWidget);
      await tester.tap(find.text('Last 6 hours'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(log.single, _options[2]);
      expect(find.text('Last 6 hours'), findsOneWidget);
    });
  });

  testWidgets('a custom relative range takes a duration and unit', (tester) async {
    await _withToday(() async {
      final log = <CsDateRangeValue?>[];
      await pumpCs(
        tester,
        _Host(log: log, options: const [], mode: CsDateRangeSelectorMode.relativeOnly),
        size: csDesktopSize,
        center: false,
      );
      await _open(tester);
      expect(find.text('Set a custom range in the past'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), '15');
      await tester.pump();
      await tester.tap(find.text('minutes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('hours'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(log.single, const CsRelativeDateRange(amount: 15, unit: CsTimeUnit.hour));
    });
  });

  testWidgets('the mode switch moves between relative and absolute', (tester) async {
    await _withToday(() async {
      await pumpCs(tester, const _Host(log: []), size: csDesktopSize, center: false);
      await _open(tester);
      expect(find.text('Choose a range'), findsOneWidget);
      await tester.tap(find.text('Absolute mode'));
      await tester.pumpAndSettle();
      expect(find.text('Start date'), findsOneWidget);
      expect(find.text('End time'), findsOneWidget);
      await tester.tap(find.text('Relative mode'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a range'), findsOneWidget);
    });
  });

  testWidgets('Clear reports null, Cancel keeps the value, Escape closes', (tester) async {
    await _withToday(() async {
      final log = <CsDateRangeValue?>[];
      await pumpCs(
        tester,
        _Host(log: log, initial: _options.first),
        size: csDesktopSize,
        center: false,
      );
      await _open(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      expect(find.text('Apply'), findsNothing);

      await _open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Apply'), findsNothing);

      await _open(tester);
      await tester.tap(find.text('Clear and dismiss'));
      await tester.pumpAndSettle();
      expect(log, [null]);
      expect(find.text('Filter by a date and time range'), findsOneWidget);
    });
  });

  testWidgets('keyboard picks days in the grid', (tester) async {
    await _withToday(() async {
      final log = <CsDateRangeValue?>[];
      await pumpCs(
        tester,
        _Host(log: log, dateOnly: true, mode: CsDateRangeSelectorMode.absoluteOnly),
        size: csDesktopSize,
        center: false,
      );
      await _open(tester);
      // Focus starts on today, March 10.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(log.single, CsAbsoluteDateRange(start: DateTime(2026, 3, 10), end: DateTime(2026, 3, 18)));
    });
  });

  testWidgets('dateOnly hides times and month granularity shows years', (tester) async {
    await _withToday(() async {
      await pumpCs(
        tester,
        const _Host(log: [], dateOnly: true, mode: CsDateRangeSelectorMode.absoluteOnly),
        size: csDesktopSize,
        center: false,
      );
      await _open(tester);
      expect(find.text('Start time'), findsNothing);
      expect(find.text('For date, use YYYY/MM/DD.'), findsOneWidget);

      final log = <CsDateRangeValue?>[];
      await pumpCs(
        tester,
        _Host(
          key: const ValueKey('months'),
          log: log,
          granularity: CsDateGranularity.month,
          mode: CsDateRangeSelectorMode.absoluteOnly,
        ),
        size: csDesktopSize,
        center: false,
      );
      await _open(tester);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('Start month'), findsOneWidget);
      await tester.tap(find.text('Feb').at(1));
      await tester.pump();
      await tester.tap(find.text('Apr').at(1));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(log.single, CsAbsoluteDateRange(start: DateTime(2026, 2), end: DateTime(2026, 4)));
    });
  });

  testWidgets('phone: one grid in a bottom sheet, also at 2x text', (tester) async {
    await _withToday(() async {
      final log = <CsDateRangeValue?>[];
      await pumpCs(tester, _Host(log: log, mode: CsDateRangeSelectorMode.absoluteOnly), center: false);
      await _open(tester);
      expect(find.text('March 2026'), findsOneWidget);
      expect(find.text('February 2026'), findsNothing);
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('6'));
      await tester.pump();
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(log.single, CsAbsoluteDateRange(start: DateTime(2026, 3, 4), end: DateTime(2026, 3, 6, 23, 59, 59)));

      await pumpCs(
        tester,
        const _Host(key: ValueKey('big'), log: [], mode: CsDateRangeSelectorMode.absoluteOnly),
        center: false,
        textScale: 2,
      );
      await _open(tester);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the trigger is a labeled button with the range as its value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, CsDateRangePicker(value: _options.first, ariaLabel: 'Time range'));
    final node = tester.getSemantics(find.bySemanticsLabel('Time range'));
    expect(node.value, 'Last 5 minutes');
    handle.dispose();
  });

  testWidgets('disabled and read-only pickers do not open', (tester) async {
    await pumpCs(tester, const CsDateRangePicker(value: null, disabled: true, placeholder: 'x'), size: csDesktopSize);
    await tester.tap(find.byType(CsDateRangePicker), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Apply'), findsNothing);
    await pumpCs(tester, const CsDateRangePicker(value: null, readOnly: true, placeholder: 'x'), size: csDesktopSize);
    await tester.tap(find.byType(CsDateRangePicker));
    await tester.pumpAndSettle();
    expect(find.text('Apply'), findsNothing);
  });

  test('relative ranges count back from now', () {
    final now = DateTime(2026, 3, 10, 12);
    expect(const CsRelativeDateRange(amount: 2, unit: CsTimeUnit.hour).startFrom(now), DateTime(2026, 3, 10, 10));
    expect(const CsRelativeDateRange(amount: 1, unit: CsTimeUnit.week).startFrom(now), DateTime(2026, 3, 3, 12));
    expect(const CsRelativeDateRange(amount: 1, unit: CsTimeUnit.month).startFrom(now), DateTime(2026, 2, 10, 12));
  });
}
