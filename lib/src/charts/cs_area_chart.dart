import 'package:flutter/widgets.dart';

import 'cs_chart_series.dart';
import 'internal/cartesian_chart.dart';

/// Cloudscape's area chart: stacked areas that show how parts add up to a
/// total over time, with thresholds, a legend, a series filter and a
/// detail popover that ends with the total.
///
/// Cloudscape reference: https://cloudscape.design/components/area-chart/
///
/// ```dart
/// CsAreaChart<DateTime>(
///   series: [site1, site2, const CsChartSeries<DateTime>.threshold(title: 'Peak capacity', y: 400)],
///   xScaleType: CsChartScaleType.time,
///   ariaLabel: 'Network traffic',
/// )
/// ```
///
/// Hovering the plot (or dragging a finger across it) moves a crosshair
/// between x positions and opens a detail popover with every series'
/// value; a click or a lifted finger pins the popover. With keyboard focus,
/// Left and Right move between x positions, Up and Down between series,
/// Enter pins and Escape dismisses. The legend highlights a series on
/// hover, focus or tap, and the filter shows and hides series.
class CsAreaChart<T> extends StatelessWidget {
  const CsAreaChart({
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
    this.detailTotalFormatter,
    this.i18nStrings = const CsChartI18nStrings(),
    this.ariaLabel,
    this.ariaDescription,
  });

  /// Area and threshold series ([CsChartSeries.area], [CsChartSeries.threshold]). Areas stack in
  /// order, so the top edge of the last visible area is the total.
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

  /// Formats the total row of the detail popover. Defaults to
  /// [yTickFormatter].
  final CsChartTickFormatter<num>? detailTotalFormatter;

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
      kind: CartesianKind.area,
      defaultRoleDescription: 'Area chart',
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
      detailTotalFormatter: detailTotalFormatter,
      i18nStrings: i18nStrings,
      ariaLabel: ariaLabel,
      ariaDescription: ariaDescription,
    );
  }
}
