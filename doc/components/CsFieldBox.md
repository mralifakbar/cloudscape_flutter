# CsFieldBox

The chrome of every Cloudscape text field: background, border, radius, focus ring and validation states, around any content.

Cloudscape reference: https://cloudscape.design/components/input/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFieldBox(
  focused: focusNode.hasFocus,
  child: CsEditable(controller: controller, focusNode: focusNode),
)
```

## When to use / when not to

- Use to build a field that must match `CsInput` but holds something else: a token list, a copyable ARN, a custom picker trigger.
- For plain text entry use `CsInput` or `CsTextarea`, which already combine `CsFieldBox`, `CsEditable` and `CsTextFieldState`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | The field content. |
| `focused` | `bool` | `false` | Draws `color-border-input-focused` and the 1px focus ring (2px with a status). |
| `status` | `CsFieldStatus` | `none` | `invalid` (red) or `warning` (yellow) border with an 8px start edge. |
| `disabled` | `bool` | `false` | `color-background-input-disabled` fill and disabled border. |
| `readOnly` | `bool` | `false` | Disabled border on the default fill. |
| `leading` | `Widget?` | `null` | An icon before the content, 12px from the start edge. |
| `trailing` | `Widget?` | `null` | Content after the field text (a clear button, a caret). |
| `padding` | `EdgeInsetsGeometry?` | field tokens | Overrides `space-field-vertical` / `space-field-horizontal`. |
| `minHeight` | `double?` | `size-vertical-input` | 32px, 28px compact. |
| `borderRadius` | `double` | `CsBorderRadius.input` (8) | |
| `multiline` | `bool` | `false` | Aligns content to the top (text areas). |

## Examples

### A copyable value

```dart
CsFieldBox(
  focused: focusNode.hasFocus,
  trailing: CsButton(
    icon: CsIcons.copy,
    variant: CsButtonVariant.inlineIcon,
    semanticLabel: 'Copy ARN',
    onPress: () => Clipboard.setData(ClipboardData(text: controller.text)),
  ),
  child: CsEditable(controller: controller, focusNode: focusNode, mono: true),
)
```

### A trigger that is not a text field

```dart
CsPressable(
  onPress: () => setState(() => open = true),
  showFocusRing: false,
  builder: (context, state) => CsFieldBox(
    focused: state.focused || open,
    trailing: const Padding(
      padding: EdgeInsetsDirectional.only(end: CsSpace.xs),
      child: CsIcon(CsIcons.caretDownFilled),
    ),
    child: Text(selectedLabel),
  ),
)
```

## Accessibility

`CsFieldBox` draws only; it adds no semantics. Give the content its own (a `CsEditable` is a text field; a pressable trigger is a button with a label and value). The invalid and warning states must be paired with a message, as in `CsFormField`.

## Motion

None: focus and status colors switch instantly. Borders are drawn inside the box and the focus ring outside it, so states never shift layout.

## Mobile

It uses a minimum height, so 2x text grows the field instead of clipping. The thick status edge eats into the start padding so text does not move when validation changes.

## Cloudscape React mapping

| Cloudscape source | Flutter parameter |
| --- | --- |
| `.input` styles (`internal/styles/forms`) | `CsFieldBox` |
| `invalid` / `warning` | `status` |
| `disabled` / `readOnly` | `disabled` / `readOnly` |
| `:focus` styles | `focused` |
| `input-icon-left` / `input-icon-right` | `leading` / `trailing` |
