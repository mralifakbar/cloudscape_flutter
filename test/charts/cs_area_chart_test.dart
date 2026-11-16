import 'package:cloudscape_flutter/src/charts/charts.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';
import 'chart_test_utils.dart';

final days = [for (var i = 0; i < 5; i++) DateTime.utc(2026, 11, 1 + i)];
final inbound = CsChartSeries<DateTime>.area(
  title: 'Inbound',
  data: [for (var i = 0; i < 5; i++) CsChartDatum(days[i], 100 + i * 10)],
  valueFormatter: (y, x) => '$y GB',
);
final outbound = CsChartSeries<DateTime>.area(
  title: 'Outbound',
  data: [for (var i = 0; i < 5; i++) CsChartDatum(days[i], 50 + i * 5)],
  valueFormatter: (y, x) => '$y GB',
);
const capacity = CsChartSeries<DateTime>.threshold(title: 'Capacity', y: 260);

Widget areaChart({
  CsChartStatusType status = CsChartStatusType.finished,
  bool fitHeight = false,
  CsChartI18nStrings i18n = const CsChartI18nStrings(),
}) => CsAreaChart<DateTime>(
  series: [inbound, outbound, capacity],
  xScaleType: CsChartScaleType.time,
  height: 220,
  fitHeight: fitHeight,
  xTickFormatter: (d) => 'Nov ${d.day}',
  detailTotalFormatter: (v) => '$v GB total',
  statusType: status,
  i18nStrings: i18n,
  ariaLabel: 'Network traffic',
);

void main() {
  group('CsAreaChart', () {
    for (final brightness in Brightness.values) {
      for (final density in CsDensity.values) {
        testWidgets('renders in ${brightness.name} ${density.name}', (tester) async {
          await pumpCs(
            tester,
            SingleChildScrollView(child: areaChart()),
            brightness: brightness,
            density: density,
            size: csDesktopSize,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Inbound'), findsOneWidget);
        });
      }
    }

    testWidgets('popover lists every area and the total', (tester) async {
      await pumpCs(tester, SingleChildScrollView(child: areaChart()), size: csDesktopSize);
      await keyboardFocus(tester, plotFinder);
      expect(find.text('Nov 1'), findsOneWidget);
      expect(find.text('100 GB'), findsOneWidget);
      expect(find.text('50 GB'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('150 GB total'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('165 GB total'), findsOneWidget);
    });

    testWidgets('Up and Down focus one area and dim the other rows', (tester) async {
      CsChartSeries<DateTime>? highlighted;
      await pumpCs(
        tester,
        SingleChildScrollView(
          child: CsAreaChart<DateTime>(
            series: [inbound, outbound],
            xScaleType: CsChartScaleType.time,
            height: 200,
            onHighlightChange: (s) => highlighted = s,
          ),
        ),
        size: csDesktopSize,
      );
      await keyboardFocus(tester, plotFinder);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(highlighted, inbound);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(highlighted, outbound);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(highlighted, isNull, reason: 'back to all series');
    });

    testWidgets('custom total label', (tester) async {
      await pumpCs(
        tester,
        SingleChildScrollView(
          child: areaChart(i18n: const CsChartI18nStrings(detailTotalLabel: 'Sum')),
        ),
        size: csDesktopSize,
      );
      await keyboardFocus(tester, plotFinder);
      expect(find.text('Sum'), findsOneWidget);
    });

    testWidgets('fitHeight fills a bounded parent', (tester) async {
      await pumpCs(tester, SizedBox(height: 600, child: areaChart(fitHeight: true)), size: csDesktopSize);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(plotFinder).height, greaterThan(400));
    });

    testWidgets('loading keeps room for filter and legend', (tester) async {
      await pumpCs(tester, areaChart(status: CsChartStatusType.loading), settle: false);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Loading chart'), findsOneWidget);
    });

    testWidgets('390px, 2x text and reduced motion', (tester) async {
      await pumpCs(tester, SingleChildScrollView(child: areaChart()), textScale: 2, disableAnimations: true);
      expect(tester.takeException(), isNull);
      final plot = tester.getRect(plotFinder);
      await tester.tapAt(plot.center);
      await tester.pumpAndSettle();
      expect(find.text('Total'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
