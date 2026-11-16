import 'package:flutter/gestures.dart' show DeviceGestureSettings, DragStartBehavior, kMinFlingVelocity;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../system/cs_focus_ring.dart';
import '../system/cs_haptics.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_radio_button.dart';

// Sizes from toggle/styles.scss, in multiples of Cloudscape's 10px base size.
const double _trackWidth = 24;
const double _trackHeight = 16;
const double _handleSize = 12;
const double _handleOffset = 2;
const double _travel = 8;

// The expressive "tail": the handle stretches 4px while it travels or is held.
const double _tailStretch = 4;

/// Cloudscape's `Toggle`: an on/off switch for a setting that takes effect
/// immediately. Use `CsCheckbox` for choices that are saved with a form.
///
/// It is controlled: pass [checked] and update it in [onChange].
///
/// ```dart
/// CsToggle(
///   checked: monitoring,
///   onChange: (v) => setState(() => monitoring = v),
///   label: 'Detailed monitoring',
///   description: 'Collects metrics every minute.',
/// )
/// ```
///
/// The handle can be tapped, or dragged with a finger: it follows the finger,
/// resists past either end, and on release settles on the side the drag (and
/// any flick) points to. Toggling fires a selection haptic.
class CsToggle extends StatefulWidget {
  const CsToggle({
    super.key,
    required this.checked,
    this.onChange,
    this.label,
    this.child,
    this.description,
    this.descriptionWidget,
    this.disabled = false,
    this.readOnly = false,
    this.ariaLabel,
    this.ariaRequired = false,
    this.focusNode,
    this.autofocus = false,
    this.haptic = CsHaptic.selection,
  });

  final bool checked;

  /// Called with the next checked state. Null renders the toggle disabled.
  final ValueChanged<bool>? onChange;

  /// Label text next to the toggle. Tapping the label toggles too.
  final String? label;

  /// Custom label content in place of [label] (Cloudscape `children`).
  final Widget? child;

  /// Secondary text under the label.
  final String? description;

  /// Custom description content in place of [description].
  final Widget? descriptionWidget;
  final bool disabled;

  /// Shows the state without letting the user change it. Still focusable.
  final bool readOnly;

  /// Accessible name when there is no visible label.
  final String? ariaLabel;

  /// Announces the toggle as required.
  final bool ariaRequired;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Feedback fired when the state changes from a tap, key or drag.
  final CsHaptic haptic;

  @override
  State<CsToggle> createState() => _CsToggleState();
}

class _CsToggleState extends State<CsToggle> with TickerProviderStateMixin {
  // 0 is off, 1 is on; past either end while dragging (rubberband).
  late final AnimationController _position;
  // 0 at rest, 1 fully stretched (held or dragging).
  late final AnimationController _stretch;
  bool _dragging = false;
  double _dragStart = 0;
  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    _position = AnimationController.unbounded(vsync: this, value: widget.checked ? 1 : 0);
    _stretch = AnimationController.unbounded(vsync: this, value: 0);
  }

  @override
  void didUpdateWidget(CsToggle old) {
    super.didUpdateWidget(old);
    if (old.checked != widget.checked && !_dragging) _settle(widget.checked, tail: true);
  }

  @override
  void dispose() {
    _position.dispose();
    _stretch.dispose();
    super.dispose();
  }

  bool get _disabled => widget.disabled || widget.onChange == null;
  bool get _interactive => !_disabled && !widget.readOnly;
  double get _direction => Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  void _settle(bool on, {double velocity = 0, bool flick = false, bool tail = false}) {
    final target = on ? 1.0 : 0.0;
    if (CsMotion.reduceMotion(context)) {
      _position.value = target;
      _stretch.value = 0;
      return;
    }
    CsMotion.springTo(
      _position,
      target,
      spring: flick ? CsSprings.momentum : CsSprings.of(dampingRatio: 1, response: 0.18),
      velocity: velocity == 0 ? _position.velocity : velocity,
    );
    if (tail && !_dragging && _stretch.value < 0.01) {
      // The tail stretches early in the travel and relaxes as it lands.
      _stretch
          .animateTo(1, duration: CsDurations.refreshOnlyMedium * 0.35, curve: CsCurves.refreshOnlyA)
          .then(
            (_) => _stretch.animateTo(0, duration: CsDurations.refreshOnlyMedium * 0.65, curve: CsCurves.refreshOnlyA),
          );
    }
  }

  void _hold(bool held) {
    if (CsMotion.reduceMotion(context)) {
      _stretch.value = 0;
      return;
    }
    CsMotion.springTo(_stretch, held ? 1 : 0, spring: CsSprings.press, velocity: _stretch.velocity);
  }

  void _commit(bool on) {
    if (on == widget.checked) return;
    csHaptic(widget.haptic);
    widget.onChange?.call(on);
    // A controlled parent may refuse the change; return to its value.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_dragging && widget.checked != on) _settle(widget.checked);
    });
  }

  void _onDragStart(DragStartDetails details) {
    _position.stop();
    _dragging = true;
    _dragStart = _position.value.clamp(0.0, 1.0);
    _dragDx = 0;
    _hold(true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragDx += (details.primaryDelta ?? 0) * _direction;
    var px = _dragStart * _travel + _dragDx;
    if (px < 0) {
      px = CsMotion.rubberband(px, _travel);
    } else if (px > _travel) {
      px = _travel + CsMotion.rubberband(px - _travel, _travel);
    }
    _position.value = px / _travel;
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    _hold(false);
    final velocity = (details.primaryVelocity ?? 0) * _direction;
    final projected = _position.value * _travel + CsMotion.project(velocity);
    final on = projected >= _travel / 2;
    _settle(on, velocity: velocity / _travel, flick: velocity.abs() >= kMinFlingVelocity);
    _commit(on);
  }

  void _onDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    _hold(false);
    _settle(widget.checked);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _disabled;
    final hasLabel = widget.label != null || widget.child != null;
    Widget result = CsPressable(
      onPress: disabled ? null : (widget.readOnly ? () {} : () => _commit(!widget.checked)),
      onPressIn: _interactive ? () => _hold(true) : null,
      onPressOut: _interactive
          ? () {
              if (!_dragging) _hold(false);
            }
          : null,
      disabled: disabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      scaleOnPress: false,
      showFocusRing: false,
      isButton: false,
      toggled: widget.checked,
      semanticLabel: widget.ariaLabel ?? (hasLabel ? null : context.csStrings.switchLabel),
      semanticHint: widget.ariaRequired ? context.csStrings.required : null,
      mouseCursor: widget.readOnly ? SystemMouseCursors.basic : null,
      builder: (context, state) => CsControlRow(
        control: CsFocusRing(
          visible: state.focused,
          offset: 2,
          borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
          child: _ToggleTrack(
            position: _position,
            stretch: _stretch,
            checked: widget.checked,
            disabled: disabled,
            readOnly: widget.readOnly,
            rtl: _direction < 0,
          ),
        ),
        controlHeight: _trackHeight,
        label: widget.child ?? (widget.label == null ? null : Text(widget.label!)),
        description: widget.descriptionWidget ?? (widget.description == null ? null : Text(widget.description!)),
        disabled: disabled,
      ),
    );

    if (_interactive) {
      final media = MediaQuery.of(context);
      // Flutter's 18px touch slop is longer than the handle's 8px travel, so
      // the drag recognizer gets a small slop; the content keeps the default.
      result = MediaQuery(
        data: media.copyWith(gestureSettings: const DeviceGestureSettings(touchSlop: 4)),
        child: GestureDetector(
          excludeFromSemantics: true,
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: _onDragCancel,
          child: MediaQuery(data: media, child: result),
        ),
      );
    }
    return result;
  }
}

class _ToggleTrack extends StatelessWidget {
  const _ToggleTrack({
    required this.position,
    required this.stretch,
    required this.checked,
    required this.disabled,
    required this.readOnly,
    required this.rtl,
  });

  final AnimationController position;
  final AnimationController stretch;
  final bool checked;
  final bool disabled;
  final bool readOnly;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final c = context.cs.colors;
    final Color offTrack;
    final Color onTrack;
    if (disabled) {
      offTrack = c.backgroundControlDisabled;
      onTrack = c.backgroundToggleCheckedDisabled;
    } else if (readOnly) {
      offTrack = c.backgroundControlDisabled;
      onTrack = c.backgroundControlDisabled;
    } else {
      offTrack = c.backgroundToggleDefault;
      onTrack = c.backgroundControlChecked;
    }
    final Color offHandle = disabled ? c.foregroundControlDisabled : c.foregroundControlDefault;
    final Color onHandle = disabled
        ? c.foregroundControlDisabled
        : readOnly
        ? c.foregroundControlReadOnly
        : c.foregroundControlDefault;
    final shadow = !disabled && !readOnly;

    return AnimatedBuilder(
      animation: Listenable.merge([position, stretch]),
      builder: (context, _) {
        final p = position.value;
        final t = p.clamp(0.0, 1.0);
        final extra = _tailStretch * stretch.value.clamp(0.0, 1.0);
        // The stretch grows away from the edge the handle leaves, so it
        // stays inside the track.
        final left = _handleOffset + (_travel - extra) * p;
        final x = rtl ? _trackWidth - left - _handleSize - extra : left;
        return SizedBox(
          width: _trackWidth,
          height: _trackHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(offTrack, onTrack, t),
              borderRadius: BorderRadius.circular(_trackHeight / 2),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: x,
                  top: _handleOffset,
                  width: _handleSize + extra,
                  height: _handleSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color.lerp(offHandle, onHandle, t),
                      borderRadius: BorderRadius.circular(_handleSize / 2),
                      boxShadow: shadow ? [BoxShadow(color: c.shadowToggleHandle, offset: const Offset(1, 1))] : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
