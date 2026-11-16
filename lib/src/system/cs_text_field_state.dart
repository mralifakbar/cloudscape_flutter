import 'package:flutter/widgets.dart';

/// Shared state for controlled text controls (`CsInput`, `CsTextarea`,
/// `CsAutosuggest`, date and time inputs): owns a [TextEditingController]
/// kept in sync with the widget's `value`, and a [FocusNode] whose focus is
/// mirrored in [focused].
///
/// Typing calls the widget's change callback; the controller only takes a
/// new value from the widget when it differs from what is already typed, so
/// the caret stays where the user put it.
///
/// ```dart
/// class _MyFieldState extends State<MyField> with CsTextFieldState<MyField> {
///   @override
///   String get value => widget.value;
///   @override
///   FocusNode? get externalFocusNode => widget.focusNode;
///   ...
/// }
/// ```
mixin CsTextFieldState<T extends StatefulWidget> on State<T> {
  late final TextEditingController controller;
  FocusNode? _ownFocusNode;

  /// Whether the field has focus.
  bool focused = false;

  /// The controlled value from the widget.
  String get value;

  /// A focus node passed by the caller, if any.
  FocusNode? get externalFocusNode => null;

  FocusNode get focusNode => externalFocusNode ?? (_ownFocusNode ??= FocusNode());

  /// Called when focus enters or leaves the field.
  void onFocusChange(bool hasFocus) {}

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: value);
    focusNode.addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncValue();
  }

  /// Writes [value] into the controller when it changed from outside.
  void syncValue() {
    if (controller.text != value) {
      final atEnd = controller.selection.baseOffset >= controller.text.length || !controller.selection.isValid;
      controller.value = TextEditingValue(
        text: value,
        selection: atEnd
            ? TextSelection.collapsed(offset: value.length)
            : TextSelection.collapsed(offset: controller.selection.baseOffset.clamp(0, value.length)),
      );
    }
  }

  void _handleFocus() {
    if (!mounted) return;
    final has = focusNode.hasFocus;
    if (has != focused) {
      setState(() => focused = has);
      onFocusChange(has);
    }
  }

  @override
  void dispose() {
    focusNode.removeListener(_handleFocus);
    _ownFocusNode?.dispose();
    controller.dispose();
    super.dispose();
  }
}
