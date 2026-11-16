# CsContainer

Cloudscape's `Container`: the standard panel for a block of related content, with an optional header, footer and media.

Cloudscape reference: https://cloudscape.design/components/container/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsContainer(
  header: const CsHeader(title: 'General configuration'),
  footer: CsButton(text: 'Edit', onPress: () {}),
  child: const CsBox(text: 'Price class: use all edge locations'),
)
```

## When to use / when not to

Use a container to group related content and actions on a page. Use `CsExpandableSection` with the container variant for optional content, `CsTabs` with the container variant for switching views, and plain spacing (`CsSpaceBetween`) rather than nested containers inside a container.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget?` |  | The content (Cloudscape `children`) |
| `header` | `Widget?` |  | Usually a `CsHeader` (h2) |
| `footer` | `Widget?` |  | Content under a divider |
| `media` | `CsContainerMedia?` |  | Image or video at the top or side (`content`, `position`, `width`, `height`) |
| `variant` | `CsContainerVariant` | `defaultVariant` | `defaultVariant` or `stacked` |
| `stackPosition` | `CsStackPosition` | `only` | `first`, `middle`, `last` or `only` for stacked containers |
| `disableHeaderPaddings` | `bool` | `false` |  |
| `disableContentPaddings` | `bool` | `false` | For content with its own padding (tables, maps) |
| `disableFooterPaddings` | `bool` | `false` |  |
| `fitHeight` | `bool` | `false` | Fill the parent height; the content takes the rest |
| `footerDivider` | `bool` | `true` | Divider above the footer |
| `style` | `CsContainerStyle?` |  | Background, border, radius, shadow and padding overrides |
| `semanticLabel` | `String?` |  | Name of the container region |

## Examples

### Stacked

```dart
const Column(
  children: [
    CsContainer(variant: CsContainerVariant.stacked, stackPosition: CsStackPosition.first, child: Text('Origin')),
    CsContainer(variant: CsContainerVariant.stacked, stackPosition: CsStackPosition.last, child: Text('Behaviors')),
  ],
)
```

### Side media

```dart
CsContainer(
  media: CsContainerMedia(
    content: Image.network('https://example.com/preview.png', fit: BoxFit.cover),
    position: CsContainerMediaPosition.side,
    width: 160,
  ),
  header: const CsHeader(title: 'Preview'),
  child: const Text('Sample media'),
)
```

### Equal heights in a row

```dart
const SizedBox(
  height: 160,
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: CsContainer(fitHeight: true, header: CsHeader(title: 'Requests'), child: Text('1,024'))),
      SizedBox(width: 20),
      Expanded(child: CsContainer(fitHeight: true, header: CsHeader(title: 'Errors'), child: Text('3'))),
    ],
  ),
)
```

## Accessibility

The container is a semantic container; pass `semanticLabel` to name it. Its header keeps the heading semantics of `CsHeader`.

## Motion

None. Hover and selection belong to the content.

## Mobile

Side media moves above the content at or below 688px. Padding stays at 20px; text wraps at 2x scale.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `header` | `header` |
| `children` | `child` |
| `footer` | `footer` |
| `media {content, position, width, height}` | `media: CsContainerMedia(...)` |
| `variant` | `variant` |
| `(sibling selectors)` | `stackPosition` |
| `disableHeaderPaddings / disableContentPaddings / disableFooterPaddings` | same names |
| `fitHeight` | `fitHeight` |
| `style` | `style: CsContainerStyle(...)` |
| `analyticsMetadata` | not supported (web only) |
