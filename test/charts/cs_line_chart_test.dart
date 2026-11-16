import 'package:cloudscape_flutter/src/charts/charts.dart';
import 'package:cloudscape_flutter/src/controls/cs_checkbox.dart';
import 'package:cloudscape_flutter/src/overlays/cs_menu_parts.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';
import 'chart_test_utils.dart';

final cpuA = CsChartSeries<int>.line(
  title: 'i-0abc123',
  data: [for (var i = 0; i < 6; i++) CsChartDatum(i, 10 + i * 5)],
  valueFormatter: (y, x) => '$y%',
);
final cpuB = CsChartSeries<int>.line(
  title: 'i-0def456',
  data: [for (var i = 0; i < 6; i++) CsChartDatum(i, 50 - i * 4)],
);
const alarm = CsChartSeries<int>.threshold(title: 'Alarm', y: 45);

Widget lineChart({
  List<CsChartSeries<int>>? series,
  List<CsChartSeries<int>>? visibleSeries,
  ValueChanged<List<CsChartSeries<int>>>? onFilterChange,
  ValueChanged<CsChartSeries<int>?>? onHighlightChange,
  CsChartStatusType statusType = CsChartStatusType.finished,
  VoidCallback? onRecoveryClick,
  Widget Function(int x)? footer,
  bool hideFilter = false,
  bool hideLegend = false,
  double height = 240,
}) => SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: CsLineChart<int>(
      series: series ?? [cpuA, cpuB, alarm],
      visibleSeries: visibleSeries,
      onFilterChange: onFilterChange,
      onHighlightChange: onHighlightChange,
      statusType: statusType,
      onRecoveryClick: onRecoveryClick,
      detailPopoverFooter: footer,
      hideFilter: hideFilter,
      hideLegend: hideLegend,
      height: height,
      xTitle: 'Hour',
      yTitle: 'CPU (%)',
      xTickFormatter: (x) => 'h$x',
      ariaLabel: 'CPU utilization',
      ariaDescription: 'Two instances over six hours.',
      empty: const Text('No data available'),
      noMatch: const Text('No matching data'),
    ),
  ),
);

void main() {
  group('CsLineChart', () {
    for (final brightness in Brightness.values) {
      for (final density in CsDensity.values) {
        testWidgets('renders in ${brightness.name} ${density.name}', (tester) async {
          await pumpCs(tester, lineChart(), brightness: brightness, density: density, size: csDesktopSize);
          expect(tester.takeException(), isNull);
          expect(find.text('Filter displayed data'), findsOneWidget);
          expect(find.text('i-0abc123'), findsOneWidget);
          expect(find.text('Alarm'), findsOneWidget);
          expect(find.text('CPU (%)'), findsOneWidget);
          expect(find.text('Hour'), findsOneWidget);
        });
      }
    }

    testWidgets('hover shows a crosshair popover with every series value', (tester) async {
      await pumpCs(tester, lineChart(), size: csDesktopSize);
      final plot = tester.getRect(plotFinder);
      final g = await hover(tester, plot.center);
      // Title from xTickFormatter, values from valueFormatter and the threshold.
      expect(find.textContaining(RegExp(r'^h\d$')), findsOneWidget);
      expect(find.textContaining('%'), findsWidgets);
      expect(find.text('45'), findsOneWidget);
      // Leaving the plot closes it.
      await g.moveTo(Offset(plot.center.dx, plot.bottom + 200));
      await tester.pumpAndSettle();
      expect(find.textContaining(RegExp(r'^h\d$')), findsNothing);
      await g.removePointer();
    });

    testWidgets('keyboard: focus highlights the first x, arrows move, Enter pins, Escape dismisses', (tester) async {
      final highlights = <CsChartSeries<int>?>[];
      await pumpCs(
        tester,
        lineChart(onHighlightChange: highlights.add, footer: (x) => Text('Footer $x')),
        size: csDesktopSize,
      );
      await keyboardFocus(tester, plotFinder);
      expect(find.text('h0'), findsOneWidget);
      expect(find.text('Footer 0'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('h1'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('h5'), findsOneWidget, reason: 'wraps around');
      // Down moves to a single series and reports it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(highlights.last, cpuA);
      expect(find.text('i-0def456'), findsOneWidget, reason: 'only in the legend now');
      // Enter pins: the close button appears.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(dismissButton, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('h5'), findsNothing);
      expect(highlights.last, isNull);
    });

    testWidgets('pinned popover closes from its dismiss button', (tester) async {
      await pumpCs(tester, lineChart(), size: csDesktopSize);
      await keyboardFocus(tester, plotFinder);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.tap(dismissButton);
      await tester.pumpAndSettle();
      expect(find.text('h0'), findsNothing);
    });

    testWidgets('touch: dragging scrubs and lifting keeps the popover pinned', (tester) async {
      await pumpCs(tester, lineChart());
      final plot = tester.getRect(plotFinder);
      final g = await tester.startGesture(Offset(plot.left + 30, plot.center.dy));
      await tester.pump();
      await g.moveBy(const Offset(40, 0));
      await tester.pump();
      await g.moveBy(Offset(plot.width - 100, 0));
      await tester.pumpAndSettle();
      expect(find.text('h5'), findsOneWidget);
      await g.up();
      await tester.pumpAndSettle();
      expect(find.text('h5'), findsOneWidget);
      expect(dismissButton, findsOneWidget);
      // Tapping outside dismisses.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('h5'), findsNothing);
    });

    testWidgets('filter hides series and reports the visible ones', (tester) async {
      List<CsChartSeries<int>>? visible;
      await pumpCs(tester, lineChart(onFilterChange: (v) => visible = v), size: csDesktopSize);
      await tester.tap(find.text('Filter data'));
      await tester.pumpAndSettle();
      expect(find.byType(CsCheckboxIcon), findsNWidgets(3));
      await tester.tap(find.descendant(of: find.byType(CsMenuRow), matching: find.text('i-0def456')));
      await tester.pumpAndSettle();
      expect(visible, [cpuA, alarm]);
      // Still open (keepOpen), and the legend no longer lists it.
      expect(find.byType(CsCheckboxIcon), findsNWidgets(3));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('i-0def456'), findsNothing);
    });

    testWidgets('filter opens as a bottom sheet on phones', (tester) async {
      await pumpCs(tester, lineChart());
      await tester.tap(find.text('Filter data'));
      await tester.pumpAndSettle();
      expect(find.byType(CsCheckboxIcon), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('controlled visibleSeries and noMatch', (tester) async {
      await pumpCs(tester, lineChart(visibleSeries: const []), size: csDesktopSize);
      expect(find.text('No matching data'), findsOneWidget);
      expect(find.text('Filter displayed data'), findsOneWidget, reason: 'filter stays to recover');
      await pumpCs(tester, lineChart(visibleSeries: [cpuB]), size: csDesktopSize);
      expect(find.text('i-0abc123'), findsNothing);
      expect(find.text('i-0def456'), findsOneWidget);
    });

    testWidgets('legend highlights a series on tap and toggles it off', (tester) async {
      final highlights = <CsChartSeries<int>?>[];
      await pumpCs(tester, lineChart(onHighlightChange: highlights.add), size: csDesktopSize);
      await tester.tap(find.text('i-0def456'));
      await tester.pumpAndSettle();
      expect(highlights.last, cpuB);
      final handle = tester.ensureSemantics();
      expect(tester.getSemantics(find.text('i-0def456')), containsSemantics(isToggled: true, isButton: true));
      handle.dispose();
      await tester.tap(find.text('i-0def456'));
      await tester.pumpAndSettle();
      expect(highlights.last, isNull);
    });

    testWidgets('legend arrow keys move focus and highlight', (tester) async {
      final highlights = <CsChartSeries<int>?>[];
      await pumpCs(tester, lineChart(onHighlightChange: highlights.add, hideFilter: true), size: csDesktopSize);
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // plot
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // legend
      await tester.pumpAndSettle();
      expect(highlights.last, cpuA);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(highlights.last, cpuB);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(highlights.last, alarm, reason: 'wraps around');
    });

    testWidgets('loading and error states, recovery link', (tester) async {
      await pumpCs(tester, lineChart(statusType: CsChartStatusType.loading), settle: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Loading chart'), findsOneWidget);
      expect(find.text('Filter displayed data'), findsNothing);
      var retried = 0;
      await pumpCs(tester, lineChart(statusType: CsChartStatusType.error, onRecoveryClick: () => retried++));
      expect(find.text("The data couldn't be fetched. Try again later."), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });

    testWidgets('empty state', (tester) async {
      await pumpCs(tester, lineChart(series: const []));
      expect(find.text('No data available'), findsOneWidget);
      expect(find.text('Filter displayed data'), findsNothing);
    });

    testWidgets('semantics: label, role, summary and active value', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCs(tester, lineChart(), size: csDesktopSize);
      final node = tester.getSemantics(plotFinder);
      expect(node.label, 'CPU utilization, Line chart');
      expect(node.hint, contains('Two instances over six hours.'));
      expect(node.hint, contains('3 series: i-0abc123, i-0def456, Alarm'));
      await keyboardFocus(tester, plotFinder);
      final active = tester.getSemantics(plotFinder);
      expect(active.value, startsWith('h0, i-0abc123 10%'));
      expect(active.increasedValue, startsWith('h1'));
      handle.dispose();
    });

    testWidgets('reduced motion renders at once', (tester) async {
      await pumpCs(tester, lineChart(), disableAnimations: true, settle: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('390px and 2x text do not overflow', (tester) async {
      await pumpCs(tester, lineChart(), textScale: 2);
      expect(tester.takeException(), isNull);
      await keyboardFocus(tester, plotFinder);
      expect(tester.takeException(), isNull);
    });

    testWidgets('time and log scales', (tester) async {
      final t = CsChartSeries<DateTime>.line(
        title: 'Requests',
        data: [for (var i = 0; i < 8; i++) CsChartDatum(DateTime(2026, 11, 1 + i), 10 * (i + 1) * (i + 1))],
      );
      await pumpCs(
        tester,
        CsLineChart<DateTime>(
          series: [t],
          xScaleType: CsChartScaleType.time,
          yScaleType: CsChartYScaleType.log,
          height: 200,
        ),
        size: csDesktopSize,
      );
      expect(tester.takeException(), isNull);
      await keyboardFocus(tester, plotFinder);
      expect(find.text('Nov 1'), findsOneWidget);
    });
  });
}
