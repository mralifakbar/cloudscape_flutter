# CsBadge

A small colored label for a count, a category or a severity, such as "New", "3" or "Critical".

Cloudscape reference: https://cloudscape.design/components/badge/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';

const badge = CsBadge(text: 'New', color: CsBadgeColor.blue);
```

## When to use / when not to

- Use a badge to tag an item with a short, static attribute: a count next to a heading, "Beta" next to a feature name, the severity of a finding.
- Use the severity colors (`severityCritical` to `severityNeutral`) only for severity scales, and always with the severity name as text.
- Do not use a badge for the state of a resource (running, stopped, failed): use `CsStatusIndicator`.
- A badge is not interactive. For a removable label use a token.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `text` | `String?` | `null` | Text inside the badge. Required unless `child` is set. |
| `child` | `Widget?` | `null` | Custom content in place of `text`. |
| `color` | `CsBadgeColor` | `CsBadgeColor.grey` | `blue`, `grey`, `green`, `red`, `severityCritical`, `severityHigh`, `severityMedium`, `severityLow`, `severityNeutral`. |
| `style` | `CsBadgeStyle?` | `null` | Overrides `background`, `borderColor`, `borderRadius`, `borderWidth`, `color` (text), `paddingBlock`, `paddingInline`. |
| `semanticLabel` | `String?` | `null` | Spoken instead of `text`, for example "3 unread". |

`CsBadge.colorsFor(colors, color)` returns the `(background, border, text)` token colors of a badge color.

## Examples

### Counter next to a heading

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

Widget header() => const Row(
  children: [
    Text('Instances'),
    SizedBox(width: CsSpace.xs),
    CsBadge(text: '12', semanticLabel: '12 instances'),
  ],
);
```

### Severity

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

Widget severities() => const Wrap(
  spacing: CsSpace.xs,
  children: [
    CsBadge(text: 'Critical', color: CsBadgeColor.severityCritical),
    CsBadge(text: 'High', color: CsBadgeColor.severityHigh),
    CsBadge(text: 'Medium', color: CsBadgeColor.severityMedium),
    CsBadge(text: 'Low', color: CsBadgeColor.severityLow),
    CsBadge(text: 'Informational', color: CsBadgeColor.severityNeutral),
  ],
);
```

### Custom style

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';

const beta = CsBadge(text: 'Beta', style: CsBadgeStyle(borderRadius: 16, paddingInline: 12));
```

## Accessibility

The badge's text is read as plain text. Give counts a `semanticLabel` that says what is counted. Never convey meaning by color alone: the severity colors always carry the severity word.

## Motion

None.

## Mobile

Body-s text (12px) on a 20px line with 8px side padding. Long text wraps inside the badge instead of overflowing; keep badge text to one or two words.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `color` | `color` (`'severity-critical'` is `CsBadgeColor.severityCritical`) |
| `children` | `text` or `child` |
| `style.root` | `style` (`CsBadgeStyle`) |
| `nativeAttributes` | not applicable (web only) |
