# CsStatusIndicator

An icon and short text for the state of a resource or process, such as "Running", "Stopped" or "3 errors".

Cloudscape reference: https://cloudscape.design/components/status-indicator/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';

const status = CsStatusIndicator(type: CsStatusType.success, text: 'Available');
```

## When to use / when not to

- Use it for the state of a resource (instance running, deployment in progress) in tables, key-value pairs and detail pages.
- Keep the text short: one to three words, or a count ("3 errors").
- Do not use it to categorize (use `CsBadge`) or for page-level messages (use an alert or flash message).

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `type` | `CsStatusType` | `CsStatusType.success` | `error`, `warning`, `success`, `info`, `stopped`, `pending`, `inProgress`, `loading`, `notStarted`, `log`. Sets icon and color. |
| `text` | `String?` | `null` | The status text. |
| `child` | `Widget?` | `null` | Custom content in place of `text`, such as a link. |
| `colorOverride` | `CsStatusColor?` | `null` | `red`, `grey`, `blue`, `green`, `yellow`: replaces the color, keeps the icon. |
| `wrapText` | `bool` | `true` | False keeps the text on one line with an ellipsis. |
| `iconAriaLabel` | `String?` | status name | Spoken before the text. Defaults to "Error", "Success" and so on; `''` speaks only the text. |
| `iconSize` | `CsIconSize` | `CsIconSize.normal` | Icon size; the loading spinner follows it. |
| `display` | `CsStatusDisplay` | `inlineBlock` | `inline` flows the icon with the text so wrapped lines start under the icon. |
| `animate` | `bool` | `false` | Fade in and shake an error icon once when first shown. |
| `embedded` | `bool` | `false` | Leaves out the status background (transparent in the default theme). |

Static helpers: `CsStatusIndicator.iconFor(type)`, `colorFor(colors, type, [override])`, `backgroundFor(colors, type, [override])`, `labelFor(strings, type)`.

## Examples

### Every type

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

Widget statuses() => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    CsStatusIndicator(type: CsStatusType.error, text: 'Failed'),
    CsStatusIndicator(type: CsStatusType.warning, text: 'Impaired'),
    CsStatusIndicator(type: CsStatusType.success, text: 'Running'),
    CsStatusIndicator(type: CsStatusType.info, text: 'Updated'),
    CsStatusIndicator(type: CsStatusType.stopped, text: 'Stopped'),
    CsStatusIndicator(type: CsStatusType.pending, text: 'Pending'),
    CsStatusIndicator(type: CsStatusType.inProgress, text: 'Stopping'),
    CsStatusIndicator(type: CsStatusType.loading, text: 'Deploying'),
    CsStatusIndicator(type: CsStatusType.notStarted, text: 'Not started'),
    CsStatusIndicator(type: CsStatusType.log, text: 'Log entry'),
  ],
);
```

### Truncated in a narrow cell

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

Widget cell() => const SizedBox(
  width: 140,
  child: CsStatusIndicator(type: CsStatusType.warning, text: 'Certificate expires soon', wrapText: false),
);
```

## Accessibility

The icon is announced before the text with the status name (`iconAriaLabel`), so the status never depends on color. The loading spinner is silent; the status name "Loading" is spoken instead.

## Motion

With `animate`, the indicator fades in over 165ms (`motion-duration-refresh-only-medium`) and an error icon shakes horizontally once. Reduced motion shows it at once.

## Mobile

The text wraps under itself by default and the icon stays on the first line. With 2x text the icon keeps its size and the text grows.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `type` | `type` (`'in-progress'` is `CsStatusType.inProgress`) |
| `children` | `text` or `child` |
| `iconAriaLabel` | `iconAriaLabel` |
| `colorOverride` | `colorOverride` |
| `wrapText` | `wrapText` |
| internal `__size`, `__display`, `__animate`, `__embedded` | `iconSize`, `display`, `animate`, `embedded` |
| `nativeAttributes` | not applicable (web only) |
