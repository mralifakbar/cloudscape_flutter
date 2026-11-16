import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../overlays/cs_tooltip.dart';
import '../selection/internal/select_trigger.dart' show InlineLabel;
import '../system/cs_field_box.dart';
import '../system/cs_grouped_control.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';

/// The axis a [CsControlGroup] lays its controls out along (Cloudscape
/// `ControlGroupDirection`).
enum CsControlGroupDirection {
  /// Side by side.
  horizontal,

  /// Stacked.
  vertical,

  /// Side by side when every control gets at least
  /// [CsControlGroup.minControlWidth], stacked otherwise. The default.
  auto,
}

/// The icon button joined to the end of a [CsControlGroup] (Cloudscape
/// `ControlGroupProps.ActionButton`), drawn in Cloudscape's
/// `control-group-action` button style.
@immutable
class CsControlGroupActionButton {
  const CsControlGroupActionButton({
    required this.icon,
    required this.ariaLabel,
    this.onPress,
    this.disabled = false,
    this.disabledReason,
    this.iconWidget,
  });

  /// The icon, such as [CsIcons.remove] or [CsIcons.close] (Cloudscape
  /// `iconName`).
  final CsIconData icon;

  /// Accessible name of the button, also shown as its tooltip (Cloudscape
  /// `ariaLabel`, which Cloudscape also puts in `title`).
  final String ariaLabel;

  /// Called when the button is pressed and not disabled (Cloudscape
  /// `onClick`).
  final VoidCallback? onPress;
  final bool disabled;

  /// Why the button is disabled. Keeps it focusable and shows the reason in
  /// a tooltip.
  final String? disabledReason;

  /// Any widget in place of [icon].
  final Widget? iconWidget;
}

/// Cloudscape's `ControlGroup`: joins form controls, for example an input
/// and a select, or an input and a button, into one visual control.
///
/// ```dart
/// CsControlGroup(
///   children: [
///     CsInput(value: size, onChange: setSize, type: CsInputType.number),
///     Flexible(flex: 0, child: SizedBox(width: 96, child: CsSelect(options: units, selectedOption: unit, onChange: setUnit))),
///   ],
///   actionButton: CsControlGroupActionButton(icon: CsIcons.remove, ariaLabel: 'Remove volume', onPress: remove),
/// )
/// ```
///
/// The controls share their borders: only the group's outer corners are
/// rounded, and the border between two controls is one 1px seam in
/// `color-border-control-group-default`. Field-based controls (`CsInput`,
/// `CsSelect`, `CsMultiselect`, `CsAutosuggest`, `CsTextarea`, `CsDateInput`)
/// join automatically through [CsGroupedControl]. The group carries the
/// validation state ([invalid], [warning]): the outer edges take the status
/// color and the leading control the thick start edge.
///
/// Each child takes an equal share of the width. Wrap a child in `Flexible`
/// to give it another `flex`, or in `Flexible(flex: 0, ...)` with a sized
/// child to give it a fixed width.
class CsControlGroup extends StatelessWidget {
  const CsControlGroup({
    super.key,
    required this.children,
    this.direction = CsControlGroupDirection.auto,
    this.inlineLabelText,
    this.actionButton,
    this.invalid = false,
    this.warning = false,
    this.semanticLabel,
    this.minControlWidth = 120,
  });

  /// The grouped controls, in order.
  final List<Widget> children;
  final CsControlGroupDirection direction;

  /// A label drawn on the group's top border (Cloudscape `inlineLabelText`).
  final String? inlineLabelText;

  /// An icon button joined to the group's end edge.
  final CsControlGroupActionButton? actionButton;

  /// Draws the group as invalid (Cloudscape reads it from the surrounding
  /// form field). Takes precedence over [warning].
  final bool invalid;

  /// Draws the group in the warning state.
  final bool warning;

  /// Accessible name of the group (Cloudscape `ariaLabelledby`). Defaults to
  /// [inlineLabelText].
  final String? semanticLabel;

  /// With [CsControlGroupDirection.auto], the narrowest a control may get
  /// before the group stacks its controls.
  final double minControlWidth;

  CsFieldStatus get _status => invalid
      ? CsFieldStatus.invalid
      : warning
      ? CsFieldStatus.warning
      : CsFieldStatus.none;

  @override
  Widget build(BuildContext context) {
    Widget group = direction == CsControlGroupDirection.auto
        ? LayoutBuilder(
            builder: (context, constraints) {
              final action = actionButton != null ? _ActionButton.width : 0.0;
              final fits =
                  !constraints.hasBoundedWidth || constraints.maxWidth >= children.length * minControlWidth + action;
              return _layout(context, fits ? Axis.horizontal : Axis.vertical);
            },
          )
        : _layout(context, direction == CsControlGroupDirection.horizontal ? Axis.horizontal : Axis.vertical);
    group = Semantics(container: true, explicitChildNodes: true, label: semanticLabel ?? inlineLabelText, child: group);
    if (inlineLabelText != null) group = InlineLabel(text: inlineLabelText!, child: group);
    return group;
  }

  Widget _layout(BuildContext context, Axis axis) {
    final n = children.length;
    final slots = <Widget>[];
    for (var i = 0; i < n; i++) {
      var child = children[i];
      var flex = 1;
      var fit = FlexFit.tight;
      if (child is Flexible) {
        flex = child.flex;
        fit = child.fit;
        child = child.child;
      }
      final position = n == 1
          ? CsGroupedControlPosition.only
          : i == 0
          ? CsGroupedControlPosition.first
          : i == n - 1
          ? CsGroupedControlPosition.last
          : CsGroupedControlPosition.middle;
      Widget slot = CsGroupedControl(
        position: position,
        direction: axis,
        hasAction: actionButton != null,
        status: _status,
        child: child,
      );
      if (axis == Axis.horizontal && flex > 0) slot = Flexible(flex: flex, fit: fit, child: slot);
      slots.add(slot);
    }
    final controls = axis == Axis.horizontal
        ? Row(crossAxisAlignment: CrossAxisAlignment.end, children: slots)
        : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: slots);
    final action = actionButton;
    if (action == null) return controls;
    return _ActionLayout(
      children: [
        controls,
        _ActionButton(action: action, vertical: axis == Axis.vertical),
      ],
    );
  }
}

/// The `control-group-action` button: `color-background-container-content`
/// with a 1px `color-border-control-group-default` border, square on the
/// side that joins the controls, `space-field-vertical` by `space-xs`
/// padding and at least `size-vertical-input` tall.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.vertical});

  final CsControlGroupActionButton action;
  final bool vertical;

  /// Icon plus `space-xs` padding on both sides plus the end border; the
  /// start edge joins the controls' border.
  static const double width = 16 + 2 * CsSpace.xs + CsBorderWidth.field;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final hasReason = action.disabled && action.disabledReason != null;
    final radius = const BorderRadiusDirectional.horizontal(
      end: Radius.circular(CsBorderRadius.input),
    ).resolve(Directionality.of(context));
    final button = CsPressable(
      onPress: action.disabled ? null : action.onPress,
      disabled: action.disabled || action.onPress == null,
      canRequestFocus: !action.disabled || hasReason,
      showFocusRing: false,
      scaleOnPress: false,
      minTapTargetSize: 0,
      semanticLabel: action.ariaLabel,
      semanticHint: hasReason ? action.disabledReason : null,
      excludeChildSemantics: true,
      borderRadius: radius,
      builder: (context, state) {
        final disabled = action.disabled || action.onPress == null;
        final background = disabled
            ? c.backgroundButtonNormalDisabled
            : state.pressed
            ? c.backgroundButtonNormalActive
            : state.hovered
            ? c.backgroundButtonNormalHover
            : c.backgroundContainerContent;
        final foreground = disabled
            ? c.textButtonIconDisabled
            : state.pressed
            ? c.textInteractiveDefault
            : state.hovered
            ? c.textButtonIconHover
            : c.textInteractiveDefault;
        final focused = state.focused && !disabled;
        final borderColor = focused ? c.borderInputFocused : c.borderControlGroupDefault;
        final side = BorderSide(color: borderColor, width: CsBorderWidth.field);
        return Container(
          width: width,
          constraints: BoxConstraints(minHeight: cs.space.sizeVerticalInput),
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            // Cloudscape `form-focus-element`: a 1px ring outside the border.
            boxShadow: focused
                ? [BoxShadow(color: c.borderItemFocused, spreadRadius: CsBorderLine.controlFocusRingShadowSpread)]
                : null,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: BorderDirectional(top: side, bottom: side, end: side),
          ),
          padding: EdgeInsetsDirectional.only(
            start: CsSpace.xs,
            end: CsSpace.xs + CsBorderWidth.field,
            top: cs.space.fieldVertical,
            bottom: cs.space.fieldVertical,
          ),
          alignment: Alignment.center,
          child: action.iconWidget != null
              ? CsIcon.custom(action.iconWidget!)
              : CsIcon(action.icon, dangerouslySetColor: foreground),
        );
      },
    );
    return CsTooltip(content: hasReason ? action.disabledReason! : action.ariaLabel, child: button);
  }
}

/// Lays the controls out in the width the action leaves, then stretches the
/// action to the controls' height (Cloudscape's `align-items: stretch` on
/// the vertical layout, `flex-end` alignment on the horizontal one).
class _ActionLayout extends MultiChildRenderObjectWidget {
  const _ActionLayout({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderActionLayout(textDirection: Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderActionLayout renderObject) {
    renderObject.textDirection = Directionality.of(context);
  }
}

class _ActionParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderActionLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ActionParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ActionParentData> {
  _RenderActionLayout({required TextDirection textDirection}) : _textDirection = textDirection;

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ActionParentData) child.parentData = _ActionParentData();
  }

  @override
  void performLayout() {
    final controls = firstChild!;
    final action = childAfter(controls)!;
    const actionWidth = _ActionButton.width;
    final maxWidth = constraints.maxWidth;
    final controlsMax = maxWidth.isFinite ? math.max(0.0, maxWidth - actionWidth) : double.infinity;
    controls.layout(BoxConstraints(maxWidth: controlsMax), parentUsesSize: true);
    action.layout(BoxConstraints.tightFor(width: actionWidth, height: controls.size.height), parentUsesSize: true);
    final width = controls.size.width + actionWidth;
    size = constraints.constrain(Size(width, controls.size.height));
    final rtl = _textDirection == TextDirection.rtl;
    (controls.parentData! as _ActionParentData).offset = Offset(rtl ? size.width - controls.size.width : 0, 0);
    (action.parentData! as _ActionParentData).offset = Offset(rtl ? 0 : controls.size.width, 0);
  }

  @override
  double computeMinIntrinsicHeight(double width) => firstChild!.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) => firstChild!.getMaxIntrinsicHeight(width);

  @override
  double computeMinIntrinsicWidth(double height) => firstChild!.getMinIntrinsicWidth(height) + _ActionButton.width;

  @override
  double computeMaxIntrinsicWidth(double height) => firstChild!.getMaxIntrinsicWidth(height) + _ActionButton.width;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    const actionWidth = _ActionButton.width;
    final controlsMax = constraints.maxWidth.isFinite
        ? math.max(0.0, constraints.maxWidth - actionWidth)
        : double.infinity;
    final s = firstChild!.getDryLayout(BoxConstraints(maxWidth: controlsMax));
    return constraints.constrain(Size(s.width + actionWidth, s.height));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
