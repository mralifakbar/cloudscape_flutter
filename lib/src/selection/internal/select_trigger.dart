import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../icons/cs_icon.dart';
import '../../icons/cs_icons.g.dart';
import '../../system/cs_field_box.dart';
import '../../system/cs_pressable.dart';
import '../../theme/theme.dart';
import '../cs_option.dart';
import 'option_list.dart';

/// The trigger of selects and multiselects (Cloudscape `ButtonTrigger`):
/// input chrome, the content, and a filled caret that turns over while the
/// list is open. Hover only recolors the caret.
class SelectTrigger extends StatelessWidget {
  const SelectTrigger({
    super.key,
    required this.child,
    required this.focusNode,
    required this.open,
    this.onPress,
    this.onKey,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warning = false,
    this.autofocus = false,
    this.semanticLabel,
    this.semanticValue,
    this.semanticHint,
    this.inlineLabelText,
  });

  final Widget child;
  final FocusNode focusNode;
  final bool open;
  final VoidCallback? onPress;
  final FocusOnKeyEventCallback? onKey;
  final bool disabled;
  final bool readOnly;
  final bool invalid;
  final bool warning;
  final bool autofocus;
  final String? semanticLabel;
  final String? semanticValue;
  final String? semanticHint;
  final String? inlineLabelText;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final status = invalid
        ? CsFieldStatus.invalid
        : warning
        ? CsFieldStatus.warning
        : CsFieldStatus.none;
    Widget trigger = CsPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPress: disabled || readOnly ? null : onPress,
      disabled: disabled,
      // Read-only triggers stay focusable so their value can be read.
      canRequestFocus: !disabled,
      showFocusRing: false,
      scaleOnPress: false,
      minTapTargetSize: 0,
      semanticLabel: semanticLabel,
      semanticValue: semanticValue,
      semanticHint: semanticHint,
      expanded: open,
      excludeChildSemantics: semanticValue != null,
      borderRadius: BorderRadius.circular(CsBorderRadius.input),
      builder: (context, state) {
        final caretColor = disabled
            ? c.textButtonInlineIconDisabled
            : state.hovered
            ? c.textButtonInlineIconHover
            : c.textButtonInlineIconDefault;
        // CsFieldBox aligns its content, which makes it fill a loose height;
        // the trigger is as tall as its content.
        return UnconstrainedBox(
          constrainedAxis: Axis.horizontal,
          child: CsFieldBox(
            focused: state.focused,
            status: status,
            disabled: disabled,
            readOnly: readOnly,
            trailing: Padding(
              padding: const EdgeInsetsDirectional.only(end: CsSpace.xxs),
              child: AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: CsMotion.duration(context, CsDurations.rotate180),
                curve: CsCurves.rotate180,
                child: CsIcon(CsIcons.caretDownFilled, dangerouslySetColor: caretColor),
              ),
            ),
            child: DefaultTextStyle.merge(
              style: cs.body.copyWith(color: disabled ? c.textInputDisabled : c.textBodyDefault),
              child: child,
            ),
          ),
        );
      },
    );
    if (onKey != null) {
      trigger = Focus(canRequestFocus: false, skipTraversal: true, onKeyEvent: onKey, child: trigger);
    }
    if (inlineLabelText != null) {
      trigger = InlineLabel(text: inlineLabelText!, disabled: disabled, child: trigger);
    }
    return trigger;
  }
}

/// Cloudscape's inline label: small bold text that sits on the top border of
/// a field, its background fading from the page color into the field color.
class InlineLabel extends StatelessWidget {
  const InlineLabel({super.key, required this.text, required this.child, this.disabled = false});

  final String text;
  final Widget child;
  final bool disabled;

  /// `inline-label-trigger-wrapper { margin-block-start: -7px }`: how far the
  /// label overlaps the field.
  static const double _overlap = 7;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final label = Container(
      padding: EdgeInsetsDirectional.only(start: cs.space.scaledXxs, end: cs.space.scaledXxs, bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.backgroundLayoutMain, disabled ? c.backgroundInputDisabled : c.backgroundInputDefault],
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: cs
            .text(CsTypeScale.bodyS, weight: CsTypography.bold, color: CsColor.textFormLabel)
            .copyWith(height: 14 / 12),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _overlap),
          child: child,
        ),
        PositionedDirectional(
          top: 0,
          start: CsBorderWidth.field + CsSpace.fieldHorizontal - CsSpace.xxs,
          end: CsSpace.fieldHorizontal,
          child: Align(alignment: AlignmentDirectional.topStart, child: label),
        ),
      ],
    );
  }
}

/// Type-to-jump in a closed or open select without a filter: letters typed
/// within 500ms build a prefix and the highlight moves to the next option
/// starting with it.
class Typeahead {
  String _buffer = '';
  DateTime? _last;

  /// The printable character of [event], or null.
  String? characterOf(KeyEvent event) {
    final ch = event.character;
    if (ch == null || ch.isEmpty) return null;
    if (ch.codeUnitAt(0) < 0x20 || ch == '\u007f') return null;
    if (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed) return null;
    return ch;
  }

  /// Whether a prefix is being typed (Space then extends it).
  bool get active => _buffer.isNotEmpty && _last != null && clock.now().difference(_last!) < _window;

  static const Duration _window = Duration(milliseconds: 500);

  /// Index of the next match after [from], or -1.
  int search(List<OptionEntry> entries, String char, int from) {
    final now = clock.now();
    if (_last == null || now.difference(_last!) > _window) _buffer = '';
    _last = now;
    _buffer += char.toLowerCase();
    bool hit(int i) => entries[i].isInteractive() && entries[i].option.text.toLowerCase().startsWith(_buffer);
    final n = entries.length;
    final start = _buffer.length == 1 ? from + 1 : from;
    for (var k = 0; k < n; k++) {
      final i = ((start < 0 ? 0 : start) + k) % n;
      if (hit(i)) return i;
    }
    return -1;
  }
}

/// Looks up an option by value in [items].
CsOption? findOption(List<CsOptionItem> items, String? value) {
  if (value == null) return null;
  for (final o in allOptions(items)) {
    if (o.value == value) return o;
  }
  return null;
}
