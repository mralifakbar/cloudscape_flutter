import 'package:flutter/widgets.dart';

import 'cs_chart_series.dart';
import 'internal/cartesian_chart.dart';

/// Cloudscape's mixed line and bar chart: bars and lines on one categorical
/// x axis, for example a monthly cost with its running average and a
/// budget threshold.
///
/// Cloudscape reference: https://cloudscape.design/components/mixed-line-bar-chart/
///
/// ```dart
/// CsMixedLineBarChart<String>(
///   series: [costs, average, const CsChartSeries<String>.threshold(title: 'Budget', y: 1500)],
///   xScaleType: CsChartScaleType.categorical,
///   ariaLabel: 'Monthly cost',
/// )
/// ```
///
/// Hovering the plot (or dragging a finger across it) highlights the bar group
/// and line points of one category and opens a detail popover with every series'
/// value; a click or a lifted finger pins the popover. With keyboard focus,
/// Left and Right move between x positions, Up and Down between series,
/// Enter pins and Escape dismisses. The legend highlights a series on
/// hover, focus or tap, and the filter shows and hides series.
class CsMixedLineBarChart<T> extends StatelessWidget {
  const CsMixedLineBarChart({
    super.key,
    required this.series,
    this.visibleSeries,
    this.onFilterChange,
    this.highlightedSeries,
    this.onHighlightChange,
    this.xScaleType = CsChartScaleType.linear,
    this.yScaleType = CsChartYScaleType.linear,
    this.xDomain,
    this.yDomain,
    this.xTitle,
    this.yTitle,
    this.legendTitle,
    this.xTickFormatter,
    this.yTickFormatter,
    this.stackedBars = false,
    this.horizontalBars = false,
    this.emphasizeBaselineAxis = true,
    this.height = 500,
    this.fitHeight = false,
    this.hideFilter = false,
    this.hideLegend = false,
    this.additionalFilters,
    this.statusType = CsChartStatusType.finished,
    this.empty,
    this.noMatch,
    this.loadingText,
    this.errorText,
    this.recoveryText,
    this.onRecoveryClick,
    this.detailPopoverSize = CsChartPopoverSize.medium,
    this.detailPopoverFooter,
    this.detailPopoverSeriesContent,
    this.i18nStrings = const CsChartI18nStrings(),
    this.ariaLabel,
    this.ariaDescription,
  });

  /// Line, bar and threshold series.
  final List<CsChartSeries<T>> series;

  /// Series currently shown (Cloudscape `visibleSeries`). Null lets the
  /// built-in filter manage it; pass a list (and update it in
  /// [onFilterChange]) to control it.
  final List<CsChartSeries<T>>? visibleSeries;

  /// Called with the new visible series when the built-in filter changes.
  final ValueChanged<List<CsChartSeries<T>>>? onFilterChange;

  /// Series to highlight (Cloudscape `highlightedSeries`). The chart also
  /// highlights on hover and focus; a new value passed here replaces the
  /// current highlight.
  final CsChartSeries<T>? highlightedSeries;

  /// Called when the user highlights a series (legend, point) or clears it.
  final ValueChanged<CsChartSeries<T>?>? onHighlightChange;

  /// How x values map onto the axis. Bars need [CsChartScaleType.categorical].
  final CsChartScaleType xScaleType;

  /// Linear or base-10 log value axis.
  final CsChartYScaleType yScaleType;

  /// Visible x range: `[min, max]` for numbers and dates, or the ordered
  /// categories. Null fits all data.
  final List<T>? xDomain;

  /// Visible value range `[min, max]`. Null fits all data (always including
  /// zero) and rounds the ends to tick steps.
  final List<num>? yDomain;

  /// Title under the x axis.
  final String? xTitle;

  /// Title above the value axis.
  final String? yTitle;

  /// Bold title above the legend entries.
  final String? legendTitle;

  /// Formats x tick labels and the popover title. Use `\n` for two lines.
  final CsChartTickFormatter<T>? xTickFormatter;

  /// Formats value axis labels.
  final CsChartTickFormatter<num>? yTickFormatter;

  /// Stacks bars of the same x instead of placing them side by side.
  final bool stackedBars;

  /// Flips the axes so bars run left to right. Only for charts of bars and
  /// thresholds.
  final bool horizontalBars;

  /// Draws the zero line 2px wide (Cloudscape `emphasizeBaselineAxis`).
  final bool emphasizeBaselineAxis;

  /// Height of the plot area in logical pixels (axis labels and titles are
  /// added to it).
  final double height;

  /// Fill the parent's height instead of using [height]. The parent must
  /// have a bounded height.
  final bool fitHeight;

  /// Hides the built-in series filter.
  final bool hideFilter;

  /// Hides the legend. Keep it unless the chart has one series.
  final bool hideLegend;

  /// Extra filters (a date range, a select) next to the built-in filter.
  final Widget? additionalFilters;

  /// Loading state of the data.
  final CsChartStatusType statusType;

  /// Shown when [series] is empty.
  final Widget? empty;

  /// Shown when the filter hides every series.
  final Widget? noMatch;

  /// Shown while loading. Defaults to "Loading chart".
  final String? loadingText;

  /// Shown on error. Defaults to "The data couldn't be fetched. Try again later.".
  final String? errorText;

  /// Text of the recovery link next to [errorText]. Defaults to "Retry".
  final String? recoveryText;

  /// Called from the recovery link. Without it there is no link.
  final VoidCallback? onRecoveryClick;

  /// Maximum width of the detail popover.
  final CsChartPopoverSize detailPopoverSize;

  /// Content under a divider at the bottom of the detail popover, for the
  /// highlighted x.
  final Widget Function(T x)? detailPopoverFooter;

  /// Replaces a series row in the detail popover: a different key or
  /// value, links, or a breakdown in `subItems`.
  final CsChartDetailPopoverSeriesContent<T>? detailPopoverSeriesContent;

  /// Labels for the filter, legend, popover and screen readers.
  final CsChartI18nStrings i18nStrings;

  /// Accessible name of the chart; match the visible heading.
  final String? ariaLabel;

  /// A short summary of what the chart shows, read before the generated
  /// series and axis summary.
  final String? ariaDescription;

  @override
  Widget build(BuildContext context) {
    return CartesianChart<T>(
      kind: CartesianKind.mixed,
      defaultRoleDescription: 'Mixed line and bar chart',
      series: series,
      visibleSeries: visibleSeries,
      onFilterChange: onFilterChange,
      highlightedSeries: highlightedSeries,
      onHighlightChange: onHighlightChange,
      xScaleType: xScaleType,
      yScaleType: yScaleType,
      xDomain: xDomain,
      yDomain: yDomain,
      xTitle: xTitle,
      yTitle: yTitle,
      legendTitle: legendTitle,
      xTickFormatter: xTickFormatter,
      yTickFormatter: yTickFormatter,
      stackedBars: stackedBars,
      horizontalBars: horizontalBars,
      emphasizeBaselineAxis: emphasizeBaselineAxis,
      height: height,
      fitHeight: fitHeight,
      hideFilter: hideFilter,
      hideLegend: hideLegend,
      additionalFilters: additionalFilters,
      statusType: statusType,
      empty: empty,
      noMatch: noMatch,
      loadingText: loadingText,
      errorText: errorText,
      recoveryText: recoveryText,
      onRecoveryClick: onRecoveryClick,
      detailPopoverSize: detailPopoverSize,
      detailPopoverFooter: detailPopoverFooter,
      detailPopoverSeriesContent: detailPopoverSeriesContent,
      i18nStrings: i18nStrings,
      ariaLabel: ariaLabel,
      ariaDescription: ariaDescription,
    );
  }
}
