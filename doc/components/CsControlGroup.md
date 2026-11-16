# CsControlGroup

Cloudscape's `ControlGroup` (`src/control-group`): joins form controls, such as an input and a select, or an input and an icon button, into one visual control with shared borders.

Cloudscape reference: https://cloudscape.design/components/control-group/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsControlGroup(
  children: [
    CsInput(value: size, type: CsInputType.number, onChange: (v) => setState(() => size = v)),
    Flexible(
      flex: 0,
      child: SizedBox(
        width: 96,
        child: CsSelect(
          options: const [CsOption(value: 'gib', label: 'GiB'), CsOption(value: 'tib', label: 'TiB')],
          selectedOption: unit,
          onChange: (o) => setState(() => unit = o),
        ),
      ),
    ),
  ],
)
```

## When to use / when not to

Use a control group when two or more controls describe one value (a size and its unit, a value and its operator) or when an input has one closely tied action (clear, remove). Do not use it to lay out unrelated fields side by side; use `CsColumnLayout` or `CsSpaceBetween` with separate `CsFormField`s.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` | required | The grouped controls in order. Each takes an equal share of the width; wrap one in `Flexible` for another `flex`, or `Flexible(flex: 0, ...)` around a sized child for a fixed width |
| `direction` | `CsControlGroupDirection` | `auto` | `horizontal`, `vertical`, or `auto` (side by side while every control gets `minControlWidth`, stacked otherwise) |
| `inlineLabelText` | `String?` |  | Label drawn on the group's top border |
| `actionButton` | `CsControlGroupActionButton?` |  | Icon button joined to the end of the group |
| `invalid` | `bool` | `false` | Error state: red outer borders, 8px start edge on the leading control |
| `warning` | `bool` | `false` | Warning state (ignored when `invalid`) |
| `semanticLabel` | `String?` | `inlineLabelText` | Accessible name of the group |
| `minControlWidth` | `double` | `120` | Narrowest control width before `auto` stacks |

`CsControlGroupActionButton`:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `icon` | `CsIconData` | required | Icon (Cloudscape `iconName`) |
| `ariaLabel` | `String` | required | Accessible name, also shown as a tooltip |
| `onPress` | `VoidCallback?` |  | Called on press (Cloudscape `onClick`) |
| `disabled` | `bool` | `false` | Disables the button |
| `disabledReason` | `String?` |  | Keeps a disabled button focusable and explains why in a tooltip |
| `iconWidget` | `Widget?` |  | Custom icon in place of `icon` |

## Examples

### Input with a remove action

```dart
CsControlGroup(
  actionButton: CsControlGroupActionButton(
    icon: CsIcons.remove,
    ariaLabel: 'Remove tag',
    onPress: () => setState(() => tag = ''),
  ),
  children: [CsInput(value: tag, placeholder: 'Tag key', onChange: (v) => setState(() => tag = v))],
)
```

### Invalid, stacked

```dart
CsFormField(
  label: 'Retention',
  errorText: 'Enter a number of days.',
  child: CsControlGroup(
    direction: CsControlGroupDirection.vertical,
    invalid: true,
    children: [
      CsInput(value: days, onChange: (v) => setState(() => days = v)),
      CsInput(value: note, placeholder: 'Reason', onChange: (v) => setState(() => note = v)),
    ],
  ),
)
```

### Inline label

```dart
CsControlGroup(
  inlineLabelText: 'Port range',
  children: [
    CsInput(value: from, onChange: (v) => setState(() => from = v)),
    CsInput(value: to, onChange: (v) => setState(() => to = v)),
  ],
)
```

## Accessibility

The group is one semantics container labelled by `semanticLabel` or `inlineLabelText`. Each control keeps its own semantics and Tab stop; the action button is a labelled button whose disabled reason is read as its hint. Validation is drawn with color and the 8px start edge; pair it with `CsFormField.errorText` so it is never color alone.

## Motion

Hover colors on the action button change instantly. Focus shows the field focus border and a 1px ring.

## Mobile

With `direction: auto` the group stacks its controls when they would get narrower than `minControlWidth` (at 390px a group of three stacks). In the stacked layout the action button spans the full column height. Field heights grow with the text scale.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `children` |
| `direction` | `direction` (`CsControlGroupDirection`) |
| `inlineLabelText` | `inlineLabelText` |
| `actionButton` | `actionButton` (`CsControlGroupActionButton`) |
| `actionButton.onClick` | `CsControlGroupActionButton.onPress` |
| `actionButton.iconName` | `CsControlGroupActionButton.icon` |
| form field `invalid` / `warning` context | `invalid` / `warning` |
| `ariaLabelledby` | `semanticLabel` |
| `ariaDescribedby`, `actionButton.ariaDescribedby` | not supported (web only) |
| grouped control context | `CsGroupedControl` (read by `CsFieldBox`; custom controls can read it too) |
