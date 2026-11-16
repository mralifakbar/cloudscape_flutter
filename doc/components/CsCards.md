# CsCards

Cloudscape's `Cards`: a collection shown as a grid of cards, with the header, filter, pagination and preferences slots of a collection and optional selection.

Cloudscape reference: https://cloudscape.design/components/cards/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsCards<Map<String, Object?>>(
  header: const CsHeader(title: 'Distributions', counter: '(1)'),
  items: const [
    {'id': 'd111111abcdef8', 'domain': 'd111111abcdef8.example.net', 'status': 'Deployed'},
  ],
  cardDefinition: CsCardDefinition(
    header: (context, item) => Text('${item['id']}'),
    sections: [
      CsCardSection(id: 'domain', header: 'Domain name', content: (context, item) => Text('${item['domain']}')),
      CsCardSection(id: 'status', header: 'Status', content: (context, item) => Text('${item['status']}')),
    ],
  ),
)
```

## When to use / when not to

Use cards when each item benefits from a visual summary (images, status, a few key attributes) and users browse rather than compare. Use `CsTable` to compare many attributes across items.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<T>` | required | The cards, in order |
| `cardDefinition` | `CsCardDefinition<T>` | required | `header(context, item)` and `sections` |
| `header`, `filter`, `pagination`, `preferences` | `Widget?` |  | Collection slots, in a container above the cards |
| `empty` | `Widget?` |  | Shown when `items` is empty |
| `loading` / `loadingText` | `bool` / `String?` | `false` | Loading status instead of cards |
| `cardsPerRow` | `List<CsCardsLayout>` | `CsCardsLayout.defaults` | Cards per row from a minimum width |
| `trackBy` | `Object? Function(T)?` |  | Item identity |
| `selectionType` | `CsSelectionType?` |  | `single` or `multi` |
| `selectedItems` / `onSelectionChange` | `List<T>` / `ValueChanged<List<T>>?` | `[]` | Controlled selection |
| `isItemDisabled` | `bool Function(T)?` |  | Disabled items cannot be selected |
| `visibleSections` | `List<String>?` |  | Ids of the visible sections |
| `entireCardClickable` | `bool` | `false` | Pressing the card selects it |
| `variant` | `CsCardsVariant` | `container` | `container` or `fullPage` |
| `stickyHeader` / `stickyHeaderVerticalOffset` | `bool` / `double` | `false` / `0` | Pinned header in a bounded height, off on phones |
| `totalItemsCount`, `firstIndex`, `renderAriaLive` |  |  | Screen reader counts and page announcements |
| `ariaLabels` | `CsCardsAriaLabels<T>?` |  | `itemSelectionLabel`, `selectionGroupLabel`, `cardsLabel` |

`CsCardSection<T>`: `id`, `header` or `headerWidget`, `content(context, item)`, `width` (percent, default 100).

`CsCardsLayout`: `cards` and `minWidth`. Default: 1 card, 2 from 768px, 3 from 992px, 4 from 1200px, 5 from 1400px, 6 from 1920px. `CsCardsLayout.cardsPerRow(width, config)` computes it.

## Examples

### Selectable cards

```dart
CsCards<Map<String, Object?>>(
  items: items,
  cardDefinition: definition,
  selectionType: CsSelectionType.multi,
  selectedItems: selected,
  onSelectionChange: (next) => setState(() => selected = next),
  entireCardClickable: true,
  ariaLabels: CsCardsAriaLabels(itemSelectionLabel: (selected, item) => 'Select ${item['id']}'),
)
```

### Side by side sections and a fixed grid

```dart
CsCards<Map<String, Object?>>(
  items: items,
  cardsPerRow: const [CsCardsLayout(cards: 1), CsCardsLayout(cards: 3, minWidth: 600)],
  cardDefinition: CsCardDefinition(
    header: (context, item) => Text('${item['id']}'),
    sections: [
      CsCardSection(id: 'status', header: 'Status', width: 50, content: (context, item) => Text('${item['status']}')),
      CsCardSection(id: 'origin', header: 'Origin', width: 50, content: (context, item) => Text('${item['origin']}')),
    ],
  ),
)
```

## Accessibility

The list is a semantics container named by `cardsLabel`. Card titles are headings. Selection controls are checkboxes or radios labeled by `itemSelectionLabel`; selected cards expose their state. Up and Down arrows move focus between selection controls.

## Motion

Selecting a card eases its background and 2px border in (`CsDurations.showPaced`); reduced motion makes it instant.

## Mobile

The grid uses one column below 768px with the default layout. Cards in a row share the tallest card's height. With the `fullPage` variant on phones the pagination moves below the cards, as in Cloudscape, and the sticky header is turned off.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `cardDefinition.header(item)` | `CsCardDefinition.header(context, item)` |
| `cardDefinition.sections[].content(item)` | `CsCardSection.content(context, item)` |
| `cardsPerRow` | `List<CsCardsLayout>` |
| `variant: 'full-page'` | `CsCardsVariant.fullPage` |
| `ariaLabels.itemSelectionLabel(data, item)` | `itemSelectionLabel(selectedItems, item)` |
| `ref.scrollToTop()` | use a `ScrollController` on the parent |
| `analyticsMetadata` | web only, not ported |
