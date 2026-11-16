# CsS3ResourceSelector

Cloudscape's `S3ResourceSelector`: an S3 URI input with a Browse button that opens a modal to pick a bucket, object or object version, plus a version picker and a View button.

Cloudscape reference: https://cloudscape.design/components/s3-resource-selector/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFormField(
  errorText: error,
  child: CsS3ResourceSelector(
    resource: resource,
    selectableItemsTypes: const {CsS3SelectableItems.objects},
    fetchBuckets: () async => const [CsS3Bucket(name: 'example-bucket', region: 'us-east-1')],
    fetchObjects: (bucket, path) async => const [CsS3Object(key: 'report.csv', size: 2048)],
    fetchVersions: (bucket, path) async => const [],
    onChange: (change) => setState(() {
      resource = change.resource;
      error = change.errorText;
    }),
  ),
)
```

## When to use / when not to

Use it when a form needs a location in S3-style object storage. In read mode allow `objects` and `versions`; in write mode allow `buckets` and `objects`. Use a plain `CsInput` when browsing is not possible.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `resource` | `CsS3Resource` | required | `uri` and optional `versionId` |
| `fetchBuckets` | `Future<List<CsS3Bucket>> Function()` | required | All buckets |
| `fetchObjects` | `Future<List<CsS3Object>> Function(String bucket, String path)` | required | Objects and folders under a path |
| `fetchVersions` | `Future<List<CsS3Version>> Function(String bucket, String path)` | required | Versions of an object |
| `onChange` | `ValueChanged<CsS3ResourceChange>?` |  | New resource and a validation `errorText` |
| `selectableItemsTypes` | `Set<CsS3SelectableItems>` | `{}` | `buckets`, `objects`, `versions` |
| `alert` | `Widget?` |  | Shown in the modal above the table |
| `inputPlaceholder`, `ariaLabel` | `String?` |  | URI input |
| `onView` | `VoidCallback?` |  | Opens the selected object; null disables View |
| `invalid` | `bool` | `false` | Invalid style on the URI input |
| `bucketsVisibleColumns` | `List<String>?` |  | `Name`, `CreationDate`, `Region` |
| `objectsVisibleColumns` | `List<String>?` |  | `Key`, `LastModified`, `Size` |
| `versionsVisibleColumns` | `List<String>?` |  | `ID`, `LastModified`, `Size` |
| `bucketsIsItemDisabled`, `objectsIsItemDisabled`, `versionsIsItemDisabled` | `bool Function(T)?` |  | Override selectability |
| `onInputFocus`, `onInputBlur` | `VoidCallback?` |  |  |
| `i18nStrings` | `CsS3ResourceSelectorI18nStrings` | English | All copy |

Helpers: `csS3ValidateUri(uri)`, `csS3SplitUri(uri)`, `csS3FormatSize(bytes)`. `CsS3ResourceSelectorState.focus()` focuses the input.

## Examples

### Versions in read mode

```dart
CsS3ResourceSelector(
  resource: resource,
  selectableItemsTypes: const {CsS3SelectableItems.objects, CsS3SelectableItems.versions},
  objectsIsItemDisabled: (object) => object.isFolder,
  fetchBuckets: listBuckets,
  fetchObjects: listObjects,
  fetchVersions: listVersions,
  onChange: (change) => setState(() => resource = change.resource),
)
```

## Behavior

- Validation runs once the input has lost focus once: the URI must start with `s3://`, and the bucket name must start with a lowercase letter or digit, have no uppercase letters, be 3 to 63 characters and follow DNS naming.
- With `versions` selectable, leaving the input loads the versions of a valid URI into the version picker ("Loading resource" shows meanwhile).
- The modal lists buckets, then objects under folders (breadcrumbs go back), then versions. Each table fetches once, then filters, sorts and pages 10 items locally; Refresh reloads and shows the time. Choose is enabled once an item is selected.

## Accessibility

The URI input is labeled "S3 URI"; the version picker is an expandable button with its value; the View button announces that it opens a new tab. The modal traps focus and closes on Escape. Tables use radios labeled per item; folder and object icons are labeled.

## Motion

The modal uses `CsDialogRoute` motion; the version list opens with `CsDropdown`. Reduced motion makes both instant.

## Mobile

Below 600px the URI input, version picker and buttons stack. The modal takes the screen width less 12px each side, and its tables scroll sideways with the first column stuck. The version picker opens as a bottom sheet on phones.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `resource`, `onChange` detail `{resource, errorText}` | `CsS3Resource`, `CsS3ResourceChange` |
| `fetchBuckets` etc. returning promises | functions returning `Future` |
| Bucket `Name`, Object `Key`/`IsFolder`, Version `VersionId` | `name`, `key`/`isFolder`, `versionId` |
| `selectableItemsTypes` array | `Set<CsS3SelectableItems>` |
| `viewHref` | `onView` |
| `labelsPagination`, `labelExpandBreadcrumbs` | local pager labels `labelPreviousPage`, `labelNextPage` |
| `getModalRoot`, `removeModalRoot`, `ariaLabelledby`, `ariaDescribedby`, `inputAriaDescribedby` | web only, not ported |
