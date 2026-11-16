// Shared chart building blocks: series markers, legend, filter, status and
// the detail popover body. Mirrors Cloudscape's internal chart-* components
// (src/internal/components/chart-legend, chart-filter, chart-series-marker,
// chart-series-details, chart-status-container, chart-popover).
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../buttons/cs_button.dart';
import '../../controls/cs_checkbox.dart';
import '../../forms/cs_form_field.dart';
import '../../icons/cs_icon.dart';
import '../../icons/cs_icons.g.dart';
import '../../navigation/cs_link.dart';
import '../../overlays/cs_dropdown.dart';
import '../../overlays/cs_menu_parts.dart';
import '../../status/cs_status_indicator.dart';
import '../../system/cs_field_box.dart';
import '../../system/cs_pressable.dart';
import '../../system/cs_strings.dart';
import '../../theme/theme.dart';
import '../cs_chart_series.dart';

/// Shape of a series marker (Cloudscape `ChartSeriesMarkerType`).
enum ChartMarkerType { line, rectangle, dashed, hollowRectangle }

ChartMarkerType markerFor(CsChartSeriesType type) => switch (type) {
  CsChartSeriesType.line => ChartMarkerType.line,
  CsChartSeriesType.bar => ChartMarkerType.rectangle,
  CsChartSeriesType.area => ChartMarkerType.hollowRectangle,
  CsChartSeriesType.threshold => ChartMarkerType.dashed,
};

/// The small color swatch in legends, filters and popovers. Cloudscape
/// sizes it from a 10px base: 14px wide, 4px tall for lines, 14px square
/// for bars and segments, two 6px dashes for thresholds, 2px corners.
class ChartSeriesMarker extends StatelessWidget {
  const ChartSeriesMarker({super.key, required this.type, required this.color});

  final ChartMarkerType type;
  final Color color;

  /// Marker width plus its `space-xxs` end margin.
  static const double extent = 14 + CsSpace.xxs;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: CsSpace.xxs),
        child: CustomPaint(
          size: const Size(14, 20),
          painter: _MarkerPainter(type, color, context.cs.colors.backgroundContainerContent),
        ),
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter(this.type, this.color, this.hollow);

  final ChartMarkerType type;
  final Color color;
  final Color hollow;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const r = Radius.circular(2);
    switch (type) {
      case ChartMarkerType.line:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 9, 14, 4), r), paint);
      case ChartMarkerType.rectangle:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 4, 14, 14), r), paint);
      case ChartMarkerType.hollowRectangle:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 4, 14, 14), r), paint);
        canvas.drawRect(const Rect.fromLTWH(2, 6, 10, 10), Paint()..color = hollow.withValues(alpha: 0.5));
      case ChartMarkerType.dashed:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 9, 6, 4), r), paint);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 9, 6, 4), r), paint);
    }
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => old.type != type || old.color != color || old.hollow != hollow;
}

/// One entry of a legend or filter.
class ChartItem<I> {
  const ChartItem({required this.label, required this.datum, required this.color, required this.marker});

  final String label;
  final I datum;
  final Color color;
  final ChartMarkerType marker;
}

/// Cloudscape's chart legend: a wrapping row of markers and titles. Hover,
/// keyboard focus or a tap highlights a series and dims the others; Left
/// and Right move between entries (one tab stop for the whole legend).
class ChartLegend<I> extends StatefulWidget {
  const ChartLegend({
    super.key,
    required this.items,
    required this.highlighted,
    required this.onHighlightChange,
    this.title,
    required this.ariaLabel,
  });

  final List<ChartItem<I>> items;
  final I? highlighted;
  final ValueChanged<I?> onHighlightChange;
  final String? title;
  final String ariaLabel;

  @override
  State<ChartLegend<I>> createState() => _ChartLegendState<I>();
}

class _ChartLegendState<I> extends State<ChartLegend<I>> {
  final List<FocusNode> _nodes = [];
  final FocusNode _group = FocusNode(debugLabel: 'ChartLegend', skipTraversal: true);

  @override
  void initState() {
    super.initState();
    _group.addListener(_onGroupFocus);
  }

  void _syncNodes() {
    while (_nodes.length < widget.items.length) {
      final i = _nodes.length;
      final node = FocusNode(debugLabel: 'ChartLegend item $i');
      node.addListener(() {
        if (node.hasFocus && i < widget.items.length) {
          final d = widget.items[i].datum;
          if (d != widget.highlighted) widget.onHighlightChange(d);
        }
      });
      _nodes.add(node);
    }
    while (_nodes.length > widget.items.length) {
      _nodes.removeLast().dispose();
    }
    final current = _currentIndex;
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != current;
    }
  }

  int get _currentIndex {
    final i = widget.items.indexWhere((e) => e.datum == widget.highlighted);
    return i < 0 ? 0 : i;
  }

  void _onGroupFocus() {
    // Leaving the legend with the keyboard clears the highlight it set.
    if (!_group.hasFocus && widget.highlighted != null) widget.onHighlightChange(null);
  }

  @override
  void dispose() {
    _group.removeListener(_onGroupFocus);
    _group.dispose();
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final n = widget.items.length;
    if (n == 0) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final focused = _nodes.indexWhere((f) => f.hasFocus);
    final from = focused < 0 ? _currentIndex : focused;
    int? next;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) next = rtl ? from - 1 : from + 1;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) next = rtl ? from + 1 : from - 1;
    if (next == null) return KeyEventResult.ignored;
    next = (next + n) % n;
    _nodes[next].requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    _syncNodes();
    final cs = context.cs;
    final someHighlighted = widget.highlighted != null;
    final fade = CsMotion.duration(context, CsDurations.transitionQuick);
    final list = Wrap(
      spacing: CsSpace.m,
      runSpacing: cs.space.scaledXxs,
      children: [
        for (var i = 0; i < widget.items.length; i++)
          Builder(
            builder: (context) {
              final item = widget.items[i];
              final isHighlighted = item.datum == widget.highlighted;
              final dimmed = someHighlighted && !isHighlighted;
              return MouseRegion(
                onEnter: (_) {
                  if (!isHighlighted) widget.onHighlightChange(item.datum);
                },
                onExit: (_) => widget.onHighlightChange(null),
                child: AnimatedOpacity(
                  opacity: dimmed ? 0.35 : 1,
                  duration: fade,
                  curve: CsCurves.transitionQuick,
                  child: CsPressable(
                    focusNode: _nodes[i],
                    toggled: isHighlighted,
                    scaleOnPress: false,
                    minTapTargetSize: 0,
                    borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
                    onPress: () => widget.onHighlightChange(isHighlighted ? null : item.datum),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ChartSeriesMarker(type: item.marker, color: item.color),
                        Flexible(child: Text(item.label, style: cs.body)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.title ?? widget.ariaLabel,
      child: Focus(
        focusNode: _group,
        canRequestFocus: false,
        onKeyEvent: _onKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null)
              ExcludeSemantics(
                child: Text(widget.title!, style: cs.text(CsTypeScale.bodyM, weight: CsTypography.bold)),
              ),
            list,
          ],
        ),
      ),
    );
  }
}

/// Cloudscape's default chart filter: a multiselect (labelled "Filter
/// displayed data") whose options are the series, each with its marker.
/// It stays open while options toggle, and opens as a bottom sheet on
/// phones.
class ChartFilter<I> extends StatefulWidget {
  const ChartFilter({
    super.key,
    required this.items,
    required this.selected,
    required this.onChange,
    required this.label,
    required this.placeholder,
    required this.selectedAriaLabel,
  });

  final List<ChartItem<I>> items;
  final List<I> selected;
  final ValueChanged<List<I>> onChange;
  final String label;
  final String placeholder;
  final String selectedAriaLabel;

  @override
  State<ChartFilter<I>> createState() => _ChartFilterState<I>();
}

class _ChartFilterState<I> extends State<ChartFilter<I>> {
  bool _open = false;
  final FocusNode _trigger = FocusNode(debugLabel: 'ChartFilter trigger');

  @override
  void dispose() {
    _trigger.dispose();
    super.dispose();
  }

  void _toggle(I datum) {
    final on = widget.selected.contains(datum);
    // Keep the series order, not the click order.
    final next = [
      for (final item in widget.items)
        if (item.datum == datum ? !on : widget.selected.contains(item.datum)) item.datum,
    ];
    widget.onChange(next);
  }

  Widget _rows(BuildContext context, bool inSheet) {
    final rows = [
      for (var i = 0; i < widget.items.length; i++)
        Builder(
          builder: (context) {
            final item = widget.items[i];
            final checked = widget.selected.contains(item.datum);
            return CsMenuRow(
              label: item.label,
              checked: checked,
              autofocus: i == 0,
              semanticLabel: checked ? '${item.label}, ${widget.selectedAriaLabel}' : item.label,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CsCheckboxIcon(checked: checked),
                  const SizedBox(width: CsSpace.xs),
                  ChartSeriesMarker(type: item.marker, color: item.color),
                ],
              ),
              onPress: () => _toggle(item.datum),
            );
          },
        ),
    ];
    if (inSheet) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: CsSpace.s),
          child: CsMenuKeyboard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CsSpace.l, vertical: CsSpace.xs),
                  child: Text(widget.label, style: context.cs.text(CsTypeScale.headingS)),
                ),
                ...rows,
              ],
            ),
          ),
        ),
      );
    }
    return CsMenuPanel(maxHeight: 320, semanticLabel: widget.label, children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final trigger = CsPressable(
      focusNode: _trigger,
      expanded: _open,
      scaleOnPress: false,
      showFocusRing: false,
      semanticLabel: '${widget.label}, ${widget.placeholder}',
      excludeChildSemantics: true,
      onPress: () => setState(() => _open = !_open),
      builder: (context, state) => CsFieldBox(
        focused: state.focused,
        trailing: Padding(
          padding: const EdgeInsetsDirectional.only(end: CsSpace.xxs),
          child: AnimatedRotation(
            turns: _open ? -0.5 : 0,
            duration: CsMotion.duration(context, CsDurations.rotate180),
            curve: CsCurves.rotate180,
            child: CsIcon(
              CsIcons.caretDownFilled,
              variant: state.hovered ? CsIconVariant.normal : CsIconVariant.subtle,
            ),
          ),
        ),
        child: Text(
          widget.placeholder,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: cs.text(CsTypeScale.bodyM, color: CsColor.textInputPlaceholder),
        ),
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: CsFormField(
        label: widget.label,
        stretch: true,
        child: CsDropdown(
          open: _open,
          onDismiss: () => setState(() => _open = false),
          sheetLabel: widget.label,
          contentBuilder: _rows,
          child: trigger,
        ),
      ),
    );
  }
}

/// Loading, error, empty and no-match content of a chart, announced
/// through a live region (Cloudscape `ChartStatusContainer`).
class ChartStatus extends StatelessWidget {
  const ChartStatus({
    super.key,
    required this.statusType,
    required this.isEmpty,
    required this.isNoMatch,
    this.empty,
    this.noMatch,
    this.loadingText,
    this.errorText,
    this.recoveryText,
    this.onRecoveryClick,
  });

  final CsChartStatusType statusType;
  final bool isEmpty;
  final bool isNoMatch;
  final Widget? empty;
  final Widget? noMatch;
  final String? loadingText;
  final String? errorText;
  final String? recoveryText;
  final VoidCallback? onRecoveryClick;

  static const String defaultErrorText = "The data couldn't be fetched. Try again later.";

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final strings = context.csStrings;
    Widget? content;
    switch (statusType) {
      case CsChartStatusType.error:
        final recovery = recoveryText ?? strings.retry;
        content = Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: CsSpace.xxs,
          children: [
            CsStatusIndicator(type: CsStatusType.error, text: errorText ?? defaultErrorText),
            if (onRecoveryClick != null && recovery.isNotEmpty)
              CsLink(text: recovery, variant: CsLinkVariant.primary, onFollow: onRecoveryClick),
          ],
        );
      case CsChartStatusType.loading:
        content = CsStatusIndicator(type: CsStatusType.loading, text: loadingText ?? strings.loadingChart);
      case CsChartStatusType.finished:
        final slot = isNoMatch ? noMatch : (isEmpty ? empty : null);
        if (slot != null) {
          content = DefaultTextStyle.merge(
            style: TextStyle(color: cs.colors.textEmpty),
            textAlign: TextAlign.center,
            child: slot,
          );
        }
    }
    if (content == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(padding: const EdgeInsets.all(CsSpace.s), child: content),
    );
  }
}

/// One row of a detail popover.
class ChartDetailRow {
  const ChartDetailRow({
    required this.key,
    this.keyWidget,
    required this.value,
    this.valueWidget,
    this.color,
    this.marker,
    this.subItems = const [],
    this.expandable = false,
    this.dimmed = false,
    this.bold = false,
  });

  final String key;
  final Widget? keyWidget;
  final String value;
  final Widget? valueWidget;
  final Color? color;
  final ChartMarkerType? marker;
  final List<CsChartDetailPair> subItems;
  final bool expandable;
  final bool dimmed;
  final bool bold;
}

/// Body of a chart detail popover: a bold header (the x position or the
/// segment), an optional close button while pinned, key-value rows with
/// series markers, optional extra rows under a divider (an area chart's
/// total) and a footer under a divider (Cloudscape `ChartPopover` with
/// `ChartSeriesDetails`).
class ChartDetailBody extends StatelessWidget {
  const ChartDetailBody({
    super.key,
    required this.title,
    this.titleMarker,
    required this.rows,
    this.extraRows = const [],
    this.footer,
    required this.pinned,
    required this.onDismiss,
    required this.dismissLabel,
    required this.size,
    this.expandLabel = 'Expand',
    this.collapseLabel = 'Collapse',
    this.compact = false,
  });

  final String title;
  final Widget? titleMarker;
  final List<ChartDetailRow> rows;
  final List<ChartDetailRow> extraRows;
  final Widget? footer;
  final bool pinned;
  final VoidCallback onDismiss;
  final String dismissLabel;
  final CsChartPopoverSize size;
  final String expandLabel;
  final String collapseLabel;

  /// Pie charts list their rows without spacing between them.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final divider = Padding(
      padding: const EdgeInsets.symmetric(vertical: CsSpace.xs),
      child: SizedBox(height: 1, child: ColoredBox(color: cs.colors.borderDividerDefault)),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: size.maxWidth),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?titleMarker,
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: cs.text(CsTypeScale.bodyM, weight: CsTypography.bold)),
                  ),
                ),
                if (pinned)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: CsSpace.xs),
                    child: CsButton(
                      variant: CsButtonVariant.inlineIcon,
                      icon: CsIcons.close,
                      semanticLabel: dismissLabel,
                      onPress: onDismiss,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: CsSpace.xxs),
            for (var i = 0; i < rows.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 || compact ? 0 : cs.space.scaledXxs),
                child: _DetailRowView(row: rows[i], expandLabel: expandLabel, collapseLabel: collapseLabel),
              ),
            if (extraRows.isNotEmpty) ...[
              divider,
              for (final r in extraRows) _DetailRowView(row: r, expandLabel: expandLabel, collapseLabel: collapseLabel),
            ],
            if (footer != null) ...[divider, footer!],
          ],
        ),
      ),
    );
  }
}

class _DetailRowView extends StatefulWidget {
  const _DetailRowView({required this.row, required this.expandLabel, required this.collapseLabel});

  final ChartDetailRow row;
  final String expandLabel;
  final String collapseLabel;

  @override
  State<_DetailRowView> createState() => _DetailRowViewState();
}

class _DetailRowViewState extends State<_DetailRowView> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final row = widget.row;
    final hasSub = row.subItems.isNotEmpty;
    final expandable = row.expandable && hasSub;
    final boldKey = row.bold || (hasSub && !expandable);
    final keyStyle = cs.text(
      CsTypeScale.bodyM,
      color: CsColor.textGroupLabel,
      weight: boldKey ? CsTypography.bold : null,
    );
    final valueStyle = cs.text(CsTypeScale.bodyM, weight: boldKey || expandable ? CsTypography.bold : null);
    Widget keyContent = row.keyWidget ?? Text(row.key, style: keyStyle);
    if (expandable) {
      keyContent = CsPressable(
        expanded: _expanded,
        scaleOnPress: false,
        minTapTargetSize: 0,
        semanticLabel: '${row.key}, ${_expanded ? widget.collapseLabel : widget.expandLabel}',
        excludeChildSemantics: true,
        onPress: () => setState(() => _expanded = !_expanded),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRotation(
              turns: _expanded ? 0 : -0.25,
              duration: CsMotion.duration(context, CsDurations.rotate90),
              curve: CsCurves.rotate90,
              child: const CsIcon(CsIcons.caretDownFilled, size: CsIconSize.small),
            ),
            const SizedBox(width: CsSpace.xxs),
            Flexible(
              child: Text(row.key, style: keyStyle.copyWith(color: cs.colors.textBodyDefault)),
            ),
          ],
        ),
      );
    }
    final pair = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (row.marker != null && row.color != null) ChartSeriesMarker(type: row.marker!, color: row.color!),
        Expanded(
          child: DefaultTextStyle(style: keyStyle, child: keyContent),
        ),
        const SizedBox(width: CsSpace.xxl),
        DefaultTextStyle(
          style: valueStyle,
          textAlign: TextAlign.end,
          child: row.valueWidget ?? Text(row.value, textAlign: TextAlign.end),
        ),
      ],
    );
    final showSub = hasSub && (!expandable || _expanded);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MergeSemantics(child: pair),
        if (showSub)
          for (final s in row.subItems)
            Padding(
              padding: EdgeInsetsDirectional.only(
                top: cs.space.scaledXxs,
                start: expandable ? 0 : ChartSeriesMarker.extent,
              ),
              child: MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DefaultTextStyle(
                        style: cs.text(CsTypeScale.bodyM, color: CsColor.textGroupLabel),
                        child: s.keyWidget ?? Text(s.key ?? ''),
                      ),
                    ),
                    const SizedBox(width: CsSpace.xxl),
                    DefaultTextStyle(style: cs.body, child: s.valueWidget ?? Text(s.value ?? '')),
                  ],
                ),
              ),
            ),
      ],
    );
    return AnimatedOpacity(
      opacity: row.dimmed ? 0.35 : 1,
      duration: CsMotion.duration(context, CsDurations.transitionQuick),
      child: content,
    );
  }
}

/// Chart wrapper (Cloudscape `ChartWrapper`): filters above with an `l`
/// gap, the chart or its status in the middle, the legend below with an
/// `m` gap. While the chart is hidden, room for the filter and legend is
/// kept so the layout does not jump when data arrives.
class ChartFrame extends StatelessWidget {
  const ChartFrame({
    super.key,
    this.filter,
    this.additionalFilters,
    required this.content,
    this.legend,
    required this.reserveFilterSpace,
    required this.reserveLegendSpace,
    required this.minContentHeight,
    this.fitHeight = false,
  });

  final Widget? filter;
  final Widget? additionalFilters;
  final Widget content;
  final Widget? legend;
  final bool reserveFilterSpace;
  final bool reserveLegendSpace;
  final double minContentHeight;
  final bool fitHeight;

  @override
  Widget build(BuildContext context) {
    // fitHeight needs a bounded parent; otherwise fall back to the fixed height.
    if (fitHeight) return LayoutBuilder(builder: (context, c) => _build(context, c.hasBoundedHeight));
    return _build(context, false);
  }

  Widget _build(BuildContext context, bool fit) {
    final lineHeight = MediaQuery.textScalerOf(context).scale(CsFontTokens.lineHeightBodyM);
    final filters = (filter != null || additionalFilters != null)
        ? Padding(
            padding: const EdgeInsets.only(bottom: CsSpace.l),
            child: Wrap(
              spacing: CsSpace.l,
              runSpacing: CsSpace.l,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [?filter, ?additionalFilters],
            ),
          )
        : null;
    Widget body = Padding(
      padding: EdgeInsets.only(
        top: reserveFilterSpace ? 2 * lineHeight : 0,
        bottom: reserveLegendSpace ? 2 * lineHeight : 0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: fit ? 0 : minContentHeight),
        child: content,
      ),
    );
    if (fit) body = Expanded(child: body);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: fit ? MainAxisSize.max : MainAxisSize.min,
      children: [
        ?filters,
        body,
        if (legend != null)
          Padding(
            padding: const EdgeInsets.only(top: CsSpace.m),
            child: legend,
          ),
      ],
    );
  }
}

/// Default English copy shared by the charts.
abstract final class ChartDefaults {
  static const String filterLabel = 'Filter displayed data';
  static const String filterPlaceholder = 'Filter data';
  static const String filterSelected = 'selected';
  static const String legend = 'Legend';
  static const String xAxis = 'x-axis';
  static const String yAxis = 'y-axis';
  static const String total = 'Total';
  static const String expand = 'Expand';
  static const String collapse = 'Collapse';
}

/// Shared English fallback for dismiss labels.
String chartDismissLabel(BuildContext context, String? custom) => custom ?? CsLocale.of(context).dismiss;
