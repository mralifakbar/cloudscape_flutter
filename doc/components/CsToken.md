# CsToken

Cloudscape's `Token`: a compact, optionally dismissible representation of a chosen item, such as a selected option or an applied filter.

Cloudscape reference: https://cloudscape.design/components/token/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsToken(label: 'example-bucket', description: 'us-east-1', onDismiss: () {})
```

## When to use / when not to

Use a token for a single chosen item, alone or inline in text. For a list of tokens use `CsTokenGroup`; for a status use `CsBadge` or `CsStatusIndicator`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String?` | | Token text (or `labelWidget`) |
| `labelWidget` | `Widget?` | | Custom label |
| `labelTag` | `String?` | | Short text after the label |
| `description` | `String?` | | Small text (normal variant) |
| `tags` | `List<String>?` | | Small tags (normal variant) |
| `icon` | `CsIconData?` | | Leading icon; x-small when inline |
| `iconWidget` | `Widget?` | | Custom icon |
| `variant` | `CsTokenVariant` | `normal` | `normal` or `inline` (20px tall) |
| `disabled` | `bool` | `false` | Disabled colors; dismiss does nothing |
| `readOnly` | `bool` | `false` | Read-only colors; dismiss does nothing |
| `dismissLabel` | `String?` | "Remove <label>" | Dismiss button name |
| `onDismiss` | `VoidCallback?` | | Shows the dismiss button |
| `tooltipContent` | `String?` | | Tooltip on hover and focus |
| `ariaLabel` | `String?` | | Accessible name |

## Examples

### Inline

```dart
Wrap(spacing: 4, children: [
  CsToken(label: 'Running', variant: CsTokenVariant.inline, onDismiss: () {}),
  const CsToken(label: 'us-east-1a', variant: CsTokenVariant.inline, icon: CsIcons.locationPin),
])
```

### Read-only and disabled

```dart
Column(children: [
  CsToken(label: 'prod', readOnly: true, onDismiss: () {}),
  CsToken(label: 'archive', disabled: true, onDismiss: () {}),
])
```

## Accessibility

The token is a container with its label; the dismiss button is a separate button labelled by `dismissLabel`. Disabled and read-only tokens keep the button visible but inactive.

## Motion

None beyond the dismiss button's press feedback.

## Mobile

Labels wrap in normal tokens; inline tokens truncate with an ellipsis. The dismiss button's touch target is padded to 44px.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `label`, `labelTag`, `description`, `tags`, `variant`, `disabled`, `readOnly`, `dismissLabel`, `onDismiss`, `tooltipContent`, `ariaLabel` | same names |
| `icon` (node) | `icon` / `iconWidget` |
| `label` (node) | `labelWidget` |
| `style` | not applicable (use theme tokens) |
