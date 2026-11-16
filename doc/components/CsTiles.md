# CsTiles

A single choice shown as bordered cards, for options that need a description or an image to be compared.

Cloudscape reference: https://cloudscape.design/components/tiles/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFormField(
  label: 'Engine',
  stretch: true,
  child: CsTiles(
    value: engine,
    onChange: (v) => setState(() => engine = v),
    items: const [
      CsTilesItem(value: 'mysql', label: 'MySQL', description: 'Open-source relational database.'),
      CsTilesItem(value: 'postgres', label: 'PostgreSQL', description: 'Extensible relational database.'),
    ],
  ),
)
```

## When to use / when not to

- Use for a few options (2 to 8) where each needs a sentence or an illustration.
- Use `CsRadioGroup` when a label is enough, and a select for long lists.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String?` | required | Value of the selected tile; null for none. |
| `items` | `List<CsTilesItem>` | required | The tiles. |
| `onChange` | `ValueChanged<String>?` | `null` | Called with the newly selected value. |
| `columns` | `int?` | from item count | 1 to 4 columns on wide layouts. By default 1 for one item, 2 for 2, 4 or 8 items, otherwise 3. |
| `readOnly` | `bool` | `false` | Focusable, not changeable. |
| `ariaLabel` | `String?` | `null` | Group name outside a labelled form field. |
| `ariaRequired` | `bool` | `false` | Adds a "Required" hint. |
| `autofocus` | `bool` | `false` | |

`CsTilesItem(value:, label:, labelWidget:, description:, descriptionWidget:, image:, disabled: false)`. The `image` is centered under the description and fades to 30% when disabled.

`CsTiles.defaultColumns(itemCount)` and `CsTiles.columnsAt(width, columns)` expose the column rules.

## Examples

### With images and four columns

```dart
CsTiles(
  value: size,
  columns: 4,
  onChange: (v) => setState(() => size = v),
  items: const [
    CsTilesItem(value: 'small', label: 'Small', description: '2 vCPU, 4 GiB', image: CsIcon(CsIcons.file, size: CsIconSize.big)),
    CsTilesItem(value: 'medium', label: 'Medium', description: '4 vCPU, 16 GiB', image: CsIcon(CsIcons.folder, size: CsIconSize.big)),
    CsTilesItem(value: 'large', label: 'Large', description: '8 vCPU, 32 GiB', image: CsIcon(CsIcons.folderOpen, size: CsIconSize.big)),
    CsTilesItem(value: 'xlarge', label: 'X-Large', disabled: true),
  ],
)
```

## Accessibility

- Each tile is announced as a radio button in a mutually exclusive group, with its label and description; the whole tile is the touch target.
- The group is one Tab stop; arrow keys move to the next enabled tile and select it, wrapping. Keyboard focus draws the focus ring around the tile's radio, as Cloudscape does.

## Motion

Border and background change over `CsDurations.transitionQuick` (90ms) when a tile is selected; the radio ring grows in. Reduced motion makes both instant.

## Mobile

Columns follow the width the tiles get (Cloudscape's container breakpoints): one column under 465px, at most two under 688px, then `columns`. Tiles in a row share the tallest tile's height. The gap is half of `space-tile-gutter` (12px, 8px compact).

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value` / `onChange` | `value` / `onChange` |
| `items` (`value`, `label`, `description`, `image`, `disabled`) | `items` (`CsTilesItem`) |
| `columns` | `columns` |
| `readOnly` | `readOnly` |
| `ariaLabel`, `ariaRequired` | `ariaLabel`, `ariaRequired` |
| `name`, `items[].controlId`, `ariaControls` | web only |
