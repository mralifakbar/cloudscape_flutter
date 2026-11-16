import 'package:cloudscape_flutter/src/charts/charts.dart';
import 'package:cloudscape_flutter/src/charts/internal/chart_math.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsChartColors', () {
    test('assigns the categorical palette in order, skipping thresholds and own colors', () {
      final theme = CsThemeData.light();
      const own = Color(0xFF123456);
      final series = <CsChartSeries<int>>[
        const CsChartSeries.line(title: 'a', data: []),
        const CsChartSeries.threshold(title: 't', y: 1),
        const CsChartSeries.line(title: 'b', data: [], color: own),
        const CsChartSeries.line(title: 'c', data: [], colorToken: CsColor.chartsStatusHigh),
        const CsChartSeries.line(title: 'd', data: []),
      ];
      final colors = CsChartColors.resolve<CsChartSeries<int>>(
        theme,
        series,
        isThreshold: (s) => s.isThreshold,
        ownColor: (s) => s.color ?? (s.colorToken == null ? null : theme.color(s.colorToken!)),
      );
      expect(colors[0], theme.color(CsColor.chartsPaletteCategorical1));
      expect(colors[1], theme.color(CsColor.chartsThresholdNeutral));
      expect(colors[2], own);
      expect(colors[3], theme.color(CsColor.chartsStatusHigh));
      expect(colors[4], theme.color(CsColor.chartsPaletteCategorical2));
      expect(CsChartColors.categorical, hasLength(50));
      expect(CsChartColors.at(theme, 50), theme.color(CsColor.chartsPaletteCategorical1));
    });

    test('dark mode resolves the dark palette', () {
      final light = CsThemeData.light();
      final dark = CsThemeData.dark();
      expect(CsChartColors.at(light, 0), isNot(CsChartColors.at(dark, 0)));
    });
  });

  group('CsChartSeries', () {
    test('threshold kinds', () {
      const y = CsChartSeries<String>.threshold(title: 'Limit', y: 10);
      const x = CsChartSeries<String>.threshold(title: 'Deploy', x: 'Feb');
      expect(y.isYThreshold, isTrue);
      expect(x.isXThreshold, isTrue);
      expect(y.type, CsChartSeriesType.threshold);
      expect(const CsChartDatum('a', 1), const CsChartDatum('a', 1));
    });

    test('popover sizes match Cloudscape', () {
      expect(CsChartPopoverSize.small.maxWidth, 210);
      expect(CsChartPopoverSize.medium.maxWidth, 310);
      expect(CsChartPopoverSize.large.maxWidth, 482);
    });
  });

  group('chart math', () {
    test('d3 ticks and nice domains', () {
      expect(niceTicks(0, 10, 5), [0, 2, 4, 6, 8, 10]);
      expect(niceTicks(0, 1, 5), [0, 0.2, 0.4, 0.6, 0.8, 1]);
      expect(niceDomain(3, 97, 5), (0, 100));
      expect(niceDomain(-12, 88, 4), (-20, 100));
    });

    test('log ticks', () {
      expect(logTicks(1, 1000, 4), [1, 10, 100, 1000]);
      expect(niceLogDomain(3, 420), (1, 1000));
    });

    test('time ticks fall on calendar days', () {
      final ticks = timeTicks(DateTime(2026, 11, 1), DateTime(2026, 11, 8), 7);
      expect(ticks.first, DateTime(2026, 11, 1));
      expect(ticks.every((t) => t.hour == 0), isTrue);
    });

    test('number formatting removes float noise', () {
      expect(formatChartNumber(0.1 + 0.2), '0.3');
      expect(formatChartNumber(12.0), '12');
      expect(formatChartNumber(1500), '1500');
    });

    test('band scale paddings', () {
      final bars = BandScale(count: 4, r0: 0, r1: 400, linesOnly: false);
      final lines = BandScale(count: 4, r0: 0, r1: 400, linesOnly: true);
      expect(bars.bandwidth, greaterThan(lines.bandwidth));
      expect(lines(0), 0, reason: 'no outer padding for lines');
    });

    test('label collisions drop every other label', () {
      final ticks = [
        for (var i = 0; i < 10; i++) FormattedTick(i * 20.0, ['label'], 30),
      ];
      final visible = visibleTicks(ticks, -100, 1000, balance: true);
      expect(visible.length, lessThan(10));
      expect(visible.first.position, 0);
    });
  });
}
