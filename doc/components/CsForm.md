# CsForm

The frame of a create or edit flow: header, form content, a form-level error and the action row.

Cloudscape reference: https://cloudscape.design/components/form/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsForm(
  header: const CsHeader(variant: CsHeaderVariant.h1, title: 'Create bucket'),
  actions: CsSpaceBetween(
    direction: CsSpaceBetweenDirection.horizontal,
    size: CsSpacingSize.xs,
    children: [
      CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () {}),
      CsButton(text: 'Create bucket', variant: CsButtonVariant.primary, onPress: () {}),
    ],
  ),
  child: CsContainer(
    header: const CsHeader(title: 'General configuration'),
    child: CsFormField(
      label: 'Bucket name',
      child: CsInput(value: name, onChange: (v) => setState(() => name = v)),
    ),
  ),
)
```

## When to use / when not to

- Use for a page or section whose purpose is to submit a set of fields.
- Do not use for a single inline edit (edit the value in place) or for multi-page flows (use a wizard).
- Put field errors on each `CsFormField`; use `errorText` here for failures that are not about one field (a server error, a quota).

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget?` | `null` | The form content, usually containers of form fields. |
| `header` | `Widget?` | `null` | Usually a `CsHeader` with `CsHeaderVariant.h1`. |
| `errorText` | `String?` | `null` | Form-level error in an error alert under the content, announced. |
| `errorWidget` | `Widget?` | `null` | Rich error content in place of `errorText`. |
| `errorIconAriaLabel` | `String?` | "Error" | Name of the alert icon. |
| `actions` | `Widget?` | `null` | Primary actions at the end of the row: a link-variant Cancel and a primary submit, in a horizontal `CsSpaceBetween` of size xs. |
| `secondaryActions` | `Widget?` | `null` | Actions at the start of the row. |
| `variant` | `CsFormVariant` | `fullPage` | Kept for parity; Cloudscape no longer draws variants differently. |

## Examples

### Submit with a form-level error

```dart
CsForm(
  header: const CsHeader(variant: CsHeaderVariant.h1, title: 'Create distribution'),
  errorText: submitError,
  secondaryActions: CsButton(text: 'Save draft', onPress: () {}),
  actions: CsSpaceBetween(
    direction: CsSpaceBetweenDirection.horizontal,
    size: CsSpacingSize.xs,
    children: [
      CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () {}),
      CsButton(
        text: 'Create distribution',
        variant: CsButtonVariant.primary,
        loading: saving,
        onPress: () {},
      ),
    ],
  ),
  child: fields,
)
```

## Accessibility

- The error alert is a live region read as "Error, <text>" when it appears, with an icon so status is not color alone.
- Tab order follows the layout: header, fields, then the action row (primary actions first in the row as Cloudscape lays it out in reverse).
- After a failed submit, move focus to the first invalid field.

## Motion

None.

## Mobile

The action row wraps: when the primary and secondary actions do not fit side by side, the secondary actions move to their own line under the primary ones, both aligned to the end. Spacing follows the density (`space-scaled-*`).

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `child` |
| `header` | `header` |
| `errorText` | `errorText` / `errorWidget` |
| `errorIconAriaLabel` | `errorIconAriaLabel` |
| `actions` | `actions` |
| `secondaryActions` | `secondaryActions` |
| `variant` (`full-page`, `embedded`) | `variant` (`fullPage`, `embedded`) |
| `analyticsMetadata` | web only |
