import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../system/cs_editable.dart';
import '../system/cs_field_box.dart';
import '../system/cs_strings.dart';
import '../system/cs_text_field_state.dart';
import '../theme/theme.dart';

/// Cloudscape's `Textarea`: a multi-line text field for free-form text
/// (a description, a policy note, a list of tags one per line).
///
/// It is controlled: pass [value] and update it in [onChange].
///
/// ```dart
/// CsTextarea(
///   value: description,
///   placeholder: 'Describe what this bucket stores',
///   rows: 3,
///   maxRows: 8,
///   onChange: (v) => setState(() => description = v),
/// )
/// ```
///
/// It shows [rows] lines (3 by default). With [maxRows] it grows with its
/// content up to that many lines and then scrolls; without it, it keeps the
/// height of [rows] and scrolls, like Cloudscape. Wrap it in a `CsFormField`
/// for a label, error text and a character count (`characterCountText`).
class CsTextarea extends StatefulWidget {
  const CsTextarea({
    super.key,
    required this.value,
    this.onChange,
    this.onFocus,
    this.onBlur,
    this.onKeyEvent,
    this.placeholder,
    this.rows = 3,
    this.maxRows,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warning = false,
    this.autoFocus = false,
    this.autoComplete = true,
    this.spellcheck = true,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
    this.ariaLabel,
    this.ariaRequired = false,
    this.focusNode,
    this.mono = false,
  }) : assert(rows >= 1, 'rows must be at least 1'),
       assert(maxRows == null || maxRows >= rows, 'maxRows must be at least rows');

  /// The text in the field.
  final String value;

  /// Called with the new text on every edit.
  final ValueChanged<String>? onChange;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;

  /// Key events while the field has focus, before the text field handles
  /// them (Cloudscape `onKeyDown`); for example Cmd+Enter to submit. Return
  /// [KeyEventResult.handled] to stop the key.
  final FocusOnKeyEventCallback? onKeyEvent;

  /// Hint shown while the field is empty. It may span several lines.
  final String? placeholder;

  /// Number of lines the field shows (Cloudscape `rows`).
  final int rows;

  /// Grow with the content up to this many lines, then scroll. Null keeps
  /// the height at [rows].
  final int? maxRows;
  final bool disabled;

  /// Shows the value without letting the user change it. Still focusable
  /// and selectable.
  final bool readOnly;

  /// Red border with a thick start edge. Set it with the form field's
  /// `errorText`.
  final bool invalid;

  /// Yellow border with a thick start edge. Ignored when [invalid].
  final bool warning;
  final bool autoFocus;

  /// Platform suggestions (Cloudscape `autoComplete`).
  final bool autoComplete;

  /// Spell checking and autocorrect.
  final bool spellcheck;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  /// Accessible name when there is no visible label.
  final String? ariaLabel;

  /// Announces the field as required.
  final bool ariaRequired;
  final FocusNode? focusNode;

  /// Monospace text, for code, JSON or keys.
  final bool mono;

  @override
  State<CsTextarea> createState() => _CsTextareaState();
}

class _CsTextareaState extends State<CsTextarea> with CsTextFieldState<CsTextarea> {
  @override
  String get value => widget.value;

  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void onFocusChange(bool hasFocus) {
    if (hasFocus) {
      widget.onFocus?.call();
    } else {
      widget.onBlur?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final status = widget.invalid
        ? CsFieldStatus.invalid
        : widget.warning
        ? CsFieldStatus.warning
        : CsFieldStatus.none;
    Widget field = Semantics(
      textField: true,
      multiline: true,
      enabled: !widget.disabled,
      readOnly: widget.readOnly,
      hint: widget.ariaRequired ? context.csStrings.required : null,
      child: CsFieldBox(
        focused: focused,
        status: status,
        disabled: widget.disabled,
        readOnly: widget.readOnly,
        multiline: true,
        child: DefaultTextStyle.merge(
          style: cs.body,
          child: CsEditable(
            controller: controller,
            focusNode: focusNode,
            placeholder: widget.placeholder,
            enabled: !widget.disabled,
            readOnly: widget.readOnly,
            autofocus: widget.autoFocus,
            autocorrect: widget.spellcheck,
            enableSuggestions: widget.autoComplete,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: widget.textCapitalization,
            inputFormatters: widget.inputFormatters,
            minLines: widget.rows,
            maxLines: widget.maxRows ?? widget.rows,
            mono: widget.mono,
            color: widget.disabled ? CsColor.textInputDisabled : CsColor.textBodyDefault,
            semanticLabel: widget.ariaLabel,
            onChanged: widget.onChange,
          ),
        ),
      ),
    );
    if (widget.onKeyEvent != null) {
      field = Focus(canRequestFocus: false, skipTraversal: true, onKeyEvent: widget.onKeyEvent, child: field);
    }
    return field;
  }
}
