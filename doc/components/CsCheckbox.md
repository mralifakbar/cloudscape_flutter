# CsCheckbox

A box with a label for a single on or off choice that is submitted with a form, or the "select all" control above a list.

Cloudscape reference: https://cloudscape.design/components/checkbox/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsCheckbox(
  checked: versioning,
  label: 'Enable versioning',
  description: 'Keeps every version of each object.',
  onChange: (v) => setState(() => versioning = v),
)
```

## When to use / when not to

- Use for independent choices, or for selecting several items from a list.
- Use `CsToggle` for settings that take effect immediately, and `CsRadioGroup` for one choice among several.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `checked` | `bool` | required | The controlled state. |
| `onChange` | `ValueChanged<bool>?` | `null` | Called with the next state; an indeterminate box becomes checked. Null disables it. |
| `label` | `String?` | `null` | Label text; tapping it toggles too. |
| `child` | `Widget?` | `null` | Custom label in place of `label`. |
| `description` | `String?` | `null` | Body-s text under the label. |
| `indeterminate` | `bool` | `false` | A dash for "some selected". |
| `disabled` | `bool` | `false` | |
| `readOnly` | `bool` | `false` | Focusable, but taps and keys do nothing. |
| `ariaLabel` | `String?` | `null` | Accessible name without a label. |
| `ariaRequired` | `bool` | `false` | Adds a "Required" hint. |
| `focusNode` | `FocusNode?` | `null` | |
| `autofocus` | `bool` | `false` | |

### CsCheckboxIcon

`CsCheckboxIcon(checked:, indeterminate: false, disabled: false, readOnly: false)` is the bare 16px glyph, for table rows and option lists that handle the tap themselves. Its check mark draws in over `CsDurations.expressive` when it becomes checked.

## Examples

### Select all

```dart
CsCheckbox(
  checked: selected.length == instances.length,
  indeterminate: selected.isNotEmpty && selected.length < instances.length,
  label: 'All instances',
  onChange: (v) => setState(() => v ? selected.addAll(instances) : selected.clear()),
)
```

### Without a visible label

```dart
CsCheckbox(checked: rowSelected, ariaLabel: 'Select i-0abc123', onChange: (v) => setState(() => rowSelected = v))
```

## Accessibility

Announced as a checkbox with checked, unchecked or mixed state, its label and description. Tab focuses it; Space or Enter toggles. Keyboard focus draws the 2px focus ring around the box.

## Motion

The check mark (or dash) draws along its path when the box becomes checked; the fill switches instantly. Reduced motion shows it at once.

## Mobile

The whole row (box, label, description) is the touch target, padded to 44px on touch. Labels wrap at 2x text.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `checked` / `onChange` | `checked` / `onChange` |
| `indeterminate` | `indeterminate` |
| `children` | `label` / `child` |
| `description` | `description` |
| `disabled` / `readOnly` | `disabled` / `readOnly` |
| `ariaLabel`, `ariaRequired` | `ariaLabel`, `ariaRequired` |
| `name`, `controlId`, `ariaControls`, `nativeInputAttributes`, `style` | web only |
