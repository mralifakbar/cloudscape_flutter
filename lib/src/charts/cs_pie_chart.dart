import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../overlays/cs_anchored_overlay.dart';
import '../overlays/cs_popup_surface.dart';
import '../theme/theme.dart';
import 'cs_chart_series.dart';
import 'internal/chart_math.dart';
import 'internal/chart_parts.dart';

/// Size of a pie or donut (Cloudscape `size`): outer radius 50, 100 or
/// 140px.
enum CsPieChartSize { small, medium, large }

/// Pie, or donut with room for a metric in the middle (Cloudscape `variant`).
enum CsPieChartVariant { pie, donut }

/// One segment of a [CsPieChart] (Cloudscape `PieChartProps.Datum`).
/// Extend it to carry more fields; the chart hands your type back in
/// callbacks.
@immutable
class CsPieChartDatum {
  const CsPieChartDatum({required this.title, required this.value, this.color, this.colorToken});

  /// Segment name in labels, the legend, the filter and the popover.
  final String title;

  /// Segment size. Zero or negative values get no segment.
  final num value;

  /// Color override. Prefer [colorToken] so it follows light and dark mode.
  final Color? color;

  /// Color override as a theme token.
  final CsColor? colorToken;

  @override
  String toString() => 'CsPieChartDatum($title, $value)';
}

/// Copy of [CsPieChart]. Null fields use Cloudscape's English defaults.
@immutable
class CsPieChartI18nStrings {
  const CsPieChartI18nStrings({
    this.detailsValue,
    this.detailsPercentage,
    this.filterLabel,
    this.filterPlaceholder,
    this.filterSelectedAriaLabel,
    this.legendAriaLabel,
    this.detailPopoverDismissAriaLabel,
    this.chartAriaRoleDescription,
    this.segmentAriaRoleDescription,
  });

  /// Key of the value row in the default popover. Default "Value".
  final String? detailsValue;

  /// Key of the percentage row in the default popover. Default "Percentage".
  final String? detailsPercentage;

  /// Default "Filter displayed data".
  final String? filterLabel;

  /// Default "Filter data".
  final String? filterPlaceholder;

  /// Default "selected".
  final String? filterSelectedAriaLabel;

  /// Default "Legend".
  final String? legendAriaLabel;

  /// Default "Dismiss".
  final String? detailPopoverDismissAriaLabel;

  /// Default "Pie chart".
  final String? chartAriaRoleDescription;

  /// Default "Segment".
  final String? segmentAriaRoleDescription;
}

/// Builds the key-value rows of a segment's popover from the segment and
/// the sum of the visible segments.
typedef CsPieChartDetailPopoverContent<T> = List<CsChartDetailPair> Function(T segment, num visibleDataSum);

/// A short description under a segment's label, from the segment and the
/// sum of the visible segments.
typedef CsPieChartSegmentDescription<T> = String Function(T segment, num visibleDataSum);

class _Dimensions {
  const _Dimensions(
    this.innerRadius,
    this.outerRadius,
    this.padding,
    this.innerLabelPadding,
    this.cornerRadius,
    this.size,
  );

  final double innerRadius;
  final double outerRadius;
  final double padding;
  final double innerLabelPadding;
  final double cornerRadius;
  final CsPieChartSize size;

  // 2 x line-height-body-m plus 2px, as in Cloudscape's utils.ts.
  static const double paddingLabels = 44;

  // Visual refresh dimensions (pie-chart/utils.ts `refreshDimensionsBySize`).
  static const Map<CsPieChartSize, _Dimensions> bySize = {
    CsPieChartSize.small: _Dimensions(38, 50, CsSpace.xs, CsSpace.xs, 3, CsPieChartSize.small),
    CsPieChartSize.medium: _Dimensions(75, 100, CsSpace.s, CsSpace.s, 4, CsPieChartSize.medium),
    CsPieChartSize.large: _Dimensions(105, 140, CsSpace.s, CsSpace.s, 5, CsPieChartSize.large),
  };

  double pixelSize(bool labels) => outerRadius * 2 + padding * 2 + (labels ? paddingLabels : 0) * 2;

  /// Fits the chart into [size] pixels (`fitHeight`), keeping the closest
  /// predefined ratio of inner to outer radius.
  static _Dimensions fit(double size, bool labels) {
    var matched = CsPieChartSize.small;
    if (size > bySize[CsPieChartSize.medium]!.pixelSize(labels)) matched = CsPieChartSize.medium;
    if (size > bySize[CsPieChartSize.large]!.pixelSize(labels)) matched = CsPieChartSize.large;
    final spec = bySize[matched]!;
    final ratio = spec.outerRadius / spec.innerRadius;
    final outer = math.max(30.0, (size - 2 * (labels ? paddingLabels : 0) - 2 * spec.padding) / 2);
    return _Dimensions(outer / ratio, outer, spec.padding, spec.innerLabelPadding, spec.cornerRadius, matched);
  }
}

class _Arc<T> {
  _Arc(this.datum, this.color, this.index, this.start, this.end);

  final T datum;
  final Color color;
  final int index;
  final double start;
  final double end;

  double get mid => (start + end) / 2;
}

Offset _polar(double r, double angle) => Offset(r * math.sin(angle), -r * math.cos(angle));

/// Cloudscape's pie chart: parts of a whole as pie or donut segments with
/// labels, a legend, a segment filter and a detail popover.
///
/// Cloudscape reference: https://cloudscape.design/components/pie-chart/
///
/// ```dart
/// CsPieChart<CsPieChartDatum>(
///   data: const [
///     CsPieChartDatum(title: 'Running', value: 60),
///     CsPieChartDatum(title: 'Stopped', value: 25),
///     CsPieChartDatum(title: 'Terminated', value: 15),
///   ],
///   variant: CsPieChartVariant.donut,
///   innerMetricValue: '100',
///   innerMetricDescription: 'instances',
///   ariaLabel: 'Instance states',
/// )
/// ```
///
/// Hovering a segment (or tapping it) highlights it and opens a popover
/// with its value and percentage; a click or tap pins the popover. With
/// keyboard focus, Left and Right move between segments, Enter pins and
/// Escape dismisses.
class CsPieChart<T extends CsPieChartDatum> extends StatefulWidget {
  const CsPieChart({
    super.key,
    required this.data,
    this.size = CsPieChartSize.medium,
    this.variant = CsPieChartVariant.pie,
    this.detailPopoverContent,
    this.detailPopoverFooter,
    this.segmentDescription,
    this.detailPopoverSize = CsChartPopoverSize.medium,
    this.hideLegend = false,
    this.hideTitles = false,
    this.hideDescriptions = false,
    this.hideFilter = false,
    this.innerMetricValue,
    this.innerMetricDescription,
    this.legendTitle,
    this.additionalFilters,
    this.highlightedSegment,
    this.onHighlightChange,
    this.visibleSegments,
    this.onFilterChange,
    this.statusType = CsChartStatusType.finished,
    this.empty,
    this.noMatch,
    this.loadingText,
    this.errorText,
    this.recoveryText,
    this.onRecoveryClick,
    this.ariaLabel,
    this.ariaDescription,
    this.i18nStrings = const CsPieChartI18nStrings(),
    this.fitHeight = false,
  });

  /// Segments, in clockwise order from 12 o'clock.
  final List<T> data;

  /// Outer radius: 50, 100 or 140px. With [fitHeight], the minimum size.
  final CsPieChartSize size;

  /// Pie, or donut with [innerMetricValue] and [innerMetricDescription] in
  /// the middle.
  final CsPieChartVariant variant;

  /// Popover rows for a segment. Defaults to its value and percentage.
  final CsPieChartDetailPopoverContent<T>? detailPopoverContent;

  /// Content under a divider at the bottom of the popover.
  final Widget Function(T segment)? detailPopoverFooter;

  /// Text under each segment's label (unless [hideDescriptions]).
  final CsPieChartSegmentDescription<T>? segmentDescription;

  /// Maximum width of the popover.
  final CsChartPopoverSize detailPopoverSize;

  /// Hides the legend. Keep it unless labels already name every segment.
  final bool hideLegend;

  /// Hides the segment titles next to the chart.
  final bool hideTitles;

  /// Hides the segment descriptions next to the chart.
  final bool hideDescriptions;

  /// Hides the built-in segment filter.
  final bool hideFilter;

  /// Large text in the middle of a donut.
  final String? innerMetricValue;

  /// Text under [innerMetricValue], usually its unit. Not shown for small donuts.
  final String? innerMetricDescription;

  /// Bold title above the legend.
  final String? legendTitle;

  /// Extra filters next to the built-in filter.
  final Widget? additionalFilters;

  /// Segment to highlight. The chart also highlights on hover and focus; a
  /// new value passed here replaces the current highlight.
  final T? highlightedSegment;

  /// Called when the user highlights a segment or clears the highlight.
  final ValueChanged<T?>? onHighlightChange;

  /// Segments currently shown. Null lets the built-in filter manage it.
  final List<T>? visibleSegments;

  /// Called with the new visible segments when the built-in filter changes.
  final ValueChanged<List<T>>? onFilterChange;

  /// Loading state of the data.
  final CsChartStatusType statusType;

  /// Shown when [data] is empty or every value is zero.
  final Widget? empty;

  /// Shown when the filter hides every segment.
  final Widget? noMatch;

  /// Defaults to "Loading chart".
  final String? loadingText;

  /// Defaults to "The data couldn't be fetched. Try again later.".
  final String? errorText;

  /// Text of the recovery link. Defaults to "Retry".
  final String? recoveryText;

  /// Called from the recovery link. Without it there is no link.
  final VoidCallback? onRecoveryClick;

  /// Accessible name of the chart; match the visible heading.
  final String? ariaLabel;

  /// A short summary of the chart, read before the generated segment list.
  final String? ariaDescription;
  final CsPieChartI18nStrings i18nStrings;

  /// Fill the parent's height. The parent must have a bounded height.
  final bool fitHeight;

  @override
  State<CsPieChart<T>> createState() => _CsPieChartState<T>();
}

class _CsPieChartState<T extends CsPieChartDatum> extends State<CsPieChart<T>> with TickerProviderStateMixin {
  late List<T> _visible;
  T? _highlighted;
  bool _popover = false;
  bool _pinned = false;
  bool _focusVisible = false;
  bool _revealed = false;
  final FocusNode _focus = FocusNode(debugLabel: 'Cs pie chart');
  final Object _tapGroup = Object();
  late final AnimationController _reveal;
  late final AnimationController _dim;
  T? _dimFrom;
  List<_Arc<T>> _arcs = const [];
  Offset _center = Offset.zero;
  _Dimensions? _dims;
  Widget? _lastPopover;

  @override
  void initState() {
    super.initState();
    _visible = widget.visibleSegments ?? List.of(widget.data);
    _highlighted = widget.highlightedSegment;
    _reveal = AnimationController(vsync: this, duration: CsDurations.complex);
    _dim = AnimationController(vsync: this, duration: CsDurations.transitionQuick, value: 1);
    _focus.addListener(_onFocus);
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void didUpdateWidget(CsPieChart<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visibleSegments == null && !_same(oldWidget.data, widget.data)) {
      _visible = [
        for (final d in widget.data)
          if (!oldWidget.data.contains(d) || _visible.contains(d)) d,
      ];
    }
    if (widget.highlightedSegment != oldWidget.highlightedSegment) {
      _setHighlighted(widget.highlightedSegment, notify: false);
    }
  }

  static bool _same<E>(List<E> a, List<E> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _reveal.dispose();
    _dim.dispose();
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode _) => _updateFocusVisible();

  void _updateFocusVisible() {
    final v = _focus.hasFocus && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (v != _focusVisible) setState(() => _focusVisible = v);
  }

  void _onFocus() {
    _updateFocusVisible();
    if (_focus.hasFocus) {
      if (FocusManager.instance.highlightMode == FocusHighlightMode.traditional && _arcs.isNotEmpty && !_pinned) {
        final current = _arcs.where((a) => a.datum == _highlighted).firstOrNull ?? _arcs.first;
        _highlight(current.datum);
      }
    } else if (!_pinned) {
      _clear();
    }
  }

  List<T> get _visibleData {
    final v = widget.visibleSegments ?? _visible;
    return [
      for (final d in widget.data)
        if (v.contains(d)) d,
    ];
  }

  void _setHighlighted(T? d, {bool notify = true}) {
    if (d == _highlighted) return;
    _dimFrom = _highlighted;
    setState(() => _highlighted = d);
    if (CsMotion.reduceMotion(context)) {
      _dim.value = 1;
    } else {
      _dim.forward(from: 0);
    }
    if (notify) widget.onHighlightChange?.call(d);
  }

  void _highlight(T d, {bool popover = true}) {
    _setHighlighted(d);
    if (popover && !_popover) setState(() => _popover = true);
  }

  void _clear() {
    setState(() {
      _popover = false;
      _pinned = false;
    });
    _setHighlighted(null);
  }

  void _move(int delta) {
    if (_arcs.isEmpty) return;
    final i = _arcs.indexWhere((a) => a.datum == _highlighted);
    final n = _arcs.length;
    final next = i < 0 ? 0 : ((i + delta) % n + n) % n;
    _highlight(_arcs[next].datum);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (key == LogicalKeyboardKey.arrowRight) {
      _move(rtl ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _move(rtl ? 1 : -1);
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (_highlighted == null) _move(1);
      setState(() => _pinned = true);
    } else if (key == LogicalKeyboardKey.escape && (_popover || _highlighted != null)) {
      _clear();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  _Arc<T>? _arcAt(Offset local) {
    final dims = _dims;
    if (dims == null) return null;
    final v = local - _center;
    final dist = v.distance;
    final inner = widget.variant == CsPieChartVariant.donut ? dims.innerRadius : 0.0;
    if (dist < inner || dist > dims.outerRadius + 6) return null;
    var angle = math.atan2(v.dx, -v.dy);
    if (angle < 0) angle += 2 * math.pi;
    for (final a in _arcs) {
      if (angle >= a.start && angle < a.end) return a;
    }
    return null;
  }

  void _onTap(Offset local) {
    final a = _arcAt(local);
    if (a == null) {
      if (_pinned) _clear();
      return;
    }
    // Cloudscape: pressing the pinned segment again unpins it.
    if (_pinned && a.datum == _highlighted) {
      _clear();
    } else {
      _highlight(a.datum);
      setState(() => _pinned = true);
    }
  }

  void _onHover(Offset local) {
    if (_pinned) return;
    final a = _arcAt(local);
    if (a == null) {
      if (_popover) _clear();
    } else {
      _highlight(a.datum);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final i18n = widget.i18nStrings;
    final colors = CsChartColors.resolve<T>(
      cs,
      widget.data,
      ownColor: (d) => d.color ?? (d.colorToken == null ? null : cs.color(d.colorToken!)),
    );
    final colorOf = {for (var i = 0; i < widget.data.length; i++) widget.data[i]: colors[i]};
    final visible = _visibleData;
    final sum = visible.fold<num>(0, (s, d) => s + d.value);
    final positive = visible.where((d) => d.value > 0).toList();
    // Cloudscape draws every segment at least 1% of the whole.
    final minValue = sum / 100;
    final weights = [for (final d in positive) math.max(d.value.toDouble(), minValue.toDouble())];
    final total = weights.fold<double>(0, (a, b) => a + b);
    final arcs = <_Arc<T>>[];
    var angle = 0.0;
    for (var i = 0; i < positive.length; i++) {
      final sweep = total == 0 ? 0.0 : weights[i] / total * 2 * math.pi;
      arcs.add(_Arc(positive[i], colorOf[positive[i]]!, widget.data.indexOf(positive[i]), angle, angle + sweep));
      angle += sweep;
    }
    _arcs = arcs;

    final hasNoData = widget.data.isEmpty;
    final isEmpty = arcs.isEmpty;
    final isNoMatch = isEmpty && visible.length != widget.data.length;
    final finished = widget.statusType == CsChartStatusType.finished;
    final showChart = finished && !isEmpty;
    if (showChart && !_revealed) {
      _revealed = true;
      if (CsMotion.reduceMotion(context)) {
        _reveal.value = 1;
      } else {
        _reveal.forward(from: 0);
      }
    }

    final items = [
      for (final d in widget.data)
        ChartItem<T>(label: d.title, datum: d, color: colorOf[d]!, marker: ChartMarkerType.rectangle),
    ];
    final showFilters = finished && !hasNoData && (widget.additionalFilters != null || !widget.hideFilter);
    final filter = showFilters && !widget.hideFilter
        ? ChartFilter<T>(
            items: items,
            selected: visible,
            label: i18n.filterLabel ?? ChartDefaults.filterLabel,
            placeholder: i18n.filterPlaceholder ?? ChartDefaults.filterPlaceholder,
            selectedAriaLabel: i18n.filterSelectedAriaLabel ?? ChartDefaults.filterSelected,
            onChange: (next) {
              if (widget.visibleSegments == null) setState(() => _visible = next);
              _clear();
              widget.onFilterChange?.call(next);
            },
          )
        : null;
    final legend = !widget.hideLegend && !hasNoData && finished
        ? ChartLegend<T>(
            items: [
              for (final item in items)
                if (visible.contains(item.datum)) item,
            ],
            highlighted: _highlighted,
            title: widget.legendTitle,
            ariaLabel: i18n.legendAriaLabel ?? ChartDefaults.legend,
            onHighlightChange: (d) {
              if (_popover && !_pinned) setState(() => _popover = false);
              _setHighlighted(d);
            },
          )
        : null;

    final hasLabels = !(widget.hideTitles && widget.hideDescriptions);
    final base = _Dimensions.bySize[widget.size]!;
    final height = 2 * (base.outerRadius + base.padding + (hasLabels ? _Dimensions.paddingLabels : 0));

    final content = showChart
        ? _buildChart(context, arcs, sum, hasLabels, height)
        : Center(
            child: ChartStatus(
              statusType: widget.statusType,
              isEmpty: isEmpty,
              isNoMatch: isNoMatch,
              empty: widget.empty,
              noMatch: widget.noMatch,
              loadingText: widget.loadingText,
              errorText: widget.errorText,
              recoveryText: widget.recoveryText,
              onRecoveryClick: widget.onRecoveryClick,
            ),
          );

    return ChartFrame(
      filter: filter,
      additionalFilters: showFilters ? widget.additionalFilters : null,
      content: content,
      legend: legend,
      reserveFilterSpace: !finished && !isNoMatch && (!widget.hideFilter || widget.additionalFilters != null),
      reserveLegendSpace: !showChart && !widget.hideLegend,
      minContentHeight: height,
      fitHeight: widget.fitHeight,
    );
  }

  List<CsChartDetailPair> _detailsFor(T d, num sum) {
    final custom = widget.detailPopoverContent;
    if (custom != null) return custom(d, sum);
    final i18n = widget.i18nStrings;
    return [
      CsChartDetailPair(key: i18n.detailsValue ?? 'Value', value: formatChartNumber(d.value)),
      CsChartDetailPair(
        key: i18n.detailsPercentage ?? 'Percentage',
        value: '${sum == 0 ? 0 : (d.value * 100 / sum).toStringAsFixed(0)}%',
      ),
    ];
  }

  Widget _buildChart(BuildContext context, List<_Arc<T>> arcs, num sum, bool hasLabels, double defaultHeight) {
    final cs = context.cs;
    final scaler = MediaQuery.textScalerOf(context);
    final narrow = context.csIsNarrow;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : defaultHeight;
        var height = defaultHeight;
        var dims = _Dimensions.bySize[widget.size]!;
        if (widget.fitHeight && constraints.maxHeight.isFinite) {
          height = math.max(constraints.maxHeight, 0);
          dims = _Dimensions.fit(math.min(height, width), hasLabels);
        }
        // Keep the pie inside narrow screens: shrink it when the labels and
        // the pie would not fit side by side.
        final labelRoom = hasLabels ? 2 * (_Dimensions.paddingLabels + 40) : 0;
        if (width - labelRoom < dims.outerRadius * 2 + dims.padding * 2) {
          final outer = math.max(30.0, (width - labelRoom) / 2 - dims.padding);
          final ratio = dims.outerRadius / dims.innerRadius;
          dims = _Dimensions(outer / ratio, outer, dims.padding, dims.innerLabelPadding, dims.cornerRadius, dims.size);
        }
        _dims = dims;
        final center = Offset(width / 2, height / 2);
        _center = center;
        final donut = widget.variant == CsPieChartVariant.donut;
        final labels = hasLabels ? _layoutLabels(context, arcs, dims, width, sum, scaler) : const <_Label>[];

        final hl = _highlighted;
        final hlArc = arcs.where((a) => a.datum == hl).firstOrNull;
        Widget? popover;
        if (hlArc != null && _popover) {
          final footer = widget.detailPopoverFooter?.call(hlArc.datum);
          popover = ChartDetailBody(
            title: hlArc.datum.title,
            titleMarker: ChartSeriesMarker(type: ChartMarkerType.rectangle, color: hlArc.color),
            rows: [
              for (final p in _detailsFor(hlArc.datum, sum))
                ChartDetailRow(
                  key: p.key ?? '',
                  keyWidget: p.keyWidget,
                  value: p.value ?? '',
                  valueWidget: p.valueWidget,
                ),
            ],
            footer: footer,
            pinned: _pinned,
            compact: true,
            onDismiss: () {
              _clear();
              _focus.requestFocus();
            },
            dismissLabel: chartDismissLabel(context, widget.i18nStrings.detailPopoverDismissAriaLabel),
            size: widget.detailPopoverSize,
          );
          _lastPopover = popover;
        }

        final painter = AnimatedBuilder(
          animation: Listenable.merge([_reveal, _dim]),
          builder: (context, _) => CustomPaint(
            size: Size(width, height),
            painter: _PiePainter<T>(
              arcs: arcs,
              center: center,
              dims: dims,
              donut: donut,
              reveal: CsCurves.showPaced.transform(_reveal.value),
              dimT: _dim.value,
              highlighted: hl,
              fromHighlighted: _dimFrom,
              background: cs.colors.backgroundContainerContent,
              labelLine: cs.colors.strokeChartLine,
              focusColor: cs.colors.borderItemFocused,
              focusVisible: _focusVisible,
              labels: labels,
            ),
          ),
        );

        final hasInner =
            donut &&
            (widget.innerMetricValue != null ||
                (widget.innerMetricDescription != null && dims.size != CsPieChartSize.small));
        final inner = hasInner
            ? Positioned.fromRect(
                rect: Rect.fromCircle(center: center, radius: dims.innerRadius),
                child: IgnorePointer(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.innerMetricValue != null)
                            Text(
                              widget.innerMetricValue!,
                              textAlign: TextAlign.center,
                              style: cs.text(
                                dims.size == CsPieChartSize.small ? CsTypeScale.headingM : CsTypeScale.headingXl,
                              ),
                            ),
                          if (widget.innerMetricDescription != null && dims.size != CsPieChartSize.small)
                            Text(
                              widget.innerMetricDescription!,
                              textAlign: TextAlign.center,
                              style: cs.text(CsTypeScale.headingM, color: CsColor.textBodySecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null;

        final anchorCenter = hlArc == null
            ? center
            : center + _polar((dims.outerRadius + (donut ? dims.innerRadius : 0)) / 2, hlArc.mid);
        Widget chart = SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              RepaintBoundary(child: painter),
              ?inner,
              Positioned.fromRect(
                rect: Rect.fromCenter(center: anchorCenter, width: 2, height: 2),
                child: CsAnchoredOverlay(
                  open: popover != null,
                  side: narrow ? CsSide.top : CsSide.right,
                  sideOffset: CsSpace.xs,
                  preferredExtent: narrow ? 120 : 240,
                  focusPopupWhenUnfocused: false,
                  tapRegionGroupId: _tapGroup,
                  onDismiss: _clear,
                  overlayBuilder: (context, placement) => IgnorePointer(
                    ignoring: !_pinned,
                    child: Semantics(
                      container: true,
                      liveRegion: !_pinned,
                      child: CsPopupSurface(
                        placement: placement,
                        showArrow: true,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: math.max(0, placement.maxWidth - 2 * CsSpace.m)),
                          child: popover ?? _lastPopover ?? const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        );
        chart = MouseRegion(
          onHover: (e) => _onHover(e.localPosition),
          onExit: (_) {
            if (!_pinned && _popover) _clear();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _onTap(d.localPosition),
            child: chart,
          ),
        );
        chart = TapRegion(groupId: _tapGroup, child: chart);

        final i18n = widget.i18nStrings;
        final role = i18n.chartAriaRoleDescription ?? 'Pie chart';
        final segmentRole = i18n.segmentAriaRoleDescription ?? 'Segment';
        String describe(_Arc<T> a) {
          final pct = sum == 0 ? 0 : (a.datum.value * 100 / sum).round();
          return '$segmentRole ${arcs.indexOf(a) + 1} of ${arcs.length}, ${a.datum.title} (${formatChartNumber(a.datum.value)}), $pct%';
        }

        final summary = [
          ?widget.ariaDescription,
          if (hasInner) [?widget.innerMetricValue, ?widget.innerMetricDescription].join(' '),
          '${arcs.length} segments: ${arcs.map((a) => '${a.datum.title} ${formatChartNumber(a.datum.value)}').join(', ')}',
        ].join('. ');
        final n = arcs.length;
        final hlIndex = hlArc == null ? -1 : arcs.indexOf(hlArc);
        return Focus(
          focusNode: _focus,
          onKeyEvent: _onKey,
          includeSemantics: false,
          child: Semantics(
            container: true,
            focusable: true,
            focused: _focus.hasFocus,
            label: [?widget.ariaLabel, role].join(', '),
            hint: summary,
            value: hlArc == null ? null : describe(hlArc),
            increasedValue: hlArc == null ? null : describe(arcs[(hlIndex + 1) % n]),
            decreasedValue: hlArc == null ? null : describe(arcs[(hlIndex - 1 + n) % n]),
            onIncrease: () => _move(1),
            onDecrease: () => _move(-1),
            child: ExcludeSemantics(child: chart),
          ),
        );
      },
    );
  }

  /// Label positions (Cloudscape labels.tsx): a leader line from the
  /// segment's edge, bending at a radius that grows near the top and
  /// bottom, then running sideways; overlapping labels are pushed down and
  /// out around the pie.
  List<_Label> _layoutLabels(
    BuildContext context,
    List<_Arc<T>> arcs,
    _Dimensions dims,
    double width,
    num sum,
    TextScaler scaler,
  ) {
    final cs = context.cs;
    final r = dims.outerRadius;
    final optimize = width - (r + dims.innerLabelPadding) * 2 < 300;
    final titleStyle = cs.text(CsTypeScale.bodyM, color: CsColor.textHeadingDefault);
    final descStyle = cs.text(CsTypeScale.bodyS, color: CsColor.textGroupLabel);
    final out = <_Label>[];
    for (final a in arcs) {
      final angle = _smartAngle(a.start, a.end, optimize);
      final ext = 0.5 * math.cos(2 * angle) + 0.5;
      final start = _polar(r - 1, angle);
      final brk = _polar(r + 20 * ext, angle);
      final right = angle < math.pi;
      final endX = optimize ? brk.dx + 20 * (right ? 1 : -1) : (r + 20) * (right ? 1 : -1);
      final textX = endX + 5 * (right ? 1 : -1);
      final description = widget.hideDescriptions ? null : widget.segmentDescription?.call(a.datum, sum);
      final title = widget.hideTitles ? null : a.datum.title;
      if (title == null && description == null) continue;
      // Text may not run past the chart's edges.
      final maxWidth = math.max(24.0, right ? width / 2 - textX : width / 2 + textX);
      TextPainter paint(String s, TextStyle style) => TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);
      final t = title == null ? null : paint(title, titleStyle);
      final dsc = description == null ? null : paint(description, descStyle);
      final h = (t?.height ?? 0) + (dsc == null ? 0 : (t == null ? 0 : 2) + dsc.height);
      out.add(_Label(a, start, brk, Offset(endX, brk.dy), textX, right, t, dsc, h, (t ?? dsc)!.height));
    }
    // Balance the right side top-down and the left side bottom-up.
    const margin = 10.0;
    final ring = r + dims.innerLabelPadding;
    void balance(List<_Label> side) {
      _Label? prev;
      for (final l in side) {
        if (prev != null) {
          final top = l.top;
          final prevBottom = prev.top + prev.height;
          final dy = prevBottom + margin - top;
          if (dy > 0) {
            final ny = l.end.dy + dy;
            // Push outward if the moved label would cut into the pie.
            final edge = math.min((ny - l.firstLine / 2).abs(), (ny - l.firstLine / 2 + l.height).abs());
            var dx = 0.0;
            if (l.textX.abs() < ring && edge < ring) dx = math.sqrt(ring * ring - edge * edge) - l.textX.abs();
            l.shift(l.right ? dx : -dx, dy);
          }
        }
        prev = l;
      }
    }

    balance(out.where((l) => l.right).toList());
    balance(out.where((l) => !l.right).toList().reversed.toList());
    return out;
  }

  static double _smartAngle(double start, double end, bool optimize) {
    const pad = math.pi / 20;
    if (!optimize || end - start < 2 * pad) return (start + end) / 2;
    final s = start + pad;
    final e = end - pad;
    if (s < 0 && e > 0) return 0;
    if (s < math.pi && e > math.pi) return math.pi;
    final endD = math.min(e, math.min((math.pi - e).abs(), 2 * math.pi - e));
    final startD = math.min(s, math.min((math.pi - s).abs(), 2 * math.pi - s));
    return endD < startD ? e : s;
  }
}

class _Label {
  _Label(
    this.arc,
    this.start,
    this.brk,
    this.end,
    this.textX,
    this.right,
    this.title,
    this.description,
    this.height,
    this.firstLine,
  );

  final _Arc<Object?> arc;
  final Offset start;
  Offset brk;
  Offset end;
  double textX;
  final bool right;
  final TextPainter? title;
  final TextPainter? description;
  final double height;

  /// Height of the first line, which is centered on the leader line.
  final double firstLine;

  double get top => end.dy - firstLine / 2;

  void shift(double dx, double dy) {
    end = end.translate(dx, dy);
    textX += dx;
  }
}

class _PiePainter<T> extends CustomPainter {
  _PiePainter({
    required this.arcs,
    required this.center,
    required this.dims,
    required this.donut,
    required this.reveal,
    required this.dimT,
    required this.highlighted,
    required this.fromHighlighted,
    required this.background,
    required this.labelLine,
    required this.focusColor,
    required this.focusVisible,
    required this.labels,
  });

  final List<_Arc<T>> arcs;
  final Offset center;
  final _Dimensions dims;
  final bool donut;
  final double reveal;
  final double dimT;
  final T? highlighted;
  final T? fromHighlighted;
  final Color background;
  final Color labelLine;
  final Color focusColor;
  final bool focusVisible;
  final List<_Label> labels;

  double _opacity(T d) {
    double at(T? h) => h != null && h != d ? 0.35 : 1;
    final from = at(fromHighlighted);
    return from + (at(highlighted) - from) * dimT;
  }

  Path _sector(double r0, double r1, double a0, double a1) {
    final path = Path();
    final outer = Rect.fromCircle(center: center, radius: r1);
    // Canvas angles start at 3 o'clock; segments start at 12.
    final s = a0 - math.pi / 2;
    final sweep = a1 - a0;
    if (sweep >= 2 * math.pi - 1e-6) {
      path.addOval(outer);
      if (r0 > 0) {
        path
          ..addOval(Rect.fromCircle(center: center, radius: r0))
          ..fillType = PathFillType.evenOdd;
      }
      return path;
    }
    if (r0 <= 0) {
      path
        ..moveTo(center.dx, center.dy)
        ..arcTo(outer, s, sweep, false)
        ..close();
    } else {
      path
        ..arcTo(outer, s, sweep, true)
        ..arcTo(Rect.fromCircle(center: center, radius: r0), s + sweep, -sweep, false)
        ..close();
    }
    return path;
  }

  /// The annular sector [r0]..[r1], [a0]..[a1] shrunk by [d] on every
  /// side: radial edges move [d] inward in parallel (not by an angle), so
  /// the gap between segments has the same width all the way to the center.
  Path? _eroded(double r0, double r1, double a0, double a1, double d) {
    final sweep = a1 - a0;
    final ro = r1 - d;
    if (ro <= d) return null;
    final ao = math.asin(math.min(1, d / ro));
    if (sweep <= 2 * ao) return null;
    Offset at(double r, double angle) => center + _polar(r, angle);
    final outer = Rect.fromCircle(center: center, radius: ro);
    final path = Path()..moveTo(at(ro, a0 + ao).dx, at(ro, a0 + ao).dy);
    path.arcTo(outer, a0 + ao - math.pi / 2, sweep - 2 * ao, false);
    if (r0 > 0) {
      final ri = r0 + d;
      final ai = math.asin(math.min(1, d / ri));
      if (sweep > 2 * ai && ri < ro) {
        final p = at(ri, a1 - ai);
        path.lineTo(p.dx, p.dy);
        path.arcTo(Rect.fromCircle(center: center, radius: ri), a1 - ai - math.pi / 2, -(sweep - 2 * ai), false);
        path.close();
        return path;
      }
    }
    // Pie wedge: the offset edges meet on the bisector, or for a reflex
    // wedge, run into a small arc around the center.
    final half = sweep / 2;
    if (half < math.pi / 2) {
      final apex = at(d / math.sin(half), (a0 + a1) / 2);
      path.lineTo(apex.dx, apex.dy);
    } else {
      final n1 = center + _polar(d, a1 - math.pi / 2);
      path.lineTo(n1.dx, n1.dy);
      path.arcTo(Rect.fromCircle(center: center, radius: d), a1 - math.pi / 2 - math.pi / 2, -(sweep - math.pi), false);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r1 = dims.outerRadius;
    final r0 = donut ? dims.innerRadius : 0.0;
    final cr = dims.cornerRadius;
    // Segments are inset by half the 2px gap plus the corner radius, then
    // stroked back out with round joins: rounded corners like d3's
    // `arc().cornerRadius()`, with Cloudscape's 2px container-colored gap.
    const gap = 1.0;
    for (final a in arcs) {
      final start = a.start * reveal;
      final end = a.end * reveal;
      if (end - start <= 0) continue;
      final o = _opacity(a.datum);
      final paint = Paint()..color = a.color.withValues(alpha: o);
      final full = arcs.length == 1 && reveal >= 1;
      // Like d3, the corner radius shrinks for thin segments so they stay
      // visible (Cloudscape keeps every segment at least 1% of the pie).
      final narrowest = (r0 > 0 ? r0 : r1) * math.sin(math.min(math.pi / 2, (end - start) / 2));
      final c = full ? cr : math.max(0.0, math.min(cr, narrowest - gap - 0.5));
      final body = full
          ? _sector(r0 <= 0 ? 0 : r0 + gap + c, r1 - gap - c, 0, 2 * math.pi)
          : _eroded(r0, r1, start, end, gap + c);
      if (body == null) continue;
      canvas.drawPath(body, paint);
      if (c > 0) {
        canvas.drawPath(
          body,
          Paint()
            ..color = paint.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = c * 2
            ..strokeJoin = StrokeJoin.round,
        );
      }
      if (a.datum == highlighted) {
        // The highlight ring 4 to 6px outside the segment.
        canvas.drawPath(_sector(r1 + 4, r1 + 6, start, end), Paint()..color = a.color);
        if (focusVisible) {
          canvas.drawPath(
            _sector(math.max(0, r0 - 3), r1 + 9, start, end),
            Paint()
              ..color = focusColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..strokeJoin = StrokeJoin.round,
          );
        }
      }
    }
    if (focusVisible && highlighted == null) {
      canvas.drawCircle(
        center,
        r1 + 9,
        Paint()
          ..color = focusColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    if (reveal < 1) return;
    final line = Paint()
      ..color = labelLine
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final l in labels) {
      final o = _opacity(l.arc.datum as T);
      canvas.saveLayer(null, Paint()..color = const Color(0xFF000000).withValues(alpha: o));
      canvas.drawLine(center + l.start, center + l.brk, line);
      canvas.drawLine(center + l.brk, center + l.end, line);
      var y = center.dy + l.top;
      for (final tp in [l.title, l.description]) {
        if (tp == null) continue;
        final x = l.right ? center.dx + l.textX : center.dx + l.textX - tp.width;
        tp.paint(canvas, Offset(x, y));
        y += tp.height + 2;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PiePainter<T> old) => true;
}
