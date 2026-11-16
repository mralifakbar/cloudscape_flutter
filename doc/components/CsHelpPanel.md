# CsHelpPanel

Cloudscape's `HelpPanel`: help content for the app layout's tools panel, with a header, body and a footer of related links.

Cloudscape reference: https://cloudscape.design/components/help-panel/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsHelpPanel(
  header: 'Instances',
  child: CsHelpPanel.paragraph('An instance is a virtual server.'),
)
```

## When to use / when not to

Use it as the `tools` content of `CsAppLayout` to explain the current page. Keep it short; link to longer documentation in the footer.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `header` | `String?` |  | Panel title |
| `headerWidget` | `Widget?` |  | Custom title |
| `child` | `Widget?` |  | The help content |
| `footer` | `Widget?` |  | Related links under a divider |
| `loading` | `bool` | `false` | Spinner instead of the content |
| `loadingText` | `String?` |  | Defaults to "Loading" |

## Examples

### Text helpers

```dart
CsHelpPanel(
  header: 'Buckets',
  footer: CsLink(text: 'Bucket naming rules', onFollow: () {}),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CsHelpPanel.paragraph('Buckets hold objects.'),
      CsHelpPanel.heading('Versioning'),
      CsHelpPanel.list(const ['Enabled', 'Suspended']),
      CsHelpPanel.divider(),
      CsHelpPanel.code('aws s3 ls'),
    ],
  ),
)
```

### Loading

```dart
const CsHelpPanel(loading: true, loadingText: 'Loading help content')
```

## Accessibility

The header is a level-2 heading; `heading()` adds headings in the content. The loading text is a live region.

## Motion

None; the spinner runs only while `loading`.

## Mobile

Content wraps; in `CsAppLayout` on phones the panel opens full screen.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `header` | `header` / `headerWidget` |
| `children` | `child` |
| `footer` | `footer` |
| `loading / loadingText` | `loading` / `loadingText` |
| `(HTML content styles)` | `CsHelpPanel.heading/paragraph/list/divider/code` |
