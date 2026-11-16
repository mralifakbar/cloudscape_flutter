# CsTextFieldState

A `State` mixin for controlled text fields: it owns a `TextEditingController` kept in sync with the widget's `value` and a `FocusNode` whose focus is mirrored in `focused`.

Cloudscape reference: https://cloudscape.design/components/input/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
class ArnField extends StatefulWidget {
  const ArnField({super.key, required this.value, required this.onChange, this.focusNode});

  final String value;
  final ValueChanged<String> onChange;
  final FocusNode? focusNode;

  @override
  State<ArnField> createState() => _ArnFieldState();
}

class _ArnFieldState extends State<ArnField> with CsTextFieldState<ArnField> {
  @override
  String get value => widget.value;

  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  Widget build(BuildContext context) {
    return CsFieldBox(
      focused: focused,
      child: CsEditable(controller: controller, focusNode: focusNode, mono: true, onChanged: widget.onChange),
    );
  }
}
```

## When to use / when not to

- Use when building a custom controlled field from `CsFieldBox` and `CsEditable`, so it behaves like `CsInput`: the parent owns the value, and the caret stays where the user put it.
- Not needed for uncontrolled fields that own their own `TextEditingController`.

## Parameters

| Member | Type | Description |
| --- | --- | --- |
| `value` | `String` (getter, required) | Return the widget's controlled value. |
| `externalFocusNode` | `FocusNode?` (getter) | Return the caller's focus node, if the widget takes one. Defaults to null, and the mixin creates and disposes its own. |
| `onFocusChange(bool hasFocus)` | method | Override to fire `onFocus` / `onBlur` callbacks. |
| `controller` | `TextEditingController` | Created in `initState` with `value`, disposed for you. |
| `focusNode` | `FocusNode` | The external node or the mixin's own. |
| `focused` | `bool` | Whether the field has focus; the mixin calls `setState` when it changes. |
| `syncValue()` | method | Writes `value` into the controller when it changed from outside. Called from `didUpdateWidget`. |

## Examples

### Focus callbacks

```dart
class _NoteFieldState extends State<NoteField> with CsTextFieldState<NoteField> {
  @override
  String get value => widget.value;

  @override
  void onFocusChange(bool hasFocus) => hasFocus ? widget.onFocus() : widget.onBlur();

  @override
  Widget build(BuildContext context) => CsFieldBox(
    focused: focused,
    multiline: true,
    child: CsEditable(controller: controller, focusNode: focusNode, maxLines: null, onChanged: widget.onChange),
  );
}
```

## Accessibility

The mixin adds nothing to semantics; the field you build does (see `CsEditable`).

## Motion

None.

## Mobile

Because the controller only takes a new value when it differs from what is typed, an IME composing region and the caret position survive rebuilds from the parent.

## Cloudscape React mapping

| Cloudscape pattern | Flutter |
| --- | --- |
| controlled `value` + `onChange` on Input, Textarea, Autosuggest | `CsTextFieldState` |
| `onFocus` / `onBlur` | `onFocusChange` |
