# CsFormField

Wraps a form control with its label, description, constraint text, character count and validation message.

Cloudscape reference: https://cloudscape.design/components/form-field/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFormField(
  label: 'Bucket name',
  description: 'The name must be unique across all accounts.',
  constraintText: 'Use 3 to 63 characters.',
  errorText: nameError,
  child: CsInput(value: name, invalid: nameError != null, onChange: (v) => setState(() => name = v)),
)
```

## When to use / when not to

- Use around every input, textarea, select, radio group, tiles or slider in a form.
- A checkbox or toggle carries its own label; wrap it only when it needs a group label or an error.
- Use `CsForm` for the page-level frame and form-level errors.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | The control. |
| `label` | `String?` | `null` | Bold label above the control. |
| `labelWidget` | `Widget?` | `null` | Custom label in place of `label`. |
| `labelHidden` | `bool` | `false` | Keep the label for screen readers only. |
| `info` | `Widget?` | `null` | An "Info" link after the label, separated by a divider. |
| `description` / `descriptionWidget` | `String?` / `Widget?` | `null` | Body-s text under the label. |
| `constraintText` | `String?` | `null` | Rules for the value, under the control. |
| `characterCountText` | `String?` | `null` | For example `'12/63'`, after the constraint text. |
| `errorText` | `String?` | `null` | Red message with an error icon, announced. Replaces the warning. |
| `warningText` | `String?` | `null` | Yellow message with a warning icon. |
| `secondaryControl` | `Widget?` | `null` | A control beside the main one (a Remove button). Moves under it at or below 688px. |
| `stretch` | `bool` | `false` | Let the control take the full width; otherwise it takes 66% on wide layouts. |
| `errorIconAriaLabel` / `warningIconAriaLabel` | `String?` | "Error" / "Warning" | Names of the status icons. |

## Examples

### Info link and character count

```dart
CsFormField(
  label: 'Description',
  info: CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: () {}),
  characterCountText: '${description.length}/200',
  stretch: true,
  child: CsTextarea(value: description, onChange: (v) => setState(() => description = v)),
)
```

### Secondary control

```dart
CsFormField(
  label: 'Tag key',
  secondaryControl: CsButton(text: 'Remove', onPress: () {}),
  child: CsInput(value: key, onChange: (v) => setState(() => key = v)),
)
```

### Warning

```dart
CsFormField(
  label: 'Tag value',
  warningText: 'Changing production tags can affect cost reports.',
  child: CsInput(value: tag, warning: true, onChange: (v) => setState(() => tag = v)),
)
```

## Accessibility

- The error and warning messages are live regions read as "Error. <text>" or "Warning. <text>" when they appear; the status is shown by icon and text, never color alone.
- With `labelHidden` the label stays in the semantics tree.
- Set the control's `invalid` or `warning` together with the message so the field border matches.

## Motion

None. Messages appear and disappear instantly, as in Cloudscape.

## Mobile

At or below 688px the control takes the full width and `secondaryControl` moves under it. Label, description and messages wrap at 2x text.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `label` | `label` / `labelWidget` |
| `info` | `info` |
| `description` | `description` / `descriptionWidget` |
| `constraintText` | `constraintText` |
| `characterCountText` | `characterCountText` |
| `errorText` / `warningText` | `errorText` / `warningText` |
| `secondaryControl` | `secondaryControl` |
| `stretch` | `stretch` |
| `i18nStrings.errorIconAriaLabel` / `warningIconAriaLabel` | `errorIconAriaLabel` / `warningIconAriaLabel` |
| `children` | `child` |
| `controlId`, `analyticsMetadata` | web only |
