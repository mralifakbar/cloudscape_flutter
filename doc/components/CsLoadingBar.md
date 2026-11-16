# CsLoadingBar

A 2px animated gradient bar that shows a generative AI process is running.

Cloudscape reference: https://cloudscape.design/components/loading-bar/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsLoadingBar(variant: CsLoadingBarVariant.genAi)
```

## When to use / when not to

- Use while a gen-AI response streams, at the top or bottom edge of the area that will receive it.
- Use `genAiMasked` at the edge of an element with rounded corners; `CsChatBubble(showLoadingBar: true)` already does this.
- Remove the bar when the process ends: it loops only while it is mounted.
- For non-AI loading use `CsSpinner` or a progress bar.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `variant` | `CsLoadingBarVariant` | `genAi` | `genAi` (full width) or `genAiMasked` (fades out over the first and last 30%). |
| `semanticLabel` | `String?` | `null` | Optional accessible name. The bar is decorative by default, as in Cloudscape. |

`CsLoadingBar.height` is 2. The gradient comes from `CsGenAiGradients.loadingBar` (token `colorBackgroundLoadingBarGenAi`).

## Examples

### Masked bar under a custom card

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: const [
    Text('Summarizing 42 log groups'),
    SizedBox(height: 8),
    CsLoadingBar(variant: CsLoadingBarVariant.genAiMasked),
  ],
)
```

## Accessibility

The bar is not announced. Tell screen reader users about the process another way: set the avatar's `loading` with an `ariaLabel` such as "Generating a response", or pass `semanticLabel`.

## Motion

The gradient tile is twice the bar's width and slides one tile every 3 seconds (`cubic-bezier(0, 0.08, 1, 0.82)`), reversed in RTL, and fades in over `motion-duration-complex`. Under reduced motion it is a still gradient.

## Mobile

Full width at every size; nothing to adapt.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `variant` | `variant` (`'gen-ai'` is `genAi`, `'gen-ai-masked'` is `genAiMasked`) |
