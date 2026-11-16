# CsFileTokenGroup

Cloudscape's `FileTokenGroup`: chosen files as tokens with name, size, date and image thumbnail, a dismiss button, and loading, error and warning states.

Cloudscape reference: https://cloudscape.design/components/file-token-group/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFileTokenGroup(
  items: [for (final f in files) CsFileTokenGroupItem(file: f)],
  showFileSize: true,
  onDismiss: (i) => setState(() => files = [...files]..removeAt(i)),
)
```

## When to use / when not to

Use it to show files attached somewhere other than a `CsFileUpload` (a chat prompt, a support case) or to show per-file upload progress. `CsFileUpload` already renders one for its value.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<CsFileTokenGroupItem>` | required | `file`, `loading`, `errorText`, `warningText` |
| `onDismiss` | `ValueChanged<int>?` | | Gets the index; the group does not remove tokens itself |
| `showFileSize` | `bool` | `false` | `482.13 KB` (decimal units) |
| `showFileLastModified` | `bool` | `false` | `2024-01-15T13:45:00` |
| `showFileThumbnail` | `bool` | `false` | 48px preview for image files |
| `thumbnailBuilder` | `Widget Function(BuildContext, CsFile)?` | | Custom preview; defaults to `CsFile.thumbnail` or a file icon |
| `limit` | `int?` | | Tokens shown before "Show more (+N)" |
| `alignment` | `CsFileTokenGroupAlignment` | `vertical` | `vertical` or `horizontal` (230px grid) |
| `readOnly` | `bool` | `false` | Dismiss buttons disabled |
| `limitShowMoreAriaLabel`, `limitShowFewerAriaLabel` | `String?` | | |
| `i18nStrings` | `CsFileTokenGroupI18nStrings` | English | `limitShowMore`, `limitShowFewer`, `removeFileAriaLabel`, `errorIconAriaLabel`, `warningIconAriaLabel`, `formatFileSize`, `formatFileLastModified` |

## Examples

### Upload progress and validation

```dart
CsFileTokenGroup(
  items: [
    CsFileTokenGroupItem(file: const CsFile(name: 'diagram.png', size: 1200000, type: 'image/png'), loading: true),
    CsFileTokenGroupItem(file: const CsFile(name: 'server.crt', size: 2048), errorText: 'The certificate has expired.'),
    CsFileTokenGroupItem(file: const CsFile(name: 'policy.json', size: 912), warningText: 'Public read access.'),
  ],
  showFileSize: true,
  showFileThumbnail: true,
  onDismiss: (i) {},
)
```

### Horizontal with a limit

```dart
CsFileTokenGroup(
  items: [for (final f in files) CsFileTokenGroupItem(file: f)],
  alignment: CsFileTokenGroupAlignment.horizontal,
  limit: 3,
  onDismiss: (i) {},
)
```

## Accessibility

Each token is a group named "file name, n of total" (plus "Loading" while loading); its dismiss button is "Remove file n, name". Errors and warnings are announced with their icon labels. After a dismiss, focus moves to the token that took its place, else the previous token, else the "Show more" toggle. The toggle announces its expanded state. Long names truncate with an ellipsis and show in full in a tooltip.

## Motion

None of its own; the loading spinner runs only while `loading` is true.

## Mobile

Below 688px a horizontal group falls back to one full-width token per line, as Cloudscape does.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items`, `showFileSize`, `showFileLastModified`, `showFileThumbnail`, `limit`, `alignment`, `readOnly`, `limitShowFewerAriaLabel`, `limitShowMoreAriaLabel`, `i18nStrings` | same names |
| `onDismiss` (`detail.fileIndex`) | `onDismiss` (`ValueChanged<int>`) |
| `Item.file` (`File`) | `CsFileTokenGroupItem.file` (`CsFile`) |
| (none) | `thumbnailBuilder` (extra) |
