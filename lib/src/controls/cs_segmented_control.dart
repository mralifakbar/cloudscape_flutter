import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../forms/cs_form_field.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_dropdown.dart';
import '../overlays/cs_menu_parts.dart';
import '../overlays/cs_sheet.dart';
import '../overlays/cs_tooltip.dart';
import '../system/cs_field_box.dart';
import '../system/cs_haptics.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';

/// One segment of a [CsSegmentedControl] (Cloudscape `Option`).
@immutable
class CsSegmentedControlOption {
  const CsSegmentedControlOption({
    required this.id,
    this.text,
    this.icon,
    this.iconWidget,
    this.iconAlt,
    this.disabled = false,
    this.disabledReason,
  }) : assert(text != null || icon != null || iconWidget != null, 'Pass text, icon or iconWidget');

  /// Reported in `onChange` when the segment is picked.
  final String id;
  final String? text;

  /// Icon before the text, or alone (Cloudscape `iconName`).
  final CsIconData? icon;

  /// Custom icon in place of [icon] (Cloudscape `iconSvg` / `iconUrl`).
  final Widget? iconWidget;

  /// Accessible name of an icon-only segment. Required when there is no
  /// [text].
  final String? iconAlt;
  final bool disabled;

  /// Shown in a tooltip on hover and focus of a disabled segment, which
  /// stays focusable so keyboard users can read it.
  final String? disabledReason;

  /// The name used for the segment in the select shown on narrow screens.
  String get label => text ?? iconAlt ?? id;
}

/// Whether a [CsSegmentedControl] shows its segments or a select.
enum CsSegmentedControlPresentation {
  /// Segments on wide screens, a select at or below 688px, like Cloudscape.
  auto,

  /// Always the segments (for 2 or 3 short segments that fit on a phone).
  segments,

  /// Always the select.
  select,
}

/// Cloudscape's `SegmentedControl`: 2 to 6 buttons in a pill where exactly
/// one is active, for switching between views of the same content (a chart
/// range, list or grid).
///
/// It is controlled: pass [selectedId] and update it in [onChange].
///
/// ```dart
/// CsSegmentedControl(
///   label: 'Time range',
///   selectedId: range,
///   onChange: (id) => setState(() => range = id),
///   options: const [
///     CsSegmentedControlOption(id: '1h', text: '1h'),
///     CsSegmentedControlOption(id: '3h', text: '3h'),
///     CsSegmentedControlOption(id: '12h', text: '12h'),
///   ],
/// )
/// ```
///
/// At or below 688px Cloudscape swaps the segments for a select; this
/// widget does the same with a dropdown list (a bottom sheet on phones),
/// labelled by [label]. Set [presentation] to keep one form.
///
/// Keyboard: the control is one Tab stop; Left and Right move focus between
/// segments (wrapping), Enter or Space picks the focused one.
class CsSegmentedControl extends StatefulWidget {
  const CsSegmentedControl({
    super.key,
    required this.selectedId,
    required this.options,
    this.onChange,
    this.label,
    this.presentation = CsSegmentedControlPresentation.auto,
    this.haptic = CsHaptic.selection,
  }) : assert(options.length <= 6, 'Cloudscape supports up to 6 segments');

  /// The id of the active segment, or null for none.
  final String? selectedId;
  final List<CsSegmentedControlOption> options;

  /// Called with the id of the newly picked segment.
  final ValueChanged<String>? onChange;

  /// Accessible name of the group. In the select form it is shown as the
  /// select's visible label.
  final String? label;
  final CsSegmentedControlPresentation presentation;

  /// Feedback fired when the selection changes.
  final CsHaptic haptic;

  @override
  State<CsSegmentedControl> createState() => _CsSegmentedControlState();
}

class _CsSegmentedControlState extends State<CsSegmentedControl> {
  final List<FocusNode> _nodes = [];
  bool _open = false;

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _syncNodes() {
    while (_nodes.length < widget.options.length) {
      _nodes.add(FocusNode(debugLabel: 'CsSegmentedControl segment ${_nodes.length}'));
    }
    while (_nodes.length > widget.options.length) {
      _nodes.removeLast().dispose();
    }
  }

  bool _focusable(int i) {
    final o = widget.options[i];
    return !o.disabled || o.disabledReason != null;
  }

  int get _tabStop {
    final selected = widget.options.indexWhere((o) => o.id == widget.selectedId);
    if (selected >= 0 && _focusable(selected)) return selected;
    for (var i = 0; i < widget.options.length; i++) {
      if (_focusable(i)) return i;
    }
    return -1;
  }

  void _select(String id) {
    if (id == widget.selectedId) return;
    csHaptic(widget.haptic);
    widget.onChange?.call(id);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final int delta;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      delta = rtl ? -1 : 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      delta = rtl ? 1 : -1;
    } else {
      return KeyEventResult.ignored;
    }
    final current = _nodes.indexWhere((n) => n.hasFocus);
    if (current < 0) return KeyEventResult.ignored;
    final n = widget.options.length;
    for (var step = 1; step <= n; step++) {
      final i = ((current + delta * step) % n + n) % n;
      if (_focusable(i)) {
        _nodes[i].requestFocus();
        break;
      }
    }
    return KeyEventResult.handled;
  }

  bool get _useSelect => switch (widget.presentation) {
    CsSegmentedControlPresentation.auto => context.csIsNarrow,
    CsSegmentedControlPresentation.segments => false,
    CsSegmentedControlPresentation.select => true,
  };

  @override
  Widget build(BuildContext context) {
    _syncNodes();
    if (_useSelect) return _buildSelect(context);
    return _buildSegments(context);
  }

  Widget _buildSegments(BuildContext context) {
    final c = context.cs.colors;
    final tabStop = _tabStop;
    final children = <Widget>[];
    for (var i = 0; i < widget.options.length; i++) {
      final o = widget.options[i];
      _nodes[i].skipTraversal = i != tabStop;
      if (i > 0) {
        children.add(
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: CsSpace.xxs, vertical: CsSpace.xs - 1),
            constraints: const BoxConstraints(minHeight: CsFontTokens.lineHeightBodyM - CsSpace.xxs * 2),
            color: c.borderSegmentDivider,
          ),
        );
      }
      Widget segment = _Segment(
        option: o,
        selected: o.id == widget.selectedId,
        focusNode: _nodes[i],
        onPress: o.disabled || widget.onChange == null ? null : () => _select(o.id),
        focusableWhenDisabled: _focusable(i),
      );
      if (o.disabled && o.disabledReason != null) {
        segment = CsTooltip(content: o.disabledReason!, child: segment);
      }
      children.add(segment);
    }

    final radius = BorderRadius.circular(CsBorderRadius.button);
    final pill = DecoratedBox(
      decoration: BoxDecoration(
        color: c.backgroundSegmentWrapper,
        borderRadius: radius,
        border: CsRing.inside(c.borderSegmentWrapper, width: CsBorderWidth.field),
      ),
      child: Padding(
        // segment.scss: `padding: calc(gap / 2 - border) calc(gap - border)`
        // inside the 1px border.
        padding: const EdgeInsets.symmetric(horizontal: CsSpace.xxs, vertical: CsSpace.xxs / 2),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.label,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, child: pill),
      ),
    );
  }

  Widget _buildSelect(BuildContext context) {
    final cs = context.cs;
    CsSegmentedControlOption? selected;
    for (final o in widget.options) {
      if (o.id == widget.selectedId) selected = o;
    }
    final enabled = widget.onChange != null;
    Widget trigger = CsPressable(
      onPress: enabled ? () => setState(() => _open = !_open) : null,
      disabled: !enabled,
      scaleOnPress: false,
      showFocusRing: false,
      expanded: _open,
      semanticLabel: widget.label,
      semanticValue: selected?.label,
      builder: (context, state) => IconTheme.merge(
        data: IconThemeData(color: cs.colors.textBodyDefault),
        child: CsFieldBox(
          focused: state.focused || _open,
          disabled: !enabled,
          trailing: Padding(
            padding: const EdgeInsetsDirectional.only(end: CsSpace.xs),
            child: CsIcon(CsIcons.caretDownFilled, variant: enabled ? CsIconVariant.normal : CsIconVariant.disabled),
          ),
          child: Row(
            spacing: CsSpace.xs,
            children: [
              if (selected?.iconWidget != null || selected?.icon != null)
                selected!.iconWidget ??
                    CsIcon(selected.icon!, variant: enabled ? CsIconVariant.normal : CsIconVariant.disabled),
              Expanded(
                child: Text(
                  selected?.label ?? '',
                  style: cs.text(
                    CsTypeScale.bodyM,
                    color: enabled ? CsColor.textBodyDefault : CsColor.textInputDisabled,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    trigger = CsDropdown(
      open: _open,
      onDismiss: () => setState(() => _open = false),
      sheetLabel: widget.label,
      contentBuilder: (context, inSheet) => CsMenuKeyboard(
        child: CsMenuPanel(
          semanticLabel: widget.label,
          children: [
            for (final o in widget.options)
              CsMenuRow(
                label: o.label,
                icon: o.icon,
                leading: o.iconWidget,
                description: o.disabled ? o.disabledReason : null,
                disabled: o.disabled,
                selected: o.id == widget.selectedId,
                autofocus: o.id == widget.selectedId,
                onPress: () {
                  setState(() => _open = false);
                  if (inSheet) CsSheetScope.closeFrom(context);
                  _select(o.id);
                },
              ),
          ],
        ),
      ),
      child: trigger,
    );

    if (widget.label == null) return trigger;
    return CsFormField(label: widget.label, stretch: true, child: trigger);
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.focusNode,
    required this.onPress,
    required this.focusableWhenDisabled,
  });

  final CsSegmentedControlOption option;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback? onPress;
  final bool focusableWhenDisabled;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final disabled = option.disabled;
    // segment.scss: radius = root radius - (field border + button border).
    final radius = BorderRadius.circular(CsBorderRadius.button - (CsBorderWidth.field + CsBorderWidth.button));
    final hasText = option.text != null;
    final hasIcon = option.icon != null || option.iconWidget != null;
    return CsPressable(
      // A disabled segment with a reason stays focusable to show its tooltip.
      onPress: disabled ? (focusableWhenDisabled ? () {} : null) : (onPress ?? () {}),
      disabled: disabled && !focusableWhenDisabled,
      focusNode: focusNode,
      borderRadius: radius,
      // Padding segments to 44px would make the whole pill taller than
      // Cloudscape's; phones get the select form instead.
      minTapTargetSize: 0,
      focusRingOffset: CsSpace.segmentedControlFocusOutlineGutter - CsSpace.xxs,
      selected: selected,
      semanticLabel: hasText ? null : option.iconAlt,
      mouseCursor: disabled ? SystemMouseCursors.basic : null,
      builder: (context, state) {
        final Color bg;
        final CsColor fg;
        if (disabled) {
          bg = c.backgroundSegmentDisabled;
          fg = CsColor.textInteractiveDisabled;
        } else if (selected) {
          bg = c.backgroundSegmentActive;
          fg = CsColor.textSegmentActive;
        } else if (state.active && !state.focused) {
          bg = c.backgroundSegmentHover;
          fg = CsColor.textSegmentHover;
        } else {
          bg = c.backgroundSegmentDefault;
          fg = CsColor.textSegmentDefault;
        }
        final style = cs.text(CsTypeScale.bodyM, weight: CsTypography.bold, color: fg).copyWith(letterSpacing: 0.25);
        final icon = option.iconWidget ?? (option.icon == null ? null : CsIcon(option.icon!));
        return Container(
          margin: const EdgeInsets.symmetric(vertical: CsSpace.xxs / 2),
          padding: EdgeInsetsDirectional.only(
            start: cs.space.buttonHorizontal - CsSpace.xxs - (hasText && hasIcon ? CsSpace.xxs : 0),
            end: cs.space.buttonHorizontal - CsSpace.xxs,
            top: cs.space.fieldVertical - CsBorderWidth.field,
            bottom: cs.space.fieldVertical - CsBorderWidth.field,
          ),
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          alignment: Alignment.center,
          child: IconTheme.merge(
            data: IconThemeData(color: cs.color(fg)),
            child: DefaultTextStyle(
              style: style,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: CsSpace.xs,
                children: [
                  ?icon,
                  if (hasText) Flexible(child: Text(option.text!)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
