import 'package:flutter/widgets.dart';

import '../forms/cs_input.dart';
import '../system/cs_strings.dart';
import 'cs_calendar.dart';
import 'cs_dates_internal.dart';

/// How a [CsDateInput] shows its date (Cloudscape `format`).
enum CsDateFormat {
  /// `2024-01-30` (or `2024-01`).
  iso,

  /// `2024/01/30` (or `2024/01`). The default.
  slashed,

  /// `January 30, 2024` (or `January 2024`) while the field is not being
  /// edited; [CsDateInputFormat] while it is.
  longLocalized,
}

/// The format of a date while it is typed (Cloudscape `inputFormat`).
enum CsDateInputFormat {
  /// `2024-01-30`.
  iso,

  /// `2024/01/30`. The default.
  slashed,
}

/// Cloudscape's `DateInput`: a masked text field for a date.
///
/// Digits are typed into `YYYY/MM/DD` (or `YYYY-MM-DD`) and the separators
/// are added for you. Out-of-range parts are corrected as you type (a 13th
/// month becomes 12, the 31st of April the 30th), and on blur or Enter an
/// incomplete date is completed (`2024/1` becomes `2024/01/01`).
///
/// It is controlled: [value] is ISO (`YYYY-MM-DD`, `YYYY-MM` with month
/// [granularity]) and [onChange] receives the ISO text as it is typed,
/// including partial dates such as `2024-0`. Validate the value yourself and
/// show errors with `CsFormField.errorText` and [invalid].
///
/// ```dart
/// CsFormField(
///   label: 'Snapshot date',
///   constraintText: 'Use YYYY/MM/DD format.',
///   child: CsDateInput(
///     value: snapshotDate,
///     placeholder: 'YYYY/MM/DD',
///     onChange: (v) => setState(() => snapshotDate = v),
///   ),
/// )
/// ```
///
/// For a field with a calendar dropdown use `CsDatePicker`.
class CsDateInput extends StatefulWidget {
  const CsDateInput({
    super.key,
    required this.value,
    this.onChange,
    this.onBlur,
    this.onFocus,
    this.onSubmit,
    this.granularity = CsDateGranularity.day,
    this.format = CsDateFormat.slashed,
    this.inputFormat = CsDateInputFormat.slashed,
    this.placeholder,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warning = false,
    this.autoFocus = false,
    this.ariaLabel,
    this.focusNode,
    this.trailing,
  });

  /// ISO date: `YYYY-MM-DD`, `YYYY-MM` for months, partial while typing, or
  /// empty.
  final String value;

  /// Called with the ISO text on every edit.
  final ValueChanged<String>? onChange;
  final VoidCallback? onBlur;
  final VoidCallback? onFocus;

  /// Called with the completed ISO value when the user presses Enter.
  final ValueChanged<String>? onSubmit;
  final CsDateGranularity granularity;

  /// How the date is shown. Default [CsDateFormat.slashed].
  final CsDateFormat format;

  /// How the date is typed when [format] is [CsDateFormat.longLocalized].
  final CsDateInputFormat inputFormat;

  /// Shown while empty, such as `YYYY/MM/DD`.
  final String? placeholder;
  final bool disabled;

  /// Focusable and selectable, but not editable.
  final bool readOnly;

  /// Red border with a thick start edge.
  final bool invalid;

  /// Yellow border with a thick start edge. Ignored when [invalid].
  final bool warning;
  final bool autoFocus;

  /// Accessible name when there is no visible label.
  final String? ariaLabel;
  final FocusNode? focusNode;

  /// Content at the end of the field.
  final Widget? trailing;

  @override
  State<CsDateInput> createState() => _CsDateInputState();
}

class _CsDateInputState extends State<CsDateInput> {
  FocusNode? _own;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode(debugLabel: 'CsDateInput'));

  bool get _monthOnly => widget.granularity == CsDateGranularity.month;
  bool get _iso =>
      widget.format == CsDateFormat.iso ||
      (widget.format == CsDateFormat.longLocalized && widget.inputFormat == CsDateInputFormat.iso);
  bool get _usesLong => widget.format == CsDateFormat.longLocalized && !(_focused && !widget.readOnly);

  CsMaskFormat get _mask => csDateMask(iso: _iso, monthOnly: _monthOnly);

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(CsDateInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _own)?.removeListener(_onFocus);
      _node.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _own?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_node.hasFocus != _focused) setState(() => _focused = _node.hasFocus);
  }

  static String _toIso(String display) => display.replaceAll('/', '-');

  String _display(CsStrings strings) {
    if (widget.value.isEmpty) return '';
    final iso = _toIso(widget.value);
    final normalized = csNormalizeIso(iso, monthOnly: _monthOnly);
    if (_usesLong && normalized.isNotEmpty) {
      final d = csParseIso(normalized);
      if (d != null) {
        final labels = CsDateLabels(strings);
        if (_monthOnly || normalized.length == 7) return labels.monthYear(d);
        if (normalized.length == 4) return '${d.year}';
        return labels.date(d);
      }
      return widget.value;
    }
    final text = _iso ? iso : iso.replaceAll('-', '/');
    final mask = _mask;
    return mask.getValidValue(mask.correctMinMaxValues(text));
  }

  String? _complete(String display) {
    if (display.isEmpty || _usesLong) return null;
    final completed = _mask.autoComplete(display);
    return _toIso(completed);
  }

  void _onBlur(String display) {
    final completed = _complete(display);
    if (completed != null && completed != _toIso(display) && !widget.readOnly) widget.onChange?.call(completed);
    widget.onBlur?.call();
  }

  @override
  Widget build(BuildContext context) {
    final display = _display(context.csStrings);
    // CsFieldBox fills a bounded height (inside Center or Align); give it
    // unbounded height so the field keeps its own.
    return UnconstrainedBox(
      constrainedAxis: Axis.horizontal,
      child: CsInput(
        value: display,
        onChange: widget.readOnly || _usesLong
            ? null
            : (text) {
                final iso = _toIso(text);
                if (iso != _toIso(widget.value)) widget.onChange?.call(iso);
              },
        onFocus: widget.onFocus,
        onBlur: () => _onBlur(display),
        onSubmit: (text) {
          final completed = _complete(text) ?? _toIso(text);
          if (completed != _toIso(text) && !widget.readOnly) widget.onChange?.call(completed);
          widget.onSubmit?.call(completed);
        },
        placeholder: widget.placeholder,
        disabled: widget.disabled,
        readOnly: widget.readOnly,
        invalid: widget.invalid,
        warning: widget.warning,
        autoFocus: widget.autoFocus,
        autoComplete: false,
        spellcheck: false,
        keyboardType: TextInputType.datetime,
        inputFormatters: _usesLong ? null : [CsMaskInputFormatter(_mask, autofix: true)],
        ariaLabel: widget.ariaLabel,
        focusNode: _node,
        trailing: widget.trailing,
      ),
    );
  }
}
