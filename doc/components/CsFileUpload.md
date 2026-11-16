# CsFileUpload

Cloudscape's `FileUpload`: a "Choose file" button with constraint and validation text, and the chosen files as tokens.

Cloudscape reference: https://cloudscape.design/components/file-upload/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFormField(
  label: 'Certificate',
  stretch: true,
  child: CsFileUpload(
    value: files,
    accept: '.pem,.crt',
    constraintText: 'PEM or CRT, up to 1 MB.',
    showFileSize: true,
    onPick: (request) => myPicker(multiple: request.multiple),
    onChange: (next) => setState(() => files = next),
  ),
)
```

## When to use / when not to

Use it in forms where users attach one or more files. Validate files in your app and pass the messages as `errorText`, `fileErrors` and `fileWarnings`. For a bare picker button use `CsFileInput`; for a large drop area use `CsFileDropzone`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `List<CsFile>` | required | |
| `onChange` | `ValueChanged<List<CsFile>>?` | | The next list: picks append when `multiple`, replace otherwise; dismiss removes |
| `onPick` | `CsFilePicker?` | | Opens the app's picker (see `CsFileInput`); null disables the button |
| `accept` | `String?` | | Allow-list passed to `onPick` |
| `multiple` | `bool` | `false` | Also switches "Choose file" to "Choose files" |
| `ariaRequired` | `bool` | `false` | |
| `showFileSize`, `showFileLastModified`, `showFileThumbnail` | `bool` | `false` | Token metadata |
| `tokenLimit` | `int?` | | Tokens shown before "Show more" |
| `constraintText` | `String?` | | File rules under the button |
| `errorText` | `String?` | | |
| `warningText` | `String?` | | Shown only without `errorText` |
| `fileErrors`, `fileWarnings` | `List<String?>?` | | Per file, by index |
| `fileLoading` | `List<bool>?` | | Per-file spinner (extra) |
| `fileTokenAlignment` | `CsFileTokenGroupAlignment` | `vertical` | |
| `dropzoneActive` | `bool` | `false` | Show the dropzone in place of the button (files dragged over the app) |
| `invalid` | `bool` | `false` | Implied by `errorText` and `fileErrors` |
| `disabled`, `readOnly` | `bool` | `false` | |
| `focusNode` | `FocusNode?` | | Focus the button (Cloudscape `ref.focus()`) |
| `i18nStrings` | `CsFileUploadI18nStrings` | English | `uploadButtonText(multiple)`, `dropzoneText(multiple)`, `removeFileAriaLabel`, `limitShowMore`, `limitShowFewer`, `errorIconAriaLabel`, `warningIconAriaLabel`, `formatFileSize`, `formatFileLastModified` |

## Examples

### Multiple files with per-file errors

```dart
CsFileUpload(
  value: files,
  multiple: true,
  tokenLimit: 3,
  showFileSize: true,
  fileErrors: [for (final f in files) f.size > 1000000 ? 'Files must be 1 MB or smaller.' : null],
  constraintText: 'Up to 10 files, 1 MB each.',
  onPick: (request) async => null,
  onChange: (next) {},
)
```

### Dropzone while dragging

```dart
CsFileUpload(
  value: files,
  multiple: true,
  dropzoneActive: draggingOverWindow,
  onChange: (next) {},
)
```

## Accessibility

The button is named "Choose file(s)" with required and invalid hints. Error and warning text are announced with icon labels; constraint text follows them. Tokens behave as in `CsFileTokenGroup`; their remove buttons are "Remove file n".

## Motion

None of its own.

## Mobile

The button stays at its natural width; tokens stack full width below 688px. On phones, `onPick` opens the platform document or photo picker; drag states do not apply.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value`, `accept`, `multiple`, `ariaRequired`, `showFileSize`, `showFileLastModified`, `showFileThumbnail`, `tokenLimit`, `constraintText`, `errorText`, `warningText`, `fileErrors`, `fileWarnings`, `fileTokenAlignment`, `invalid`, `i18nStrings` | same names |
| `onChange` (`detail.value`) | `onChange` (`ValueChanged<List<CsFile>>`) |
| native file dialog | `onPick` |
| browser drag detection | `dropzoneActive` (or in-app `Draggable<CsFile>`) |
| `ref.focus()` | `focusNode` |
| `controlId`, `ariaDescribedby`, `ariaLabelledby` | not applicable |
