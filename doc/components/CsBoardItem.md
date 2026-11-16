# CsBoardItem

The container for one item on a `CsBoard` or in a `CsItemsPalette`, with a drag handle, header, settings slot, content, footer and resize handle.

Cloudscape reference: https://cloudscape.design/components/board-item/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsBoardItem(
  header: const CsHeader(title: 'Instance health'),
  settings: CsButton(variant: CsButtonVariant.icon, icon: CsIcons.ellipsis, semanticLabel: 'Settings', onPress: () {}),
  footer: const Text('Updated 2 minutes ago'),
  child: const Text('12 of 12 instances healthy'),
)
```

## When to use / when not to

- Return it from `CsBoard.renderItem` and `CsItemsPalette.renderItem`.
- Outside a board it renders as a plain container with an inert drag handle; use `CsContainer` there instead.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `header` | `Widget?` | `null` | Heading, usually a `CsHeader`. |
| `child` | `Widget?` | `null` | Main content. On a board it fills the remaining height and clips. |
| `footer` | `Widget?` | `null` | Footer below a divider. |
| `settings` | `Widget?` | `null` | Slot after the header for an overflow actions menu or a remove button. |
| `disableContentPaddings` | `bool` | `false` | Removes the content padding for full-bleed charts or tables. |
| `i18nStrings` | `CsBoardItemI18nStrings` | English | `dragHandleAriaLabel`, `dragHandleAriaDescription`, `resizeHandleAriaLabel`, `resizeHandleAriaDescription`, `dragHandleTooltipText`, `resizeHandleTooltipText`, and `addButtonAriaLabel` (the add button on palette items). |

## Examples

### Full-bleed content

```dart
const CsBoardItem(
  header: CsHeader(title: 'Requests per minute'),
  disableContentPaddings: true,
  child: SizedBox(height: 120),
)
```

### Localized handles

```dart
const CsBoardItem(
  header: CsHeader(title: 'Alarms'),
  i18nStrings: CsBoardItemI18nStrings(
    dragHandleAriaLabel: 'Move Alarms',
    resizeHandleAriaLabel: 'Resize Alarms',
    dragHandleTooltipText: 'Drag to move',
  ),
)
```

## Accessibility

Handles are labelled buttons with a hint that explains the keyboard interaction. In keyboard mode the active handle keeps a 2px `color-border-item-focused` outline. See `CsBoard` for the keys.

## Motion

The active shadow fades in over `motion-duration-responsive` when the item lifts.

## Mobile

On a board the item takes the size of its grid cells; the header wraps and the content clips rather than overflowing. Handles have 44px hit areas on touch screens.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `header` | `header` |
| `children` | `child` |
| `footer` | `footer` |
| `settings` | `settings` |
| `disableContentPaddings` | `disableContentPaddings` |
| `i18nStrings` | `i18nStrings` (optional, English defaults) |
