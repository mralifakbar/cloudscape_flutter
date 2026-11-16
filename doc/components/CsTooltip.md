# CsTooltip

Cloudscape's `Tooltip`: a short text label for a control, shown on hover after a delay, at once on keyboard focus, and on long press with touch. Drawn as Cloudscape's popover container with its arrow.

Cloudscape reference: https://cloudscape.design/components/tooltip/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsTooltip(
  content: 'Copy ARN',
  child: CsButton(icon: CsIcons.copy, variant: CsButtonVariant.icon, semanticLabel: 'Copy ARN', onPress: () {}),
)
```

## When to use / when not to

Use tooltips for labels of icon-only controls and short clarifications. Never put essential information or interactive content in a tooltip: use `CsPopover` for that.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `content` | `String` | | Tooltip text |
| `child` | `Widget` | | The trigger |
| `side` | `CsSide` | `top` | Preferred side; flips when there is no room |
| `align` | `CsAlign` | `center` | |
| `delay` | `Duration` | 600ms | Hover delay; consecutive tooltips show at once |
| `closeDelay` | `Duration` | 0 | |
| `touchDuration` | `Duration` | 1500ms | How long a long-press tooltip stays |
| `disabled` | `bool` | `false` | |
| `showArrow` | `bool` | `true` | |
| `open`, `onOpenChange` | | | Control visibility from outside |

## Accessibility

The tooltip text is not a separate node; give the trigger its own label. Escape closes it.

## Motion

Fades and scales in from its trigger with Cloudscape's 115ms responsive timing; instant under reduced motion.

## Mobile

Shown on long press for `touchDuration`.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `content` | `content` |
| `position` | `side` |
| `trackRef`, `getTrack` | the `child` widget |
