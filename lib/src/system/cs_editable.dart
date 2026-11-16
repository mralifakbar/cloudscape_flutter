import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// The bare text-editing core shared by every Cs field (input, textarea,
/// select search, combobox, tag input, date input, command palette).
///
/// It draws no box, border or label: just Cs-styled text, a Cs caret and
/// selection color, the placeholder, and platform selection handles and
/// context menu. Components put it inside their own field chrome.
///
/// ```dart
/// CsEditable(
///   controller: controller,
///   focusNode: focusNode,
///   placeholder: 'my-worker',
///   onChanged: (v) => setState(() => name = v),
/// )
/// ```
class CsEditable extends StatelessWidget {
  const CsEditable({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.size = CsTypeScale.bodyM,
    this.mono = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onTapOutside,
    this.onEditingComplete,
    this.semanticLabel,
    this.color = CsColor.textBodyDefault,
    this.scrollPadding = const EdgeInsets.all(20),
    this.showCursor,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final CsTypeScale size;

  /// Monospace text (API tokens, IDs, code).
  final bool mono;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? minLines;

  /// 1 for single line, null to grow without limit.
  final int? maxLines;
  final TextAlign textAlign;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final VoidCallback? onEditingComplete;

  /// Accessible name when there is no visible label wired up by the parent.
  final String? semanticLabel;
  final CsColor color;

  /// Space kept between the field and the screen edge (or the keyboard) when
  /// the field scrolls into view on focus.
  final EdgeInsets scrollPadding;

  /// Null shows the cursor while focused; false hides it (hidden-field
  /// patterns such as one-time-code inputs).
  final bool? showCursor;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final style = mono
        ? cs.code(scale: size, color: color)
        : cs.text(size, color: color);
    final caret = cs.colors.textBodyDefault;
    final multiline = maxLines != 1;

    Widget field = TextSelectionTheme(
      data: TextSelectionThemeData(
        cursorColor: caret,
        selectionColor: cs.colors.borderItemFocused.withValues(alpha: 0.24),
        selectionHandleColor: cs.colors.borderItemFocused,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        readOnly: readOnly,
        obscureText: obscureText,
        autofocus: autofocus,
        autocorrect: autocorrect && !obscureText,
        enableSuggestions: enableSuggestions && !obscureText,
        keyboardType: keyboardType ?? (multiline ? TextInputType.multiline : null),
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        buildCounter: _noCounter,
        minLines: minLines,
        maxLines: obscureText ? 1 : maxLines,
        textAlign: textAlign,
        textAlignVertical: multiline ? TextAlignVertical.top : TextAlignVertical.center,
        autofillHints: autofillHints,
        style: style,
        cursorColor: caret,
        showCursor: showCursor,
        cursorWidth: 1.5,
        cursorRadius: const Radius.circular(1),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
        onTapOutside: onTapOutside,
        onEditingComplete: onEditingComplete,
        scrollPadding: scrollPadding,
        decoration: InputDecoration.collapsed(
          hintText: placeholder,
          hintStyle: style.copyWith(
            color: enabled ? cs.colors.textInputPlaceholder : cs.colors.textInputPlaceholderDisabled,
            fontStyle: FontStyle.italic,
          ),
        ).copyWith(isDense: true, contentPadding: EdgeInsets.zero),
      ),
    );
    if (semanticLabel != null) {
      field = Semantics(label: semanticLabel, textField: true, child: field);
    }
    // TextField needs a Material ancestor for ink and selection toolbars;
    // a transparent one keeps Cs surfaces visible.
    return Material(type: MaterialType.transparency, child: field);
  }

  static Widget? _noCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) => null;
}
