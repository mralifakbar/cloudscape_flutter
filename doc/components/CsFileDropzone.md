# CsFileDropzone

Cloudscape's `FileDropzone`: the dashed area files are dropped onto, with Cloudscape's hovered state.

Cloudscape reference: https://cloudscape.design/components/file-dropzone/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFileDropzone(
  onPick: (request) => myPicker(multiple: request.multiple),
  onChange: (files) => setState(() => uploads = [...uploads, ...files]),
  child: const Text('Drop files to upload, or tap to choose'),
)
```

## When to use / when not to

Use it for a large drop target in an upload page or panel. `CsFileUpload` already swaps its button for a dropzone while files are dragged (`dropzoneActive`), so you only need this component for custom layouts.

## Drag and drop in Flutter

Flutter has no cross-platform drag and drop of operating system files without a plugin, so the dropzone supports three sources:

- **Tap.** With `onPick`, the whole zone is a button that opens the app's picker. This is the main path on phones.
- **Your drag and drop plugin.** Wrap the zone with the plugin's drop target (`desktop_drop`, `super_drag_and_drop`), set `active` while files hover over it, and handle the drop in the plugin's callback. `active` shows the hovered colors.
- **In-app drags.** The zone is a `DragTarget` for `Draggable<CsFile>` and `Draggable<List<CsFile>>`: hovering lights it up and dropping calls `onChange`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | Centered content with a 4px gap (text, an icon, a `CsFileInput`) |
| `onChange` | `ValueChanged<List<CsFile>>?` | | Dropped or picked files |
| `onPick` | `CsFilePicker?` | | Makes the zone a button that opens the app picker |
| `active` | `bool` | `false` | Files are dragged over the zone (hovered colors) |
| `multiple` | `bool` | `true` | Passed to `onPick` |
| `accept` | `String?` | | Passed to `onPick` |
| `semanticLabel` | `String?` | | Accessible name |

## Examples

### Driven by a plugin

```dart
CsFileDropzone(
  active: draggingOver,
  child: const Text('Drop files to upload'),
)
```

### With a file input inside

```dart
CsFileDropzone(
  onChange: (files) {},
  child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('Drop files here'),
    CsFileInput(value: const [], text: 'Choose files', multiple: true, onPick: (r) async => null, onChange: (f) {}),
  ]),
)
```

## Accessibility

With `onPick` it is a button named by `semanticLabel` (Enter and Space open the picker); otherwise a labelled container. The text inside should say what to drop.

## Motion

Hovered colors switch instantly (`color-dropzone-*-hover`), as Cloudscape does on drag over.

## Mobile

Use `onPick` so a tap opens the picker; there is no drag source on phones. The zone keeps 20px padding and wraps its text at 390px.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `child` |
| `onChange` (`detail.value`) | `onChange` (`ValueChanged<List<CsFile>>`) |
| browser drag over state | `active` (or in-app `Draggable<CsFile>`) |
| (none) | `onPick`, `multiple`, `accept`, `semanticLabel` (extras) |
