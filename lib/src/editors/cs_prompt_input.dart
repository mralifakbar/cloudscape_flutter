import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icon_data.dart';
import '../system/cs_editable.dart';
import '../system/cs_field_box.dart';
import '../system/cs_text_field_state.dart';
import '../theme/theme.dart';

/// Copy for [CsPromptInput] (Cloudscape `PromptInputProps.I18nStrings`).
@immutable
class CsPromptInputI18nStrings {
  const CsPromptInputI18nStrings({this.actionButtonAriaLabel = 'Submit prompt'});

  /// Accessible name of the action (send) button.
  final String actionButtonAriaLabel;
}

/// Cloudscape's `PromptInput`: the multi-line field of a chat or generative
/// AI experience, with a send button, optional actions under the text and
/// content above it (attached files).
///
/// It is controlled: pass [value] and update it in [onChange]. Enter calls
/// [onAction] with the text; Shift+Enter starts a new line. The field grows
/// from [minRows] to [maxRows] lines, then scrolls.
///
/// ```dart
/// CsPromptInput(
///   value: prompt,
///   placeholder: 'Ask a question about your instances',
///   actionButtonIcon: CsIcons.send,
///   onChange: (v) => setState(() => prompt = v),
///   onAction: (v) => send(v),
/// )
/// ```
///
/// Cloudscape's token mode (`tokens`, `menus` with `@` and `/` triggers)
/// is not part of this port; build mentions on top with [secondaryContent]
/// and your own menu.
class CsPromptInput extends StatefulWidget {
  const CsPromptInput({
    super.key,
    required this.value,
    this.onChange,
    this.onAction,
    this.actionButtonIcon,
    this.actionButtonIconWidget,
    this.actionButtonAriaLabel,
    this.disableActionButton = false,
    this.customPrimaryAction,
    this.minRows = 1,
    this.maxRows = 3,
    this.secondaryActions,
    this.secondaryContent,
    this.disableSecondaryActionsPaddings = false,
    this.disableSecondaryContentPaddings = false,
    this.placeholder,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warning = false,
    this.ariaLabel,
    this.autoFocus = false,
    this.spellcheck = true,
    this.autoComplete = true,
    this.onFocus,
    this.onBlur,
    this.focusNode,
    this.i18nStrings = const CsPromptInputI18nStrings(),
  });

  final String value;
  final ValueChanged<String>? onChange;

  /// Called with the text when the user presses Enter or the action button.
  /// Clear [value] here once the prompt is sent.
  final ValueChanged<String>? onAction;

  /// Icon of the action button (Cloudscape `actionButtonIconName`, usually
  /// `CsIcons.send`). No icon and no [customPrimaryAction] means no button.
  final CsIconData? actionButtonIcon;

  /// A custom icon in the action button (Cloudscape `actionButtonIconSvg`).
  final Widget? actionButtonIconWidget;

  /// Overrides [CsPromptInputI18nStrings.actionButtonAriaLabel].
  final String? actionButtonAriaLabel;

  /// Keeps the action button visible but disabled (empty prompt, or a
  /// response streaming).
  final bool disableActionButton;

  /// Replaces the action button (a stop button while streaming).
  final Widget? customPrimaryAction;

  /// Lines shown when empty.
  final int minRows;

  /// Lines before the field scrolls. -1 grows without limit; 0 or less
  /// means the default of 3.
  final int maxRows;

  /// Actions under the text (attach file, model picker). The action button
  /// moves to the end of this row.
  final Widget? secondaryActions;

  /// Content above the text (attached file tokens).
  final Widget? secondaryContent;
  final bool disableSecondaryActionsPaddings;
  final bool disableSecondaryContentPaddings;
  final String? placeholder;
  final bool disabled;
  final bool readOnly;

  /// Red border with a thick start edge.
  final bool invalid;

  /// Yellow border with a thick start edge. Ignored when [invalid].
  final bool warning;

  /// Accessible name when there is no visible label.
  final String? ariaLabel;
  final bool autoFocus;
  final bool spellcheck;
  final bool autoComplete;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;
  final FocusNode? focusNode;
  final CsPromptInputI18nStrings i18nStrings;

  @override
  State<CsPromptInput> createState() => _CsPromptInputState();
}

class _CsPromptInputState extends State<CsPromptInput> with CsTextFieldState<CsPromptInput> {
  bool _focusWithin = false;

  @override
  String get value => widget.value;

  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void onFocusChange(bool hasFocus) => hasFocus ? widget.onFocus?.call() : widget.onBlur?.call();

  bool get _actionEnabled =>
      !widget.disabled && !widget.readOnly && !widget.disableActionButton && widget.onAction != null;

  void _action() {
    if (widget.disabled || widget.readOnly) return;
    widget.onAction?.call(widget.value);
  }

  void _insertNewline() {
    final sel = controller.selection;
    final text = controller.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final next = text.replaceRange(start, end, '\n');
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + 1),
    );
    widget.onChange?.call(next);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.enter) return KeyEventResult.ignored;
    if (!focusNode.hasFocus || widget.disabled || widget.readOnly) return KeyEventResult.ignored;
    if (controller.value.composing.isValid && !controller.value.composing.isCollapsed) return KeyEventResult.ignored;
    if (HardwareKeyboard.instance.isShiftPressed) {
      _insertNewline();
    } else {
      _action();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final status = widget.invalid
        ? CsFieldStatus.invalid
        : widget.warning
        ? CsFieldStatus.warning
        : CsFieldStatus.none;
    // `$invalid-border-offset`: the thick start border eats into the padding.
    final startPad = status == CsFieldStatus.none
        ? CsSpace.fieldHorizontal
        : CsSpace.fieldHorizontal - (CsBorderWidth.fieldStatusInlineStart - CsBorderWidth.field);
    final minRows = widget.minRows < 1 ? 1 : widget.minRows;
    final maxRows = widget.maxRows == -1 ? null : (widget.maxRows <= 0 ? 3 : widget.maxRows);
    final hasAction =
        widget.actionButtonIcon != null || widget.actionButtonIconWidget != null || widget.customPrimaryAction != null;

    final textarea = Padding(
      padding: EdgeInsetsDirectional.only(
        start: startPad,
        end: CsSpace.fieldHorizontal,
        top: cs.space.fieldVertical,
        bottom: cs.space.fieldVertical,
      ),
      child: CsEditable(
        controller: controller,
        focusNode: focusNode,
        placeholder: widget.placeholder,
        enabled: !widget.disabled,
        readOnly: widget.readOnly,
        autofocus: widget.autoFocus,
        autocorrect: widget.spellcheck,
        enableSuggestions: widget.autoComplete,
        minLines: maxRows == null ? minRows : (minRows > maxRows ? maxRows : minRows),
        maxLines: maxRows,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.send,
        semanticLabel: widget.ariaLabel,
        color: widget.disabled ? CsColor.textInputDisabled : CsColor.textBodyDefault,
        onChanged: widget.onChange,
        onSubmitted: (_) => _action(),
      ),
    );

    final Widget? action = !hasAction
        ? null
        : Padding(
            padding: EdgeInsetsDirectional.only(
              start: CsSpace.fieldHorizontal / 2,
              end: CsSpace.fieldHorizontal / 2,
              bottom: cs.space.scaledXxxs,
            ),
            child:
                widget.customPrimaryAction ??
                CsButton(
                  variant: CsButtonVariant.icon,
                  icon: widget.actionButtonIcon,
                  iconWidget: widget.actionButtonIconWidget,
                  semanticLabel: widget.actionButtonAriaLabel ?? widget.i18nStrings.actionButtonAriaLabel,
                  disabled: !_actionEnabled,
                  onPress: _actionEnabled ? _action : null,
                ),
          );

    final children = <Widget>[
      if (widget.secondaryContent != null)
        Padding(
          padding: widget.disableSecondaryContentPaddings
              ? EdgeInsets.zero
              : EdgeInsetsDirectional.only(
                  start: startPad,
                  end: CsSpace.fieldHorizontal,
                  top: cs.space.scaledS,
                  bottom: cs.space.scaledS,
                ),
          child: widget.secondaryContent,
        ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: textarea),
          if (action != null && widget.secondaryActions == null) action,
        ],
      ),
      if (widget.secondaryActions != null)
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // `.buffer`: empty space in the action stripe focuses the text;
            // the secondary actions keep their own taps.
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: widget.disabled ? null : focusNode.requestFocus,
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Padding(
                    padding: widget.disableSecondaryActionsPaddings
                        ? EdgeInsets.zero
                        : EdgeInsetsDirectional.only(
                            start: startPad,
                            end: action != null ? 0 : cs.space.scaledXxs,
                            top: cs.space.scaledS,
                            bottom: cs.space.fieldVertical,
                          ),
                    child: widget.secondaryActions,
                  ),
                ),
              ),
            ),
            ?action,
          ],
        ),
    ];

    return Semantics(
      container: true,
      label: widget.ariaLabel,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        onFocusChange: (f) => setState(() => _focusWithin = f),
        child: CsFieldBox(
          focused: _focusWithin,
          status: status,
          disabled: widget.disabled,
          readOnly: widget.readOnly,
          multiline: true,
          minHeight: 0,
          padding: EdgeInsets.zero,
          child: DefaultTextStyle.merge(
            style: cs.body,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
