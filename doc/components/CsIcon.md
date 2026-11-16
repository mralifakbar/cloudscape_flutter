# CsIcon

Cloudscape's `Icon`: one of the 148 built-in `CsIcons`, drawn as a vector outline in the current text color, with Cloudscape's stroke width for each size.

Cloudscape reference: https://cloudscape.design/components/icon/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsIcon(CsIcons.statusPositive, variant: CsIconVariant.success)
```

## When to use / when not to

Use icons to support a label or status, not to replace text people need to read. Most components take an `icon` parameter directly (`CsButton(icon: CsIcons.addPlus)`), so you rarely build `CsIcon` yourself.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `icon` | `CsIconData` | | A `CsIcons` icon or your own `CsIconData` |
| `size` | `CsIconSize` | `normal` | `xSmall` 12, `small` 16, `normal` 16 (20px line), `medium` 20, `big` 32, `large` 48 |
| `variant` | `CsIconVariant` | `normal` | `normal` (current color), `disabled`, `inverted`, `subtle`, `warning`, `error`, `success`, `link`, `info` |
| `semanticLabel` | `String?` | | Without it the icon is decorative and hidden from screen readers |
| `badge` | `bool` | `false` | A small dot at the top end corner |
| `mapHeight` | `bool` | `false` | Size the box to the icon's line height, to align with text |
| `dangerouslySetColor` | `Color?` | | Raw color override |

`CsIcon.custom(widget)` puts an image or any widget in an icon-sized box (Cloudscape `url` / `svg`). `CsIcons.all` lists every icon; `CsIcons.byName('status-positive')` looks one up by its Cloudscape name.

## Examples

### Sizes

```dart
const Row(children: [
  CsIcon(CsIcons.settings, size: CsIconSize.small),
  CsIcon(CsIcons.settings, size: CsIconSize.medium),
  CsIcon(CsIcons.settings, size: CsIconSize.big),
])
```

### Custom icon data

```dart
const CsIcon(CsIconData('diamond', [CsIconPart('M8 1L15 8L8 15L1 8Z', roundJoin: true)]))
```

## Accessibility

Decorative by default. Pass `semanticLabel` when the icon carries meaning on its own. Directional icons (arrows, angles, external, undo, redo, send) mirror in right-to-left layouts.

## Motion

None.

## Mobile

Icons keep their size; tappable icons go in `CsButton(variant: icon)` for a 44px hit area.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `name="status-positive"` | `CsIcons.statusPositive` |
| `size`, `variant`, `badge` | same names |
| `ariaLabel`, `alt` | `semanticLabel` |
| `url`, `svg` | `CsIcon.custom(widget)` |
