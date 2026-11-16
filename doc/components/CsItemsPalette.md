# CsItemsPalette

A catalog of items people drag onto a `CsBoard`, with an add button as the keyboard and screen reader alternative.

Cloudscape reference: https://cloudscape.design/components/items-palette/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsItemsPalette<String>(
  items: const [
    CsItemsPaletteItem(
      id: 'traffic',
      data: 'Network traffic',
      definition: CsBoardItemDefinition(defaultColumnSpan: 2, defaultRowSpan: 3),
    ),
  ],
  renderItem: (context, item, ctx) => CsBoardItem(
    header: CsHeader(title: item.data),
    child: Text(ctx.showPreview ? 'Bytes in and out per minute' : 'Shows network traffic'),
  ),
  onItemAdd: (item) {},
)
```

## When to use / when not to

- Use with a `CsBoard`, usually in a split panel or drawer next to it.
- Remove an item from `items` once it is on the board (from `onItemsChange`'s `addedItem` or from `onItemAdd`).

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<CsItemsPaletteItem<T>>` | required | `id`, `data` and an optional `definition` whose default spans size the item on the board. `toBoardEntry()` converts one. |
| `renderItem` | `Widget Function(BuildContext, CsItemsPaletteItem<T>, CsItemsPaletteItemContext)` | required | Return a `CsBoardItem`. `showPreview` is true while the item is dragged over a board. |
| `onItemAdd` | `ValueChanged<CsItemsPaletteItem<T>>?` | `null` | Adds without dragging. Shows an add button on each item and makes Enter or Space on the drag handle add the item. |
| `i18nStrings` | `CsItemsPaletteI18nStrings` | English | `liveAnnouncementDndStarted`, `liveAnnouncementDndDiscarded`. |
| `columns` | `int?` | `null` | Forces a column count; by default 1 below 688px, 2 below 912px, 3 above. |

## Examples

### Adding with the button

```dart
CsItemsPalette<String>(
  items: const [CsItemsPaletteItem(id: 'errors', data: 'Error rate')],
  renderItem: (context, item, ctx) => CsBoardItem(header: CsHeader(title: item.data)),
  onItemAdd: (item) => setState(() {}),
)
```

## Accessibility

- Dragging is pointer only, as in Cloudscape's palette; `onItemAdd` gives keyboard and screen reader users an equivalent (the add button, or Enter on the drag handle). Always provide it.
- The start of a drag and a drop outside a board are announced.

## Motion

The dragged item follows the pointer, keeping its offset from the finger; the item left in the palette dims to 50% until the drag ends. Over a board, the board shows where the item will land.

## Mobile

Drag by the handle (immediately) or press and hold anywhere on the item (touch, with haptic feedback). Items stack in one column below 688px.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items` | `items` (`CsItemsPaletteItem<T>`) |
| `renderItem(item, context)` | `renderItem(context, item, itemContext)` |
| `i18nStrings.liveAnnouncementDndStarted`, `liveAnnouncementDndDiscarded` | `i18nStrings` |
| `i18nStrings.navigationAriaLabel`, `navigationAriaDescription`, `navigationItemAriaLabel` | not applicable (deprecated, no effect) |
| (none) | `onItemAdd`, the keyboard alternative |
