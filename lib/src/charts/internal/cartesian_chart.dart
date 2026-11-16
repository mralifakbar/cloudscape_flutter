// The engine behind CsLineChart, CsBarChart, CsMixedLineBarChart and
// CsAreaChart: status and filtering (Cloudscape mixed-line-bar-chart/
// internal.tsx, area-chart/internal.tsx), the plot with its hover, touch
// and keyboard navigation (chart-container.tsx, hooks/use-navigation.ts,
// hooks/use-mouse-hover.ts), and the detail popover.
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../overlays/cs_anchored_overlay.dart';
import '../../overlays/cs_popup_surface.dart';
import '../../system/cs_haptics.dart';
import '../../system/cs_strings.dart';
import '../../theme/theme.dart';
import '../cs_chart_series.dart';
import 'cartesian_model.dart';
import 'chart_math.dart';
import 'chart_parts.dart';

/// Line, bar and mixed charts share one model; area charts stack areas and
/// add a total to the popover.
enum CartesianKind { mixed, area }

const Set<PointerDeviceKind> _kTouch = {
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
};

class CartesianChart<T> extends StatefulWidget {
  const CartesianChart({
    super.key,
    required this.kind,
    required this.series,
    required this.defaultRoleDescription,
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
    this.detailTotalFormatter,
    this.i18nStrings = const CsChartI18nStrings(),
    this.ariaLabel,
    this.ariaDescription,
  });

  final CartesianKind kind;
  final List<CsChartSeries<T>> series;
  final String defaultRoleDescription;
  final List<CsChartSeries<T>>? visibleSeries;
  final ValueChanged<List<CsChartSeries<T>>>? onFilterChange;
  final CsChartSeries<T>? highlightedSeries;
  final ValueChanged<CsChartSeries<T>?>? onHighlightChange;
  final CsChartScaleType xScaleType;
  final CsChartYScaleType yScaleType;
  final List<T>? xDomain;
  final List<num>? yDomain;
  final String? xTitle;
  final String? yTitle;
  final String? legendTitle;
  final CsChartTickFormatter<T>? xTickFormatter;
  final CsChartTickFormatter<num>? yTickFormatter;
  final bool stackedBars;
  final bool horizontalBars;
  final bool emphasizeBaselineAxis;
  final double height;
  final bool fitHeight;
  final bool hideFilter;
  final bool hideLegend;
  final Widget? additionalFilters;
  final CsChartStatusType statusType;
  final Widget? empty;
  final Widget? noMatch;
  final String? loadingText;
  final String? errorText;
  final String? recoveryText;
  final VoidCallback? onRecoveryClick;
  final CsChartPopoverSize detailPopoverSize;
  final Widget Function(T x)? detailPopoverFooter;
  final CsChartDetailPopoverSeriesContent<T>? detailPopoverSeriesContent;
  final CsChartTickFormatter<num>? detailTotalFormatter;
  final CsChartI18nStrings i18nStrings;
  final String? ariaLabel;
  final String? ariaDescription;

  @override
  State<CartesianChart<T>> createState() => CartesianChartState<T>();
}

/// What the pointer or keyboard points at: navigation position [nav] and,
/// for a single point or threshold, its [series].
class _Highlight<T> {
  const _Highlight(this.nav, [this.series]);

  final int nav;
  final CsChartSeries<T>? series;

  @override
  bool operator ==(Object other) => other is _Highlight<T> && other.nav == nav && other.series == series;

  @override
  int get hashCode => Object.hash(nav, series);
}

class CartesianChartState<T> extends State<CartesianChart<T>> with TickerProviderStateMixin {
  late List<CsChartSeries<T>> _visible;
  CsChartSeries<T>? _highlightedSeries;
  _Highlight<T>? _hl;
  bool _pinned = false;
  bool _touch = false;
  bool _touchUp = true;
  bool _scrubbing = false;
  bool _focusVisible = false;
  bool _revealed = false;
  final FocusNode _focus = FocusNode(debugLabel: 'Cs chart plot');
  final Object _tapGroup = Object();
  late final AnimationController _reveal;
  late final AnimationController _dim;
  CsChartSeries<T>? _dimFromSeries;
  int? _dimFromGroup;
  CartesianModel<T>? _model;
  Widget? _lastPopover;

  @override
  void initState() {
    super.initState();
    _visible = widget.visibleSeries ?? List.of(widget.series);
    _highlightedSeries = widget.highlightedSeries;
    _reveal = AnimationController(vsync: this, duration: CsDurations.complex);
    _dim = AnimationController(vsync: this, duration: CsDurations.transitionQuick, value: 1);
    _focus.addListener(_onFocusChange);
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void didUpdateWidget(CartesianChart<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget;
    if (widget.visibleSeries == null && !_sameList(old.series, widget.series)) {
      _visible = [
        for (final s in widget.series)
          if (!old.series.contains(s) || _visible.contains(s)) s,
      ];
    }
    if (widget.highlightedSeries != old.highlightedSeries) {
      _setHighlightedSeries(widget.highlightedSeries, notify: false);
    }
  }

  static bool _sameList<E>(List<E> a, List<E> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i]) && a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _reveal.dispose();
    _dim.dispose();
    super.dispose();
  }

  List<CsChartSeries<T>> get _visibleSeries {
    final v = widget.visibleSeries ?? _visible;
    return [
      for (final s in widget.series)
        if (v.contains(s)) s,
    ];
  }

  void _onHighlightMode(FocusHighlightMode mode) => _updateFocusVisible();

  void _updateFocusVisible() {
    final v = _focus.hasFocus && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (v != _focusVisible) setState(() => _focusVisible = v);
  }

  void _onFocusChange() {
    _updateFocusVisible();
    if (_focus.hasFocus) {
      if (FocusManager.instance.highlightMode == FocusHighlightMode.traditional && _hl == null) _focusFirst();
    } else if (!_pinned) {
      _clear();
    }
  }

  void _startDim() {
    if (CsMotion.reduceMotion(context)) {
      _dim.value = 1;
    } else {
      _dim.forward(from: 0);
    }
  }

  int? get _group {
    final m = _model;
    final h = _hl;
    if (m == null || h == null || !m.groupNavigation || h.nav >= m.navigation.length) return null;
    return m.navigation[h.nav].category;
  }

  void _setHighlightedSeries(CsChartSeries<T>? s, {bool notify = true}) {
    if (s == _highlightedSeries) return;
    _dimFromSeries = _highlightedSeries;
    _dimFromGroup = _group;
    setState(() => _highlightedSeries = s);
    _startDim();
    if (notify) widget.onHighlightChange?.call(s);
  }

  void _setHighlight(_Highlight<T>? h) {
    if (h == _hl) return;
    final prevGroup = _group;
    setState(() => _hl = h);
    if (h == null) {
      _pinned = false;
    }
    final group = _group;
    if (group != prevGroup) {
      _dimFromGroup = prevGroup;
      _dimFromSeries = _highlightedSeries;
      _startDim();
    }
    // A single point highlights its series; an x or a group clears it.
    _setHighlightedSeries(h?.series);
  }

  void _clear() {
    if (_hl == null && !_pinned) return;
    setState(() => _pinned = false);
    _setHighlight(null);
  }

  void _dismissPopover() {
    _clear();
    if (_focus.hasFocus) setState(() {});
  }

  void _focusFirst() {
    final m = _model;
    if (m == null || m.navigation.isEmpty) return;
    final navigable = _navigableSeries(m);
    if (!m.groupNavigation && navigable.length == 1) {
      _setHighlight(_Highlight(0, navigable.first));
    } else {
      _setHighlight(const _Highlight(0));
    }
  }

  List<CsChartSeries<T>> _navigableSeries(CartesianModel<T> m) => [
    for (final r in m.config.visible)
      if (r.series.type == CsChartSeriesType.line || r.series.type == CsChartSeriesType.area || r.series.isYThreshold)
        r.series,
  ];

  /// Navigation indices where [s] has a point (every index for thresholds).
  List<int> _navOf(CartesianModel<T> m, CsChartSeries<T> s) {
    if (s.isThreshold) return [for (var i = 0; i < m.navigation.length; i++) i];
    return [
      for (var i = 0; i < m.navigation.length; i++)
        if (s.data.any((d) => d.x == m.navigation[i].value)) i,
    ];
  }

  void _moveX(int delta) {
    final m = _model;
    if (m == null || m.navigation.isEmpty) return;
    final h = _hl;
    final n = m.navigation.length;
    if (h == null) {
      _focusFirst();
      return;
    }
    if (h.series != null && !m.groupNavigation) {
      final idx = _navOf(m, h.series!);
      if (idx.isEmpty) return;
      final at = idx.indexOf(h.nav);
      final next = idx[((at < 0 ? 0 : at + delta) % idx.length + idx.length) % idx.length];
      _setHighlight(_Highlight(next, h.series));
    } else {
      _setHighlight(_Highlight(((h.nav + delta) % n + n) % n));
    }
  }

  void _moveSeries(int delta) {
    final m = _model;
    if (m == null || m.groupNavigation || m.navigation.isEmpty) return;
    final navigable = _navigableSeries(m);
    if (navigable.isEmpty) return;
    final h = _hl ?? const _Highlight(0);
    final multiple = navigable.length > 1;
    final first = multiple ? -1 : 0;
    var i = h.series == null ? -1 : navigable.indexOf(h.series!);
    i += delta;
    if (i > navigable.length - 1) i = first;
    if (i < first) i = navigable.length - 1;
    if (i == -1) {
      _setHighlight(_Highlight(h.nav));
      return;
    }
    final s = navigable[i];
    final idx = _navOf(m, s);
    if (idx.isEmpty) return;
    // Closest position of the next series to the current x.
    final target = m.navigation[h.nav].position;
    var best = idx.first;
    for (final j in idx) {
      if ((m.navigation[j].position - target).abs() < (m.navigation[best].position - target).abs()) best = j;
    }
    _setHighlight(_Highlight(best, s));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final m = _model;
    if (m == null || m.navigation.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Horizontal bars run top to bottom: Up and Down move between groups.
    final horizontal = m.horizontal;
    if (key == LogicalKeyboardKey.arrowRight && !horizontal) {
      _moveX(rtl ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowLeft && !horizontal) {
      _moveX(rtl ? 1 : -1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      horizontal ? _moveX(1) : _moveSeries(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      horizontal ? _moveX(-1) : _moveSeries(-1);
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.arrowLeft) {
      _moveX(key == LogicalKeyboardKey.arrowRight ? 1 : -1);
    } else if (key == LogicalKeyboardKey.home) {
      _setHighlight(_Highlight(0, _hl?.series));
    } else if (key == LogicalKeyboardKey.end) {
      _setHighlight(_Highlight(m.navigation.length - 1, _hl?.series));
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (_hl == null) _focusFirst();
      setState(() => _pinned = true);
    } else if (key == LogicalKeyboardKey.escape) {
      if (_hl == null) return KeyEventResult.ignored;
      _dismissPopover();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// Highlight under [p] (canvas coordinates). Mouse hover snaps to a point
  /// within 6px (Cloudscape `MAX_HOVER_MARGIN`); touch scrubs between x.
  void _pointAt(Offset p, {required bool touch}) {
    final m = _model;
    if (m == null || m.navigation.isEmpty) return;
    if (m.groupNavigation) {
      var g = m.groupAt(p);
      if (g == null && touch) g = m.nearestNav(m.horizontal ? p.dy : p.dx);
      if (g == null) {
        if (!_pinned) _clear();
        return;
      }
      _setTouchHighlight(_Highlight(g), touch);
      return;
    }
    final nav = m.nearestNav(p.dx)!;
    if (!touch) {
      const margin = 6.0;
      final x = m.navigation[nav].position;
      if ((p.dx - x).abs() < margin) {
        ScaledPoint<T>? best;
        var bestD = double.infinity;
        for (final pt in m.pointsAt(nav)) {
          final d = (pt.position.dy - p.dy).abs();
          if (d < bestD) {
            bestD = d;
            best = pt;
          }
        }
        CsChartSeries<T>? hit = bestD < margin ? best?.series : null;
        if (hit == null) {
          for (final r in m.config.visible.where((r) => r.series.isYThreshold)) {
            if ((m.valuePosition(r.series.y!) - p.dy).abs() < margin) hit = r.series;
          }
        }
        if (hit != null) {
          _setTouchHighlight(_Highlight(nav, hit), touch);
          return;
        }
      }
    }
    _setTouchHighlight(_Highlight(nav), touch);
  }

  void _setTouchHighlight(_Highlight<T> h, bool touch) {
    if (touch && _hl != null && _hl!.nav != h.nav) csHaptic(CsHaptic.selection);
    _touch = touch;
    _setHighlight(h);
  }

  void _onMouseTap() {
    // Cloudscape: a click pins an open popover, a second click dismisses it.
    if (_hl == null) return;
    if (_pinned) {
      _dismissPopover();
    } else {
      setState(() => _pinned = true);
    }
  }

  String _summary(CartesianModel<T> m, CsChartI18nStrings i18n) {
    final visible = m.config.visible.map((r) => r.series.title).toList();
    final parts = <String>[
      if (widget.ariaDescription != null) widget.ariaDescription!,
      '${visible.length} ${visible.length == 1 ? 'series' : 'series'}: ${visible.join(', ')}',
    ];
    final xAxis = i18n.xAxisAriaRoleDescription ?? ChartDefaults.xAxis;
    final yAxis = i18n.yAxisAriaRoleDescription ?? ChartDefaults.yAxis;
    if (m.categorical && m.categories.isNotEmpty) {
      parts.add('$xAxis${widget.xTitle == null ? '' : ' ${widget.xTitle}'}: ${m.categories.map(m.formatX).join(', ')}');
    } else if (m.navigation.isNotEmpty) {
      parts.add(
        '$xAxis${widget.xTitle == null ? '' : ' ${widget.xTitle}'} from ${m.formatX(m.navigation.first.value)} '
        'to ${m.formatX(m.navigation.last.value)}',
      );
    }
    parts.add(
      '$yAxis${widget.yTitle == null ? '' : ' ${widget.yTitle}'} from ${m.formatY(m.valueDomain.$1)} '
      'to ${m.formatY(m.valueDomain.$2)}',
    );
    return parts.join('. ');
  }

  String _formatValue(CsChartSeries<T> s, num y, T x) => s.valueFormatter?.call(y, x) ?? formatChartNumber(y);

  /// The rows of the popover and the semantic value for the highlight.
  (String, List<ChartDetailRow>, List<ChartDetailRow>) _details(CartesianModel<T> m, _Highlight<T> h) {
    final nav = m.navigation[h.nav];
    final x = nav.value;
    final rows = <ChartDetailRow>[];
    final extra = <ChartDetailRow>[];
    final colors = {for (final r in m.config.visible) r.series: r.color};
    if (widget.kind == CartesianKind.area) {
      num total = 0;
      for (final r in m.config.visible) {
        final s = r.series;
        if (s.isYThreshold) {
          rows.add(
            ChartDetailRow(
              key: s.title,
              value: s.thresholdValueFormatter?.call(s.y!) ?? formatChartNumber(s.y!),
              color: r.color,
              marker: ChartMarkerType.dashed,
              dimmed: h.series != null && h.series != s,
            ),
          );
          continue;
        }
        final d = s.data.where((d) => d.x == x).firstOrNull;
        if (d == null) continue;
        total += d.y;
        rows.add(
          ChartDetailRow(
            key: s.title,
            value: _formatValue(s, d.y, x),
            color: r.color,
            marker: markerFor(s.type),
            dimmed: h.series != null && h.series != s,
          ),
        );
      }
      extra.add(
        ChartDetailRow(
          key: widget.i18nStrings.detailTotalLabel ?? ChartDefaults.total,
          value:
              widget.detailTotalFormatter?.call(total) ??
              widget.yTickFormatter?.call(total) ??
              formatChartNumber(total),
          bold: true,
        ),
      );
      return (m.formatX(x), rows, extra);
    }
    final shown = h.series == null
        ? m.config.visible.map((r) => r.series)
        : m.config.visible.map((r) => r.series).where((s) => s == h.series || s.isXThreshold);
    for (final s in shown) {
      final color = colors[s];
      if (s.isXThreshold) {
        if (s.x == x) rows.add(ChartDetailRow(key: s.title, value: '', color: color, marker: ChartMarkerType.dashed));
        continue;
      }
      if (s.isYThreshold) {
        rows.add(
          ChartDetailRow(
            key: s.title,
            value: s.thresholdValueFormatter?.call(s.y!) ?? formatChartNumber(s.y!),
            color: color,
            marker: ChartMarkerType.dashed,
          ),
        );
        continue;
      }
      final d = s.data.where((d) => d.x == x).firstOrNull;
      if (d == null) continue;
      final custom = widget.detailPopoverSeriesContent?.call(s, x, d.y);
      final expandable = (custom?.expandable ?? false) && (custom?.subItems.isNotEmpty ?? false);
      rows.add(
        ChartDetailRow(
          key: custom?.key ?? s.title,
          keyWidget: expandable ? null : custom?.keyWidget,
          value: custom?.value ?? _formatValue(s, d.y, x),
          valueWidget: custom?.valueWidget,
          color: color,
          marker: markerFor(s.type),
          subItems: custom?.subItems ?? const [],
          expandable: expandable,
        ),
      );
    }
    return (m.formatX(x), rows, extra);
  }

  String _activeLabel(String position, List<ChartDetailRow> rows, List<ChartDetailRow> extra) => [
    position,
    for (final r in [...rows, ...extra]) r.value.isEmpty ? r.key : '${r.key} ${r.value}',
  ].join(', ');

  // Where the popover attaches: the point, the x line or the bar group.
  Rect _anchor(CartesianModel<T> m, _Highlight<T> h, bool narrow) {
    final nav = m.navigation[h.nav];
    if (h.series != null) {
      final s = h.series!;
      final y = s.isYThreshold
          ? m.valuePosition(s.y!)
          : m.pointsAt(h.nav).where((p) => p.series == s).firstOrNull?.position.dy ?? m.plot.center.dy;
      return Rect.fromCenter(center: Offset(nav.position, y), width: 8, height: 8);
    }
    if (m.groupNavigation) {
      final rect = m.groupRect(nav.category!);
      final bars = m.barsAt(nav.category!);
      if (m.horizontal) {
        // The group spans the plot's width: attach to the end of its bars.
        final right = bars.isEmpty ? rect.center.dx : bars.map((b) => b.rect.right).reduce(math.max);
        return Rect.fromLTRB(right, rect.top, right, rect.bottom);
      }
      if (!narrow || bars.isEmpty) return rect;
      final top = bars.map((b) => b.rect.top).reduce(math.min);
      return Rect.fromLTRB(rect.left, top, rect.right, top);
    }
    if (narrow) {
      final pts = m.pointsAt(h.nav);
      final top = pts.isEmpty ? m.plot.top : pts.map((p) => p.position.dy).reduce(math.min);
      return Rect.fromCenter(center: Offset(nav.position, top), width: 8, height: 8);
    }
    return Rect.fromLTRB(nav.position, m.plot.top, nav.position, m.plot.bottom);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final i18n = widget.i18nStrings;
    final visibleSeries = _visibleSeries;
    final isEmpty = visibleSeries.isEmpty;
    final isNoMatch = isEmpty && widget.series.isNotEmpty;
    final finished = widget.statusType == CsChartStatusType.finished;
    final showChart = finished && !isEmpty;
    final resolvedColors = CsChartColors.resolve<CsChartSeries<T>>(
      cs,
      widget.series,
      isThreshold: (s) => s.isThreshold,
      ownColor: (s) => s.color ?? (s.colorToken == null ? null : cs.color(s.colorToken!)),
    );
    final resolved = [
      for (var i = 0; i < widget.series.length; i++) ResolvedSeries(widget.series[i], resolvedColors[i], i),
    ];
    final items = [
      for (final r in resolved)
        ChartItem(label: r.series.title, datum: r.series, color: r.color, marker: markerFor(r.series.type)),
    ];

    if (showChart && !_revealed) {
      _revealed = true;
      if (CsMotion.reduceMotion(context)) {
        _reveal.value = 1;
      } else {
        _reveal.forward(from: 0);
      }
    }

    final showFilters = finished && (!isEmpty || isNoMatch) && (widget.additionalFilters != null || !widget.hideFilter);
    final showLegend = !widget.hideLegend && !isEmpty && finished;
    final filter = showFilters && !widget.hideFilter
        ? ChartFilter<CsChartSeries<T>>(
            items: items,
            selected: visibleSeries,
            label: i18n.filterLabel ?? ChartDefaults.filterLabel,
            placeholder: i18n.filterPlaceholder ?? ChartDefaults.filterPlaceholder,
            selectedAriaLabel: i18n.filterSelectedAriaLabel ?? ChartDefaults.filterSelected,
            onChange: (next) {
              if (widget.visibleSeries == null) setState(() => _visible = next);
              _clear();
              widget.onFilterChange?.call(next);
            },
          )
        : null;
    final legend = showLegend
        ? ChartLegend<CsChartSeries<T>>(
            items: [
              for (final item in items)
                if (visibleSeries.contains(item.datum)) item,
            ],
            highlighted: _hl == null ? _highlightedSeries : null,
            title: widget.legendTitle,
            ariaLabel: i18n.legendAriaLabel ?? ChartDefaults.legend,
            onHighlightChange: (s) {
              if (_hl != null && !_pinned) setState(() => _hl = null);
              _setHighlightedSeries(s);
            },
          )
        : null;

    final Widget content = showChart
        ? _buildChart(context, resolved, visibleSeries)
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
      reserveFilterSpace: !showChart && !isNoMatch && (!widget.hideFilter || widget.additionalFilters != null),
      reserveLegendSpace: !showChart && !widget.hideLegend,
      minContentHeight: widget.height,
      fitHeight: widget.fitHeight,
    );
  }

  Widget _buildChart(BuildContext context, List<ResolvedSeries<T>> resolved, List<CsChartSeries<T>> visibleSeries) {
    final cs = context.cs;
    final scaler = MediaQuery.textScalerOf(context);
    final strings = context.csStrings;
    final narrow = context.csIsNarrow;
    final tickStyle = cs.text(CsTypeScale.bodyS, color: CsColor.textBodySecondary);
    final titleStyle = cs.text(CsTypeScale.bodyM, weight: CsTypography.bold);
    final yTitle = widget.yTitle == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: CsSpace.l),
            child: ExcludeSemantics(child: Text(widget.yTitle!, style: titleStyle)),
          );
    final xTitle = widget.xTitle == null
        ? null
        : ExcludeSemantics(
            child: Text(widget.xTitle!, style: titleStyle, textAlign: TextAlign.center),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 500.0;
        var plotHeight = widget.height;
        if (widget.fitHeight && constraints.maxHeight.isFinite) {
          final yTitleH = widget.yTitle == null ? 0 : scaler.scale(CsFontTokens.lineHeightBodyM) + CsSpace.l;
          final xTitleH = widget.xTitle == null ? 0 : scaler.scale(CsFontTokens.lineHeightBodyM);
          final bottom = kTickLength + kTickMargin + scaler.scale(kTickLineHeight);
          plotHeight = math.max(40, constraints.maxHeight - yTitleH - xTitleH - bottom);
        }
        final config = CartesianConfig<T>(
          series: resolved,
          visible: [
            for (final r in resolved)
              if (visibleSeries.contains(r.series)) r,
          ],
          xScaleType: widget.xScaleType,
          yScaleType: widget.yScaleType,
          xDomain: widget.xDomain,
          yDomain: widget.yDomain,
          stackedBars: widget.stackedBars,
          horizontalBars: widget.horizontalBars,
          stackedAreas: widget.kind == CartesianKind.area,
          xTickFormatter: widget.xTickFormatter,
          yTickFormatter: widget.yTickFormatter,
          strings: strings,
          tickStyle: tickStyle,
          textScaler: scaler,
        );
        final m = CartesianModel.build<T>(config, width, plotHeight);
        _model = m;
        var h = _hl;
        if (h != null && h.nav >= m.navigation.length) {
          h = null;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) _clear();
          });
        }

        String? activeLabel;
        String? increasedLabel;
        String? decreasedLabel;
        Widget? popover;
        if (h != null) {
          String labelAt(int nav) {
            final n = m.navigation.length;
            final (p, r, e) = _details(m, _Highlight((nav % n + n) % n, h!.series));
            return _activeLabel(p, r, e);
          }

          increasedLabel = labelAt(h.nav + 1);
          decreasedLabel = labelAt(h.nav - 1);
          final (position, rows, extra) = _details(m, h);
          activeLabel = _activeLabel(position, rows, extra);
          final footer = widget.detailPopoverFooter?.call(m.navigation[h.nav].value);
          popover = ChartDetailBody(
            title: position,
            rows: rows,
            extraRows: extra,
            footer: footer,
            pinned: _pinned,
            onDismiss: () {
              _dismissPopover();
              _focus.requestFocus();
            },
            dismissLabel: chartDismissLabel(context, widget.i18nStrings.detailPopoverDismissAriaLabel),
            size: widget.detailPopoverSize,
            expandLabel: widget.i18nStrings.expandAriaLabel ?? ChartDefaults.expand,
            collapseLabel: widget.i18nStrings.collapseAriaLabel ?? ChartDefaults.collapse,
          );
          _lastPopover = popover;
        }

        final colors = _PaintColors(
          grid: cs.colors.chartsLineGrid,
          tick: cs.colors.chartsLineTick,
          axis: cs.colors.chartsLineAxis,
          markerFill: cs.colors.backgroundContainerContent,
          focus: cs.colors.borderItemFocused,
        );
        final group = h == null || !m.groupNavigation ? null : m.navigation[h.nav].category;

        final base = AnimatedBuilder(
          animation: Listenable.merge([_reveal, _dim]),
          builder: (context, _) => CustomPaint(
            size: m.size,
            painter: _BasePainter<T>(
              model: m,
              colors: colors,
              tickStyle: tickStyle,
              scaler: scaler,
              reveal: CsCurves.showPaced.transform(_reveal.value),
              dimT: _dim.value,
              highlighted: _highlightedSeries,
              fromHighlighted: _dimFromSeries,
              group: group,
              fromGroup: _dimFromGroup,
              emphasizeBaseline: widget.emphasizeBaselineAxis,
            ),
          ),
        );
        final overlay = CustomPaint(
          size: m.size,
          painter: _OverlayPainter<T>(model: m, colors: colors, highlight: h, focusVisible: _focusVisible),
        );

        final anchor = h == null ? null : _anchor(m, h, narrow);
        final popoverOpen = popover != null;
        final anchorRect = anchor ?? Rect.fromLTWH(m.plot.left, m.plot.top, 0, 0);
        final stack = Stack(
          clipBehavior: Clip.none,
          children: [
            RepaintBoundary(child: base),
            overlay,
            Positioned.fromRect(
              rect: anchorRect,
              child: CsAnchoredOverlay(
                open: popoverOpen,
                side: narrow ? CsSide.top : CsSide.right,
                align: CsAlign.center,
                sideOffset: CsSpace.xs,
                preferredExtent: narrow ? 120 : math.min(widget.detailPopoverSize.maxWidth, 240),
                dismissOnOutsideTap: true,
                closeOnEscape: true,
                focusPopupWhenUnfocused: false,
                tapRegionGroupId: _tapGroup,
                onDismiss: _dismissPopover,
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
        );

        Widget plot = SizedBox.fromSize(size: m.size, child: stack);
        plot = MouseRegion(
          onHover: (e) {
            if (_pinned) return;
            _pointAt(e.localPosition, touch: false);
          },
          onExit: (_) {
            if (!_pinned && !_touch) _clear();
          },
          child: plot,
        );
        plot = Listener(
          onPointerDown: (e) {
            if (_kTouch.contains(e.kind)) _touchUp = false;
          },
          onPointerUp: (e) {
            if (_kTouch.contains(e.kind)) {
              _touchUp = true;
              // A lifted finger keeps the popover, pinned so its content
              // (links, expandable rows) can be used.
              if (_hl != null) setState(() => _pinned = true);
            }
          },
          onPointerCancel: (e) {
            if (_kTouch.contains(e.kind)) _clear();
          },
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: {
              _ScrubRecognizer: GestureRecognizerFactoryWithHandlers<_ScrubRecognizer>(
                () => _ScrubRecognizer(supportedDevices: _kTouch),
                (r) => r
                  ..onDown = (d) {
                    _scrubbing = false;
                    _pinned = false;
                    _pointAt(d.localPosition, touch: true);
                  }
                  ..onStart = (d) {
                    _scrubbing = true;
                    _pinned = false;
                    _pointAt(d.localPosition, touch: true);
                  }
                  ..onUpdate = (d) {
                    _pointAt(d.localPosition, touch: true);
                  }
                  ..onEnd = (_) {
                    _scrubbing = false;
                  }
                  ..onCancel = () {
                    // Lifted without moving: a tap, keep it. Otherwise a
                    // vertical scroll took the gesture over.
                    if (!_touchUp && !_scrubbing) _clear();
                  },
              ),
              TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                () =>
                    TapGestureRecognizer(supportedDevices: const {PointerDeviceKind.mouse, PointerDeviceKind.trackpad}),
                (r) => r
                  ..onTapUp = (d) {
                    _focus.requestFocus();
                    if (_hl == null) _pointAt(d.localPosition, touch: false);
                    _onMouseTap();
                  },
              ),
            },
            child: plot,
          ),
        );
        plot = TapRegion(groupId: _tapGroup, child: plot);

        final roleDescription = widget.i18nStrings.chartAriaRoleDescription ?? widget.defaultRoleDescription;
        plot = Focus(
          focusNode: _focus,
          onKeyEvent: _onKey,
          includeSemantics: false,
          child: Semantics(
            container: true,
            focusable: true,
            focused: _focus.hasFocus,
            label: [?widget.ariaLabel, roleDescription].join(', '),
            hint: _summary(m, widget.i18nStrings),
            value: activeLabel,
            increasedValue: increasedLabel,
            decreasedValue: decreasedLabel,
            onIncrease: () => _moveX(1),
            onDecrease: () => _moveX(-1),
            child: ExcludeSemantics(child: plot),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [?yTitle, plot, ?xTitle],
        );
      },
    );
  }
}

class _ScrubRecognizer extends HorizontalDragGestureRecognizer {
  _ScrubRecognizer({super.supportedDevices});
}

class _PaintColors {
  const _PaintColors({
    required this.grid,
    required this.tick,
    required this.axis,
    required this.markerFill,
    required this.focus,
  });

  final Color grid;
  final Color tick;
  final Color axis;
  final Color markerFill;
  final Color focus;

  @override
  bool operator ==(Object other) =>
      other is _PaintColors &&
      other.grid == grid &&
      other.tick == tick &&
      other.axis == axis &&
      other.markerFill == markerFill &&
      other.focus == focus;

  @override
  int get hashCode => Object.hash(grid, tick, axis, markerFill, focus);
}

/// Grid, ticks, labels and series. Repaints for the reveal and dimming.
class _BasePainter<T> extends CustomPainter {
  _BasePainter({
    required this.model,
    required this.colors,
    required this.tickStyle,
    required this.scaler,
    required this.reveal,
    required this.dimT,
    required this.highlighted,
    required this.fromHighlighted,
    required this.group,
    required this.fromGroup,
    required this.emphasizeBaseline,
  });

  final CartesianModel<T> model;
  final _PaintColors colors;
  final TextStyle tickStyle;
  final TextScaler scaler;
  final double reveal;
  final double dimT;
  final CsChartSeries<T>? highlighted;
  final CsChartSeries<T>? fromHighlighted;
  final int? group;
  final int? fromGroup;
  final bool emphasizeBaseline;

  double _seriesOpacity(CsChartSeries<T> s, CsChartSeries<T>? h) => h != null && h != s ? 0.3 : 1;

  double _opacity(CsChartSeries<T> s, {int? category}) {
    double at(CsChartSeries<T>? h, int? g) {
      var o = _seriesOpacity(s, h);
      if (category != null && g != null && g != category) o *= 0.3;
      return o;
    }

    final to = at(highlighted, group);
    final from = at(fromHighlighted, fromGroup);
    return from + (to - from) * dimT;
  }

  void _text(Canvas canvas, List<String> lines, Offset anchor, {required TextAlign align, bool center = false}) {
    final lineHeight = scaler.scale(kTickLineHeight);
    for (var i = 0; i < lines.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: lines[i], style: tickStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final dy = center
          ? anchor.dy + (i - (lines.length - 1) / 2) * lineHeight - tp.height / 2
          : anchor.dy + i * lineHeight;
      final dx = switch (align) {
        TextAlign.right || TextAlign.end => anchor.dx - tp.width,
        TextAlign.center => anchor.dx - tp.width / 2,
        _ => anchor.dx,
      };
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final m = model;
    final plot = m.plot;
    final hairline = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Grid lines and value labels.
    if (!m.horizontal) {
      for (final t in m.leftTicks) {
        final y = t.position.roundToDouble() + 0.5;
        canvas.drawLine(Offset(plot.left - kTickLength, y), Offset(plot.right, y), hairline..color = colors.grid);
        _text(
          canvas,
          t.lines,
          Offset(plot.left - kTickLength - kTickMargin, t.position),
          align: TextAlign.right,
          center: true,
        );
      }
    } else {
      for (final t in m.leftTicks) {
        _text(
          canvas,
          t.lines,
          Offset(plot.left - kTickLength - kTickMargin, t.position),
          align: TextAlign.right,
          center: true,
        );
      }
      for (final v in m.valueTicks) {
        final x = m.valueScale(v).roundToDouble() + 0.5;
        canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), hairline..color = colors.grid);
      }
    }
    // Bottom ticks and labels.
    for (final t in m.bottomTicks) {
      final x = t.position.roundToDouble() + 0.5;
      canvas.drawLine(Offset(x, plot.bottom), Offset(x, plot.bottom + kTickLength), hairline..color = colors.tick);
      _text(canvas, t.lines, Offset(t.position, plot.bottom + kTickLength + kTickMargin), align: TextAlign.center);
    }

    final baseline = emphasizeBaseline ? _baseline(m) : null;
    if (baseline != null && m.linesOnly) _drawBaseline(canvas, baseline);

    canvas.save();
    // Data is clipped to the plot, revealed from the start of the x axis.
    final clip = m.horizontal
        ? plot.inflate(2)
        : Rect.fromLTWH(plot.left - 4, plot.top - 4, (plot.width + 8) * reveal, plot.height + 8);
    canvas.clipRect(clip);

    const strokeCap = StrokeCap.round;
    for (final area in m.areas) {
      final o = _opacity(area.series);
      canvas.drawPath(area.fill, Paint()..color = area.color.withValues(alpha: 0.4 * o));
      canvas.drawPath(
        area.line,
        Paint()
          ..color = area.color.withValues(alpha: o)
          ..style = PaintingStyle.stroke
          ..strokeWidth = CsBorderLine.lineChartWidth
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = strokeCap,
      );
    }

    for (final bar in m.bars) {
      final o = _opacity(bar.series, category: bar.category);
      var rect = bar.rect;
      if (reveal < 1) {
        // Bars grow out of the baseline.
        final base = m.valueScale(math.max(m.valueDomain.$1, math.min(m.valueDomain.$2, 0)).toDouble());
        rect = m.horizontal
            ? Rect.fromLTRB(
                base + (rect.left - base) * reveal,
                rect.top,
                base + (rect.right - base) * reveal,
                rect.bottom,
              )
            : Rect.fromLTRB(
                rect.left,
                base + (rect.top - base) * reveal,
                rect.right,
                base + (rect.bottom - base) * reveal,
              );
      }
      canvas.drawRRect(bar.radius.toRRect(rect), Paint()..color = bar.color.withValues(alpha: o));
    }

    for (final r in m.config.visible) {
      final s = r.series;
      if (s.type != CsChartSeriesType.line) continue;
      final pts = m.points.where((p) => p.series == s).toList();
      if (pts.isEmpty) continue;
      final o = _opacity(s);
      final paint = Paint()
        ..color = r.color.withValues(alpha: o)
        ..style = PaintingStyle.stroke
        ..strokeWidth = CsBorderLine.lineChartWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = strokeCap;
      if (pts.length == 1) {
        canvas.drawCircle(pts.first.position, CsBorderLine.lineChartWidth, paint..style = PaintingStyle.fill);
        continue;
      }
      canvas.drawPath(Path()..addPolygon([for (final p in pts) p.position], false), paint);
    }

    for (final r in m.config.visible) {
      final s = r.series;
      if (!s.isThreshold) continue;
      final paint = Paint()
        ..color = r.color.withValues(alpha: _opacity(s))
        ..style = PaintingStyle.stroke
        ..strokeWidth = CsBorderLine.lineChartWidth
        ..strokeCap = strokeCap;
      final Path path;
      if (s.isYThreshold) {
        final v = m.valuePosition(s.y!);
        path = m.horizontal
            ? (Path()
                ..moveTo(v, plot.top)
                ..lineTo(v, plot.bottom))
            : (Path()
                ..moveTo(plot.left, v)
                ..lineTo(plot.right, v));
      } else {
        final x = m.categoryPosition(s.x as T);
        if (!x.isFinite) continue;
        path = m.horizontal
            ? (Path()
                ..moveTo(plot.left, x)
                ..lineTo(plot.right, x))
            : (Path()
                ..moveTo(x, plot.top)
                ..lineTo(x, plot.bottom));
      }
      drawDashedPath(canvas, path, paint);
    }
    canvas.restore();

    if (baseline != null && !m.linesOnly) _drawBaseline(canvas, baseline);
  }

  (Offset, Offset)? _baseline(CartesianModel<T> m) {
    final (d0, d1) = m.valueDomain;
    if (m.config.yScaleType == CsChartYScaleType.log) return null;
    if (!(math.min(d0, d1) <= 0 && 0 <= math.max(d0, d1))) return null;
    final v = m.valueScale(0);
    final plot = m.plot;
    return m.horizontal
        ? (Offset(v, plot.top), Offset(v, plot.bottom))
        : (Offset(plot.left - kTickMargin, v), Offset(plot.right, v));
  }

  void _drawBaseline(Canvas canvas, (Offset, Offset) line) {
    canvas.drawLine(
      line.$1,
      line.$2,
      Paint()
        ..color = colors.axis
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_BasePainter<T> old) =>
      old.model != model ||
      old.colors != colors ||
      old.reveal != reveal ||
      old.dimT != dimT ||
      old.highlighted != highlighted ||
      old.fromHighlighted != fromHighlighted ||
      old.group != group ||
      old.fromGroup != fromGroup ||
      old.emphasizeBaseline != emphasizeBaseline;
}

/// The vertical marker, highlighted points and the keyboard focus outline.
class _OverlayPainter<T> extends CustomPainter {
  _OverlayPainter({required this.model, required this.colors, required this.highlight, required this.focusVisible});

  final CartesianModel<T> model;
  final _PaintColors colors;
  final _Highlight<T>? highlight;
  final bool focusVisible;

  @override
  void paint(Canvas canvas, Size size) {
    final m = model;
    final h = highlight;
    final focus = Paint()
      ..color = colors.focus
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (h == null) {
      if (focusVisible) {
        canvas.drawRRect(RRect.fromRectAndRadius(m.plot.inflate(2), const Radius.circular(4)), focus);
      }
      return;
    }
    final nav = m.navigation[h.nav];
    final x = nav.position;
    void circle(Offset c, Color color) {
      canvas.drawCircle(c, 4, Paint()..color = colors.markerFill);
      canvas.drawCircle(
        c,
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = CsBorderLine.lineChartWidth,
      );
    }

    final thresholdPoints = [
      for (final r in m.config.visible)
        if (r.series.isYThreshold && !m.horizontal) (r.series, Offset(x, m.valuePosition(r.series.y!)), r.color),
    ];

    if (m.groupNavigation) {
      // Line points inside the highlighted group, no vertical line.
      for (final p in m.pointsAt(h.nav)) {
        circle(p.position, p.color);
      }
      if (focusVisible) {
        canvas.drawRRect(RRect.fromRectAndRadius(m.groupRect(nav.category!), const Radius.circular(4)), focus);
      }
      return;
    }

    canvas.drawLine(
      Offset(x.roundToDouble() + 0.5, m.plot.top),
      Offset(x.roundToDouble() + 0.5, m.plot.bottom),
      Paint()
        ..color = colors.axis
        ..strokeWidth = 1,
    );
    if (h.series == null) {
      for (final p in m.pointsAt(h.nav)) {
        circle(p.position, p.color);
      }
      for (final t in thresholdPoints) {
        circle(t.$2, t.$3);
      }
      if (focusVisible) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(x - 8, m.plot.top, x + 8, m.plot.bottom), const Radius.circular(4)),
          focus,
        );
      }
      return;
    }
    Offset? c;
    Color? color;
    final p = m.pointsAt(h.nav).where((p) => p.series == h.series).firstOrNull;
    if (p != null) {
      c = p.position;
      color = p.color;
    } else {
      final t = thresholdPoints.where((t) => t.$1 == h.series).firstOrNull;
      c = t?.$2;
      color = t?.$3;
    }
    if (c == null || color == null) return;
    circle(c, color);
    if (focusVisible) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCircle(center: c, radius: 4 + 3), const Radius.circular(4)),
        focus,
      );
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter<T> old) =>
      old.model != model || old.colors != colors || old.highlight != highlight || old.focusVisible != focusVisible;
}
