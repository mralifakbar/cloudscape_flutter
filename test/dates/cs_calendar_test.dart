import 'package:clock/clock.dart';
import 'package:cloudscape_flutter/src/dates/cs_dates_internal.dart';
import 'package:cloudscape_flutter/src/dates/dates.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

final _today = DateTime(2026, 3, 10);

Future<void> _withToday(Future<void> Function() body) => withClock(Clock.fixed(_today), body);

class _Host extends StatefulWidget {
  const _Host({this.initial = '', this.onChange, this.builder});

  final String initial;
  final ValueChanged<String>? onChange;
  final Widget Function(String value, ValueChanged<String> onChange)? builder;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String value = widget.initial;

  void _set(String v) {
    setState(() => value = v);
    widget.onChange?.call(v);
  }

  @override
  Widget build(BuildContext context) => widget.builder?.call(value, _set) ?? CsCalendar(value: value, onChange: _set);
}

void main() {
  testWidgets('renders day and month calendars in light, dark and compact', (tester) async {
    await _withToday(() async {
      for (final b in Brightness.values) {
        for (final d in CsDensity.values) {
          for (final g in CsDateGranularity.values) {
            await pumpCs(
              tester,
              CsCalendar(
                value: g == CsDateGranularity.day ? '2026-03-15' : '2026-03',
                granularity: g,
                onChange: (_) {},
              ),
              brightness: b,
              density: d,
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
      expect(find.text('2026'), findsOneWidget);
    });
  });

  testWidgets('shows the month of the value with six weeks and weekday headings', (tester) async {
    await _withToday(() async {
      await pumpCs(tester, CsCalendar(value: '2026-03-15', onChange: (_) {}));
      expect(find.text('March 2026'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(find.byType(CsCalendarCell), findsNWidgets(42));
    });
  });

  testWidgets('tapping a day calls onChange with an ISO date', (tester) async {
    await _withToday(() async {
      final picked = <String>[];
      await pumpCs(tester, _Host(initial: '2026-03-15', onChange: picked.add));
      await tester.tap(find.text('20'));
      await tester.pump();
      expect(picked, ['2026-03-20']);
    });
  });

  testWidgets('selected day and today are exposed to screen readers', (tester) async {
    await _withToday(() async {
      final handle = tester.ensureSemantics();
      await pumpCs(tester, CsCalendar(value: '2026-03-15', onChange: (_) {}));
      expect(
        tester.getSemantics(find.bySemanticsLabel('March 15, 2026')),
        matchesSemantics(
          label: 'March 15, 2026',
          isSelected: true,
          hasSelectedState: true,
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      expect(find.bySemanticsLabel('March 10, 2026. Today'), findsOneWidget);
      expect(find.bySemanticsLabel('Previous month'), findsOneWidget);
      expect(find.bySemanticsLabel('Next month'), findsOneWidget);
      handle.dispose();
    });
  });

  testWidgets('previous and next buttons change the month', (tester) async {
    await _withToday(() async {
      await pumpCs(tester, CsCalendar(value: '2026-03-15', onChange: (_) {}));
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('April 2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('February 2026'), findsOneWidget);
    });
  });

  testWidgets('follows the controlled value to another month', (tester) async {
    await _withToday(() async {
      await pumpCs(tester, CsCalendar(value: '2026-03-15', onChange: (_) {}));
      await pumpCs(tester, CsCalendar(value: '2026-07-04', onChange: (_) {}));
      expect(find.text('July 2026'), findsOneWidget);
    });
  });

  testWidgets('keyboard moves focus by day, week and month and picks with Enter', (tester) async {
    await _withToday(() async {
      final picked = <String>[];
      await pumpCs(
        tester,
        _Host(
          initial: '2026-03-15',
          onChange: picked.add,
          builder: (v, set) => CsCalendar(value: v, onChange: set, autofocus: true),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked.last, '2026-03-16');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(picked.last, '2026-03-23');

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(find.text('April 2026'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked.last, '2026-04-23');

      // Home goes to Sunday of that week, End to Saturday.
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked.last, '2026-04-19');
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked.last, '2026-04-25');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked.last, '2026-03-17');
    });
  });

  testWidgets('disabled days can not be picked and are skipped by arrows', (tester) async {
    await _withToday(() async {
      final picked = <String>[];
      bool weekday(DateTime d) => d.weekday != DateTime.saturday && d.weekday != DateTime.sunday;
      await pumpCs(
        tester,
        _Host(
          initial: '2026-03-13',
          onChange: picked.add,
          builder: (v, set) => CsCalendar(value: v, onChange: set, isDateEnabled: weekday, autofocus: true),
        ),
      );
      await tester.tap(find.text('14'));
      await tester.pump();
      expect(picked, isEmpty);
      await tester.pump();
      // Friday 13 -> skips the weekend to Monday 16.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked, ['2026-03-16']);
    });
  });

  testWidgets('a disabled reason keeps the day focusable and describes it', (tester) async {
    await _withToday(() async {
      final handle = tester.ensureSemantics();
      await pumpCs(
        tester,
        CsCalendar(
          value: '',
          onChange: (_) {},
          isDateEnabled: (d) => d.day != 20,
          dateDisabledReason: (d) => 'Maintenance window',
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('March 20, 2026'));
      expect(node.hint, 'Maintenance window');
      expect(node.getSemanticsData().hasAction(SemanticsAction.focus), isTrue);
      handle.dispose();
    });
  });

  testWidgets('month granularity picks a YYYY-MM value and pages by year', (tester) async {
    await _withToday(() async {
      final picked = <String>[];
      await pumpCs(
        tester,
        _Host(
          initial: '2026-03',
          onChange: picked.add,
          builder: (v, set) => CsCalendar(value: v, onChange: set, granularity: CsDateGranularity.month),
        ),
      );
      expect(find.text('2026'), findsOneWidget);
      expect(find.bySemanticsLabel('March 2026. Current month'), findsOneWidget);
      await tester.tap(find.text('Jun'));
      await tester.pump();
      expect(picked, ['2026-06']);
      await tester.tap(find.bySemanticsLabel('Next year'));
      await tester.pumpAndSettle();
      expect(find.text('2027'), findsOneWidget);
    });
  });

  testWidgets('startOfWeek and i18nStrings change headings and labels', (tester) async {
    await _withToday(() async {
      await pumpCs(
        tester,
        CsCalendar(
          value: '2026-03-15',
          startOfWeek: 1,
          onChange: (_) {},
          i18nStrings: const CsCalendarI18nStrings(nextMonthAriaLabel: 'Bulan berikutnya', todayAriaLabel: 'Hari ini'),
        ),
      );
      final first = tester.getTopLeft(find.text('Mon')).dx;
      expect(first, lessThan(tester.getTopLeft(find.text('Sun')).dx));
      expect(find.bySemanticsLabel('Bulan berikutnya'), findsOneWidget);
      expect(find.bySemanticsLabel('March 10, 2026. Hari ini'), findsOneWidget);
    });
  });

  testWidgets('a swipe changes the month on touch', (tester) async {
    await _withToday(() async {
      await pumpCs(tester, CsCalendar(value: '2026-03-15', onChange: (_) {}));
      await tester.fling(find.text('18'), const Offset(-200, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('April 2026'), findsOneWidget);
    });
  });

  testWidgets('fits 390px with 2x text, stretches when asked, and works without motion', (tester) async {
    await _withToday(() async {
      await pumpCs(tester, CsCalendar(value: '2026-03-15', onChange: (_) {}), textScale: 2);
      expect(tester.takeException(), isNull);
      await pumpCs(
        tester,
        SizedBox(
          width: 360,
          child: CsCalendar(value: '2026-03-15', stretch: true, onChange: (_) {}),
        ),
        disableAnimations: true,
      );
      expect(tester.getSize(find.byType(CsCalendar)).width, 360);
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      expect(find.text('April 2026'), findsOneWidget);
    });
  });
}
