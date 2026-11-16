import 'package:flutter/widgets.dart';

import '../system/cs_focus_ring.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// The 16px Cloudscape checkbox glyph: a box with a 3px radius that fills
/// with `color-background-control-checked` and draws its check mark in when
/// it becomes checked. Used by `CsCheckbox`, table row selection and
/// multiselect options.
class CsCheckboxIcon extends StatefulWidget {
  const CsCheckboxIcon({
    super.key,
    required this.checked,
    this.indeterminate = false,
    this.disabled = false,
    this.readOnly = false,
  });

  final bool checked;

  /// Draws a dash instead of a check (some items of a list selected).
  final bool indeterminate;
  final bool disabled;
  final bool readOnly;

  @override
  State<CsCheckboxIcon> createState() => _CsCheckboxIconState();
}

class _CsCheckboxIconState extends State<CsCheckboxIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _draw;

  @override
  void initState() {
    super.initState();
    // The draw-in only plays after the state changes; at mount it is drawn.
    _draw = AnimationController(vsync: this, duration: CsDurations.expressive, value: 1);
  }

  @override
  void didUpdateWidget(CsCheckboxIcon old) {
    super.didUpdateWidget(old);
    final wasOn = old.checked || old.indeterminate;
    final isOn = widget.checked || widget.indeterminate;
    if (isOn && (!wasOn || old.indeterminate != widget.indeterminate)) {
      if (CsMotion.reduceMotion(context)) {
        _draw.value = 1;
      } else {
        _draw.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cs.colors;
    final on = widget.checked || widget.indeterminate;
    final inactive = widget.disabled || widget.readOnly;
    final fill = inactive
        ? c.backgroundControlDisabled
        : (on ? c.backgroundControlChecked : c.backgroundControlDefault);
    final stroke = inactive ? c.borderControlDisabled : (on ? c.borderControlChecked : c.borderControlDefault);
    final line = widget.disabled
        ? c.foregroundControlDisabled
        : widget.readOnly
        ? c.foregroundControlReadOnly
        : c.foregroundControlDefault;
    return SizedBox.square(
      dimension: CsSize.control,
      child: CustomPaint(
        painter: _CheckboxPainter(
          progress: _draw,
          fill: fill,
          stroke: stroke,
          line: line,
          mark: widget.indeterminate ? _Mark.dash : (widget.checked ? _Mark.check : _Mark.none),
        ),
      ),
    );
  }
}

enum _Mark { none, check, dash }

class _CheckboxPainter extends CustomPainter {
  _CheckboxPainter({
    required this.progress,
    required this.fill,
    required this.stroke,
    required this.line,
    required this.mark,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color fill;
  final Color stroke;
  final Color line;
  final _Mark mark;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 16;
    canvas.scale(s);
    final box = RRect.fromRectAndRadius(const Rect.fromLTWH(0.5, 0.5, 15, 15), const Radius.circular(3));
    canvas.drawRRect(box, Paint()..color = fill);
    canvas.drawRRect(
      box,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = CsBorderWidth.field
        ..color = stroke,
    );
    if (mark == _Mark.none) return;
    final path = Path();
    if (mark == _Mark.check) {
      path
        ..moveTo(3.5, 8)
        ..lineTo(7, 11)
        ..lineTo(12, 4);
    } else {
      path
        ..moveTo(3.5, 8)
        ..lineTo(12.5, 8);
    }
    var drawn = path;
    final t = Curves.easeOut.transform(progress.value);
    if (t < 1) {
      drawn = Path();
      for (final m in path.computeMetrics()) {
        drawn.addPath(m.extractPath(0, m.length * t), Offset.zero);
      }
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.miter
        ..color = line,
    );
  }

  @override
  bool shouldRepaint(_CheckboxPainter old) =>
      old.fill != fill || old.stroke != stroke || old.line != line || old.mark != mark;
}

/// Cloudscape's `Checkbox`: a box with a label for a single on or off choice,
/// or the "select all" control above a list ([indeterminate]).
///
/// ```dart
/// CsCheckbox(
///   checked: agreed,
///   onChange: (v) => setState(() => agreed = v),
///   label: 'I acknowledge the terms',
/// )
/// ```
///
/// Tapping the label toggles it too. Use `CsToggle` for settings that take
/// effect at once, and a checkbox for choices submitted with a form. A
/// read-only checkbox stays focusable but ignores taps and keys.
class CsCheckbox extends StatelessWidget {
  const CsCheckbox({
    super.key,
    required this.checked,
    this.onChange,
    this.label,
    this.child,
    this.description,
    this.indeterminate = false,
    this.disabled = false,
    this.readOnly = false,
    this.ariaLabel,
    this.ariaRequired = false,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether the box is checked.
  final bool checked;

  /// Called with the next checked state. An indeterminate checkbox becomes
  /// checked. Null renders the checkbox disabled.
  final ValueChanged<bool>? onChange;
  final String? label;

  /// Custom label content in place of [label].
  final Widget? child;
  final String? description;

  /// A dash for "some selected". Takes priority over [checked] in the visual.
  final bool indeterminate;
  final bool disabled;
  final bool readOnly;

  /// Accessible name when there is no visible label.
  final String? ariaLabel;

  /// Announces the checkbox as required.
  final bool ariaRequired;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final isDisabled = disabled || onChange == null;
    final hasLabel = label != null || child != null;
    final labelStyle = cs.text(
      CsTypeScale.bodyM,
      color: isDisabled ? CsColor.textControlDisabled : CsColor.textFormDefault,
    );
    final descStyle = cs.text(
      CsTypeScale.bodyS,
      color: isDisabled ? CsColor.textControlDisabled : CsColor.textFormSecondary,
    );
    return CsPressable(
      // Read-only stays focusable (Cloudscape) but ignores activation.
      onPress: isDisabled ? null : (readOnly ? () {} : () => onChange!(indeterminate ? true : !checked)),
      mouseCursor: readOnly ? SystemMouseCursors.basic : null,
      disabled: isDisabled,
      focusNode: focusNode,
      autofocus: autofocus,
      scaleOnPress: false,
      showFocusRing: false,
      checked: indeterminate ? null : checked,
      mixed: indeterminate ? true : null,
      semanticLabel: ariaLabel,
      semanticHint: ariaRequired ? context.csStrings.required : null,
      isButton: false,
      builder: (context, state) {
        Widget box = CsCheckboxIcon(
          checked: checked,
          indeterminate: indeterminate,
          disabled: isDisabled,
          readOnly: readOnly,
        );
        box = CsFocusRing(
          visible: state.focused,
          offset: 2,
          borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
          child: box,
        );
        // The box sits centered on the 20px first line of the label.
        box = Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: box);
        if (!hasLabel && description == null) return box;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            box,
            Flexible(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: CsSpace.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasLabel) DefaultTextStyle(style: labelStyle, child: child ?? Text(label!)),
                    if (description != null) Text(description!, style: descStyle),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
