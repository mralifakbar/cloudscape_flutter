# CsTokenGroup

Cloudscape's `TokenGroup`: a list of dismissible tokens with an optional limit and "Show more" toggle.

Cloudscape reference: https://cloudscape.design/components/token-group/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsTokenGroup(
  items: const [
    CsTokenGroupItem(label: 'example-bucket', description: 'us-east-1'),
    CsTokenGroupItem(label: 'logs-bucket', description: 'eu-west-1'),
  ],
  onDismiss: (index) {},
)
```

## When to use / when not to

Use it to show and remove several chosen items, for example under a file upload or a custom multi-value field. `CsMultiselect` already shows its own tokens.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<CsTokenGroupItem>` | required | `label`, `labelTag`, `description`, `tags`, `icon`, `iconWidget`, `disabled`, `dismissLabel` |
| `onDismiss` | `ValueChanged<int>?` | | Index of the dismissed token; without it there is no dismiss button |
| `limit` | `int?` | | Tokens shown before "Show more (+N)" |
| `alignment` | `CsTokenGroupAlignment` | `horizontal` | `horizontal` (wrap) or `vertical` |
| `disableOuterPadding` | `bool` | `false` | Drops the 8px top padding |
| `readOnly` | `bool` | `false` | |
| `i18nStrings` | `CsTokenGroupI18nStrings` | English | `limitShowMore`, `limitShowFewer` |
| `limitShowMoreAriaLabel`, `limitShowFewerAriaLabel` | `String?` | | |

## Examples

### Vertical with a limit

```dart
CsTokenGroup(
  alignment: CsTokenGroupAlignment.vertical,
  limit: 2,
  items: const [
    CsTokenGroupItem(label: 'report.csv', labelTag: '12 KB', icon: CsIcons.file),
    CsTokenGroupItem(label: 'chart.png', labelTag: '80 KB', icon: CsIcons.file),
    CsTokenGroupItem(label: 'notes.txt', labelTag: '1 KB', icon: CsIcons.file),
  ],
  onDismiss: (index) {},
)
```

## Accessibility

The group is a container; each dismiss button is labelled "Remove <label>" unless `dismissLabel` is set. The limit toggle announces its expanded state.

## Motion

None.

## Mobile

Horizontal tokens wrap to new lines at 390px.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items`, `limit`, `alignment`, `disableOuterPadding`, `readOnly`, `i18nStrings`, `limitShowMoreAriaLabel`, `limitShowFewerAriaLabel` | same names |
| `onDismiss` (`detail.itemIndex`) | `onDismiss` (index) |
