# CsCopyToClipboard

Cloudscape's `CopyToClipboard`: copies a value (an ID, an ARN, a command) to the clipboard and confirms in a small popover.

Cloudscape reference: https://cloudscape.design/components/copy-to-clipboard/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsCopyToClipboard(
  variant: CsCopyToClipboardVariant.inline,
  textToCopy: 'i-0abc123',
  copySuccessText: 'Instance ID copied',
  copyErrorText: 'Instance ID failed to copy',
)
```

## When to use / when not to

Use it next to values users paste elsewhere. Don't use it for long text blocks; offer a download instead.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `textToCopy` | `String` | required | Placed on the clipboard |
| `copySuccessText` | `String` | required | Popover after success |
| `copyErrorText` | `String` | required | Popover after failure |
| `variant` | `CsCopyToClipboardVariant` | `button` | `button`, `icon`, `inline` |
| `copyButtonText` | `String?` | "Copy" | Button variant text |
| `copyButtonAriaLabel` | `String?` | "Copy to clipboard" | Icon and inline variants |
| `textToDisplay` | `String?` | `textToCopy` | Inline variant text |
| `wrapText` | `bool` | `true` | Inline text wraps or truncates |
| `disabled`, `disabledReason` | | | |
| `onCopySuccess`, `onCopyFailure` | `ValueChanged<String>?` | | |
| `mono` | `bool` | `false` | Monospace inline text |

## Examples

### Button and icon

```dart
Wrap(spacing: 8, children: const [
  CsCopyToClipboard(textToCopy: 'arn:aws:s3:::example-bucket', copyButtonText: 'Copy ARN', copySuccessText: 'ARN copied', copyErrorText: 'ARN failed to copy'),
  CsCopyToClipboard(variant: CsCopyToClipboardVariant.icon, textToCopy: 'd111111abcdef8', copySuccessText: 'Copied', copyErrorText: 'Failed to copy'),
])
```

## Accessibility

The copy control is a button; the popover content is a live region with a status icon and text. Escape and an outside tap close the popover.

## Motion

The popover scales and fades from the button (reduced motion: fade only).

## Mobile

The popover flips below when there is no room above. Inline text wraps at 390px unless `wrapText` is false.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `variant`, `textToCopy`, `textToDisplay`, `copyButtonText`, `copyButtonAriaLabel`, `copySuccessText`, `copyErrorText`, `wrapText`, `disabled`, `disabledReason` | same names |
| `onCopySuccess`, `onCopyFailure` | same names (the text) |
| `popoverRenderWithPortal` | not applicable (always in the overlay) |
