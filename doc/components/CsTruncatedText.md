# CsTruncatedText

Text that ends with an ellipsis when it does not fit and shows the full text in a tooltip on hover, keyboard focus or tap.

Cloudscape reference: https://cloudscape.design/components/truncated-text/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';

const path = CsTruncatedText('arn:aws:s3:::example-bucket/logs/2026/11/16/distribution-d111111abcdef8.gz');
```

## When to use / when not to

- Use it for long identifiers, paths and names in narrow places: table cells, key-value pairs, cards, breadcrumbs.
- Use `maxLines` above 1 to clamp a description to a few lines.
- Do not truncate text people need to read in full to act (error messages, instructions): let it wrap.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `text` | `String` | required (positional) | The text. |
| `maxLines` | `int` | `1` | Lines before the ellipsis. |
| `tooltipText` | `String?` | `text` | Tooltip content when it should differ from the text. |
| `style` | `TextStyle?` | `null` | Merged over the surrounding text style. |
| `textAlign` | `TextAlign?` | `null` | Alignment of the text. |

## Examples

### In a narrow cell

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

Widget cell() => const SizedBox(
  width: 160,
  child: CsTruncatedText('distribution-d111111abcdef8.cloudfront.example'),
);
```

### Clamped description

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';

const description = CsTruncatedText(
  'Serves static assets for the storefront from example-bucket through every edge location, '
  'with logs delivered to logs-bucket.',
  maxLines: 2,
);
```

## Accessibility

Screen readers always read the full text. Only truncated text is interactive: it joins the Tab order, keyboard focus shows the tooltip with a focus ring drawn inside the text, and Escape hides it. Text that fits is plain text with no tooltip and no tab stop.

## Motion

The tooltip scales and fades in from the text (the shared popover motion of `CsAnchoredOverlay`); reduced motion leaves only the fade.

## Mobile

On touch screens a tap toggles the tooltip and a tap elsewhere closes it. Truncation is measured at the current width and text scale, so rotating the device or changing the text size updates it.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `text` |
| `tooltipText` | `tooltipText` |
| (single line only) | `maxLines` (extra) |
