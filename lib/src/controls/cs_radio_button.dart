import 'package:flutter/widgets.dart';

import '../system/cs_focus_ring.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';

/// The 16px Cloudscape radio glyph: a circle with a 1px
/// `color-border-control-default` stroke that, when checked, fills with a
/// thick `color-background-control-checked` ring around a small dot.
///
/// The ring grows in from a thin stroke when the button becomes checked
/// (Cloudscape's `awsui-radio-select`, 250ms). Used by [CsRadioButton],
/// `CsRadioGroup`, `CsTiles` and single-select option lists.
///
/// ```dart
/// CsRadioIcon(checked: selected)
/// ```
class CsRadioIcon extends StatefulWidget {
  const CsRadioIcon({super.key, required this.checked, this.disabled = false, this.readOnly = false});

  final bool checked;
  final bool disabled;
  final bool readOnly;

  @override
  State<CsRadioIcon> createState() => _CsRadioIconState();
}

class _CsRadioIconState extends State<CsRadioIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _select;

  @override
  void initState() {
    super.initState();
    // At mount the glyph is already in its final state; the select motion
    // only plays after the value changes (`data-awsui-motion-ready`).
    _select = AnimationController(vsync: this, duration: const Duration(milliseconds: 250), value: 1);
  }

  @override
  void didUpdateWidget(CsRadioIcon old) {
    super.didUpdateWidget(old);
    if (widget.checked && !old.checked) {
      if (CsMotion.reduceMotion(context)) {
        _select.value = 1;
      } else {
        _select.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _select.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cs.colors;
    final inactive = widget.disabled || widget.readOnly;
    return SizedBox.square(
      dimension: CsSize.control,
      child: CustomPaint(
        painter: _RadioPainter(
          progress: _select,
          checked: widget.checked,
          outerFill: inactive ? c.backgroundControlDisabled : c.backgroundControlDefault,
          outerStroke: inactive ? c.backgroundControlDisabled : c.borderControlDefault,
          ring: inactive ? c.backgroundControlDisabled : c.backgroundControlChecked,
          dot: widget.disabled
              ? c.foregroundControlDisabled
              : widget.readOnly
              ? c.foregroundControlReadOnly
              : c.foregroundControlDefault,
        ),
      ),
    );
  }
}

class _RadioPainter extends CustomPainter {
  _RadioPainter({
    required this.progress,
    required this.checked,
    required this.outerFill,
    required this.outerStroke,
    required this.ring,
    required this.dot,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final bool checked;
  final Color outerFill;
  final Color outerStroke;
  final Color ring;
  final Color dot;

  // Cloudscape's SVG works in a 100x100 view box.
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    const center = Offset(50, 50);
    canvas
      ..drawCircle(center, 46, Paint()..color = outerFill)
      ..drawCircle(
        center,
        46,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.25
          ..color = outerStroke,
      );
    if (!checked) return;
    final t = const Cubic(0.2, 0, 0, 1).transform(progress.value);
    final stroke = 6 + (30 - 6) * t;
    canvas
      ..drawCircle(center, 35, Paint()..color = dot)
      ..drawCircle(
        center,
        35,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = ring,
      );
  }

  @override
  bool shouldRepaint(_RadioPainter old) =>
      old.checked != checked ||
      old.outerFill != outerFill ||
      old.outerStroke != outerStroke ||
      old.ring != ring ||
      old.dot != dot;
}

/// Cloudscape's `RadioButton`: one radio with a label and an optional
/// description, for building custom single-choice layouts. Most screens use
/// `CsRadioGroup`, which handles selection and arrow keys for a list.
///
/// ```dart
/// CsRadioButton(
///   checked: plan == 'standard',
///   onSelect: () => setState(() => plan = 'standard'),
///   label: 'Standard',
///   description: 'General purpose storage for frequently accessed data.',
/// )
/// ```
///
/// [onSelect] fires only when the button is not already checked, like the
/// native radio input.
class CsRadioButton extends StatelessWidget {
  const CsRadioButton({
    super.key,
    required this.checked,
    this.onSelect,
    this.label,
    this.child,
    this.description,
    this.descriptionWidget,
    this.disabled = false,
    this.readOnly = false,
    this.ariaLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether this radio is the selected one.
  final bool checked;

  /// Called when the user selects this radio while it is not checked. Null
  /// renders it disabled.
  final VoidCallback? onSelect;

  /// Label text next to the radio. Tapping the label selects it too.
  final String? label;

  /// Custom label content in place of [label].
  final Widget? child;

  /// Secondary text under the label (body-s, `color-text-form-secondary`).
  final String? description;

  /// Custom description content in place of [description].
  final Widget? descriptionWidget;

  /// Not selectable and not focusable.
  final bool disabled;

  /// Shows the value without letting the user change it. Still focusable.
  final bool readOnly;

  /// Accessible name when there is no visible label.
  final String? ariaLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onSelect == null;
    return CsPressable(
      onPress: isDisabled ? null : (readOnly || checked ? () {} : onSelect),
      disabled: isDisabled,
      focusNode: focusNode,
      autofocus: autofocus,
      scaleOnPress: false,
      showFocusRing: false,
      isButton: false,
      checked: checked,
      inMutuallyExclusiveGroup: true,
      semanticLabel: ariaLabel,
      mouseCursor: readOnly ? SystemMouseCursors.basic : null,
      builder: (context, state) => CsControlRow(
        control: CsFocusRing(
          visible: state.focused,
          offset: 2,
          borderRadius: BorderRadius.circular(CsBorderRadius.controlCircularFocusRing),
          child: CsRadioIcon(checked: checked, disabled: isDisabled, readOnly: readOnly),
        ),
        controlHeight: CsSize.control,
        label: child ?? (label == null ? null : Text(label!)),
        description: descriptionWidget ?? (description == null ? null : Text(description!)),
        disabled: isDisabled,
      ),
    );
  }
}

/// Lays out a 16px-ish control (checkbox, radio, toggle) with a label and a
/// description the way Cloudscape's abstract switch does: the control
/// centered on the label's first 20px line, the text 8px after it.
///
/// Building block for custom controls; `CsRadioButton` and `CsToggle` use it.
///
/// ```dart
/// CsControlRow(
///   control: CsRadioIcon(checked: true),
///   controlHeight: 16,
///   label: Text('Standard'),
/// )
/// ```
class CsControlRow extends StatelessWidget {
  const CsControlRow({
    super.key,
    required this.control,
    required this.controlHeight,
    this.label,
    this.description,
    this.disabled = false,
  });

  final Widget control;

  /// Height of [control], used to center it on the first label line.
  final double controlHeight;
  final Widget? label;
  final Widget? description;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    const line = CsFontTokens.lineHeightBodyM;
    final top = ((line - controlHeight) / 2).clamp(0.0, line);
    final boxed = Padding(
      padding: EdgeInsets.only(top: top, bottom: top),
      child: control,
    );
    if (label == null && description == null) return boxed;
    final labelStyle = cs.text(
      CsTypeScale.bodyM,
      color: disabled ? CsColor.textControlDisabled : CsColor.textFormDefault,
    );
    final descStyle = cs.text(
      CsTypeScale.bodyS,
      color: disabled ? CsColor.textControlDisabled : CsColor.textFormSecondary,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        boxed,
        Flexible(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: CsSpace.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null) DefaultTextStyle(style: labelStyle, child: label!),
                if (description != null) DefaultTextStyle(style: descStyle, child: description!),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
