# CsRadioButton

A single radio button with a label, for building custom single-choice layouts; also exports the `CsRadioIcon` glyph and the `CsControlRow` layout.

Cloudscape reference: https://cloudscape.design/components/radio-button/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsRadioButton(
  checked: plan == 'spot',
  label: 'Spot',
  description: 'Spare capacity at a discount.',
  onSelect: () => setState(() => plan = 'spot'),
)
```

## When to use / when not to

- Use when the options sit in a custom layout, such as a row with a price beside each radio.
- For a plain list use `CsRadioGroup`, which also handles arrow keys and a single Tab stop.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `checked` | `bool` | required | Whether this radio is selected. |
| `onSelect` | `VoidCallback?` | `null` | Called when the user picks it while unchecked. Null disables it. |
| `label` / `child` | `String?` / `Widget?` | `null` | Label; tapping it selects too. |
| `description` / `descriptionWidget` | `String?` / `Widget?` | `null` | Body-s text under the label. |
| `disabled` | `bool` | `false` | |
| `readOnly` | `bool` | `false` | Focusable, not selectable. |
| `ariaLabel` | `String?` | `null` | Accessible name without a label. |
| `focusNode` | `FocusNode?` | `null` | |
| `autofocus` | `bool` | `false` | |

### CsRadioIcon

`CsRadioIcon(checked:, disabled: false, readOnly: false)` is the bare 16px glyph for option lists and tiles.

### CsControlRow

`CsControlRow(control:, controlHeight:, label:, description:, disabled: false)` lays out a control with a label and description the way Cloudscape's checkbox, radio and toggle do: the control centered on the first 20px line, the text 8px after it.

## Examples

### Priced options

```dart
Column(
  children: [
    for (final plan in const ['on-demand', 'reserved', 'spot'])
      Row(
        children: [
          Expanded(
            child: CsRadioButton(
              checked: selected == plan,
              label: plan,
              onSelect: () => setState(() => selected = plan),
            ),
          ),
          const CsBox(variant: CsBoxVariant.small, text: 'Sample price'),
        ],
      ),
  ],
)
```

## Accessibility

Announced as a radio button in a mutually exclusive group with its checked state. Tab focuses it and Space or Enter selects it. Standalone radios do not move with arrow keys; give a list of them a `CsRadioGroup` when possible.

## Motion

The checked ring grows in over 250ms; reduced motion shows it at once.

## Mobile

The row is padded to a 44px touch target; labels wrap at 2x text.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `checked` | `checked` |
| `onSelect` | `onSelect` |
| `children` | `label` / `child` |
| `description` | `description` / `descriptionWidget` |
| `disabled` / `readOnly` | `disabled` / `readOnly` |
| `ariaLabel` | `ariaLabel` |
| `name`, `value`, `controlId`, `ariaLabelledby`, `ariaDescribedby`, `nativeInputAttributes`, `style` | web only |
