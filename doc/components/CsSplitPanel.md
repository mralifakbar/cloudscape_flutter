# CsSplitPanel

Cloudscape's `SplitPanel`: a secondary panel, usually details of the selected item, under or beside the content of an app layout.

Cloudscape reference: https://cloudscape.design/components/split-panel/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsAppLayout(
  content: const Text('Instances table'),
  splitPanel: const CsSplitPanel(header: 'i-0abc123', child: Text('Instance details')),
)
```

## When to use / when not to

Use it to show details of a selection without leaving the page. Put it in `CsAppLayout.splitPanel`; the layout owns its open state, position and size. Used on its own it renders as an open bottom panel that collapses into its header.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` |  | Panel content |
| `header` | `String?` |  | Title |
| `headerWidget` | `Widget?` |  |  |
| `headerActions` | `Widget?` |  |  |
| `headerDescription` | `String?` |  |  |
| `headerInfo` | `Widget?` |  |  |
| `headerBefore` | `Widget?` |  |  |
| `closeBehavior` | `CsSplitPanelCloseBehavior` | `collapse` | `collapse` keeps a bar; `hide` removes it and the layout shows a trigger |
| `hidePreferencesButton` | `bool` | `false` |  |
| `i18nStrings` | `CsSplitPanelI18nStrings` |  | Button labels and preferences copy |
| `semanticLabel` | `String?` |  | Defaults to `header` |

## Examples

### Hidden when closed

```dart
CsAppLayout(
  splitPanelOpen: false,
  onSplitPanelToggle: (open) {},
  splitPanel: const CsSplitPanel(
    header: 'example-bucket',
    closeBehavior: CsSplitPanelCloseBehavior.hide,
    child: Text('Bucket details'),
  ),
  content: const Text('Buckets'),
)
```

## Accessibility

The panel is a named region with a level-2 heading. Open, close and preferences buttons are labelled; the resize handle is a focusable slider (arrows 10px, Page Up / Page Down 60px). The preferences dialog traps focus and closes with Escape.

## Motion

Resizing follows the pointer 1:1; the preferences dialog uses `CsDialogRoute`.

## Mobile

On phones the panel always docks at the bottom, the preferences button hides, and opening it covers the screen.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `header` | `header` / `headerWidget` |
| `children` | `child` |
| `headerActions / headerDescription / headerInfo / headerBefore` | same names |
| `closeBehavior` | `closeBehavior` |
| `hidePreferencesButton` | `hidePreferencesButton` |
| `i18nStrings` | `i18nStrings` |
| `ariaLabel` | `semanticLabel` |
| `(open, size, position)` | `CsAppLayout.splitPanelOpen`, `splitPanelSize`, `splitPanelPosition` |
