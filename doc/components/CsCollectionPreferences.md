# CsCollectionPreferences

Cloudscape's `CollectionPreferences`: a settings button for a table or cards that opens a modal with page size, line wrapping, striped rows, density, sticky columns, column order and visibility, and custom preferences.

Cloudscape reference: https://cloudscape.design/components/collection-preferences/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsCollectionPreferences<void>(
  preferences: prefs,
  onConfirm: (next) => setState(() => prefs = next),
  pageSizePreference: const CsPageSizePreference(
    options: [
      CsPageSizeOption(value: 10, label: '10 instances'),
      CsPageSizeOption(value: 20, label: '20 instances'),
    ],
  ),
  wrapLinesPreference: const CsCheckboxPreference(),
  stripedRowsPreference: const CsCheckboxPreference(),
  contentDensityPreference: const CsCheckboxPreference(),
  contentDisplayPreference: const CsContentDisplayPreference(
    options: [
      CsContentDisplayOption(id: 'id', label: 'Instance ID', alwaysVisible: true),
      CsContentDisplayOption(id: 'state', label: 'State'),
    ],
  ),
)
```

Pass it to the `preferences` slot of `CsTable` or `CsCards`, and feed the confirmed values back: `pageSize` to your `CsCollectionPagination`, `wrapLines`, `stripedRows`, `contentDensity`, `stickyColumns` and `contentDisplay` (as `columnDisplay`) to the table, `visibleContent` to `CsCards.visibleSections`.

## When to use / when not to

Use it on collections where people work for long periods and want control over density and columns. Keep it out of small, read-only lists.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `preferences` | `CsCollectionPreferencesValue<C>` | empty | Current values; the modal starts from them |
| `onConfirm` | `ValueChanged<CsCollectionPreferencesValue<C>>?` |  | Every configured preference, even unchanged |
| `onCancel` | `VoidCallback?` |  | Cancel, close or Escape |
| `title`, `confirmLabel`, `cancelLabel`, `closeAriaLabel` | `String?` | English | Modal copy; `title` names the trigger |
| `disabled` | `bool` | `false` | Disables the trigger |
| `pageSizePreference` | `CsPageSizePreference?` |  | `title`, `options` (`value`, `label`) as radios |
| `wrapLinesPreference`, `stripedRowsPreference`, `contentDensityPreference` | `CsCheckboxPreference?` |  | Checkboxes with `label` and `description` |
| `stickyColumnsPreference` | `CsStickyColumnsPreference?` |  | `firstColumns` and `lastColumns` radio groups |
| `contentDisplayPreference` | `CsContentDisplayPreference?` |  | Column order and visibility, with optional filter |
| `visibleContentPreference` | `CsVisibleContentPreference?` |  | Grouped visibility toggles (cards); ignored with content display |
| `customPreference` | `Widget Function(BuildContext, C?, ValueChanged<C>)?` |  | Your own control for `custom` |
| `contentBefore` | `Widget?` |  | Above the preferences |
| `i18nStrings` | `CsCollectionPreferencesI18nStrings` | English | All fixed copy and announcements |

`CsCollectionPreferencesValue<C>`: `pageSize`, `wrapLines`, `stripedRows`, `contentDensity` (`CsDensity`), `visibleContent`, `stickyColumns` (`CsStickyColumns`), `contentDisplay` (`List<CsColumnDisplay>`), `custom`; `copyWith`.

`open(context)` opens the modal from code.

## Examples

### Sticky columns and a custom preference

```dart
CsCollectionPreferences<bool>(
  preferences: prefs,
  onConfirm: (next) => setState(() => prefs = next),
  stickyColumnsPreference: const CsStickyColumnsPreference(
    firstColumns: CsStickyColumnPreference(
      title: 'Stick first column(s)',
      description: 'Keep the first column(s) visible while horizontally scrolling the table content.',
      options: [(label: 'None', value: 0), (label: 'First column', value: 1), (label: 'First two columns', value: 2)],
    ),
  ),
  customPreference: (context, value, setValue) =>
      CsCheckbox(checked: value ?? false, label: 'Show tags column', onChange: setValue),
)
```

### Visible content for cards

```dart
CsCollectionPreferences<void>(
  preferences: prefs,
  onConfirm: (next) => setState(() => prefs = next),
  visibleContentPreference: const CsVisibleContentPreference(
    title: 'Select visible content',
    options: [
      CsVisibleContentOptionsGroup(
        label: 'Distribution properties',
        options: [
          CsVisibleContentOption(id: 'domain', label: 'Domain name', editable: false),
          CsVisibleContentOption(id: 'status', label: 'Status'),
        ],
      ),
    ],
  ),
)
```

## Accessibility

The trigger is an icon button named by `title`. The modal traps focus, closes on Escape and restores focus to the trigger. Radios are mutually exclusive checked controls; toggles report their state and are labeled by the column. Drag handles are focusable buttons: Space or Enter picks a column up, Up and Down move it, Space or Enter drops it and Escape restores the order; each step is announced with Cloudscape's messages.

## Motion

The modal fades and scales in from 0.9 (`CsDialogRoute`). Toggles slide their handle over `CsDurations.responsive`. A dragged column lifts with the dropdown shadow. Reduced motion makes these instant.

## Mobile

The modal takes the screen width less 12px each side. Below 600px the two columns stack, with the column preferences under the others. Drag works with touch on the handle.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `preferences` / `onConfirm` detail | `CsCollectionPreferencesValue<C>` |
| `contentDensity: 'compact'` | `CsDensity.compact` |
| `wrapLinesPreference` etc. | `CsCheckboxPreference` |
| `stickyColumnsPreference.firstColumns.options` | records `(label:, value:)` |
| `customPreference(value, setValue)` | `customPreference(context, value, setValue)` |
| `contentDisplayPreference.groups` (column groups) | not supported yet |
| `getModalRoot`, `removeModalRoot` | not needed (a route) |
