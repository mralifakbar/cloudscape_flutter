# CsItemCard

Cloudscape's `ItemCard`: a bordered card for one item, with an icon, title, description and actions in the header, content and a footer.

Cloudscape reference: https://cloudscape.design/components/item-card/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsItemCard(
  icon: const CsIcon(CsIcons.folder),
  header: const Text('example-bucket'),
  description: const Text('us-east-1'),
  footer: const Text('Updated 2 hours ago'),
  child: const Text('Versioning enabled'),
)
```

## When to use / when not to

Use an item card to present one resource in a grid or list of similar resources. `CsCards` builds a collection of them. Use `CsActionCard` when the whole card is a single action, and `CsContainer` for a page section.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `header` | `Widget?` |  | Title, heading-s |
| `description` | `Widget?` |  | Under the title, body-s secondary |
| `icon` | `Widget?` |  | Before the title |
| `actions` | `Widget?` |  | End of the header row; wraps below when narrow |
| `child` | `Widget?` |  | Content |
| `footer` | `Widget?` |  | Bottom content |
| `variant` | `CsItemCardVariant` | `defaultVariant` | `defaultVariant` (16px radius, 20px padding) or `embedded` (8px, 12px) |
| `disableHeaderPaddings`, `disableContentPaddings`, `disableFooterPaddings` | `bool` | `false` |  |
| `fitHeight` | `bool` | `false` | Fill a bounded height; the footer goes to the bottom |
| `highlighted` | `bool` | `false` | Selected look (used by `CsCards`) |
| `onPress` / `semanticLabel` | `VoidCallback?` / `String?` |  | Makes the card pressable |
| `style` | `CsItemCardStyle?` |  | Background, border, radius, shadow, paddings and footer divider |

## Examples

### Embedded with actions

```dart
CsItemCard(
  variant: CsItemCardVariant.embedded,
  header: const Text('i-0abc123'),
  actions: CsButton(icon: CsIcons.ellipsis, variant: CsButtonVariant.icon, semanticLabel: 'Actions', onPress: () {}),
  child: const CsStatusIndicator(text: 'Running'),
)
```

### Footer divider through style

```dart
const CsItemCard(
  header: Text('example-bucket'),
  style: CsItemCardStyle(footerDividerColor: Color(0xFFE9EBED)),
  footer: Text('3 objects'),
  child: Text('Standard storage'),
)
```

## Accessibility

The card is a semantics container and its title a heading. With `onPress` the card is a focusable button with `semanticLabel` and exposes `highlighted` as selected.

## Motion

Highlight changes ease the background and border over `CsDurations.showPaced`; reduced motion is instant.

## Mobile

Actions wrap under the title below 200px of header width. Text wraps; minimum heights only.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `header`, `description`, `footer`, `actions`, `icon`, `children` | same (`child`) |
| `variant: 'default'` | `CsItemCardVariant.defaultVariant` |
| `style` | `CsItemCardStyle` |
| internal `highlighted`, `onClick` | `highlighted`, `onPress` |
| `nativeAttributes` | web only, not ported |
