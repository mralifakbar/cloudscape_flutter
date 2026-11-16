import 'package:cloudscape_flutter/src/charts/charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';
import 'chart_test_utils.dart';

const cost = CsChartSeries<String>.bar(
  title: 'Cost',
  data: [CsChartDatum('Jan', 1200), CsChartDatum('Feb', 1350), CsChartDatum('Mar', 980)],
);
const average = CsChartSeries<String>.line(
  title: 'Average',
  data: [CsChartDatum('Jan', 1100), CsChartDatum('Feb', 1150), CsChartDatum('Mar', 1176)],
);
const budget = CsChartSeries<String>.threshold(title: 'Budget', y: 1500);
const migration = CsChartSeries<String>.threshold(title: 'Migration', x: 'Feb');

Widget mixedChart({List<CsChartSeries<String>>? series, ValueChanged<List<CsChartSeries<String>>>? onFilterChange}) =>
    SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CsMixedLineBarChart<String>(
          series: series ?? const [cost, average, budget, migration],
          xScaleType: CsChartScaleType.categorical,
          height: 240,
          yTickFormatter: (v) => '\$$v',
          onFilterChange: onFilterChange,
          ariaLabel: 'Monthly cost',
        ),
      ),
    );

void main() {
  group('CsMixedLineBarChart', () {
    for (final brightness in Brightness.values) {
      testWidgets('renders bars, lines and thresholds in ${brightness.name}', (tester) async {
        await pumpCs(tester, mixedChart(), brightness: brightness, size: csDesktopSize);
        expect(tester.takeException(), isNull);
        for (final t in ['Cost', 'Average', 'Budget', 'Migration']) {
          expect(find.text(t), findsOneWidget);
        }
      });
    }

    testWidgets('groups include line values and matching x thresholds', (tester) async {
      await pumpCs(tester, mixedChart(), size: csDesktopSize);
      await keyboardFocus(tester, plotFinder);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('1200'), findsOneWidget);
      expect(find.text('1100'), findsOneWidget);
      expect(find.text('Migration'), findsOneWidget, reason: 'x threshold only in the legend at Jan');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Migration'), findsNWidgets(2), reason: 'legend and popover at Feb');
    });

    testWidgets('hiding the bars switches to line navigation', (tester) async {
      List<CsChartSeries<String>>? visible;
      await pumpCs(tester, mixedChart(onFilterChange: (v) => visible = v), size: csDesktopSize);
      await tester.tap(find.text('Filter data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cost').first);
      await tester.pumpAndSettle();
      expect(visible, isNot(contains(cost)));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await keyboardFocus(tester, plotFinder);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('1100'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('phone width and 2x text', (tester) async {
      await pumpCs(tester, mixedChart(), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
