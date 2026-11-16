# CsVisualContext

Recolors a subtree the way Cloudscape's `awsui-context-*` classes do: the always-dark top navigation and high-contrast header, and the inside of flash messages and alerts.

Cloudscape reference: https://cloudscape.design/foundation/visual-foundation/visual-context/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsVisualContext(
  context: CsVisualContextName.header,
  child: CsHeader(variant: CsHeaderVariant.h1, title: 'Amazon S3'),
)
```

## When to use / when not to

For custom dark headers and bars that should look like Cloudscape's. Components that need a context already apply it (`CsTopNavigation`, `CsFlashbar`, `CsAlert`, `CsContentLayout` with a high-contrast header).

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `context` | `CsVisualContextName` | | `topNavigation`, `header`, `appLayoutToolbar`, `flashbar`, `flashbarWarning`, `alert`, `alertHeader` |
| `child` | `Widget` | | |

## Accessibility

Contexts keep Cloudscape's contrast: text tokens change together with backgrounds.

## Motion

None.

## Mobile

Same.

## Cloudscape React mapping

| Cloudscape | Flutter |
| --- | --- |
| `className="awsui-context-top-navigation"` | `CsVisualContext(context: CsVisualContextName.topNavigation)` |
| `awsui-context-content-header` | `CsVisualContextName.header` |
