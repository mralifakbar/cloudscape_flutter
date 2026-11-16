import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../system/cs_editable.dart';
import '../system/cs_field_box.dart';
import '../system/cs_strings.dart';
import '../system/cs_text_field_state.dart';
import '../theme/theme.dart';

/// Input types (Cloudscape `type`). They pick the keyboard, obscure
/// passwords and add the search icon and clear button.
enum CsInputType { text, password, search, number, email, url }

/// Cloudscape's `Input`: a single-line text field.
///
/// It is controlled: pass [value] and update it in [onChange].
///
/// ```dart
/// CsInput(
///   value: name,
///   placeholder: 'my-bucket',
///   onChange: (v) => setState(() => name = v),
/// )
/// CsInput(
///   type: CsInputType.search,
///   value: query,
///   placeholder: 'Find instances',
///   onChange: (v) => setState(() => query = v),
/// )
/// ```
///
/// Put it in a `CsFormField` for a label, description and error text. The
/// field is 32px tall (28px compact); [invalid] and [warning] color the
/// border and thicken its start edge. A search input shows a search icon and,
/// once it has text, a clear button.
class CsInput extends StatefulWidget {
  const CsInput({
    super.key,
    required this.value,
    this.onChange,
    this.onSubmit,
    this.onFocus,
    this.onBlur,
    this.type = CsInputType.text,
    this.placeholder,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warning = false,
    this.autoFocus = false,
    this.autoComplete = true,
    this.spellcheck = true,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.ariaLabel,
    this.clearAriaLabel,
    this.focusNode,
    this.leading,
    this.trailing,
    this.mono = false,
  });

  final String value;

  /// Called with the new text on every edit (Cloudscape `onChange`).
  final ValueChanged<String>? onChange;

  /// Called when the user presses Enter or the keyboard's action key.
  final ValueChanged<String>? onSubmit;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;
  final CsInputType type;
  final String? placeholder;
  final bool disabled;
  final bool readOnly;

  /// Red border with a thick start edge. Set it together with the form
  /// field's `errorText`.
  final bool invalid;

  /// Yellow border with a thick start edge. Ignored when [invalid].
  final bool warning;
  final bool autoFocus;

  /// Platform autofill and suggestions (Cloudscape `autoComplete`).
  final bool autoComplete;

  /// Spell checking and autocorrect.
  final bool spellcheck;

  /// Overrides the keyboard chosen from [type] (Cloudscape `inputMode`).
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  /// Accessible name when there is no visible label (Cloudscape `ariaLabel`).
  final String? ariaLabel;

  /// Accessible name of the clear button of a search input.
  final String? clearAriaLabel;
  final FocusNode? focusNode;

  /// Replaces the start icon (search inputs show a search icon).
  final Widget? leading;

  /// Content after the text, inside the field.
  final Widget? trailing;

  /// Monospace text, for IDs and ARNs.
  final bool mono;

  @override
  State<CsInput> createState() => _CsInputState();
}

class _CsInputState extends State<CsInput> with CsTextFieldState<CsInput> {
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

  void _clear() {
    widget.onChange?.call('');
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final search = widget.type == CsInputType.search;
    final status = widget.invalid
        ? CsFieldStatus.invalid
        : widget.warning
        ? CsFieldStatus.warning
        : CsFieldStatus.none;
    final keyboard =
        widget.keyboardType ??
        switch (widget.type) {
          CsInputType.number => const TextInputType.numberWithOptions(decimal: true, signed: true),
          CsInputType.email => TextInputType.emailAddress,
          CsInputType.url => TextInputType.url,
          _ => TextInputType.text,
        };
    final color = widget.disabled
        ? CsColor.textInputDisabled
        : widget.invalid
        ? CsColor.textStatusError
        : CsColor.textBodyDefault;

    final leading =
        widget.leading ??
        (search
            ? CsIcon(
                CsIcons.search,
                variant: widget.disabled ? CsIconVariant.disabled : CsIconVariant.subtle,
              )
            : null);
    Widget? trailing = widget.trailing;
    if (search && widget.value.isNotEmpty && !widget.disabled && !widget.readOnly) {
      trailing = CsButton(
        icon: CsIcons.close,
        variant: CsButtonVariant.inlineIcon,
        semanticLabel: widget.clearAriaLabel ?? context.csStrings.clear,
        onPress: _clear,
      );
      trailing = Padding(padding: const EdgeInsetsDirectional.only(end: CsSpace.xs), child: trailing);
    }

    final editable = CsEditable(
      controller: controller,
      focusNode: focusNode,
      placeholder: widget.placeholder,
      enabled: !widget.disabled,
      readOnly: widget.readOnly,
      obscureText: widget.type == CsInputType.password,
      autofocus: widget.autoFocus,
      autocorrect: widget.spellcheck,
      enableSuggestions: widget.autoComplete,
      keyboardType: keyboard,
      textInputAction: widget.textInputAction ?? (search ? TextInputAction.search : null),
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autoComplete ? widget.autofillHints : null,
      mono: widget.mono,
      color: color,
      semanticLabel: widget.ariaLabel,
      onChanged: widget.onChange,
      onSubmitted: widget.onSubmit,
    );

    return Semantics(
      textField: true,
      enabled: !widget.disabled,
      readOnly: widget.readOnly,
      child: CsFieldBox(
        focused: focused,
        status: status,
        disabled: widget.disabled,
        readOnly: widget.readOnly,
        leading: leading,
        trailing: trailing,
        child: DefaultTextStyle.merge(style: cs.body, child: editable),
      ),
    );
  }
}
