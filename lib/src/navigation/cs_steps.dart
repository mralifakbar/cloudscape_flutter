import 'package:flutter/widgets.dart';

import '../feedback/cs_spinner.dart';
import '../icons/cs_icon.dart';
import '../status/cs_status_indicator.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// Orientation of [CsSteps] (Cloudscape `orientation`).
enum CsStepsOrientation { vertical, horizontal }

/// Connector lines of [CsSteps] (Cloudscape `connectorLines`).
enum CsStepsConnectorLines { visible, none }

/// One step of [CsSteps] (Cloudscape `StepsProps.Step`).
@immutable
class CsStepsStep {
  const CsStepsStep({
    required this.status,
    this.header,
    this.headerWidget,
    this.details,
    this.detailsWidget,
    this.annotation,
    this.annotationWidget,
    this.statusIconAriaLabel,
    this.data,
  }) : assert(header != null || headerWidget != null, 'Pass header or headerWidget');

  /// The step's status, shown with the matching status icon.
  final CsStatusType status;

  /// Summary of the step, in the status color.
  final String? header;

  /// Rich header in place of [header].
  final Widget? headerWidget;

  /// More information under the header.
  final String? details;
  final Widget? detailsWidget;

  /// Content before the icon, such as a timestamp in a timeline.
  final String? annotation;
  final Widget? annotationWidget;

  /// Spoken name of the status icon. Defaults to the status name.
  final String? statusIconAriaLabel;

  /// Any value of yours, for [CsSteps.renderStep].
  final Object? data;

  bool get _hasAnnotation => annotation != null || annotationWidget != null;
}

/// What [CsSteps.renderStep] returns for a step.
@immutable
class CsStepsRenderedStep {
  const CsStepsRenderedStep({required this.header, this.details, this.icon});

  final Widget header;
  final Widget? details;

  /// Replaces the status icon.
  final Widget? icon;
}

/// Cloudscape's `Steps`: the progress of a multi-step process, such as a
/// deployment or a set of checks, each step with a status.
///
/// ```dart
/// CsSteps(
///   steps: const [
///     CsStepsStep(status: CsStatusType.success, header: 'Instance launched'),
///     CsStepsStep(status: CsStatusType.loading, header: 'Running health checks', details: '2 of 3 complete'),
///     CsStepsStep(status: CsStatusType.pending, header: 'Attach to load balancer'),
///   ],
/// )
/// ```
///
/// Vertical steps stack with a connector line beside them; horizontal steps
/// share the width in equal columns with the connector running between the
/// icons. Horizontal steps fall back to vertical when each column would be
/// narrower than [minHorizontalStepWidth] (a phone in portrait); set it to
/// 0 to keep them horizontal. Annotations (timestamps) get a column of their
/// own, at most half the width, aligned across steps.
class CsSteps extends StatelessWidget {
  const CsSteps({
    super.key,
    required this.steps,
    this.orientation = CsStepsOrientation.vertical,
    this.connectorLines = CsStepsConnectorLines.visible,
    this.renderStep,
    this.ariaLabel,
    this.minHorizontalStepWidth = 120,
  });

  final List<CsStepsStep> steps;
  final CsStepsOrientation orientation;
  final CsStepsConnectorLines connectorLines;

  /// Builds the header, details and icon of each step yourself.
  final CsStepsRenderedStep Function(CsStepsStep step)? renderStep;

  /// Accessible name of the list (Cloudscape `ariaLabel`).
  final String? ariaLabel;

  /// Below this column width horizontal steps lay out vertically.
  final double minHorizontalStepWidth;

  @override
  Widget build(BuildContext context) {
    final list = orientation == CsStepsOrientation.vertical
        ? _vertical(context)
        : LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  constraints.maxWidth.isFinite &&
                  steps.isNotEmpty &&
                  constraints.maxWidth / steps.length < minHorizontalStepWidth;
              return narrow ? _vertical(context) : _horizontal(context);
            },
          );
    return Semantics(container: true, explicitChildNodes: true, label: ariaLabel, child: list);
  }

  Color _statusColor(BuildContext context, CsStatusType status) =>
      CsStatusIndicator.colorFor(context.cs.colors, status);

  Widget _icon(BuildContext context, CsStepsStep step) {
    final color = _statusColor(context, step.status);
    final data = CsStatusIndicator.iconFor(step.status);
    final glyph = data == null
        ? CsSpinner(semanticLabel: '', dangerouslySetColor: color)
        : CsIcon(data, dangerouslySetColor: color);
    return SizedBox(
      height: CsSpace.staticL,
      child: Center(widthFactor: 1, child: glyph),
    );
  }

  String _statusLabel(BuildContext context, CsStepsStep step) =>
      step.statusIconAriaLabel ?? CsStatusIndicator.labelFor(context.csStrings, step.status);

  ({Widget header, Widget? details, Widget icon, bool custom}) _parts(BuildContext context, CsStepsStep step) {
    final cs = context.cs;
    if (renderStep != null) {
      final r = renderStep!(step);
      return (header: r.header, details: r.details, icon: r.icon ?? _icon(context, step), custom: true);
    }
    final header =
        step.headerWidget ?? Text(step.header!, style: cs.body.copyWith(color: _statusColor(context, step.status)));
    final details = step.detailsWidget ?? (step.details == null ? null : Text(step.details!, style: cs.body));
    return (header: header, details: details, icon: _icon(context, step), custom: false);
  }

  Widget? _annotation(BuildContext context, CsStepsStep step) {
    if (!step._hasAnnotation) return null;
    return DefaultTextStyle.merge(
      style: TextStyle(color: context.cs.colors.textStatusInactive),
      child: step.annotationWidget ?? Text(step.annotation!),
    );
  }

  Widget _connector(BuildContext context) => Container(
    width: CsBorderLine.dividerListWidth,
    constraints: const BoxConstraints(minHeight: CsSpace.staticXs),
    color: connectorLines == CsStepsConnectorLines.none ? null : context.cs.colors.borderDividerDefault,
  );

  Widget _vertical(BuildContext context) {
    final withAnnotation = steps.any((s) => s._hasAnnotation);
    final rows = <TableRow>[];
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final last = i == steps.length - 1;
      final p = _parts(context, step);
      final annotation = _annotation(context, step);
      // The rail: the icon, then the connector filling the rest of the step.
      // Default steps align the icon to the start (it belongs to the status
      // indicator); custom steps center icon and line in the 20px column.
      final rail = Column(
        crossAxisAlignment: p.custom ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          p.icon,
          if (!last)
            Expanded(
              child: Padding(
                // Cloudscape nudges the default connector 2px toward the
                // start so it sits under the center of the 16px icon.
                padding: EdgeInsetsDirectional.only(start: p.custom ? 0 : (CsSize.iconNormal - 1) / 2),
                child: _connector(context),
              ),
            ),
        ],
      );
      final content = Padding(
        padding: EdgeInsetsDirectional.only(
          start: p.custom ? 0 : CsSpace.xxs,
          bottom: (p.details != null && !p.custom) || !last ? CsSpace.staticXs : 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: CsSpace.staticL),
              child: p.header,
            ),
            ?p.details,
          ],
        ),
      );
      rows.add(
        TableRow(
          children: [
            if (withAnnotation)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: CsSpace.xxs),
                child: Align(alignment: AlignmentDirectional.topEnd, child: annotation ?? const SizedBox.shrink()),
              ),
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.fill,
              child: ExcludeSemantics(child: rail),
            ),
            MergeSemantics(
              child: Semantics(label: _statusLabel(context, step), child: content),
            ),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = constraints.maxWidth.isFinite ? constraints.maxWidth / 2 : double.infinity;
        return Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          columnWidths: {
            if (withAnnotation) 0: MinColumnWidth(const IntrinsicColumnWidth(), FixedColumnWidth(half)),
            (withAnnotation ? 1 : 0): FixedColumnWidth(renderStep != null ? CsSpace.staticL : CsSize.iconNormal),
            (withAnnotation ? 2 : 1): const FlexColumnWidth(),
          },
          children: rows,
        );
      },
    );
  }

  Widget _horizontal(BuildContext context) {
    final cs = context.cs;
    final withAnnotation = steps.any((s) => s._hasAnnotation);
    final parts = [for (final s in steps) _parts(context, s)];
    Widget cell(Widget child, {double end = CsSpace.xs}) => Padding(
      padding: EdgeInsetsDirectional.only(end: end),
      child: child,
    );
    final hidden = connectorLines == CsStepsConnectorLines.none;
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        if (withAnnotation)
          TableRow(
            children: [
              for (final s in steps)
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.bottom,
                  child: cell(_annotation(context, s) ?? const SizedBox.shrink()),
                ),
            ],
          ),
        TableRow(
          children: [
            for (var i = 0; i < steps.length; i++)
              ExcludeSemantics(
                child: SizedBox(
                  height: CsSpace.staticL,
                  child: Row(
                    spacing: CsSpace.xxs,
                    children: [
                      parts[i].icon,
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: CsBorderLine.dividerListWidth,
                            constraints: const BoxConstraints(minWidth: CsSpace.staticXs),
                            margin: const EdgeInsetsDirectional.only(end: CsSpace.staticXxs),
                            color: hidden ? null : cs.colors.borderDividerDefault,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        TableRow(
          children: [
            for (var i = 0; i < steps.length; i++)
              MergeSemantics(
                child: Semantics(
                  label: _statusLabel(context, steps[i]),
                  child: cell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        parts[i].header,
                        if (parts[i].details != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: CsSpace.staticXs),
                            child: parts[i].details,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
