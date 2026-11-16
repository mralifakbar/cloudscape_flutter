# CsRadioGroup

A list of mutually exclusive options where all choices stay visible.

Cloudscape reference: https://cloudscape.design/components/radio-group/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFormField(
  label: 'Storage class',
  child: CsRadioGroup(
    value: storageClass,
    onChange: (v) => setState(() => storageClass = v),
    items: const [
      CsRadioGroupItem(value: 'standard', label: 'Standard', description: 'For frequently accessed data.'),
      CsRadioGroupItem(value: 'ia', label: 'Infrequent access'),
    ],
  ),
)
```

## When to use / when not to

- Use for 2 to 7 options the user should compare at a glance.
- Use a select for longer lists, `CsTiles` when options need more description or an image, and `CsSegmentedControl` to switch views.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String?` | required | Value of the selected item; null for none. |
| `items` | `List<CsRadioGroupItem>` | required | The options. |
| `onChange` | `ValueChanged<String>?` | `null` | Called with the newly selected value. Null disables the group. |
| `direction` | `CsRadioGroupDirection` | `vertical` | `horizontal` lays radios side by side, wrapping, 20px apart. |
| `readOnly` | `bool` | `false` | Focusable, not changeable. |
| `disabled` | `bool` | `false` | Disables every item (a Flutter addition). |
| `ariaLabel` | `String?` | `null` | Group name outside a labelled form field. |
| `ariaRequired` | `bool` | `false` | Adds a "Required" hint. |
| `autofocus` | `bool` | `false` | Focus the tab-stop radio on mount. |

`CsRadioGroupItem(value:, label:, labelWidget:, description:, descriptionWidget:, disabled: false)`: pass `label` or `labelWidget`.

## Examples

### Horizontal

```dart
CsRadioGroup(
  value: protocol,
  direction: CsRadioGroupDirection.horizontal,
  ariaLabel: 'Origin protocol',
  onChange: (v) => setState(() => protocol = v),
  items: const [
    CsRadioGroupItem(value: 'http', label: 'HTTP only'),
    CsRadioGroupItem(value: 'https', label: 'HTTPS only'),
    CsRadioGroupItem(value: 'match', label: 'Match viewer'),
  ],
)
```

### Disabled item

```dart
CsRadioGroup(
  value: tier,
  onChange: (v) => setState(() => tier = v),
  items: const [
    CsRadioGroupItem(value: 'basic', label: 'Basic'),
    CsRadioGroupItem(value: 'archive', label: 'Archive', description: 'Not available in this Region.', disabled: true),
  ],
)
```

## Accessibility

- Each radio is announced as a checked or unchecked radio button in a mutually exclusive group, with its label and description.
- The group is one Tab stop: the selected radio, or the first enabled one. Arrow keys (Up/Left previous, Down/Right next, mirrored in RTL) move to the next enabled radio and select it, wrapping at the ends, like native radios. Disabled items are skipped; in a read-only group arrows move focus without changing the value.

## Motion

When a radio becomes checked its ring grows in from a thin stroke over 250ms (Cloudscape's `awsui-radio-select`). Reduced motion shows the final state.

## Mobile

Each row is padded to a 44px touch target. Vertical groups suit phones best; horizontal groups wrap at 390px and cap each item at about 80 characters wide.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value` / `onChange` | `value` / `onChange` (`ValueChanged<String>`) |
| `items` (`value`, `label`, `description`, `disabled`) | `items` (`CsRadioGroupItem`) |
| `direction` | `direction` |
| `readOnly` | `readOnly` |
| `ariaLabel`, `ariaRequired` | `ariaLabel`, `ariaRequired` |
| `name`, `controlId`, `items[].controlId`, `ariaControls`, `style` | web only |
