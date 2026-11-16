// Geometry of a cartesian chart for one size: scales, ticks, scaled points,
// bars and areas. A port of Cloudscape's mixed-line-bar-chart and
// area-chart models (domain.ts, make-scaled-series.ts,
// make-scaled-bar-groups.ts, bar-series.tsx, area-chart/model).
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../system/cs_strings.dart';
import '../cs_chart_series.dart';
import 'chart_math.dart';

/// A series with its resolved color and its index in the full list.
class ResolvedSeries<T> {
  ResolvedSeries(this.series, this.color, this.index);

  final CsChartSeries<T> series;
  final Color color;
  final int index;
}

/// A data point in plot coordinates.
class ScaledPoint<T> {
  ScaledPoint(this.position, this.x, this.y, this.series, this.color);

  final Offset position;
  final T x;
  final num y;
  final CsChartSeries<T> series;
  final Color color;
}

/// A bar in plot coordinates with the corners Cloudscape rounds.
class ScaledBar<T> {
  ScaledBar(this.rect, this.radius, this.series, this.color, this.category, this.datum);

  final Rect rect;
  final BorderRadius radius;
  final CsChartSeries<T> series;
  final Color color;
  final int category;
  final CsChartDatum<T> datum;
}

/// A stacked area: its outline (the top edge) and filled band.
class ScaledArea<T> {
  ScaledArea(this.fill, this.line, this.series, this.color);

  final Path fill;
  final Path line;
  final CsChartSeries<T> series;
  final Color color;
}

/// A position the keyboard and pointer can move between: a category (bar
/// groups) or a distinct x value (lines and areas).
class NavX<T> {
  NavX(this.value, this.position, {this.category});

  final T value;

  /// Pixel position along the category axis (center of a band).
  final double position;
  final int? category;
}

/// How the chart is laid out and what it shows.
class CartesianConfig<T> {
  CartesianConfig({
    required this.series,
    required this.visible,
    required this.xScaleType,
    required this.yScaleType,
    required this.xDomain,
    required this.yDomain,
    required this.stackedBars,
    required this.horizontalBars,
    required this.stackedAreas,
    required this.xTickFormatter,
    required this.yTickFormatter,
    required this.strings,
    required this.tickStyle,
    required this.textScaler,
  });

  final List<ResolvedSeries<T>> series;
  final List<ResolvedSeries<T>> visible;
  final CsChartScaleType xScaleType;
  final CsChartYScaleType yScaleType;
  final List<T>? xDomain;
  final List<num>? yDomain;
  final bool stackedBars;
  final bool horizontalBars;
  final bool stackedAreas;
  final CsChartTickFormatter<T>? xTickFormatter;
  final CsChartTickFormatter<num>? yTickFormatter;
  final CsStrings strings;
  final TextStyle tickStyle;
  final TextScaler textScaler;
}

const double kTickLength = 8;
const double kTickMargin = 4;
const double kTickLineHeight = 16;
const double _kInlineStartGap = kTickLength + kTickMargin;

/// [v] as the chart's x type: a tick value of `2.0` is `2` on an `int` axis.
T? coerceX<T>(Object v) {
  if (v is T) return v as T;
  if (v is num) {
    final i = v.round();
    if (i == v && i is T) return i as T;
    final d = v.toDouble();
    if (d is T) return d as T;
  }
  return null;
}

double xNumber(Object? x) => switch (x) {
  final num n => n.toDouble(),
  final DateTime d => d.millisecondsSinceEpoch.toDouble(),
  _ => double.nan,
};

/// Every derived position for one chart size.
class CartesianModel<T> {
  CartesianModel._({
    required this.config,
    required this.size,
    required this.plot,
    required this.categories,
    required this.band,
    required this.xScale,
    required this.valueScale,
    required this.valueTicks,
    required this.leftTicks,
    required this.bottomTicks,
    required this.points,
    required this.bars,
    required this.areas,
    required this.navigation,
    required this.groupNavigation,
    required this.linesOnly,
    required this.xSpanMs,
    required this.valueDomain,
  });

  final CartesianConfig<T> config;

  /// The painted canvas: the plot plus the bottom labels.
  final Size size;
  final Rect plot;

  /// Category domain of a categorical x axis, else empty.
  final List<T> categories;
  final BandScale? band;
  final ContinuousScale? xScale;
  final ContinuousScale valueScale;
  final List<double> valueTicks;
  final List<FormattedTick> leftTicks;
  final List<FormattedTick> bottomTicks;

  /// Points of line and area series (areas: the top of each band).
  final List<ScaledPoint<T>> points;
  final List<ScaledBar<T>> bars;
  final List<ScaledArea<T>> areas;
  final List<NavX<T>> navigation;

  /// True when bars are visible: navigation moves between bar groups.
  final bool groupNavigation;
  final bool linesOnly;
  final double xSpanMs;
  final (double, double) valueDomain;

  bool get horizontal => config.horizontalBars;
  bool get categorical => band != null;

  /// Center of [x] along the category axis, or NaN when off the axis.
  double categoryPosition(T x) {
    final b = band;
    if (b != null) {
      final i = categories.indexOf(x);
      if (i < 0) return double.nan;
      return (horizontal ? plot.top : plot.left) + b(i) + math.max(0, b.bandwidth - 1) / 2;
    }
    return xScale!(xNumber(x));
  }

  /// The band of category [i] across the plot (a bar group's hit area).
  Rect groupRect(int i) {
    final b = band!;
    final start = b(i);
    return horizontal
        ? Rect.fromLTWH(plot.left, plot.top + start, plot.width, b.bandwidth)
        : Rect.fromLTWH(plot.left + start, plot.top, b.bandwidth, plot.height);
  }

  /// Value of a y threshold in plot coordinates.
  double valuePosition(num v) => valueScale(v.toDouble());

  String formatX(T x) {
    final f = config.xTickFormatter;
    if (f != null) return f(x);
    if (x is DateTime) return formatChartTime(x, config.strings, spanMs: xSpanMs);
    if (x is num) return formatChartNumber(x);
    return '$x';
  }

  String formatY(num y) => config.yTickFormatter?.call(y) ?? formatChartNumber(y);

  static bool matchesX(Object? a, Object? b) => a == b;

  static CartesianModel<T> build<T>(CartesianConfig<T> c, double width, double plotHeight) {
    final all = c.series.map((s) => s.series).toList();
    final categorical = c.xScaleType == CsChartScaleType.categorical;
    final linesOnly = all.every((s) => s.type == CsChartSeriesType.line || s.isThreshold);
    final visibleBars = c.visible.where((s) => s.series.type == CsChartSeriesType.bar).toList();
    final groupNavigation = categorical && visibleBars.isNotEmpty;

    // X domain from every series, so filtering never rescales the axis.
    final categories = <T>[];
    var xMin = double.infinity;
    var xMax = double.negativeInfinity;
    T? xMinValue;
    T? xMaxValue;
    if (categorical) {
      if (c.xDomain != null) {
        categories.addAll(c.xDomain!);
      } else {
        for (final s in all) {
          for (final d in s.data) {
            if (!categories.contains(d.x)) categories.add(d.x);
          }
          if (s.isXThreshold && !categories.contains(s.x as T)) categories.add(s.x as T);
        }
      }
    } else if (c.xDomain != null && c.xDomain!.length >= 2) {
      xMinValue = c.xDomain!.first;
      xMaxValue = c.xDomain!.last;
      xMin = xNumber(xMinValue);
      xMax = xNumber(xMaxValue);
    } else {
      void take(T x) {
        final v = xNumber(x);
        if (!v.isFinite) return;
        if (v < xMin) {
          xMin = v;
          xMinValue = x;
        }
        if (v > xMax) {
          xMax = v;
          xMaxValue = x;
        }
      }

      for (final s in all) {
        for (final d in s.data) {
          take(d.x);
        }
        if (s.isXThreshold) take(s.x as T);
      }
      if (!xMin.isFinite) {
        xMin = 0;
        xMax = 1;
      }
    }
    final isTime = c.xScaleType == CsChartScaleType.time || xMinValue is DateTime;

    // Y domain: starts at [0, 0], takes thresholds and data (stacked sums
    // for stacked bars and areas).
    var lo = 0.0;
    var hi = 0.0;
    void takeY(num v) {
      final d = v.toDouble();
      if (!d.isFinite) return;
      lo = math.min(lo, d);
      hi = math.max(hi, d);
    }

    if (c.yDomain != null && c.yDomain!.length >= 2) {
      lo = c.yDomain!.first.toDouble();
      hi = c.yDomain!.last.toDouble();
    } else {
      final pos = <Object?, double>{};
      final neg = <Object?, double>{};
      final areaSums = <Object?, double>{};
      for (final s in all) {
        if (s.isYThreshold) takeY(s.y!);
        if (s.type == CsChartSeriesType.bar && c.stackedBars) {
          for (final d in s.data) {
            final m = d.y < 0 ? neg : pos;
            m[d.x] = (m[d.x] ?? 0) + d.y;
          }
        } else if (s.type == CsChartSeriesType.area && c.stackedAreas) {
          for (final d in s.data) {
            areaSums[d.x] = (areaSums[d.x] ?? 0) + d.y;
            takeY(areaSums[d.x]!);
            takeY(d.y);
          }
        } else {
          for (final d in s.data) {
            takeY(d.y);
          }
        }
      }
      pos.values.forEach(takeY);
      neg.values.forEach(takeY);
      if (c.yScaleType == CsChartYScaleType.log && lo <= 0 && hi > 1) lo = 1;
    }
    final log = c.yScaleType == CsChartYScaleType.log;
    if (log && lo <= 0) lo = math.min(1, hi <= 0 ? 1 : hi / 10);
    if (log && hi <= lo) hi = lo * 10;
    final explicitY = c.yDomain != null && c.yDomain!.length >= 2;

    final scaler = c.textScaler;
    final lineHeight = scaler.scale(kTickLineHeight);
    TextPainter measure(String s) => TextPainter(
      text: TextSpan(text: s, style: c.tickStyle),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    double widthOf(List<String> lines) => lines.map((l) => measure(l).width).fold(0.0, math.max);

    // Value axis ticks for a given length (px) of the value axis.
    (ContinuousScale, List<double>, (double, double)) valueAxis(double length, double r0, double r1) {
      final count = yTickCount(length);
      var d0 = lo;
      var d1 = hi;
      if (!explicitY) {
        if (log) {
          (d0, d1) = niceLogDomain(d0, d1);
        } else {
          if (d0 == d1) d1 = d0 + 1;
          (d0, d1) = niceDomain(d0, d1, count);
        }
      }
      final scale = ContinuousScale(d0: d0, d1: d1, r0: r0, r1: r1, log: log);
      final ticks = log ? logTicks(d0, d1, count) : niceTicks(d0, d1, count);
      return (scale, ticks, (d0, d1));
    }

    String fmtX(T x) {
      final f = c.xTickFormatter;
      if (f != null) return f(x);
      if (x is DateTime) return formatChartTime(x, c.strings, spanMs: xMax - xMin);
      if (x is num) return formatChartNumber(x);
      return '$x';
    }

    String fmtY(num y) => c.yTickFormatter?.call(y) ?? formatChartNumber(y);

    final maxLabelWidth = (width / 2).roundToDouble();
    late Rect plot;
    late ContinuousScale valueScale;
    late List<double> valueTicks;
    late (double, double) valueDomain;
    BandScale? band;
    ContinuousScale? xScale;
    final leftTicks = <FormattedTick>[];
    final bottomTicks = <FormattedTick>[];

    if (!c.horizontalBars) {
      final (vs, vt, vd) = valueAxis(plotHeight, plotHeight, 0);
      valueScale = vs;
      valueTicks = vt;
      valueDomain = vd;
      final labels = [for (final t in vt) fmtY(t).split('\n')];
      var labelsWidth = 0.0;
      for (final l in labels) {
        labelsWidth = math.max(labelsWidth, widthOf(l));
      }
      labelsWidth = math.min(labelsWidth, maxLabelWidth);
      final left = labelsWidth + _kInlineStartGap;
      final plotWidth = math.max(0.0, width - labelsWidth - _kInlineStartGap - kTickMargin);
      plot = Rect.fromLTWH(left, 0, plotWidth, plotHeight);
      valueScale = ContinuousScale(d0: vs.d0, d1: vs.d1, r0: plotHeight, r1: 0, log: log);
      for (var i = 0; i < vt.length; i++) {
        leftTicks.add(FormattedTick(valueScale(vt[i]), labels[i], labels[i].length * lineHeight, value: vt[i]));
      }
      // X axis along the bottom.
      if (categorical) {
        band = BandScale(count: categories.length, r0: 0, r1: plotWidth, linesOnly: linesOnly);
        for (var i = 0; i < categories.length; i++) {
          final lines = fmtX(categories[i]).split('\n');
          bottomTicks.add(
            FormattedTick(
              left + band(i) + math.max(0, band.bandwidth - 1) / 2,
              lines,
              widthOf(lines),
              value: categories[i],
            ),
          );
        }
      } else {
        xScale = ContinuousScale(
          d0: xMin,
          d1: xMax,
          r0: left,
          r1: left + plotWidth,
          log: c.xScaleType == CsChartScaleType.log,
        );
        final count = xTickCount(plotWidth);
        final List<Object> raw;
        if (isTime) {
          raw = timeTicks(
            DateTime.fromMillisecondsSinceEpoch(xMin.round(), isUtc: (xMinValue as DateTime?)?.isUtc ?? false),
            DateTime.fromMillisecondsSinceEpoch(xMax.round(), isUtc: (xMinValue as DateTime?)?.isUtc ?? false),
            count,
          );
        } else if (c.xScaleType == CsChartScaleType.log) {
          raw = logTicks(xMin, xMax, count);
        } else {
          raw = niceTicks(xMin, xMax, count);
        }
        for (final t in raw) {
          final asT = coerceX<T>(t);
          final String label;
          if (asT != null && c.xTickFormatter != null) {
            label = c.xTickFormatter!(asT);
          } else if (t is DateTime) {
            label = formatChartTime(t, c.strings, spanMs: xMax - xMin);
          } else {
            label = formatChartNumber(t as num);
          }
          final lines = label.split('\n');
          bottomTicks.add(FormattedTick(xScale(xNumber(t)), lines, widthOf(lines), value: t));
        }
      }
    } else {
      // Horizontal bars: categories down the left, values along the bottom.
      final labels = [for (final cat in categories) fmtX(cat).split('\n')];
      var labelsWidth = 0.0;
      for (final l in labels) {
        labelsWidth = math.max(labelsWidth, widthOf(l));
      }
      labelsWidth = math.min(labelsWidth, maxLabelWidth);
      final left = labelsWidth + _kInlineStartGap;
      final plotWidth = math.max(0.0, width - labelsWidth - _kInlineStartGap - kTickMargin);
      plot = Rect.fromLTWH(left, 0, plotWidth, plotHeight);
      band = BandScale(count: categories.length, r0: 0, r1: plotHeight, linesOnly: false);
      for (var i = 0; i < categories.length; i++) {
        leftTicks.add(
          FormattedTick(
            band(i) + math.max(0, band.bandwidth - 1) / 2,
            labels[i],
            labels[i].length * lineHeight,
            value: categories[i],
          ),
        );
      }
      final (vs, vt, vd) = valueAxis(plotWidth, left, left + plotWidth);
      valueScale = vs;
      valueTicks = vt;
      valueDomain = vd;
      for (final t in vt) {
        final lines = fmtY(t).split('\n');
        bottomTicks.add(FormattedTick(valueScale(t), lines, widthOf(lines), value: t));
      }
    }

    var maxLines = 0;
    for (final t in bottomTicks) {
      maxLines = math.max(maxLines, t.lines.length);
    }
    final bottomHeight = kTickLength + kTickMargin + maxLines * lineHeight;
    final size = Size(width, plotHeight + bottomHeight);

    final visibleLeft = visibleTicks(leftTicks, -kTickLength, plotHeight + kTickLength);
    final visibleBottom = visibleTicks(
      bottomTicks,
      0,
      // Cloudscape lets the last label run 12px past the plot.
      plot.right + _kInlineStartGap,
      balance: !c.horizontalBars && c.xScaleType != CsChartScaleType.log,
    );

    final model = CartesianModel<T>._(
      config: c,
      size: size,
      plot: plot,
      categories: categories,
      band: band,
      xScale: xScale,
      valueScale: valueScale,
      valueTicks: valueTicks,
      leftTicks: visibleLeft,
      bottomTicks: visibleBottom,
      points: [],
      bars: [],
      areas: [],
      navigation: [],
      groupNavigation: groupNavigation,
      linesOnly: linesOnly,
      xSpanMs: xMax - xMin,
      valueDomain: valueDomain,
    );
    model._scaleSeries(visibleBars);
    return model;
  }

  void _scaleSeries(List<ResolvedSeries<T>> visibleBars) {
    final c = config;
    // Lines and points.
    for (final r in c.visible) {
      final s = r.series;
      if (s.type == CsChartSeriesType.line) {
        for (final d in s.data) {
          final cx = categoryPosition(d.x);
          if (!cx.isFinite) continue;
          final y = valuePosition(d.y);
          points.add(ScaledPoint(Offset(cx, y), d.x, d.y, s, r.color));
        }
      }
    }

    // Stacked areas share the x values of the first area series.
    final areaSeries = c.visible.where((r) => r.series.type == CsChartSeriesType.area).toList();
    if (areaSeries.isNotEmpty) {
      final xs = <T>[];
      for (final r in c.series.where((r) => r.series.type == CsChartSeriesType.area)) {
        for (final d in r.series.data) {
          if (!xs.any((x) => matchesX(x, d.x))) xs.add(d.x);
        }
      }
      final cum = List<double>.filled(xs.length, 0);
      for (final r in areaSeries) {
        final top = <Offset>[];
        final bottom = <Offset>[];
        for (var i = 0; i < xs.length; i++) {
          final d = r.series.data.where((d) => matchesX(d.x, xs[i])).firstOrNull;
          final y = d?.y.toDouble() ?? 0;
          final px = categoryPosition(xs[i]);
          if (!px.isFinite) continue;
          final y0 = c.stackedAreas ? cum[i] : 0.0;
          final y1 = y0 + y;
          if (c.stackedAreas) cum[i] = y1;
          bottom.add(Offset(px, valuePosition(y0)));
          top.add(Offset(px, valuePosition(y1)));
          if (d != null) points.add(ScaledPoint(Offset(px, valuePosition(y1)), xs[i], d.y, r.series, r.color));
        }
        if (top.isEmpty) continue;
        final line = Path()..addPolygon(top, false);
        final fill = Path()..addPolygon([...top, ...bottom.reversed], true);
        areas.add(ScaledArea(fill, line, r.series, r.color));
      }
    }

    // Bars.
    final b = band;
    if (b != null && visibleBars.isNotEmpty) {
      final stacked = c.stackedBars;
      final n = visibleBars.length;
      const padding = 4.0;
      const minWidth = 4.0;
      var barWidth = b.bandwidth;
      if (!stacked && n > 1) barWidth = math.max(minWidth, (barWidth - (n - 1) * padding) / n);
      // Cumulative values per category for stacking, positives and
      // negatives separately (Cloudscape `calculateStackedBarValues`).
      final cumulative = <int, Map<int, double>>{};
      if (stacked) {
        final pos = <int, double>{};
        final neg = <int, double>{};
        for (var si = 0; si < n; si++) {
          for (final d in visibleBars[si].series.data) {
            final ci = categories.indexOf(d.x);
            if (ci < 0) continue;
            final m = d.y < 0 ? neg : pos;
            m[ci] = (m[ci] ?? 0) + d.y;
            (cumulative[ci] ??= {})[si] = m[ci]!;
          }
        }
      }
      final base = valueScale(math.max(valueDomain.$1, math.min(valueDomain.$2, 0)).toDouble());
      for (var si = 0; si < n; si++) {
        final r = visibleBars[si];
        for (final d in r.series.data) {
          final ci = categories.indexOf(d.x);
          if (ci < 0) continue;
          var cross = b(ci);
          var v0 = 0.0;
          var v1 = d.y.toDouble();
          var roundStart = !stacked;
          var roundEnd = !stacked;
          if (stacked) {
            final values = cumulative[ci]!;
            final cum = values[si] ?? 0;
            v1 = cum;
            v0 = cum - d.y;
            final sorted = values.values.toList()..sort();
            roundStart = cum == sorted.first;
            roundEnd = cum == sorted.last;
          } else if (n > 1) {
            cross += si * (barWidth + padding);
          }
          final p0 = v0 == 0 ? base : valueScale(v0);
          final p1 = valueScale(v1);
          if (!p0.isFinite || !p1.isFinite) continue;
          final extent = (p1 - p0).abs();
          final small = extent < 4;
          final valueInset = stacked && !small ? 3.0 : 0.0;
          const crossInset = 2.0;
          final rx = small ? 2.0 : 4.0;
          final lo = math.min(p0, p1) + valueInset / 2;
          final hi = math.max(p0, p1) - valueInset / 2;
          final Rect rect;
          if (!horizontal) {
            rect = Rect.fromLTRB(
              plot.left + cross + crossInset / 2,
              lo,
              plot.left + cross + barWidth - crossInset / 2,
              hi,
            );
          } else {
            rect = Rect.fromLTRB(
              lo,
              plot.top + cross + crossInset / 2,
              hi,
              plot.top + cross + barWidth - crossInset / 2,
            );
          }
          // Cloudscape rounds the start (bottom, or left) of the lowest
          // value in a stack and the end (top, or right) of the highest.
          final rs = roundStart ? Radius.circular(rx) : Radius.zero;
          final re = roundEnd ? Radius.circular(rx) : Radius.zero;
          final radius = horizontal
              ? BorderRadius.only(topLeft: rs, bottomLeft: rs, topRight: re, bottomRight: re)
              : BorderRadius.only(topLeft: re, topRight: re, bottomLeft: rs, bottomRight: rs);
          bars.add(ScaledBar(rect, radius, r.series, r.color, ci, d));
        }
      }
    }

    // Navigation positions.
    if (groupNavigation) {
      for (var i = 0; i < categories.length; i++) {
        final hasData = c.visible.any(
          (r) => r.series.isYThreshold || r.series.data.any((d) => matchesX(d.x, categories[i])),
        );
        if (!hasData) continue;
        navigation.add(NavX(categories[i], categoryPosition(categories[i]), category: i));
      }
    } else {
      final seen = <double>{};
      final sorted = [...points]..sort((a, b) => a.position.dx.compareTo(b.position.dx));
      for (final p in sorted) {
        if (seen.add(p.position.dx)) {
          navigation.add(NavX(p.x, p.position.dx, category: categorical ? categories.indexOf(p.x) : null));
        }
      }
    }
  }

  /// Points at navigation position [i] (lines and areas, top first).
  List<ScaledPoint<T>> pointsAt(int i) {
    if (i < 0 || i >= navigation.length) return const [];
    final nav = navigation[i];
    return points.where((p) => matchesX(p.x, nav.value)).toList();
  }

  /// Bars of category [category].
  List<ScaledBar<T>> barsAt(int category) => bars.where((b) => b.category == category).toList();

  /// Navigation index closest to [position] along the category axis.
  int? nearestNav(double position) {
    if (navigation.isEmpty) return null;
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < navigation.length; i++) {
      final d = (navigation[i].position - position).abs();
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  /// The group whose band contains [p], for bar charts.
  int? groupAt(Offset p) {
    if (!groupNavigation) return null;
    for (var i = 0; i < navigation.length; i++) {
      final r = groupRect(navigation[i].category!);
      if (r.contains(p)) return i;
    }
    return null;
  }
}

/// Strokes [path] with Cloudscape's `3 5` threshold dash (round caps).
void drawDashedPath(ui.Canvas canvas, Path path, Paint paint, {double dash = 3, double gap = 5}) {
  for (final metric in path.computeMetrics()) {
    var d = 0.0;
    while (d < metric.length) {
      final end = math.min(d + dash, metric.length);
      canvas.drawPath(metric.extractPath(d, end), paint);
      d += dash + gap;
    }
  }
}
