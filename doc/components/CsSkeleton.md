# CsSkeleton

Cloudscape's `Skeleton`: a placeholder shaped like the content that is loading, so the layout does not jump when the content arrives.

Cloudscape reference: https://cloudscape.design/components/skeleton/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsSkeleton(variant: CsSkeletonVariant.textHeadingM, width: 180)
```

## When to use / when not to

Use skeletons for content whose shape you know while it loads: a heading, a few lines, a chart area. For an unknown amount of work use `CsSpinner`; for a table or list use its own loading state (`loading` + `loadingText`).

## Parameters

### CsSkeleton

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `variant` | `CsSkeletonVariant` | `dynamic` | Height of one line of the matching text step: `textBodyS`, `textBodyM`, `textHeadingXs` to `textHeadingXl`, `textDisplayL`; `dynamic` follows the surrounding text |
| `width` | `double?` | available width | Width of the bar; 160 where the width is unbounded |
| `height` | `double?` | | Block height; replaces the text line |
| `loading` | `bool` | `true` | With a `child`: shows the skeleton while true and cross-fades to the child when false |
| `child` | `Widget?` | | The content the skeleton stands in for |

### CsSkeletonLines

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `lines` | `int` | `3` | Number of lines |
| `variant` | `CsSkeletonVariant` | `textBodyM` | Line height |
| `lastLineWidthFactor` | `double` | `0.6` | Width of the last line as a share of the width |
| `spacing` | `double` | `0` | Extra gap between lines |

## Examples

### A loading summary

```dart
const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    CsSkeleton(variant: CsSkeletonVariant.textHeadingL, width: 220),
    SizedBox(height: 8),
    CsSkeletonLines(lines: 3),
    SizedBox(height: 16),
    CsSkeleton(height: 160),
  ],
)
```

### Swap to content when loaded

```dart
CsSkeleton(
  loading: false,
  variant: CsSkeletonVariant.textBodyM,
  width: 120,
  child: const Text('i-0abc123'),
)
```

## Accessibility

Skeletons are hidden from screen readers (`aria-hidden` in Cloudscape). Tell assistive technology that content is loading with the surrounding component's loading text or a `CsLiveRegion`, and announce when it has loaded.

## Motion

A soft wave (`color-background-skeleton-wave`) crosses the bar every 1.25s with ease-in-out, from start to end (mirrored in RTL). It runs only while the skeleton is on screen: it stops when the skeleton is replaced by its `child`, scrolled into an offstage route or disposed. Under reduced motion there is no wave and the bar stays still.

## Mobile

Skeletons fill the available width by default, so they reflow with the layout. Heights follow the type scale and do not grow with the text scale; the content that replaces them may be taller.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `variant="text-heading-m"` | `variant: CsSkeletonVariant.textHeadingM` |
| `width`, `height` (CSS strings) | `width`, `height` (logical pixels) |
| `display` | not applicable: use Flutter layout (`Row`, `Wrap`, `width`) |
| `tagOverride` | not applicable |
