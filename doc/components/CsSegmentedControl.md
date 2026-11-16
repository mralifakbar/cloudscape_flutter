# CsSegmentedControl

A row of 2 to 6 buttons in a pill where exactly one is active, for switching between views of the same content.

Cloudscape reference: https://cloudscape.design/components/segmented-control/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsSegmentedControl(
  label: 'Time range',
  selectedId: range,
  onChange: (id) => setState(() => range = id),
  options: const [
    CsSegmentedControlOption(id: '1h', text: '1h'),
    CsSegmentedControlOption(id: '3h', text: '3h'),
    CsSegmentedControlOption(id: '12h', text: '12h'),
  ],
)
```

## When to use / when not to

- Use to switch the presentation of content in place: a chart range, a list or grid view.
- Use tabs to switch between different content, and a radio group for a form value.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `selectedId` | `String?` | required | Id of the active segment; null for none. |
| `options` | `List<CsSegmentedControlOption>` | required | Up to 6 segments. |
| `onChange` | `ValueChanged<String>?` | `null` | Called with the picked id. |
| `label` | `String?` | `null` | Group name; shown as the visible label of the select form. |
| `presentation` | `CsSegmentedControlPresentation` | `auto` | `auto`: segments above 688px, a select at or below. `segments` or `select` force one form. |
| `haptic` | `CsHaptic` | `selection` | Feedback on change. |

`CsSegmentedControlOption(id:, text:, icon:, iconWidget:, iconAlt:, disabled: false, disabledReason:)`: pass `text`, an icon, or both. Icon-only segments need `iconAlt`. A disabled segment with a `disabledReason` stays focusable and explains itself in a tooltip.

## Examples

### Icons

```dart
CsSegmentedControl(
  label: 'Layout',
  selectedId: view,
  presentation: CsSegmentedControlPresentation.segments,
  onChange: (id) => setState(() => view = id),
  options: const [
    CsSegmentedControlOption(id: 'list', icon: CsIcons.listView, iconAlt: 'List'),
    CsSegmentedControlOption(id: 'grid', icon: CsIcons.gridView, iconAlt: 'Grid'),
  ],
)
```

### Disabled with a reason

```dart
CsSegmentedControl(
  selectedId: range,
  onChange: (id) => setState(() => range = id),
  options: const [
    CsSegmentedControlOption(id: '1d', text: '1d'),
    CsSegmentedControlOption(id: '1w', text: '1w', disabled: true, disabledReason: 'Turn on detailed monitoring.'),
  ],
)
```

## Accessibility

- Segments are buttons; the active one is marked selected. Icon-only segments are named by `iconAlt`.
- The control is one Tab stop (the active segment). Left and Right move focus between segments, wrapping (mirrored in RTL); Enter or Space picks the focused one.
- In the select form, the trigger announces the label and the current value and opens a list where the current option is selected.

## Motion

Hover and selection colors change instantly. The select form's dropdown scales in from the trigger; on phones it is a bottom sheet.

## Mobile

At or below 688px Cloudscape replaces the segments with a select; this widget does the same with a dropdown list that opens as a bottom sheet, labelled by `label`. Set `presentation: CsSegmentedControlPresentation.segments` to keep a short pill on phones (it scrolls sideways if it does not fit).

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `selectedId` / `onChange` | `selectedId` / `onChange` (`ValueChanged<String>`) |
| `options` (`id`, `text`, `iconName`, `iconAlt`, `iconSvg`, `iconUrl`, `disabled`, `disabledReason`) | `options` (`id`, `text`, `icon`, `iconAlt`, `iconWidget`, `disabled`, `disabledReason`) |
| `label` | `label` |
| narrow-container select | `presentation` |
| `ariaLabelledby`, `style` | web only |
