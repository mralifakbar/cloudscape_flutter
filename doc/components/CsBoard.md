# CsBoard

A configurable dashboard grid whose items people rearrange by dragging, resize from the corner, add from a palette and remove.

Cloudscape reference: https://cloudscape.design/components/board/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsBoard<String>(
  items: const [
    CsBoardEntry(id: 'health', data: 'Instance health', columnSpan: 2),
    CsBoardEntry(id: 'cost', data: 'Monthly cost', columnSpan: 2),
  ],
  onItemsChange: (change) => setState(() {}),
  renderItem: (context, item, actions) => CsBoardItem(
    header: CsHeader(title: item.data),
    settings: CsButton(
      variant: CsButtonVariant.icon,
      icon: CsIcons.close,
      semanticLabel: 'Remove ${item.data}',
      onPress: actions.removeItem,
    ),
    child: const Text('No alarms'),
  ),
  empty: const Text('No widgets. Add widgets from the palette.'),
)
```

Store `change.items` in your state and pass it back as `items`: the board is controlled and never changes its items itself.

## When to use / when not to

- Use for dashboards people personalize: overview pages with widgets of different sizes.
- Use a static grid (`CsColumnLayout`, `CsGrid`) when the layout is fixed.
- Persist `items` (for example to local storage) so arrangements survive reloads; `columnOffset` stores one arrangement per column count.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<CsBoardEntry<T>>` | required | Items and their positions. |
| `renderItem` | `Widget Function(BuildContext, CsBoardEntry<T>, CsBoardItemActions)` | required | Builds each item; return a `CsBoardItem`. `actions.removeItem()` removes it. |
| `onItemsChange` | `ValueChanged<CsBoardItemsChange<T>>` | required | Called on every commit with the new `items` and one of `movedItem`, `resizedItem`, `addedItem`, `removedItem`. |
| `empty` | `Widget?` | `null` | Shown when `items` is empty; also the loading slot while items load. |
| `i18nStrings` | `CsBoardI18nStrings<T>?` | English | Live announcement builders (all optional): `liveAnnouncementDndStarted`, `liveAnnouncementDndItemReordered`, `liveAnnouncementDndItemResized`, `liveAnnouncementDndItemInserted`, `liveAnnouncementDndCommitted`, `liveAnnouncementDndDiscarded`, `liveAnnouncementItemRemoved`. |
| `columns` | `int?` | `null` | Forces 1, 2, 4 or 6 columns instead of following the width. |

`CsBoardEntry<T>`: `id` (`String`, unique on the page), `data` (`T`), `definition` (`CsBoardItemDefinition?`: `minRowSpan`, `minColumnSpan`, `defaultRowSpan`, `defaultColumnSpan`), `columnOffset` (`Map<int, int>?`, column per column count), `rowSpan` (`int?`, 2 or more), `columnSpan` (`int?`).

`CsBoardLayout` holds the grid math as pure functions: `interpret(items, columns)` returns a `CsBoardGrid` of `CsBoardPlacement`s, and `place`, `resize` and `remove` return updated item lists, for app code that adds items at a given spot.

## Examples

### Adding from a palette

```dart
Column(
  children: [
    CsBoard<String>(
      items: const [],
      onItemsChange: (change) {},
      renderItem: (context, item, actions) => CsBoardItem(header: CsHeader(title: item.data)),
      empty: const Text('Drag a widget here'),
    ),
    CsItemsPalette<String>(
      items: const [CsItemsPaletteItem(id: 'traffic', data: 'Network traffic')],
      renderItem: (context, item, ctx) => CsBoardItem(header: CsHeader(title: item.data)),
      onItemAdd: (item) {},
    ),
  ],
)
```

### Custom announcements

```dart
CsBoard<String>(
  items: const [],
  onItemsChange: (change) {},
  renderItem: (context, item, actions) => CsBoardItem(header: CsHeader(title: item.data)),
  i18nStrings: CsBoardI18nStrings<String>(
    liveAnnouncementDndItemReordered: (s) => '${s.item.data} moved to column ${s.placement.x + 1}, row ${s.placement.y + 1}',
    liveAnnouncementItemRemoved: (s) => 'Removed ${s.item.data}',
  ),
)
```

## Accessibility

- Each item has a drag handle and a resize handle (buttons with labels and hints from `CsBoardItemI18nStrings`).
- Keyboard: focus a handle and press Enter or Space to start moving or resizing; arrow keys move the item a cell or change its size by a column or row (left and right swap in RTL); Enter or Space commits, Escape discards, and moving focus away commits.
- Every start, step, commit, discard and removal is announced through `SemanticsService`; the step messages say where the item lands and how many items moved.

## Motion

- The dragged item follows the pointer 1:1 and lifts with `shadow-container-active`; the others slide out of the way over 200ms (Cloudscape `TRANSITION_DURATION_MS`). On release it settles from where it was dropped into its slot.
- While dragging, the grid shows placeholder cells (`color-board-placeholder-active`) and the landing cells (`color-board-placeholder-hover`).
- Under reduced motion items jump to their slots without sliding.

## Mobile

Columns come from the board's own width: 1 below 688px, 2 below 912px, 4 below 2100px, 6 above (override with `columns`). Each column count keeps its own arrangement in `columnOffset`. Handles grow to 44px hit areas on touch screens and start a drag on contact, so the page scrolls everywhere except on a handle. Rows are 96px with 20px gaps (76px and 16px in compact density).

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items` | `items` (`CsBoardEntry<T>`) |
| `renderItem(item, actions)` | `renderItem(context, item, actions)` |
| `onItemsChange` | `onItemsChange` (`CsBoardItemsChange<T>`) |
| `empty` | `empty` |
| `i18nStrings` | `i18nStrings` (`CsBoardI18nStrings<T>`, optional) |
| `i18nStrings.navigationAriaLabel`, `navigationAriaDescription`, `navigationItemAriaLabel` | not applicable (deprecated, no effect in Cloudscape) |
| container query columns | `columns` override |
