# CsSlider

Picks a number from a range by dragging a handle along a track.

Cloudscape reference: https://cloudscape.design/components/slider/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFormField(
  label: 'Target utilization',
  child: CsSlider(
    min: 0,
    max: 100,
    step: 10,
    tickMarks: true,
    value: target,
    valueFormatter: (v) => '${v.round()}%',
    onChange: (v) => setState(() => target = v),
  ),
)
```

## When to use / when not to

- Use when the position in the range matters more than the exact number (a percentage, a relative capacity).
- Use `CsInput` with `type: CsInputType.number` when users need exact values, or pair the two.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `min` / `max` | `double` | required | The range; `max` must be greater than `min`. |
| `value` | `double?` | middle of the range | The controlled value, shown at the nearest step. |
| `onChange` | `ValueChanged<double>?` | `null` | Called with each new value while dragging, tapping or pressing keys. Null disables it. |
| `onChangeEnd` | `ValueChanged<double>?` | `null` | Called once when a drag, tap or key press ends (a Flutter addition). |
| `step` | `double?` | `null` | Granularity; null moves continuously (keyboard steps of 1). |
| `valueFormatter` | `String Function(double)?` | `null` | Formats the min, max and reference labels and the tooltip. |
| `referenceValues` | `List<double>` | `[]` | Labels between min and max; crowded, out-of-range and non-integer values are skipped. |
| `tickMarks` | `bool` | `false` | A tick at every step (needs `step`). |
| `hideFillLine` | `bool` | `false` | Hides the fill from the start to the handle. |
| `disabled` / `readOnly` | `bool` | `false` | Read-only stays focusable and shows a smaller handle. |
| `invalid` / `warning` | `bool` | `false` | Error or warning colors for the fill and handle. |
| `ariaLabel` | `String?` | `null` | Accessible name without a label. |
| `ariaDescription` | `String?` | `null` | Extra description read after the value. |
| `i18nStrings` | `CsSliderI18nStrings` | English | `valueTextRange(previous, value, next)` for values the formatter leaves empty. |
| `haptic` | `CsHaptic` | `selection` | Fired at each step while dragging a stepped slider. |
| `focusNode` / `autofocus` | | | |

`CsSlider.snap(value, min:, max:, step:)` and `CsSlider.visibleReferenceValues(values, min, max, narrow:)` expose the rounding and label rules.

## Examples

### Commit on release

```dart
CsSlider(
  min: 1,
  max: 10,
  step: 1,
  tickMarks: true,
  value: instances,
  onChange: (v) => setState(() => instances = v),
  onChangeEnd: (v) => saveDesiredCount(v.round()),
)
```

### Reference values and a warning

```dart
CsFormField(
  label: 'Target utilization',
  warningText: target > 80 ? 'High targets leave little room for traffic spikes.' : null,
  child: CsSlider(
    min: 0,
    max: 100,
    referenceValues: const [25, 50, 75],
    value: target,
    warning: target > 80,
    valueFormatter: (v) => '${v.round()}%',
    onChange: (v) => setState(() => target = v),
  ),
)
```

## Accessibility

- Announced as a slider with its label, the formatted value and the next and previous values; screen reader increase and decrease gestures move one step.
- Keyboard: arrows move one step (Right and Up increase; Left and Right mirror in RTL), Page Up and Page Down a tenth of the range, Home and End jump to the ends.
- Status is paired with the form field's error or warning text, not color alone.

## Motion

While focused or dragged the handle grows from 16px to 20px and shows its halo (`CsDurations.responsive`); hovering shows the halo. A tooltip with the formatted value shows over the handle while it is hovered, focused with the keyboard or dragged. Reduced motion makes the size change instant.

## Mobile

- Pressing the track jumps the handle there, then it follows the finger 1:1. The touch area is 44px tall around the 20px band.
- Stepped sliders fire a selection haptic at each step.
- On narrow screens fewer reference labels are kept (a quarter of the range apart), and under 465px only min and max show.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value` / `onChange` | `value` / `onChange` (+ `onChangeEnd`) |
| `min` / `max` / `step` | `min` / `max` / `step` |
| `valueFormatter` | `valueFormatter` |
| `referenceValues` | `referenceValues` |
| `tickMarks` | `tickMarks` |
| `hideFillLine` | `hideFillLine` |
| `disabled` / `readOnly` | `disabled` / `readOnly` |
| `invalid` / `warning` | `invalid` / `warning` |
| `ariaLabel`, `ariaDescription` | `ariaLabel`, `ariaDescription` |
| `i18nStrings.valueTextRange` | `i18nStrings` (`CsSliderI18nStrings`) |
| `ariaLabelledby`, `ariaDescribedby`, `controlId`, `nativeInputAttributes`, `style` | web only |
