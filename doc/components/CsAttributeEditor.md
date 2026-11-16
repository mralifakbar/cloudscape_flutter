# CsAttributeEditor

Cloudscape's `AttributeEditor`: rows of form fields with add and remove buttons, for key-value pairs, environment variables, headers and other repeated attributes.

Cloudscape reference: https://cloudscape.design/components/attribute-editor/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsAttributeEditor<MapEntry<String, String>>(
  items: vars,
  addButtonText: 'Add environment variable',
  onAddButtonClick: () => setState(() => vars = [...vars, const MapEntry('', '')]),
  onRemoveButtonClick: (i) => setState(() => vars = [...vars]..removeAt(i)),
  definition: [
    CsAttributeEditorField(
      label: 'Key',
      control: (item, i) => CsInput(value: item.key, invalid: item.key.isEmpty, onChange: (v) => setKey(i, v)),
      errorText: (item, i) => item.key.isEmpty ? 'Enter a key.' : null,
    ),
    CsAttributeEditorField(
      label: 'Value',
      control: (item, i) => CsInput(value: item.value, onChange: (v) => setValue(i, v)),
    ),
  ],
)
```

## When to use / when not to

Use it when users add, edit and remove a variable number of structured entries (one to six fields per row) in a form. For resource tags use `CsTagEditor`, which adds tag validation and suggestions on top of this component. For a fixed set of fields use `CsFormField`s; for picking existing items use a multiselect.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<T>` | required | One row per item |
| `definition` | `List<CsAttributeEditorField<T>>` | required | The columns of each row; more than six need a `gridLayout` |
| `addButtonText` | `String` | required | |
| `onAddButtonClick` | `VoidCallback?` | | Append an item here |
| `onRemoveButtonClick` | `ValueChanged<int>?` | | Gets the row index; remove the item here |
| `removeButtonText` | `String?` | `i18nStrings.removeButtonText` ("Remove") | |
| `removeButtonAriaLabel` | `String Function(T)?` | | Accessible name of a row's remove button |
| `isItemRemovable` | `bool Function(T)?` | all removable | False hides the row's remove button |
| `disableAddButton` | `bool` | `false` | |
| `hideAddButton` | `bool` | `false` | |
| `additionalActions` | `Widget?` | | Next to (or instead of) the add button |
| `addButtonVariant` | `CsAttributeEditorAddButtonVariant` | `normal` | `normal` or `inlineLink` (with an add icon) |
| `empty` | `Widget?` | | Shown when `items` is empty, in `color-text-empty` |
| `additionalInfo` | `Widget?` | | Under the add button, body-s, announced when it changes |
| `itemLimit` | `int?` | | Disables the add button once `items.length` reaches it |
| `gridLayout` | `List<CsAttributeEditorGridLayout>?` | Cloudscape defaults for 1 to 6 fields | Row layouts by container breakpoint |
| `customRowActions` | `Widget Function(BuildContext, CsAttributeEditorRowActions<T>)?` | | Replaces the remove button (a button dropdown) |
| `i18nStrings` | `CsAttributeEditorI18nStrings` | English | `errorIconAriaLabel`, `warningIconAriaLabel`, `itemRemovedAriaLive`, `removeButtonText` |

`CsAttributeEditorField<T>`: `label`, `labelWidget`, `description`, `info`, `control` (`(item, index) => Widget`), `errorText`, `warningText`, `constraintText` (each `(item, index) => String?`).

`CsAttributeEditorGridLayout`: `breakpoint` (`CsBreakpoint?`, null is the narrowest fallback), `rows` (`List<List<int>>` of relative widths), `removeButton` (`CsAttributeEditorRemoveButtonLayout(ownRow:, width:, autoWidth:)`). `CsAttributeEditorGridLayout.defaultsFor(n)` returns Cloudscape's defaults.

`CsAttributeEditorState<T>` (through a `GlobalKey`): `focusAddButton()`, `focusRemoveButton(index)`.

## Examples

### Item limit and additional info

```dart
CsAttributeEditor<String>(
  items: headers,
  addButtonText: 'Add header',
  itemLimit: 5,
  additionalInfo: Text('You can add up to ${5 - headers.length} more headers.'),
  empty: const Text('No custom headers.'),
  onAddButtonClick: () {},
  onRemoveButtonClick: (i) {},
  definition: [CsAttributeEditorField(label: 'Header', control: (h, i) => CsInput(value: h))],
)
```

### Custom layout for four fields

```dart
CsAttributeEditor<List<String>>(
  items: rules,
  addButtonText: 'Add rule',
  addButtonVariant: CsAttributeEditorAddButtonVariant.inlineLink,
  onAddButtonClick: () {},
  onRemoveButtonClick: (i) {},
  gridLayout: const [
    CsAttributeEditorGridLayout(breakpoint: CsBreakpoint.s, rows: [[2, 1, 2, 3]]),
    CsAttributeEditorGridLayout(breakpoint: CsBreakpoint.xxs, rows: [[1, 1], [1, 1]]),
    CsAttributeEditorGridLayout(rows: [[1], [1], [1], [1]]),
  ],
  definition: [
    CsAttributeEditorField(label: 'Type', control: (r, i) => CsInput(value: r[0])),
    CsAttributeEditorField(label: 'Port', control: (r, i) => CsInput(value: r[1])),
    CsAttributeEditorField(label: 'Source', control: (r, i) => CsInput(value: r[2])),
    CsAttributeEditorField(label: 'Description', control: (r, i) => CsInput(value: r[3])),
  ],
)
```

### Focus after removing the last row

```dart
// editorKey: a GlobalKey<CsAttributeEditorState<String>> passed as the editor's key.
void afterRemovingLastItem(GlobalKey<CsAttributeEditorState<String>> editorKey) {
  editorKey.currentState?.focusAddButton();
}
```

## Accessibility

Each row is a semantics group named after the first field's label. Labels show above the first row only when a row fits on one line; every field keeps its label as its accessible name. The remove button takes `removeButtonAriaLabel`. Removing a row announces `itemRemovedAriaLive` ("Item removed"); `additionalInfo` is a live region. Validation messages use the form field's error and warning treatment with icon labels.

## Motion

None of its own. Buttons give press feedback through `CsButton`.

## Mobile

Layout follows the editor's own width, not the window (Cloudscape container breakpoints). With the default layouts, fields stack below 465px (two fields) and the remove button moves to its own line, end-aligned, followed by a divider. Pass `gridLayout` to change where rows wrap.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items`, `definition`, `addButtonText`, `removeButtonText`, `removeButtonAriaLabel`, `isItemRemovable`, `disableAddButton`, `hideAddButton`, `additionalActions`, `addButtonVariant`, `empty`, `additionalInfo`, `gridLayout`, `customRowActions`, `i18nStrings` | same names |
| `onAddButtonClick` | `onAddButtonClick` (`VoidCallback`) |
| `onRemoveButtonClick` (`detail.itemIndex`) | `onRemoveButtonClick` (`ValueChanged<int>`) |
| `gridLayout[].removeButton.width: 'auto'` | `removeButton: CsAttributeEditorRemoveButtonLayout(autoWidth: true)` |
| `ref.focusAddButton()`, `ref.focusRemoveButton(i)` | `GlobalKey<CsAttributeEditorState<T>>` methods |
| `customRowActions` `ref` | `CsAttributeEditorRowActions.focusNode` |
| (none) | `itemLimit` (extra) |
