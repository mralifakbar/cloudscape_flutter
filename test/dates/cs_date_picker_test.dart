import 'package:clock/clock.dart';
import 'package:cloudscape_flutter/src/buttons/cs_button.dart';
import 'package:cloudscape_flutter/src/dates/dates.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

Future<void> _withToday(Future<void> Function() body) => withClock(Clock.fixed(DateTime(2026, 3, 10)), body);

class _Host extends StatefulWidget {
  const _Host({required this.log, this.initial = '', this.granularity = CsDateGranularity.day});

  final List<String> log;
  final String initial;
  final CsDateGranularity granularity;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String value = widget.initial;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.only(top: 40),
      child: CsDatePicker(
        value: value,
        granularity: widget.granularity,
        placeholder: 'YYYY/MM/DD',
        onChange: (v) {
          widget.log.add(v);
          setState(() => value = v);
        },
      ),
    ),
  );
}

void main() {
  testWidgets('renders every state in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CsDatePicker(value: '2026-03-15'),
              CsDatePicker(value: '', placeholder: 'YYYY/MM/DD', disabled: true),
              CsDatePicker(value: '2026-03-15', readOnly: true),
              CsDatePicker(value: '2026-03-15', invalid: true),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('the calendar button describes the selection', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsDatePicker(value: '2026-03-15'));
    expect(find.bySemanticsLabel('Choose date, selected date is March 15, 2026'), findsOneWidget);
    await pumpCs(tester, const CsDatePicker(value: '2026-03'));
    expect(find.bySemanticsLabel('Choose date'), findsOneWidget);
    await pumpCs(
      tester,
      CsDatePicker(
        value: '',
        i18nStrings: CsDatePickerI18nStrings(openCalendarAriaLabel: (d) => 'Pilih tanggal ${d ?? '-'}'),
      ),
    );
    expect(find.bySemanticsLabel('Pilih tanggal -'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('desktop: opens a dropdown calendar, picks a day and closes', (tester) async {
    await _withToday(() async {
      final log = <String>[];
      await pumpCs(
        tester,
        _Host(log: log, initial: '2026-03-15'),
        size: csDesktopSize,
        center: false,
      );
      await tester.tap(find.byType(CsButton));
      await tester.pumpAndSettle();
      expect(find.text('March 2026'), findsOneWidget);
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      expect(log, ['2026-03-20']);
      expect(find.text('March 2026'), findsNothing);
    });
  });

  testWidgets('desktop: Escape closes the calendar', (tester) async {
    await _withToday(() async {
      await pumpCs(
        tester,
        const _Host(log: [], initial: '2026-03-15'),
        size: csDesktopSize,
        center: false,
      );
      await tester.tap(find.byType(CsButton));
      await tester.pumpAndSettle();
      expect(find.byType(CsCalendar), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(CsCalendar), findsNothing);
    });
  });

  testWidgets('phone: opens the calendar in a bottom sheet', (tester) async {
    await _withToday(() async {
      final log = <String>[];
      await pumpCs(tester, _Host(log: log, initial: '2026-03-15'), center: false);
      await tester.tap(find.byType(CsButton));
      await tester.pumpAndSettle();
      expect(find.byType(CsCalendar), findsOneWidget);
      expect(tester.getSize(find.byType(CsCalendar)).width, greaterThan(300));
      await tester.tap(find.text('21'));
      await tester.pumpAndSettle();
      expect(log, ['2026-03-21']);
      expect(find.byType(CsCalendar), findsNothing);
    });
  });

  testWidgets('month granularity picks a month', (tester) async {
    await _withToday(() async {
      final log = <String>[];
      await pumpCs(
        tester,
        _Host(log: log, initial: '2026-03', granularity: CsDateGranularity.month),
        size: csDesktopSize,
        center: false,
      );
      await tester.tap(find.byType(CsButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sep'));
      await tester.pumpAndSettle();
      expect(log, ['2026-09']);
    });
  });

  testWidgets('typing reports ISO and disabled pickers can not open', (tester) async {
    final log = <String>[];
    await pumpCs(tester, _Host(log: log), size: csDesktopSize);
    await tester.enterText(find.byType(EditableText), '20260401');
    await tester.pump();
    expect(log.last, '2026-04-01');

    await pumpCs(tester, const CsDatePicker(value: '2026-03-15', disabled: true), size: csDesktopSize);
    await tester.tap(find.byType(CsButton), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(CsCalendar), findsNothing);
  });

  testWidgets('fits 390px with 2x text and without motion', (tester) async {
    await pumpCs(
      tester,
      const CsDatePicker(value: '2026-03-15', placeholder: 'YYYY/MM/DD'),
      textScale: 2,
      disableAnimations: true,
    );
    expect(tester.takeException(), isNull);
  });
}
