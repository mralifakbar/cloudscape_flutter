# CsSpinner

Cloudscape's `Spinner`: shows that a short, unknown amount of work is in progress.

Cloudscape reference: https://cloudscape.design/components/spinner/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsSpinner()
```

## When to use / when not to

Use it for waits of a few seconds where the length is unknown: loading a list, saving. For a measurable operation use `CsProgressBar`; for content that is loading in place use `CsSkeleton` or the component's `loading` state.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `size` | `CsSpinnerSize` | `normal` | `normal` 16, `big` 32, `large` 48 |
| `variant` | `CsSpinnerVariant` | `normal` | `normal` (current color), `disabled`, `inverted` |
| `semanticLabel` | `String?` | `CsStrings.loading` | Pass `''` when nearby text already says what is loading |
| `dangerouslySetColor` | `Color?` | | |

## Examples

### With text

```dart
const Row(children: [CsSpinner(semanticLabel: ''), SizedBox(width: 4), CsBox(text: 'Loading instances')])
```

## Accessibility

Announced as a live region with "Loading" unless `semanticLabel` is empty.

## Motion

The ring turns every 0.7s while its halves grow and shrink every 1.5s, as in Cloudscape. Under reduced or disabled motion the halves stop pulsing and only the rotation remains, so loading never looks stuck. The animation stops when the spinner leaves the tree.

## Mobile

Same on every size.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `size`, `variant` | same names |
