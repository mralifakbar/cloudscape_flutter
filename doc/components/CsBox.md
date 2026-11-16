# CsBox

Cloudscape's `Box`: the text and spacing primitive. A `variant` gives semantic text styles (headings, paragraph, small, code, key label, large value), with overrides for size, weight and color, and token-based padding and margin. `CsVisualAccent` is Box's `visualAccent`.

Cloudscape reference: https://cloudscape.design/components/box/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsBox(variant: CsBoxVariant.h1, text: 'Distributions')
```

## When to use / when not to

Use `CsBox` for any text that needs a Cloudscape style: headings outside a `CsHeader`, paragraphs, descriptions, key-value labels, large dashboard values, inline code. For page and container titles with actions use `CsHeader`; for long formatted content use `CsTextContent`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `text` | `String?` | | Text content |
| `child` | `Widget?` | | Any content; receives the variant's text style |
| `variant` | `CsBoxVariant` | `div` | `div`, `span`, `h1`-`h5`, `p`, `strong`, `small`, `code`, `pre`, `samp`, `awsuiKeyLabel`, `awsuiGenAiLabel`, `awsuiValueLarge`, `awsuiInlineCode` |
| `color` | `CsBoxColor` | `defaultColor` | `inherit`, `textLabel`, `textBodySecondary`, `textStatusError`, `textStatusSuccess`, `textStatusInfo`, `textStatusInactive`, `textStatusWarning`, `inverted` |
| `fontSize` | `CsTypeScale?` | | Overrides the variant's size |
| `fontWeight` | `CsBoxFontWeight?` | | `light`, `normal`, `bold`, `heavy` |
| `textAlign` | `TextAlign?` | | |
| `padding`, `margin` | `CsBoxSpacing?` | | Per-side `CsSpacingSize` (`n`, `xxxs` to `xxxl`); headings and `p` default to 4px vertical padding |
| `maxLines`, `overflow` | | | |

`CsVisualAccent(color:, child:, equalAspect:, radius:, fullyRounded:)` draws a tinted tile behind an icon or short label.

## Examples

### Headings and text

```dart
const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  CsBox(variant: CsBoxVariant.h2, text: 'Origin settings'),
  CsBox(variant: CsBoxVariant.p, text: 'Choose where CloudFront gets your content.'),
  CsBox(variant: CsBoxVariant.small, text: 'Changes take a few minutes to deploy.'),
])
```

### Key-value and large value

```dart
const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  CsBox(variant: CsBoxVariant.awsuiKeyLabel, text: 'Running instances'),
  CsBox(variant: CsBoxVariant.awsuiValueLarge, text: '14'),
])
```

### Status color and inline code

```dart
const Wrap(spacing: 4, children: [
  CsBox(color: CsBoxColor.textStatusError, text: 'Validation failed.'),
  CsBox(variant: CsBoxVariant.awsuiInlineCode, text: 'aws s3 ls'),
])
```

### Visual accent

```dart
const CsVisualAccent(color: CsVisualAccentColor.indigo, equalAspect: true, child: CsIcon(CsIcons.globe))
```

## Accessibility

Heading variants (`h1`-`h5`) are marked as headings. Color is never the only signal: pair status colors with words or a `CsStatusIndicator`.

## Motion

None.

## Mobile

Text wraps; use `maxLines` with `overflow` only where the full value is reachable elsewhere.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `variant="awsui-key-label"` | `variant: CsBoxVariant.awsuiKeyLabel` |
| `color="text-body-secondary"` | `color: CsBoxColor.textBodySecondary` |
| `fontSize="heading-m"` | `fontSize: CsTypeScale.headingM` |
| `fontWeight`, `textAlign` | same names |
| `padding={{ vertical: 's' }}` | `padding: CsBoxSpacing.symmetric(vertical: CsSpacingSize.s)` |
| `margin` | `margin` |
| `visualAccent` | `CsVisualAccent` |
| `display`, `float`, `tagOverride` | not applicable (use Flutter layout) |
