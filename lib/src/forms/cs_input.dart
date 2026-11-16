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
    this.prefix,
    this.suffix,
    this.inlineLabelText,
    this.ariaRequired = false,
    this.onKeyEvent,
    this.mono = false,
  });

  /// The text in the field.
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

  /// Fixed content before the editable value (a protocol `https://`, a
  /// currency), separated from it by a divider. Ignored for search inputs.
  final Widget? prefix;

  /// Fixed content after the editable value (a unit `GiB`, a domain),
  /// separated from it by a divider. Ignored for search inputs.
  final Widget? suffix;

  /// A small label drawn on the field's top border, to save vertical space
  /// when there is no surrounding `CsFormField` label.
  final String? inlineLabelText;

  /// Announces the field as required.
  final bool ariaRequired;

  /// Key events while the field has focus, before the text field handles
  /// them (Cloudscape `onKeyDown`). Return [KeyEventResult.handled] to stop
  /// the key.
  final FocusOnKeyEventCallback? onKeyEvent;

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
            ? CsIcon(CsIcons.search, variant: widget.disabled ? CsIconVariant.disabled : CsIconVariant.subtle)
            : null);
    Widget? trailing = widget.trailing;
    if (search && widget.value.isNotEmpty && !widget.disabled && !widget.readOnly) {
      trailing = CsButton(
        icon: CsIcons.close,
        variant: CsButtonVariant.inlineIcon,
        semanticLabel: widget.clearAriaLabel ?? context.csStrings.clear,
        onPress: _clear,
      );
      trailing = Padding(
        padding: const EdgeInsetsDirectional.only(end: CsSpace.xs),
        child: trailing,
      );
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

    final adorned = !search && (widget.prefix != null || widget.suffix != null);
    Widget content = DefaultTextStyle.merge(style: cs.body, child: editable);
    Widget? leadingSlot = leading;
    Widget? trailingSlot = trailing;
    EdgeInsetsGeometry? padding;
    if (adorned) {
      final c = cs.colors;
      final startWidth = status == CsFieldStatus.none ? CsBorderWidth.field : CsBorderWidth.fieldStatusInlineStart;
      final startPad = CsSpace.fieldHorizontal - (startWidth - CsBorderWidth.field);
      final vertical = cs.space.fieldVertical;
      final adornmentStyle = cs.text(
        CsTypeScale.bodyM,
        color: widget.disabled
            ? CsColor.textInputDisabled
            : widget.invalid
            ? CsColor.textStatusError
            : widget.warning
            ? CsColor.textStatusWarning
            : CsColor.textBodyDefault,
      );
      Widget adornment(Widget child, {required bool start}) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: start ? startPad : CsSpace.fieldHorizontal,
            end: CsSpace.fieldHorizontal,
            top: vertical,
            bottom: vertical,
          ),
          child: ExcludeSemantics(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              child: DefaultTextStyle(
                style: adornmentStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: child,
              ),
            ),
          ),
        ),
      );
      final divider = SizedBox(
        width: CsBorderWidth.field,
        child: ColoredBox(color: c.borderDividerDefault),
      );
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.prefix != null) ...[adornment(widget.prefix!, start: true), divider],
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: widget.prefix != null ? CsSpace.fieldHorizontal : startPad,
                  end: CsSpace.fieldHorizontal,
                  top: vertical,
                  bottom: vertical,
                ),
                child: Align(alignment: AlignmentDirectional.centerStart, child: content),
              ),
            ),
            if (widget.suffix != null) ...[divider, adornment(widget.suffix!, start: false)],
          ],
        ),
      );
      padding = EdgeInsets.zero;
      leadingSlot = null;
      trailingSlot = null;
    }

    Widget field = Semantics(
      textField: true,
      enabled: !widget.disabled,
      readOnly: widget.readOnly,
      hint: widget.ariaRequired ? context.csStrings.required : null,
      label: widget.inlineLabelText,
      child: CsFieldBox(
        focused: focused,
        status: status,
        disabled: widget.disabled,
        readOnly: widget.readOnly,
        leading: leadingSlot,
        trailing: trailingSlot,
        padding: padding,
        child: content,
      ),
    );
    if (widget.onKeyEvent != null) {
      field = Focus(canRequestFocus: false, skipTraversal: true, onKeyEvent: widget.onKeyEvent, child: field);
    }
    if (widget.inlineLabelText != null) {
      field = _InlineLabel(text: widget.inlineLabelText!, disabled: widget.disabled, child: field);
    }
    return field;
  }
}

/// Cloudscape's inline label: body-s bold text sitting on the field's top
/// border, its background fading from the page to the field color so the
/// border line stops behind it.
class _InlineLabel extends StatelessWidget {
  const _InlineLabel({required this.text, required this.disabled, required this.child});

  final String text;
  final bool disabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final style = cs
        .text(CsTypeScale.bodyS, weight: CsTypography.bold, color: CsColor.textFormLabel)
        .copyWith(height: 14 / CsFontTokens.fontSizeBodyS);
    // forms/mixins.scss `inline-label`: 14px line + 2px bottom padding, the
    // field moves up by space-scaled-xs so the label straddles its border.
    const labelHeight = 16.0;
    final overlap = cs.space.scaledXs;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: labelHeight - overlap + cs.space.scaledXs),
          child: child,
        ),
        PositionedDirectional(
          top: cs.space.scaledXs,
          start: CsBorderWidth.field + CsSpace.fieldHorizontal - cs.space.scaledXxs,
          end: CsSpace.fieldHorizontal,
          child: ExcludeSemantics(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: EdgeInsets.only(left: cs.space.scaledXxs, right: cs.space.scaledXxs, bottom: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.backgroundLayoutMain, disabled ? c.backgroundInputDisabled : c.backgroundInputDefault],
                  ),
                ),
                child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
