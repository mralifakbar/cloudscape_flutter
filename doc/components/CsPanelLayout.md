# CsPanelLayout

Cloudscape's `PanelLayout`: a side panel next to main content with a draggable divider.

Cloudscape reference: https://cloudscape.design/components/panel-layout/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsPanelLayout(
  resizable: true,
  panelContent: Text('Filters'),
  mainContent: Text('Results'),
)
```

## When to use / when not to

Use it for a panel that belongs to a part of the page, such as filters beside results or a list beside a preview. For page-level panels use `CsAppLayout`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `panelContent` | `Widget` |  |  |
| `mainContent` | `Widget` |  |  |
| `panelPosition` | `CsPanelPosition` | `sideStart` | `sideStart` or `sideEnd` |
| `defaultPanelSize` | `double?` |  | Defaults to `minPanelSize` or 200 |
| `panelSize` | `double?` |  | Controlled width |
| `minPanelSize` | `double?` |  |  |
| `maxPanelSize` | `double?` |  | Also capped at the layout width |
| `resizable` | `bool` | `false` | Shows the drag handle |
| `display` | `CsPanelLayoutDisplay` | `all` | `all`, `panelOnly`, `mainOnly` |
| `scrollable` | `bool` | `false` | Each side scrolls |
| `panelSemanticLabel / mainSemanticLabel` | `String?` |  |  |
| `i18nStrings` | `CsPanelLayoutI18nStrings` |  | Handle label and tooltip |
| `onPanelResize` | `ValueChanged<CsPanelResizeDetail>?` |  | `totalSize`, `panelSize` |
| `onLayoutChange` | `ValueChanged<CsPanelResizeDetail>?` |  |  |

## Examples

### Controlled

```dart
CsPanelLayout(
  resizable: true,
  panelSize: 240,
  minPanelSize: 150,
  maxPanelSize: 400,
  onPanelResize: (d) {},
  panelContent: const Text('Filters'),
  mainContent: const Text('Results'),
)
```

## Accessibility

The handle is a focusable slider: arrows resize in 10px steps, Page Up / Page Down in 60px, Home and End go to the limits.

## Motion

Resizing follows the pointer 1:1.

## Mobile

On phones show one side at a time with `display` (`panelOnly` or `mainOnly`).

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `panelContent / mainContent` | same names |
| `panelPosition` | `panelPosition` (`side-start` is `sideStart`) |
| `defaultPanelSize / panelSize / minPanelSize / maxPanelSize` | same names |
| `resizable` | `resizable` |
| `display` | `display` |
| `scrollable` | `scrollable` |
| `panelFocusable / mainFocusable` | `panelSemanticLabel` / `mainSemanticLabel` |
| `onPanelResize / onLayoutChange` | same names |
