import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// The kind of a cartesian chart series (Cloudscape `series[].type`).
enum CsChartSeriesType {
  /// A line through the data points. [CsLineChart], [CsMixedLineBarChart].
  line,

  /// One bar per data point. Needs a categorical x axis.
  /// [CsBarChart], [CsMixedLineBarChart].
  bar,

  /// A filled area, stacked on the areas before it. [CsAreaChart].
  area,

  /// A dashed reference line at a fixed y value (or x value in mixed, line
  /// and bar charts), such as an alarm limit.
  threshold,
}

/// How values map to positions on the x axis (Cloudscape `xScaleType`).
enum CsChartScaleType {
  /// Numbers, evenly spaced.
  linear,

  /// Numbers on a base-10 logarithmic axis.
  log,

  /// `DateTime` values, ticks on calendar boundaries.
  time,

  /// Distinct values (usually strings) in equal bands. Required for bars.
  categorical,
}

/// How values map to positions on the y (value) axis (Cloudscape `yScaleType`).
enum CsChartYScaleType { linear, log }

/// Loading state of a chart's data (Cloudscape `statusType`).
enum CsChartStatusType {
  /// Data is being fetched: shows `loadingText` with a spinner.
  loading,

  /// Data loaded: shows the chart, or `empty` / `noMatch`.
  finished,

  /// Fetching failed: shows `errorText` and a recovery link.
  error,
}

/// Maximum width of the detail popover (Cloudscape `detailPopoverSize`).
enum CsChartPopoverSize {
  /// 210px.
  small(210),

  /// 310px. The default.
  medium(310),

  /// 482px.
  large(482);

  const CsChartPopoverSize(this.maxWidth);

  /// Width limit in logical pixels (from Cloudscape's popover container).
  final double maxWidth;
}

/// One data point of a series: an [x] position and a [y] value
/// (Cloudscape `Datum`).
@immutable
class CsChartDatum<T> {
  const CsChartDatum(this.x, this.y);

  /// A `num` on linear and log axes, a `DateTime` on time axes, a `String`
  /// (or any value with `==`) on categorical axes.
  final T x;
  final num y;

  @override
  bool operator ==(Object other) => other is CsChartDatum<T> && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'CsChartDatum($x, $y)';
}

/// Formats a value for the detail popover: the y value and its x position.
typedef CsChartValueFormatter<T> = String Function(num y, T x);

/// Formats an axis tick label.
typedef CsChartTickFormatter<V> = String Function(V value);

/// One series of a line, bar, area or mixed chart (Cloudscape
/// `series[]`). Charts compare series by identity: keep the same instances
/// between builds (declare them `final` or `const`) so filtering and
/// highlighting stay attached.
///
/// ```dart
/// final cpu = CsChartSeries<DateTime>.line(
///   title: 'CPU utilization',
///   data: [CsChartDatum(DateTime(2026, 11, 1), 42), CsChartDatum(DateTime(2026, 11, 2), 57)],
///   valueFormatter: (y, x) => '$y%',
/// );
/// const limit = CsChartSeries<DateTime>.threshold(title: 'Alarm', y: 80);
/// ```
@immutable
class CsChartSeries<T> {
  /// A series of any [type]. Prefer the named constructors.
  const CsChartSeries({
    required this.type,
    required this.title,
    this.data = const [],
    this.color,
    this.colorToken,
    this.valueFormatter,
    this.y,
    this.x,
    this.thresholdValueFormatter,
  });

  /// A line through [data].
  const CsChartSeries.line({required this.title, required this.data, this.color, this.colorToken, this.valueFormatter})
    : type = CsChartSeriesType.line,
      y = null,
      x = null,
      thresholdValueFormatter = null;

  /// One bar per datum of [data].
  const CsChartSeries.bar({required this.title, required this.data, this.color, this.colorToken, this.valueFormatter})
    : type = CsChartSeriesType.bar,
      y = null,
      x = null,
      thresholdValueFormatter = null;

  /// A filled area for [CsAreaChart]. Every area series must use the same
  /// x values.
  const CsChartSeries.area({required this.title, required this.data, this.color, this.colorToken, this.valueFormatter})
    : type = CsChartSeriesType.area,
      y = null,
      x = null,
      thresholdValueFormatter = null;

  /// A dashed reference line at [y] (horizontal) or at [x] (vertical, line,
  /// bar and mixed charts only). Pass exactly one of them.
  const CsChartSeries.threshold({
    required this.title,
    this.y,
    this.x,
    this.color,
    this.colorToken,
    CsChartTickFormatter<num>? valueFormatter,
  }) : assert((y == null) != (x == null), 'Pass either y or x'),
       type = CsChartSeriesType.threshold,
       data = const [],
       valueFormatter = null,
       thresholdValueFormatter = valueFormatter;

  final CsChartSeriesType type;

  /// Name shown in the legend, filter and detail popover.
  final String title;

  /// Data points of line, bar and area series. Empty for thresholds.
  final List<CsChartDatum<T>> data;

  /// Color override (Cloudscape `color`). Takes priority over [colorToken]
  /// and the automatic categorical palette. Prefer [colorToken] so the color
  /// follows light and dark mode.
  final Color? color;

  /// Color override as a theme token, such as
  /// `CsColor.chartsStatusHigh` or `CsColor.chartsThresholdNegative`.
  final CsColor? colorToken;

  /// Formats this series' values in the detail popover and summaries.
  final CsChartValueFormatter<T>? valueFormatter;

  /// Value of a horizontal threshold.
  final num? y;

  /// Position of a vertical threshold.
  final T? x;

  /// Formats a threshold's [y] value in the detail popover.
  final CsChartTickFormatter<num>? thresholdValueFormatter;

  bool get isThreshold => type == CsChartSeriesType.threshold;
  bool get isYThreshold => isThreshold && y != null;
  bool get isXThreshold => isThreshold && y == null && x != null;

  @override
  String toString() => 'CsChartSeries(${type.name}, $title)';
}

/// A key and value pair in a detail popover (Cloudscape `ChartDetailPair`).
/// Use the widget slots for links or other rich content.
@immutable
class CsChartDetailPair {
  const CsChartDetailPair({this.key, this.keyWidget, this.value, this.valueWidget})
    : assert(key != null || keyWidget != null, 'Pass key or keyWidget');

  final String? key;
  final Widget? keyWidget;
  final String? value;
  final Widget? valueWidget;
}

/// Custom popover content for one series at the highlighted x
/// (Cloudscape `DetailPopoverSeriesKeyValuePair`).
@immutable
class CsChartSeriesDetail {
  const CsChartSeriesDetail({
    this.key,
    this.keyWidget,
    this.value,
    this.valueWidget,
    this.subItems = const [],
    this.expandable = false,
  });

  /// Replaces the series title. Null keeps the title.
  final String? key;
  final Widget? keyWidget;

  /// Replaces the formatted value. Null keeps the default value.
  final String? value;
  final Widget? valueWidget;

  /// A nested breakdown shown under the series row.
  final List<CsChartDetailPair> subItems;

  /// Collapse [subItems] behind an expand toggle on the series row.
  final bool expandable;
}

/// Builds custom popover content for [series] at [x], whose value is [y]
/// (Cloudscape `detailPopoverSeriesContent`).
typedef CsChartDetailPopoverSeriesContent<T> = CsChartSeriesDetail Function(CsChartSeries<T> series, T x, num y);

/// The categorical color palette charts assign to series, in Cloudscape's
/// order (`color-charts-palette-categorical-1` to `-50`).
abstract final class CsChartColors {
  /// The 50 palette tokens in assignment order: blue, pink, teal, purple,
  /// orange, then darker and lighter steps of each.
  static const List<CsColor> categorical = [
    CsColor.chartsPaletteCategorical1,
    CsColor.chartsPaletteCategorical2,
    CsColor.chartsPaletteCategorical3,
    CsColor.chartsPaletteCategorical4,
    CsColor.chartsPaletteCategorical5,
    CsColor.chartsPaletteCategorical6,
    CsColor.chartsPaletteCategorical7,
    CsColor.chartsPaletteCategorical8,
    CsColor.chartsPaletteCategorical9,
    CsColor.chartsPaletteCategorical10,
    CsColor.chartsPaletteCategorical11,
    CsColor.chartsPaletteCategorical12,
    CsColor.chartsPaletteCategorical13,
    CsColor.chartsPaletteCategorical14,
    CsColor.chartsPaletteCategorical15,
    CsColor.chartsPaletteCategorical16,
    CsColor.chartsPaletteCategorical17,
    CsColor.chartsPaletteCategorical18,
    CsColor.chartsPaletteCategorical19,
    CsColor.chartsPaletteCategorical20,
    CsColor.chartsPaletteCategorical21,
    CsColor.chartsPaletteCategorical22,
    CsColor.chartsPaletteCategorical23,
    CsColor.chartsPaletteCategorical24,
    CsColor.chartsPaletteCategorical25,
    CsColor.chartsPaletteCategorical26,
    CsColor.chartsPaletteCategorical27,
    CsColor.chartsPaletteCategorical28,
    CsColor.chartsPaletteCategorical29,
    CsColor.chartsPaletteCategorical30,
    CsColor.chartsPaletteCategorical31,
    CsColor.chartsPaletteCategorical32,
    CsColor.chartsPaletteCategorical33,
    CsColor.chartsPaletteCategorical34,
    CsColor.chartsPaletteCategorical35,
    CsColor.chartsPaletteCategorical36,
    CsColor.chartsPaletteCategorical37,
    CsColor.chartsPaletteCategorical38,
    CsColor.chartsPaletteCategorical39,
    CsColor.chartsPaletteCategorical40,
    CsColor.chartsPaletteCategorical41,
    CsColor.chartsPaletteCategorical42,
    CsColor.chartsPaletteCategorical43,
    CsColor.chartsPaletteCategorical44,
    CsColor.chartsPaletteCategorical45,
    CsColor.chartsPaletteCategorical46,
    CsColor.chartsPaletteCategorical47,
    CsColor.chartsPaletteCategorical48,
    CsColor.chartsPaletteCategorical49,
    CsColor.chartsPaletteCategorical50,
  ];

  /// Default color of threshold series (`color-charts-threshold-neutral`).
  static const CsColor threshold = CsColor.chartsThresholdNeutral;

  /// Resolves the color of every item, Cloudscape's
  /// `createCategoryColorScale`: an item's own color wins; thresholds get
  /// [threshold]; everything else takes the next palette color. Items with
  /// their own color or thresholds do not use up a palette slot.
  static List<Color> resolve<I>(
    CsThemeData theme,
    List<I> items, {
    bool Function(I item)? isThreshold,
    Color? Function(I item)? ownColor,
  }) {
    final out = <Color>[];
    var next = 0;
    for (final item in items) {
      final own = ownColor?.call(item);
      final thr = isThreshold?.call(item) ?? false;
      if (own != null) {
        out.add(own);
      } else if (thr) {
        out.add(theme.color(threshold));
      } else {
        out.add(theme.color(categorical[next % categorical.length]));
        next++;
      }
    }
    return out;
  }

  /// The palette color at [index] (wrapping after 50).
  static Color at(CsThemeData theme, int index) => theme.color(categorical[index % categorical.length]);
}

/// Copy used by the line, bar, area and mixed charts (Cloudscape
/// `i18nStrings` plus the status texts). Null fields fall back to
/// Cloudscape's English defaults.
@immutable
class CsChartI18nStrings {
  const CsChartI18nStrings({
    this.filterLabel,
    this.filterPlaceholder,
    this.filterSelectedAriaLabel,
    this.legendAriaLabel,
    this.detailPopoverDismissAriaLabel,
    this.chartAriaRoleDescription,
    this.xAxisAriaRoleDescription,
    this.yAxisAriaRoleDescription,
    this.detailTotalLabel,
    this.expandAriaLabel,
    this.collapseAriaLabel,
  });

  /// Visible label of the default filter. Default "Filter displayed data".
  final String? filterLabel;

  /// Text of the filter trigger. Default "Filter data".
  final String? filterPlaceholder;

  /// Appended to selected filter options for screen readers. Default "selected".
  final String? filterSelectedAriaLabel;

  /// Accessible name of the legend when there is no `legendTitle`. Default "Legend".
  final String? legendAriaLabel;

  /// Accessible name of the pinned popover's close button. Default "Dismiss".
  final String? detailPopoverDismissAriaLabel;

  /// Kind of chart announced to screen readers, such as "Line chart".
  final String? chartAriaRoleDescription;

  /// Default "x-axis".
  final String? xAxisAriaRoleDescription;

  /// Default "y-axis".
  final String? yAxisAriaRoleDescription;

  /// Area charts: title of the total row in the popover. Default "Total".
  final String? detailTotalLabel;

  /// Accessible name of an expandable popover row's toggle. Default "Expand".
  final String? expandAriaLabel;

  /// Default "Collapse".
  final String? collapseAriaLabel;
}
