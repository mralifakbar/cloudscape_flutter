# CsToggle

An on/off switch for a setting that takes effect immediately.

Cloudscape reference: https://cloudscape.design/components/toggle/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsToggle(
  checked: monitoring,
  label: 'Detailed monitoring',
  description: 'Collects metrics every minute.',
  onChange: (v) => setState(() => monitoring = v),
)
```

## When to use / when not to

- Use when flipping the control applies the change at once.
- Use `CsCheckbox` when the choice is submitted later with a form.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `checked` | `bool` | required | The controlled state. |
| `onChange` | `ValueChanged<bool>?` | `null` | Called after a tap, key press or a drag that changes sides. Null disables it. |
| `label` / `child` | `String?` / `Widget?` | `null` | Label; tapping it toggles too. |
| `description` / `descriptionWidget` | `String?` / `Widget?` | `null` | Body-s text under the label. |
| `disabled` | `bool` | `false` | |
| `readOnly` | `bool` | `false` | Focusable, not changeable. |
| `ariaLabel` | `String?` | "Switch" without a label | Accessible name. |
| `ariaRequired` | `bool` | `false` | Adds a "Required" hint. |
| `haptic` | `CsHaptic` | `selection` | Feedback when the state changes. |
| `focusNode` | `FocusNode?` | `null` | |
| `autofocus` | `bool` | `false` | |

## Examples

### Saving to a service

```dart
CsToggle(
  checked: protection,
  label: 'Termination protection',
  onChange: (v) async {
    setState(() => protection = v);
    await saveProtection(v);
  },
)
```

### Read-only

```dart
CsToggle(checked: true, readOnly: true, label: 'Encryption at rest', onChange: (_) {})
```

## Accessibility

Announced as a switch with its toggled state, label and description. Tab focuses it; Space or Enter toggles. Keyboard focus draws the 2px focus ring around the track. Without a label it is announced as "Switch" unless `ariaLabel` is set.

## Motion

- Tap: the handle springs to the other side, starting from wherever it is, and stretches by 4px early in its travel (Cloudscape's expressive tail). Track and handle colors follow its position.
- Press: the handle stretches while held.
- Drag: the handle follows the finger 1:1 from the touch point and resists past either end (`CsMotion.rubberband`). On release the side comes from the position plus the projected flick (`CsMotion.project`); a flick settles with `CsSprings.momentum`. If the parent does not accept the new value, the handle springs back.
- A selection haptic marks each change. Reduced motion moves the handle without animation.

## Mobile

The track keeps Cloudscape's 24x16 size; the row is padded to a 44px hit area on touch. The drag recognizer uses a 4px slop, because Flutter's 18px default is longer than the handle's 8px travel.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `checked` / `onChange` | `checked` / `onChange` |
| `children` | `label` / `child` |
| `description` | `description` / `descriptionWidget` |
| `disabled` / `readOnly` | `disabled` / `readOnly` |
| `ariaLabel`, `ariaRequired` | `ariaLabel`, `ariaRequired` |
| `name`, `controlId`, `ariaControls`, `nativeInputAttributes`, `style` | web only |
