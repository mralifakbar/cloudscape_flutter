import 'package:cloudscape_flutter/src/charts/charts.dart';
import 'package:cloudscape_flutter/src/system/cs_pressable.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';
import 'chart_test_utils.dart';

const site1 = CsChartSeries<String>.bar(
  title: 'Site 1',
  data: [CsChartDatum('Jan', 120), CsChartDatum('Feb', 80), CsChartDatum('Mar', 140)],
);
const site2 = CsChartSeries<String>.bar(
  title: 'Site 2',
  data: [CsChartDatum('Jan', 60), CsChartDatum('Feb', -20), CsChartDatum('Mar', 90)],
);
const target = CsChartSeries<String>.threshold(title: 'Target', y: 150);

Widget barChart({
  bool stacked = false,
  bool horizontal = false,
  CsChartDetailPopoverSeriesContent<String>? seriesContent,
  CsChartPopoverSize size = CsChartPopoverSize.medium,
}) => SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: CsBarChart<String>(
      series: const [site1, site2, target],
      stackedBars: stacked,
      horizontalBars: horizontal,
      height: 240,
      detailPopoverSize: size,
      detailPopoverSeriesContent: seriesContent,
      ariaLabel: 'Requests',
    ),
  ),
);

void main() {
  group('CsBarChart', () {
    for (final brightness in Brightness.values) {
      testWidgets('renders grouped, stacked and horizontal in ${brightness.name}', (tester) async {
        for (final (stacked, horizontal) in [(false, false), (true, false), (false, true), (true, true)]) {
          await pumpCs(
            tester,
            barChart(stacked: stacked, horizontal: horizontal),
            brightness: brightness,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Site 1'), findsOneWidget);
        }
      });
    }

    testWidgets('compact density', (tester) async {
      await pumpCs(tester, barChart(), density: CsDensity.compact, size: csDesktopSize);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hovering a group shows all its bars and the threshold', (tester) async {
      await pumpCs(tester, barChart(), size: csDesktopSize);
      final plot = tester.getRect(plotFinder);
      // The middle third of the plot is the "Feb" group.
      final g = await hover(tester, Offset(plot.left + plot.width / 2, plot.center.dy));
      expect(find.text('Feb'), findsOneWidget);
      expect(find.text('80'), findsOneWidget);
      expect(find.text('-20'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      // A click pins the popover, a second click dismisses it.
      await tester.tapAt(Offset(plot.left + plot.width / 2, plot.center.dy), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(dismissButton, findsOneWidget);
      await tester.tapAt(Offset(plot.left + plot.width / 2, plot.center.dy), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(find.text('Feb'), findsNothing);
      await g.removePointer();
    });

    testWidgets('keyboard moves between groups; Up and Down for horizontal bars', (tester) async {
      await pumpCs(tester, barChart(), size: csDesktopSize);
      await keyboardFocus(tester, plotFinder);
      expect(find.text('Jan'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Feb'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(find.text('Mar'), findsOneWidget);

      await pumpCs(tester, const SizedBox());
      await pumpCs(tester, barChart(horizontal: true), size: csDesktopSize);
      await keyboardFocus(tester, plotFinder);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Feb'), findsOneWidget);
    });

    testWidgets('tap on a phone highlights the group under the finger', (tester) async {
      await pumpCs(tester, barChart(stacked: true));
      final plot = tester.getRect(plotFinder);
      await tester.tapAt(Offset(plot.right - 20, plot.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('Mar'), findsOneWidget);
      expect(dismissButton, findsOneWidget);
    });

    testWidgets('detailPopoverSeriesContent: custom value and expandable breakdown', (tester) async {
      await pumpCs(
        tester,
        barChart(
          size: CsChartPopoverSize.large,
          seriesContent: (series, x, y) => series == site1
              ? CsChartSeriesDetail(
                  value: '$y requests',
                  expandable: true,
                  subItems: const [
                    CsChartDetailPair(key: 'GET', value: '70'),
                    CsChartDetailPair(key: 'PUT', value: '50'),
                  ],
                )
              : const CsChartSeriesDetail(),
        ),
        size: csDesktopSize,
      );
      await keyboardFocus(tester, plotFinder);
      expect(find.text('120 requests'), findsOneWidget);
      expect(find.text('GET'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((w) => w is CsPressable && w.semanticLabel == 'Site 1, Expand'));
      await tester.pumpAndSettle();
      expect(find.text('GET'), findsOneWidget);
      expect(find.text('PUT'), findsOneWidget);
    });

    testWidgets('390px and 2x text do not overflow', (tester) async {
      await pumpCs(tester, barChart(horizontal: true), textScale: 2);
      expect(tester.takeException(), isNull);
      await keyboardFocus(tester, plotFinder);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion', (tester) async {
      await pumpCs(tester, barChart(), disableAnimations: true, settle: false);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('semantics name the chart kind', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCs(tester, barChart(), size: csDesktopSize);
      final node = tester.getSemantics(plotFinder);
      expect(node.label, 'Requests, Bar chart');
      expect(node.hint, contains('x-axis: Jan, Feb, Mar'));
      handle.dispose();
    });
  });
}
