# CsProgressBar

Cloudscape's `ProgressBar`: how far an operation of known length has got, with a label, a percentage and, when it ends, a success or error result.

Cloudscape reference: https://cloudscape.design/components/progress-bar/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsProgressBar(
  label: 'Creating snapshot',
  description: 'vol-0abc123',
  value: 42,
  additionalInfo: 'About 3 minutes remaining',
)
```

## When to use / when not to

Use a progress bar when you know how much of an operation is done. For work of unknown length use `CsSpinner` or a `CsStatusIndicator` of type `loading`. Inside a flash message use `variant: CsProgressBarVariant.flash`; as the value of a key-value pair use `keyValue`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `double` | `0` | Percent from 0 to 100, rounded for display |
| `status` | `CsProgressBarStatus` | `inProgress` | `inProgress`, `success`, `error` |
| `variant` | `CsProgressBarVariant` | `standalone` | `standalone`, `flash`, `keyValue` |
| `label` / `labelWidget` | `String?` / `Widget?` | | Name of the operation |
| `description` / `descriptionWidget` | `String?` / `Widget?` | | Small text under the label |
| `additionalInfo` / `additionalInfoWidget` | `String?` / `Widget?` | | Small text under the bar or result |
| `resultText` / `resultWidget` | `String?` / `Widget?` | | Shown with the status icon when the status is success or error |
| `resultButtonText` | `String?` | | Button after the result (not in the flash variant) |
| `onResultButtonPress` | `VoidCallback?` | | Result button pressed |
| `semanticLabel` | `String?` | `label` | Accessible name of the bar |

## Examples

### Result states

```dart
Column(
  children: [
    const CsProgressBar(label: 'Uploading index.html', status: CsProgressBarStatus.success, resultText: 'Upload complete'),
    CsProgressBar(
      label: 'Creating snapshot',
      status: CsProgressBarStatus.error,
      resultText: 'Snapshot failed',
      resultButtonText: 'Retry',
      onResultButtonPress: () {},
    ),
  ],
)
```

### Key-value

```dart
const CsProgressBar(variant: CsProgressBarVariant.keyValue, label: 'Storage used', value: 73, additionalInfo: '73 of 100 GiB')
```

## Accessibility

The bar exposes its label and its value ("42%"). While the value changes, screen readers hear "label: 42%" at most every 5 seconds (Cloudscape's assertion throttle). When the status turns to success or error, the result text is announced. The result status is an icon plus text, never color alone.

## Motion

The bar moves to each new value linearly over Cloudscape's 135ms `motion-duration-moderate`; the result state fades in over 180ms. Reduced motion makes both instant.

## Mobile

The bar takes the available width (at most 800px) with the percentage in a 33px column at the end. Label, description and result text wrap; the result button wraps below the result at narrow widths.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value`, `status`, `variant`, `resultButtonText` | same names |
| `status="in-progress"`, `variant="key-value"` | `CsProgressBarStatus.inProgress`, `CsProgressBarVariant.keyValue` |
| `label`, `description`, `additionalInfo`, `resultText` | same names, plus `*Widget` slots |
| `onResultButtonClick` | `onResultButtonPress` |
| `ariaLabel` | `semanticLabel` |
| `ariaLabelledby`, `ariaDescribedby`, `style` | not applicable |
