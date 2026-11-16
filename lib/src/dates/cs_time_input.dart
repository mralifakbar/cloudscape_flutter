import 'package:flutter/widgets.dart';

import '../forms/cs_input.dart';
import 'cs_dates_internal.dart';

/// The parts a [CsTimeInput] accepts (Cloudscape `format`).
enum CsTimeInputFormat {
  /// Hours only: `hh`.
  hh('hh', 1),

  /// Hours and minutes: `hh:mm`.
  hhMm('hh:mm', 2),

  /// Hours, minutes and seconds: `hh:mm:ss`. The default.
  hhMmSs('hh:mm:ss', 3);

  const CsTimeInputFormat(this.pattern, this.parts);

  /// The pattern as Cloudscape writes it, handy as a placeholder.
  final String pattern;

  /// Number of two-digit parts.
  final int parts;
}

/// Cloudscape's `TimeInput`: a masked text field for a time of day.
///
/// Digits are typed into `hh:mm:ss` (or `hh:mm`, `hh`) and the colons are
/// added for you. A first digit that can not start a valid part is padded
/// (typing 7 in the hour gives `07:`), out-of-range values are capped, and
/// on blur or Enter an incomplete time is completed (`10:1` becomes
/// `10:01:00`).
///
/// It is controlled: [onChange] receives the text as it is typed.
///
/// ```dart
/// CsFormField(
///   label: 'Backup window starts',
///   constraintText: 'Use 24-hour format.',
///   child: CsTimeInput(
///     value: start,
///     format: CsTimeInputFormat.hhMm,
///     placeholder: 'hh:mm',
///     onChange: (v) => setState(() => start = v),
///   ),
/// )
/// ```
///
/// With [use24Hour] false hours run from 01 to 12; like Cloudscape there is
/// no AM/PM part, so say which half of the day you mean in the label.
class CsTimeInput extends StatelessWidget {
  const CsTimeInput({
    super.key,
    required this.value,
    this.onChange,
    this.onBlur,
    this.onFocus,
    this.onSubmit,
    this.format = CsTimeInputFormat.hhMmSs,
    this.use24Hour = true,
    this.placeholder,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warning = false,
    this.autoFocus = false,
    this.autoComplete = true,
    this.ariaLabel,
    this.focusNode,
  });

  /// The time as typed: `hh:mm:ss` (or the parts of [format]), partial
  /// while typing, or empty.
  final String value;

  /// Called with the text on every edit.
  final ValueChanged<String>? onChange;
  final VoidCallback? onBlur;
  final VoidCallback? onFocus;

  /// Called with the completed time when the user presses Enter.
  final ValueChanged<String>? onSubmit;
  final CsTimeInputFormat format;

  /// 00-23 hours. False allows 01-12.
  final bool use24Hour;

  /// Shown while empty, such as `hh:mm:ss`.
  final String? placeholder;
  final bool disabled;
  final bool readOnly;
  final bool invalid;
  final bool warning;
  final bool autoFocus;

  /// Platform autofill and suggestions.
  final bool autoComplete;

  /// Accessible name when there is no visible label.
  final String? ariaLabel;
  final FocusNode? focusNode;

  CsMaskFormat get _mask => csTimeMask(parts: format.parts, use24Hour: use24Hour);

  @override
  Widget build(BuildContext context) {
    final mask = _mask;
    final display = mask.getValidValue(value);
    String? complete(String text) {
      if (text.isEmpty) return null;
      final completed = mask.autoComplete(text);
      return completed == text ? null : completed;
    }

    // CsFieldBox fills a bounded height (inside Center or Align); give it
    // unbounded height so the field keeps its own.
    return UnconstrainedBox(
      constrainedAxis: Axis.horizontal,
      child: CsInput(
        value: display,
        onChange: readOnly
            ? null
            : (text) {
                if (text != display) onChange?.call(text);
              },
        onFocus: onFocus,
        onBlur: () {
          final completed = complete(display);
          if (completed != null && !readOnly) onChange?.call(completed);
          onBlur?.call();
        },
        onSubmit: (text) {
          final completed = complete(text);
          if (completed != null && !readOnly) onChange?.call(completed);
          onSubmit?.call(completed ?? text);
        },
        placeholder: placeholder,
        disabled: disabled,
        readOnly: readOnly,
        invalid: invalid,
        warning: warning,
        autoFocus: autoFocus,
        autoComplete: autoComplete,
        spellcheck: false,
        keyboardType: TextInputType.datetime,
        inputFormatters: [CsMaskInputFormatter(mask)],
        ariaLabel: ariaLabel,
        focusNode: focusNode,
      ),
    );
  }
}
