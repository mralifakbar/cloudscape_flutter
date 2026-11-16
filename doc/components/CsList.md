# CsList

A vertical list of structured items (icon, content, secondary content, actions) separated by dividers, with an optional sortable mode for drag and keyboard reordering.

Cloudscape reference: https://cloudscape.design/components/list/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

Widget buckets() => CsList<String>(
  items: const ['example-bucket', 'logs-bucket'],
  renderItem: (name) => CsListItem(
    id: name,
    content: Text(name),
    icon: const CsIcon(CsIcons.folder),
  ),
);
```

## When to use / when not to

- Use it for a short collection of items that need no columns: attached policies, recent resources, a ranked list of rules.
- Use `sortable` when the order matters and users set it (rule priority, column order).
- Do not use it for many items with several attributes: use a table or cards.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<T>` | required | The items. |
| `renderItem` | `CsListItem Function(T)` | required | Describes one item. |
| `sortable` | `bool` | `false` | Adds drag handles and reordering. |
| `sortDisabled` | `bool` | `false` | Disables the handles temporarily. |
| `onSortingChange` | `ValueChanged<List<T>>?` | `null` | Called with the reordered items after a drop. Pass them back in `items`. |
| `disableItemPaddings` | `bool` | `false` | Removes the vertical padding inside items and the gaps between icon, content and actions. |
| `disablePaddings` | `bool` | `false` | Removes the padding above the first and below the last item (not for sortable lists). |
| `ordered` | `bool?` | `sortable` | Order is meaningful: screen readers hear "2 of 5" per item. |
| `ariaLabel` | `String?` | `null` | Accessible name of the list. |
| `i18nStrings` | `CsListI18nStrings` | English | Drag handle label and hint, and the live announcements. |

`CsListItem`:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `id` | `String` | required | Unique, stable identifier. |
| `content` | `Widget` | required | Main content (body text). |
| `secondaryContent` | `Widget?` | `null` | Below the content, in body-s secondary text. |
| `icon` | `Widget?` | `null` | At the start, aligned with the first line. |
| `actions` | `Widget?` | `null` | At the end of the first line. |
| `announcementLabel` | `String?` | text of `content` | Name of the item in reorder announcements. |

`CsListI18nStrings`: `dragHandleAriaLabel` (`'Drag handle'`), `dragHandleAriaDescription`, `liveAnnouncementDndStarted(position, total)`, `liveAnnouncementDndItemReordered(initial, current, total)`, `liveAnnouncementDndItemCommitted(initial, final, total)`, `liveAnnouncementDndDiscarded` (`'Reordering canceled'`).

## Examples

### Items with descriptions and actions

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

Widget policies(void Function(String) detach) => CsList<String>(
  items: const ['ReadOnlyAccess', 'ExampleBucketWrite'],
  renderItem: (name) => CsListItem(
    id: name,
    content: Text(name),
    secondaryContent: const Text('Customer managed policy'),
    actions: CsButton(text: 'Detach', onPress: () => detach(name)),
  ),
);
```

### Sortable

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

class Rules extends StatefulWidget {
  const Rules({super.key});

  @override
  State<Rules> createState() => _RulesState();
}

class _RulesState extends State<Rules> {
  List<String> rules = ['Block bad bots', 'Rate limit login', 'Allow office IPs'];

  @override
  Widget build(BuildContext context) => CsList<String>(
    items: rules,
    sortable: true,
    ariaLabel: 'Rule priority',
    renderItem: (rule) => CsListItem(id: rule, content: Text(rule)),
    onSortingChange: (next) => setState(() => rules = next),
  );
}
```

## Accessibility

Each item is its own semantics node; in an ordered (or sortable) list it also reports its position ("2 of 3"). Drag handles are buttons named "Drag handle, <item>" with a hint that explains the keyboard interaction: Space or Enter picks the item up, the arrow keys move it, Space or Enter drops it and Escape cancels. Moving focus away also cancels. Every step is announced with the `liveAnnouncement*` strings, as in Cloudscape.

## Motion

While dragged by pointer, the item lifts with `shadow-container-active` on the container background and follows the finger 1:1; the other items slide out of its way and the item settles into its slot on release. Keyboard moves are instant and the picked-up item keeps the lifted look.

## Mobile

Drag starts as soon as the finger moves on the handle (the handle has a 44px wide hit area on touch screens), so the rest of the item still scrolls the page. Content and secondary content wrap; actions stay at the end of the first line.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items` | `items` |
| `renderItem` | `renderItem` returning `CsListItem` |
| `sortable`, `sortDisabled` | `sortable`, `sortDisabled` |
| `onSortingChange` (`detail.items`) | `onSortingChange` (the list) |
| `disableItemPaddings`, `disablePaddings` | same |
| `tagOverride` (`'ol'`/`'ul'`) | `ordered` |
| `ariaLabel` | `ariaLabel` |
| `ariaLabelledby`, `ariaDescribedby` | not applicable (use `ariaLabel`) |
| `i18nStrings` | `i18nStrings` (`CsListI18nStrings`) |
