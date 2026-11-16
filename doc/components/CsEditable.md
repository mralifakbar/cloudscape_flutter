# CsEditable

The bare text-editing core shared by every Cloudscape field: styled text, caret, selection color and placeholder, with no box or label.

Cloudscape reference: https://cloudscape.design/components/input/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsEditable(
  controller: controller,
  focusNode: focusNode,
  placeholder: 'example-bucket',
  onChanged: (v) => setState(() => name = v),
)
```

## When to use / when not to

- Use inside `CsFieldBox` (or another custom chrome) to build a field that `CsInput` does not cover: a token input, a command palette search, a one-time-code field.
- Use `CsInput` or `CsTextarea` for ordinary text entry.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `controller` | `TextEditingController?` | `null` | |
| `focusNode` | `FocusNode?` | `null` | |
| `placeholder` | `String?` | `null` | Italic `color-text-input-placeholder` hint. |
| `size` | `CsTypeScale` | `bodyM` | Text size. |
| `mono` | `bool` | `false` | Monospace text. |
| `enabled` / `readOnly` | `bool` | `true` / `false` | |
| `obscureText` | `bool` | `false` | Password entry; forces one line and turns off suggestions. |
| `autofocus`, `autocorrect`, `enableSuggestions` | `bool` | `false`, `true`, `true` | |
| `keyboardType` | `TextInputType?` | multiline when `maxLines != 1` | |
| `textInputAction`, `textCapitalization`, `inputFormatters`, `autofillHints` | | | Passed to the text field. |
| `maxLength` | `int?` | `null` | Enforced without Material's counter. |
| `minLines` / `maxLines` | `int?` | `null` / `1` | `maxLines: null` grows without limit. |
| `textAlign` | `TextAlign` | `start` | |
| `onChanged`, `onSubmitted`, `onTap`, `onTapOutside`, `onEditingComplete` | callbacks | `null` | |
| `semanticLabel` | `String?` | `null` | Accessible name when the parent does not provide one. |
| `color` | `CsColor` | `textBodyDefault` | Text color token. |
| `scrollPadding` | `EdgeInsets` | `EdgeInsets.all(20)` | Space kept around the field when it scrolls into view. |
| `showCursor` | `bool?` | `null` | `false` hides the caret (hidden-field patterns). |

## Examples

### A borderless search in a toolbar

```dart
Row(
  children: [
    const CsIcon(CsIcons.search, variant: CsIconVariant.subtle),
    const SizedBox(width: CsSpace.xs),
    Expanded(
      child: CsEditable(
        controller: controller,
        placeholder: 'Search resources',
        textInputAction: TextInputAction.search,
        onSubmitted: (q) => runSearch(q),
      ),
    ),
  ],
)
```

## Accessibility

It is a platform text field: screen readers announce it as an editable text field with its value; pass `semanticLabel` when no surrounding label names it. Selection handles and the context menu are the platform's.

## Motion

None beyond the platform caret blink.

## Mobile

On-screen keyboards, selection handles and the paste menu come from the platform. Text scales with the system setting; give the field a minimum height (as `CsFieldBox` does), never a fixed one.

## Cloudscape React mapping

| Cloudscape source | Flutter parameter |
| --- | --- |
| native `<input>` / `<textarea>` inside Input and Textarea | `CsEditable` |
| `placeholder` | `placeholder` |
| `autoComplete`, `spellcheck` | `enableSuggestions`, `autocorrect` |
| `inputMode` | `keyboardType` |
