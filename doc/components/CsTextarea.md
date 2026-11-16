# CsTextarea

A multi-line text field for free-form text such as a description, a note or a policy document.

Cloudscape reference: https://cloudscape.design/components/textarea/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFormField(
  label: 'Description',
  characterCountText: '${description.length}/200',
  child: CsTextarea(
    value: description,
    placeholder: 'Describe what this bucket stores',
    onChange: (v) => setState(() => description = v),
  ),
)
```

## When to use / when not to

- Use when the value can be longer than one line.
- Use `CsInput` for single-line values; it keeps forms compact and Enter submits.
- For code with syntax highlighting, use a code editor instead.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | The controlled text. |
| `onChange` | `ValueChanged<String>?` | `null` | Called on every edit. |
| `onFocus` / `onBlur` | `VoidCallback?` | `null` | |
| `onKeyEvent` | `FocusOnKeyEventCallback?` | `null` | Key events before the field handles them (Cloudscape `onKeyDown`), for example Cmd+Enter to submit. |
| `placeholder` | `String?` | `null` | May span several lines. |
| `rows` | `int` | `3` | Lines shown. |
| `maxRows` | `int?` | `null` | Grow with the content up to this many lines, then scroll. Null keeps the height at `rows`. |
| `disabled` / `readOnly` | `bool` | `false` | |
| `invalid` / `warning` | `bool` | `false` | Status border with an 8px start edge. |
| `autoFocus` | `bool` | `false` | |
| `autoComplete` | `bool` | `true` | Platform suggestions. |
| `spellcheck` | `bool` | `true` | Spell checking and autocorrect. |
| `textCapitalization` | `TextCapitalization` | `sentences` | On-screen keyboard capitalization. |
| `inputFormatters` | `List<TextInputFormatter>?` | `null` | For example `LengthLimitingTextInputFormatter(200)`. |
| `mono` | `bool` | `false` | Monospace text for JSON or keys. |
| `ariaLabel` | `String?` | `null` | Accessible name without a visible label. |
| `ariaRequired` | `bool` | `false` | Adds a "Required" hint. |
| `focusNode` | `FocusNode?` | `null` | |

## Examples

### Character count with a limit

```dart
CsFormField(
  label: 'Description',
  constraintText: 'Up to 200 characters.',
  characterCountText: '${description.length}/200',
  errorText: description.length > 200 ? 'The description is too long.' : null,
  child: CsTextarea(
    value: description,
    invalid: description.length > 200,
    onChange: (v) => setState(() => description = v),
  ),
)
```

### Grows with its content

```dart
CsTextarea(
  value: notes,
  rows: 2,
  maxRows: 8,
  ariaLabel: 'Notes',
  onChange: (v) => setState(() => notes = v),
)
```

### Submit with Cmd+Enter

```dart
CsTextarea(
  value: message,
  onChange: (v) => setState(() => message = v),
  onKeyEvent: (node, event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        HardwareKeyboard.instance.isMetaPressed) {
      send();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  },
)
```

## Accessibility

Exposed as a multi-line text field with its label, enabled and read-only state. Enter inserts a line break; Tab leaves the field. Pair the character count with `CsFormField` so it is read with the field.

## Motion

None. Growth with `maxRows` follows the text instantly.

## Mobile

The on-screen keyboard shows a return key. With `maxRows` the field grows instead of scrolling inside a small box, which is easier with a finger; at 2x text each row grows with the text.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value` / `onChange` | `value` / `onChange` |
| `rows` | `rows` (+ `maxRows` for growth) |
| `resize` | not supported: the height follows `rows` and `maxRows` |
| `placeholder` | `placeholder` |
| `disabled` / `readOnly` | `disabled` / `readOnly` |
| `invalid` / `warning` | `invalid` / `warning` |
| `autoFocus`, `autoComplete`, `spellcheck`, `disableBrowserAutocorrect`, `disableBrowserSpellcheck` | `autoFocus`, `autoComplete`, `spellcheck` |
| `onKeyDown` / `onKeyUp` | `onKeyEvent` |
| `onFocus` / `onBlur` | `onFocus` / `onBlur` |
| `ariaLabel`, `ariaRequired` | `ariaLabel`, `ariaRequired` |
| `name`, `controlId`, `ariaDescribedby`, `ariaLabelledby`, `nativeTextareaAttributes`, `style` | web only |
