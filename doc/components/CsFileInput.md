# CsFileInput

Cloudscape's `FileInput`: a button (or icon button) that opens a file picker, for custom upload flows.

Cloudscape reference: https://cloudscape.design/components/file-input/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFileInput(
  value: files,
  text: 'Choose file',
  accept: '.json',
  onPick: (request) => myPicker(multiple: request.multiple, accept: request.accept),
  onChange: (picked) => setState(() => files = picked),
)
```

## When to use / when not to

Use it when the chosen files are shown somewhere else (a chat composer, a table) or when you need an icon-only upload trigger. For the standard form control with file tokens, constraint and validation text use `CsFileUpload`.

## The picker

The package has no file picker dependency. `onPick` receives a `CsFilePickRequest` (`multiple`, `accept`) and returns the user's choice as `List<CsFile>` (or null when cancelled). Wire it to the picker your app already uses; for example with `file_picker`:

```dart
Future<List<CsFile>?> pick(CsFilePickRequest request) async {
  final result = await myFilePicker(allowMultiple: request.multiple);
  if (result == null) return null;
  return [
    for (final f in result)
      CsFile(name: f.name, size: f.size, type: f.mimeType ?? '', lastModified: f.modified, data: f.path),
  ];
}
```

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `List<CsFile>` | required | The selected files (not drawn by the input) |
| `onPick` | `CsFilePicker?` | | Opens the app's picker; null disables the button |
| `onChange` | `ValueChanged<List<CsFile>>?` | | The picked files (only the first one unless `multiple`) |
| `text` | `String?` | | Button text, also the accessible name without `ariaLabel` |
| `variant` | `CsFileInputVariant` | `button` | `button` or `icon` (needs `ariaLabel`) |
| `ariaLabel` | `String?` | | |
| `accept` | `String?` | | Allow-list passed to `onPick` (`'image/*,.pdf'`) |
| `multiple` | `bool` | `false` | |
| `ariaRequired` | `bool` | `false` | Announced as required |
| `invalid` | `bool` | `false` | Announced as invalid |
| `warning` | `bool` | `false` | |
| `disabled` | `bool` | `false` | |
| `focusNode` | `FocusNode?` | | Focus the button (Cloudscape `ref.focus()`) |

`CsFile`: `name`, `size` (bytes), `lastModified`, `type` (MIME), `thumbnail` (`ImageProvider?`), `data` (your payload), `isImage`.

## Examples

### Icon variant

```dart
CsFileInput(
  value: const [],
  variant: CsFileInputVariant.icon,
  ariaLabel: 'Attach file',
  onPick: (request) async => null,
  onChange: (files) {},
)
```

## Accessibility

A button named by `ariaLabel` or `text`, with "Required" and "Error" hints when `ariaRequired` or `invalid`. Tab focuses, Enter and Space open the picker.

## Motion

`CsButton`'s press feedback.

## Mobile

The button keeps Cloudscape's size with a 44px touch target. Pick from the platform's document or photo picker in `onPick`.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value`, `variant`, `ariaLabel`, `accept`, `multiple`, `ariaRequired`, `invalid`, `warning` | same names |
| `children` | `text` |
| `onChange` (`detail.value`) | `onChange` (`ValueChanged<List<CsFile>>`) |
| native file dialog | `onPick` (your picker) |
| `File` | `CsFile` |
| `ref.focus()` | `focusNode` |
| `controlId`, `ariaDescribedby`, `ariaLabelledby` | not applicable |
