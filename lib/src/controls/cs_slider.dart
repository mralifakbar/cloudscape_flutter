import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../overlays/cs_tooltip.dart';
import '../system/cs_haptics.dart';
import '../theme/theme.dart';

/// Copy for [CsSlider] (Cloudscape `i18nStrings`).
@immutable
class CsSliderI18nStrings {
  const CsSliderI18nStrings({this.valueTextRange});

  /// Spoken value when [CsSlider.valueFormatter] returns an empty string for
  /// the current value (it sits between two labelled values). Defaults to
  /// "{value}, between {previousValue} and {nextValue}".
  final String Function(String previousValue, double value, String nextValue)? valueTextRange;
}

// Sizes from slider/mixins.scss and styles.scss.
const double _thumbSize = 16;
const double _thumbActiveSize = 20;
const double _thumbReadOnlySize = 12;
const double _trackHeight = 2;
const double _rangeHeight = 4;
const double _tickHeight = CsSpace.xs;
const double _tickWidth = CsSpace.xxxs;

/// Cloudscape's `Slider`: picks a number from a range by dragging a handle
/// along a track, for values where the relative position matters more than
/// the exact number (a percentage, a capacity). Pair it with an input when
/// users need to type exact values.
///
/// It is controlled: pass [value] and update it in [onChange].
///
/// ```dart
/// CsSlider(
///   min: 0,
///   max: 100,
///   step: 10,
///   tickMarks: true,
///   value: capacity,
///   valueFormatter: (v) => '${v.round()}%',
///   onChange: (v) => setState(() => capacity = v),
/// )
/// ```
///
/// Touch: pressing the track jumps the handle there and the handle then
/// follows the finger. Stepped sliders fire a selection haptic at each step.
/// Keyboard: arrows move one step, Page Up and Page Down ten, Home and End
/// jump to the ends. The value shows in a tooltip over the handle while it is
/// hovered, focused or dragged.
class CsSlider extends StatefulWidget {
  const CsSlider({
    super.key,
    required this.min,
    required this.max,
    this.value,
    this.onChange,
    this.onChangeEnd,
    this.step,
    this.valueFormatter,
    this.referenceValues = const [],
    this.tickMarks = false,
    this.hideFillLine = false,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warning = false,
    this.ariaLabel,
    this.ariaDescription,
    this.i18nStrings = const CsSliderI18nStrings(),
    this.focusNode,
    this.autofocus = false,
    this.haptic = CsHaptic.selection,
  }) : assert(max > min, 'max must be greater than min');

  final double min;
  final double max;

  /// The current value. Null shows the middle of the range, like the native
  /// range input. A value off the step grid is shown at the nearest step.
  final double? value;

  /// Called with each new value while the user drags, taps or presses keys.
  final ValueChanged<double>? onChange;

  /// Called once when a drag or tap ends, with the final value (a Flutter
  /// addition for saving only the committed value).
  final ValueChanged<double>? onChangeEnd;

  /// Granularity of the value. Null lets the value move continuously (with
  /// keyboard steps of 1).
  final double? step;

  /// Formats the min and max labels, reference labels and the tooltip.
  final String Function(double value)? valueFormatter;

  /// Labels shown between min and max. Values that would crowd their
  /// neighbors, sit outside the range or are not integers are skipped, and
  /// they all hide under 465px.
  final List<double> referenceValues;

  /// Draws a tick at every step. Requires [step].
  final bool tickMarks;

  /// Hides the colored fill from the start to the handle.
  final bool hideFillLine;
  final bool disabled;

  /// Shows the value without letting the user change it. Still focusable.
  final bool readOnly;

  /// Error colors for the fill and handle. Set it with the form field's
  /// `errorText`.
  final bool invalid;

  /// Warning colors for the fill and handle. Ignored when [invalid].
  final bool warning;

  /// Accessible name when there is no visible label.
  final String? ariaLabel;

  /// Extra description read after the value, for formatted labels.
  final String? ariaDescription;
  final CsSliderI18nStrings i18nStrings;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Feedback fired when a drag crosses a step.
  final CsHaptic haptic;

  /// Rounds [value] to the nearest step from [min], within the range.
  static double snap(double value, {required double min, required double max, double? step}) {
    final clamped = value.clamp(min, max).toDouble();
    if (step == null || step <= 0) return clamped;
    final steps = ((clamped - min) / step).round();
    final snapped = min + steps * step;
    // Keeps 0.1 steps from drifting into 0.30000000000000004.
    final decimals = _decimals(step);
    return double.parse(math.min(max, snapped).toStringAsFixed(decimals));
  }

  static int _decimals(double v) {
    final s = v.toString();
    final dot = s.indexOf('.');
    if (s.contains('e-')) return int.parse(s.split('e-').last);
    if (dot < 0) return 0;
    final frac = s.substring(dot + 1);
    return frac == '0' ? 0 : frac.length;
  }

  /// The reference values Cloudscape would show: integers inside the range,
  /// at least a tenth (a quarter on phones) of the range apart.
  static List<double> visibleReferenceValues(List<double> values, double min, double max, {required bool narrow}) {
    final minDistance = (max - min) / (narrow ? 4 : 10);
    final result = <double>[];
    var last = min;
    for (final v in values) {
      if (v > min &&
          v < max &&
          (v - last).abs() >= minDistance &&
          (max - v).abs() >= minDistance &&
          v == v.roundToDouble()) {
        result.add(v);
        last = v;
      }
    }
    return result;
  }

  @override
  State<CsSlider> createState() => _CsSliderState();
}

class _CsSliderState extends State<CsSlider> {
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'CsSlider'));
  bool _focused = false;
  bool _focusVisible = false;
  bool _hovered = false;
  bool _dragging = false;
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(CsSlider old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (mounted && _focused != _focus.hasFocus) setState(() => _focused = _focus.hasFocus);
  }

  bool get _enabled => !widget.disabled && widget.onChange != null;
  bool get _interactive => _enabled && !widget.readOnly;

  double get _value {
    final v = widget.value ?? widget.min + (widget.max - widget.min) / 2;
    return CsSlider.snap(v, min: widget.min, max: widget.max, step: widget.step);
  }

  double get _keyStep => widget.step ?? 1;

  String _format(double v) {
    final f = widget.valueFormatter;
    if (f != null) return f(v);
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  void _emit(double v, {bool end = false}) {
    final snapped = CsSlider.snap(v, min: widget.min, max: widget.max, step: widget.step);
    if (snapped != (_dragValue ?? _value)) {
      if (widget.step != null) csHaptic(widget.haptic);
      _dragValue = snapped;
      widget.onChange?.call(snapped);
    }
    if (end) {
      widget.onChangeEnd?.call(_dragValue ?? _value);
      _dragValue = null;
    }
  }

  double _valueAt(double dx, double width) {
    final usable = width - _thumbSize;
    if (usable <= 0) return widget.min;
    var f = ((dx - _thumbSize / 2) / usable).clamp(0.0, 1.0);
    if (Directionality.of(context) == TextDirection.rtl) f = 1 - f;
    return widget.min + f * (widget.max - widget.min);
  }

  void _stepBy(double delta) {
    if (!_interactive) return;
    _emit(_value + delta);
    widget.onChangeEnd?.call(_dragValue ?? _value);
    _dragValue = null;
  }

  void _setTo(double v) {
    if (!_interactive) return;
    _emit(v);
    widget.onChangeEnd?.call(_dragValue ?? _value);
    _dragValue = null;
  }

  String? _valueText() {
    final f = widget.valueFormatter;
    final v = _value;
    if (f == null) return null;
    final formatted = f(v);
    if (formatted.isNotEmpty) return formatted;
    final sorted = [widget.min, ...widget.referenceValues, widget.max]..sort();
    double? lower;
    double? higher;
    for (final r in sorted) {
      if (r < v) lower = r;
      if (r > v && higher == null) higher = r;
    }
    final prev = f(lower ?? widget.min);
    final next = f(higher ?? widget.max);
    final custom = widget.i18nStrings.valueTextRange;
    if (custom != null) return custom(prev, v, next);
    return '${_format(v)}, between $prev and $next';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final value = _value;
    final fraction = (value - widget.min) / (widget.max - widget.min);
    final active = (_focused || _dragging) && _enabled;
    final showTooltip = _enabled && (_hovered || _focusVisible || _dragging);
    final narrow = context.csIsNarrow;
    final tiny = MediaQuery.sizeOf(context).width < CsBreakpoint.xxs.minWidth;
    final refs = tiny
        ? const <double>[]
        : CsSlider.visibleReferenceValues(widget.referenceValues, widget.min, widget.max, narrow: narrow);

    final up = CsSlider.snap(value + _keyStep, min: widget.min, max: widget.max, step: widget.step);
    final down = CsSlider.snap(value - _keyStep, min: widget.min, max: widget.max, step: widget.step);

    final bigStep = math.max(_keyStep, (widget.max - widget.min) / 10);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.arrowRight): () => _stepBy(rtl ? -_keyStep : _keyStep),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _stepBy(rtl ? _keyStep : -_keyStep),
      const SingleActivator(LogicalKeyboardKey.arrowUp): () => _stepBy(_keyStep),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () => _stepBy(-_keyStep),
      const SingleActivator(LogicalKeyboardKey.pageUp): () => _stepBy(bigStep),
      const SingleActivator(LogicalKeyboardKey.pageDown): () => _stepBy(-bigStep),
      const SingleActivator(LogicalKeyboardKey.home): () => _setTo(widget.min),
      const SingleActivator(LogicalKeyboardKey.end): () => _setTo(widget.max),
    };

    final band = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbX = _thumbSize / 2 + (width - _thumbSize) * (rtl ? 1 - fraction : fraction);
        final thumbDiameter = widget.readOnly ? _thumbReadOnlySize : (active ? _thumbActiveSize : _thumbSize);
        Widget paint = TweenAnimationBuilder<double>(
          tween: Tween(end: thumbDiameter),
          duration: CsMotion.duration(context, CsDurations.responsive),
          curve: CsCurves.responsive,
          builder: (context, diameter, _) => CustomPaint(
            size: Size(width, 20),
            painter: _SliderPainter(
              colors: _SliderColors.resolve(
                cs,
                disabled: !_enabled,
                readOnly: widget.readOnly,
                invalid: widget.invalid,
                warning: widget.warning && !widget.invalid,
                active: active,
              ),
              fraction: fraction,
              rtl: rtl,
              thumbDiameter: diameter,
              halo: _enabled && !widget.readOnly && (_hovered || active),
              hideFill: widget.hideFillLine,
              ticks: widget.tickMarks && widget.step != null
                  ? _tickFractions(widget.min, widget.max, widget.step!)
                  : const [],
            ),
          ),
        );
        // The tooltip anchors to a box over the handle.
        paint = Stack(
          clipBehavior: Clip.none,
          children: [
            paint,
            Positioned(
              left: thumbX - _thumbActiveSize / 2,
              top: 0,
              width: _thumbActiveSize,
              height: 20,
              child: CsTooltip(
                content: _format(value),
                open: showTooltip,
                onOpenChange: (_) {},
                child: const SizedBox.expand(),
              ),
            ),
          ],
        );
        paint = Padding(
          padding: const EdgeInsets.symmetric(vertical: CsSpace.s),
          child: paint,
        );
        if (!_interactive) return paint;
        return GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onTapDown: (d) {
            _focus.requestFocus();
            _emit(_valueAt(d.localPosition.dx, width));
          },
          onTapUp: (_) => _emit(_dragValue ?? _value, end: true),
          onHorizontalDragStart: (d) {
            setState(() => _dragging = true);
            _focus.requestFocus();
            _emit(_valueAt(d.localPosition.dx, width));
          },
          onHorizontalDragUpdate: (d) => _emit(_valueAt(d.localPosition.dx, width)),
          onHorizontalDragEnd: (_) {
            setState(() => _dragging = false);
            _emit(_dragValue ?? _value, end: true);
          },
          onHorizontalDragCancel: () {
            setState(() => _dragging = false);
            _dragValue = null;
          },
          child: paint,
        );
      },
    );

    final labelStyle = cs.text(
      CsTypeScale.bodyS,
      color: _enabled ? CsColor.textBodyDefault : CsColor.textControlDisabled,
    );
    final labels = ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final usable = width - _thumbSize;
          return DefaultTextStyle(
            style: labelStyle,
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(_format(widget.min))),
                    Expanded(child: Text(_format(widget.max), textAlign: TextAlign.end)),
                  ],
                ),
                for (final r in refs)
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    start: _thumbSize / 2 + usable * (r - widget.min) / (widget.max - widget.min) - 40,
                    width: 80,
                    top: 0,
                    child: Text(_format(r), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          );
        },
      ),
    );

    Widget result = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        band,
        labels,
        const SizedBox(height: CsSpace.s),
      ],
    );

    result = Semantics(
      slider: true,
      enabled: !widget.disabled,
      readOnly: widget.readOnly,
      focusable: _enabled,
      label: widget.ariaLabel,
      hint: widget.ariaDescription,
      value: _valueText() ?? _format(value),
      increasedValue: _interactive && value < widget.max ? _format(up) : null,
      decreasedValue: _interactive && value > widget.min ? _format(down) : null,
      onIncrease: _interactive && value < widget.max ? () => _stepBy(_keyStep) : null,
      onDecrease: _interactive && value > widget.min ? () => _stepBy(-_keyStep) : null,
      child: result,
    );

    return FocusableActionDetector(
      enabled: _enabled,
      focusNode: _focus,
      autofocus: widget.autofocus,
      shortcuts: {for (final k in shortcuts.keys) k: VoidCallbackIntent(shortcuts[k]!)},
      onShowFocusHighlight: (v) {
        if (_focusVisible != v) setState(() => _focusVisible = v);
      },
      onShowHoverHighlight: (v) {
        if (_hovered != v) setState(() => _hovered = v);
      },
      mouseCursor: _interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: result,
    );
  }

  static List<double> _tickFractions(double min, double max, double step) {
    final count = ((max - min) / step).floor();
    if (count <= 0 || count > 200) return const [];
    return [for (var i = 0; i <= count; i++) (i * step) / (max - min)];
  }
}

@immutable
class _SliderColors {
  const _SliderColors({required this.track, required this.range, required this.thumb, required this.ring});

  final Color track;
  final Color range;
  final Color thumb;
  final Color ring;

  static _SliderColors resolve(
    CsThemeData cs, {
    required bool disabled,
    required bool readOnly,
    required bool invalid,
    required bool warning,
    required bool active,
  }) {
    final c = cs.colors;
    if (disabled) {
      return _SliderColors(
        track: c.backgroundControlDisabled,
        range: c.backgroundControlDisabled,
        thumb: c.backgroundControlDisabled,
        ring: c.backgroundSliderHandleRing,
      );
    }
    if (readOnly) {
      return _SliderColors(
        track: c.backgroundControlDisabled,
        range: c.foregroundControlReadOnly,
        thumb: c.foregroundControlReadOnly,
        ring: c.backgroundSliderHandleRing,
      );
    }
    if (invalid) {
      return _SliderColors(
        track: c.backgroundSliderTrackDefault,
        range: active ? c.backgroundSliderRangeErrorActive : c.backgroundSliderRangeErrorDefault,
        thumb: active ? c.backgroundSliderHandleErrorActive : c.backgroundSliderHandleErrorDefault,
        ring: c.backgroundSliderHandleRing,
      );
    }
    if (warning) {
      return _SliderColors(
        track: c.backgroundSliderTrackDefault,
        range: active ? c.backgroundSliderRangeWarningActive : c.backgroundSliderRangeWarningDefault,
        thumb: active ? c.backgroundSliderHandleWarningActive : c.backgroundSliderHandleWarningDefault,
        ring: c.backgroundSliderHandleRing,
      );
    }
    return _SliderColors(
      track: c.backgroundSliderTrackDefault,
      range: active ? c.backgroundSliderRangeActive : c.backgroundSliderRangeDefault,
      thumb: active ? c.backgroundSliderHandleActive : c.backgroundSliderHandleDefault,
      ring: c.backgroundSliderHandleRing,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _SliderColors &&
      other.track == track &&
      other.range == range &&
      other.thumb == thumb &&
      other.ring == ring;

  @override
  int get hashCode => Object.hash(track, range, thumb, ring);
}

class _SliderPainter extends CustomPainter {
  _SliderPainter({
    required this.colors,
    required this.fraction,
    required this.rtl,
    required this.thumbDiameter,
    required this.halo,
    required this.hideFill,
    required this.ticks,
  });

  final _SliderColors colors;
  final double fraction;
  final bool rtl;
  final double thumbDiameter;
  final bool halo;
  final bool hideFill;
  final List<double> ticks;

  double _x(Size size, double f) => _thumbSize / 2 + (size.width - _thumbSize) * (rtl ? 1 - f : f);

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    const radius = Radius.circular(3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, cy - _trackHeight / 2, size.width, _trackHeight), radius),
      Paint()..color = colors.track,
    );
    final thumbX = _x(size, fraction);
    if (!hideFill) {
      // The fill runs from the start edge to the far side of the handle.
      final rect = rtl
          ? Rect.fromLTRB(thumbX - _thumbSize / 2, cy - _rangeHeight / 2, size.width, cy + _rangeHeight / 2)
          : Rect.fromLTRB(0, cy - _rangeHeight / 2, thumbX + _thumbSize / 2, cy + _rangeHeight / 2);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), Paint()..color = colors.range);
    }
    for (var i = 1; i < ticks.length - 1; i++) {
      final f = ticks[i];
      final x = _x(size, f);
      final filled = !hideFill && fraction > f;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, cy), width: _tickWidth, height: _tickHeight),
        Paint()..color = filled ? colors.range : colors.track,
      );
    }
    final center = Offset(thumbX, cy);
    final r = thumbDiameter / 2;
    if (halo) {
      canvas
        ..drawCircle(center, r + 4, Paint()..color = colors.thumb)
        ..drawCircle(center, r + 2, Paint()..color = colors.ring);
    }
    canvas.drawCircle(center, r, Paint()..color = colors.thumb);
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      old.colors != colors ||
      old.fraction != fraction ||
      old.rtl != rtl ||
      old.thumbDiameter != thumbDiameter ||
      old.halo != halo ||
      old.hideFill != hideFill ||
      old.ticks.length != ticks.length;
}
