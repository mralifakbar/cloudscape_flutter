# CsContentLayout

Cloudscape's `ContentLayout`: the page frame inside the app layout content, with notifications, breadcrumbs, a page header and the content.

Cloudscape reference: https://cloudscape.design/components/content-layout/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsContentLayout(
  header: CsHeader(variant: CsHeaderVariant.h1, title: 'Distributions'),
  child: CsContainer(child: Text('d111111abcdef8')),
)
```

## When to use / when not to

Use it as the `content` of `CsAppLayout` on every page with a page header. Use `highContrast` for dashboards and landing pages where the first container should overlap a dark header band.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget?` |  | Page content |
| `header` | `Widget?` |  | Usually a `CsHeader` h1 |
| `headerVariant` | `CsContentLayoutHeaderVariant` | `defaultVariant` | `defaultVariant`, `highContrast`, `divider` |
| `headerBackgroundStyle` | `CsHeaderBackgroundBuilder?` |  | `Decoration Function(Brightness)` |
| `maxContentWidth` | `double?` |  |  |
| `disableOverlap` | `bool` | `false` |  |
| `secondaryHeader` | `Widget?` |  | Beside the header on wide screens |
| `breadcrumbs` | `Widget?` |  |  |
| `notifications` | `Widget?` |  |  |
| `defaultPadding` | `bool` | `false` | App layout padding for pages without one |

## Examples

### High contrast with a secondary header

```dart
const CsContentLayout(
  headerVariant: CsContentLayoutHeaderVariant.highContrast,
  header: CsHeader(variant: CsHeaderVariant.h1, title: 'example-bucket'),
  secondaryHeader: CsContainer(child: Text('1,204 objects')),
  child: CsContainer(child: Text('Objects')),
)
```

### Custom background

```dart
CsContentLayout(
  headerBackgroundStyle: (b) => BoxDecoration(
    gradient: LinearGradient(colors: b == Brightness.dark
        ? const [Color(0xFF0F1B2A), Color(0xFF1B2D44)]
        : const [Color(0xFFE8F1FB), Color(0xFFF7FAFD)]),
  ),
  header: const CsHeader(variant: CsHeaderVariant.h1, title: 'Dashboard'),
  child: const Text('Widgets'),
)
```

## Accessibility

The high-contrast band uses the dark header visual context, so text keeps its contrast. Content overlapping the band stays reachable and tappable.

## Motion

None.

## Mobile

The secondary header moves under the header at or below 688px. Inside `CsAppLayout` the band reaches the content edges.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `child` |
| `header` | `header` |
| `headerVariant` | `headerVariant` |
| `headerBackgroundStyle` | `headerBackgroundStyle` (builder) |
| `maxContentWidth` | `maxContentWidth` |
| `disableOverlap` | `disableOverlap` |
| `secondaryHeader` | `secondaryHeader` |
| `breadcrumbs / notifications` | same names |
| `defaultPadding` | `defaultPadding` |
