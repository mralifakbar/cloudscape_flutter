# CsTagEditor

Cloudscape's `TagEditor`: an attribute editor for resource tags with key and value suggestions, tag validation, a tag limit and undo for removing tags the resource already has.

Cloudscape reference: https://cloudscape.design/components/tag-editor/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsTagEditor(
  tags: tags,
  keysRequest: (key) async => ['environment', 'team', 'cost-center'],
  valuesRequest: (key, value) async => key == 'environment' ? ['production', 'staging'] : [],
  onChange: (change) => setState(() {
    tags = change.tags;
    valid = change.valid;
  }),
)
```

## When to use / when not to

Use it to add, edit and remove the key-value tags of a resource (an instance, a bucket, a distribution). For other repeated attributes use `CsAttributeEditor`. To only display tags use a key-value pairs list.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `tags` | `List<CsTag>` | `[]` | The tags, including ones marked for removal |
| `onChange` | `ValueChanged<CsTagEditorChange>?` | | Gets the next `tags` and whether every tag is `valid` |
| `loading` | `bool` | `false` | Shows a loading status in place of the editor |
| `tagLimit` | `int` | `50` | Tags marked for removal do not count |
| `allowedCharacterPattern` | `String?` | Unicode letters, digits, spaces and `_.:/=+@-` | Regular expression for allowed characters |
| `keysRequest` | `Future<List<String>> Function(String key)?` | | Key suggestions; called with `''` on focus, then as the user types |
| `valuesRequest` | `Future<List<String>> Function(String key, String value)?` | | Value suggestions for a key |
| `i18nStrings` | `CsTagEditorI18nStrings` | English | Every label, placeholder, suggestion and error message |

`CsTag`: `key`, `value` (`''`), `existing` (`false`; existing keys are read-only and removing marks them), `markedForRemoval` (`false`), `valueSuggestionOptions` (`List<String>?`), `copyWith`.

`CsTagEditorChange`: `tags`, `valid`. `CsTagEditor.getTagsDiff(initialTags, tags)` returns `CsTagsDiff(created: Map<String, String>, removed: List<String>)`.

`CsTagEditorState` (through a `GlobalKey`): `focus()` moves to the first key or value with an error.

## Examples

### Existing tags with undo

```dart
CsTagEditor(
  tags: const [
    CsTag(key: 'environment', value: 'production', existing: true),
    CsTag(key: 'team', value: 'payments', existing: true, markedForRemoval: true),
  ],
  onChange: (change) {},
)
```

### Limit and custom copy

```dart
CsTagEditor(
  tags: tags,
  tagLimit: 10,
  i18nStrings: CsTagEditorI18nStrings(
    addButton: 'Add tag',
    tagLimit: (available, limit) => '$available of $limit tags left.',
  ),
  onChange: (change) {},
)
```

### Sending the changes

```dart
final diff = CsTagEditor.getTagsDiff(initialTags, tags);
// diff.created: {'cost-center': 'cc-1001'}; diff.removed: ['team']
```

## Accessibility

Key and value fields are text fields named by their column headers; their suggestion lists are announced as expanded and move with Up and Down, Enter picks, Escape closes. Removing an existing tag replaces the value with an announced "This tag will be removed upon saving changes" and an Undo link, which takes focus; Undo returns focus to the row's remove button. Removing a new tag moves focus to the next key, the previous row, or the add button. Errors are announced with the form field's error icon label.

## Motion

None of its own; the suggestion dropdown uses `CsDropdown`'s open and close transition.

## Mobile

Rows follow `CsAttributeEditor`'s default two-field layout: key and value side by side from 465px of editor width, stacked below with the remove button on its own line. Suggestions always open as an anchored dropdown (not a bottom sheet) so the keyboard stays up while typing.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `tags`, `loading`, `tagLimit`, `allowedCharacterPattern`, `keysRequest`, `valuesRequest`, `i18nStrings` | same names (requests return `Future<List<String>>`) |
| `onChange` (`detail.tags`, `detail.valid`) | `onChange` (`CsTagEditorChange`) |
| `Tag.valueSuggestionOptions` (autosuggest options) | `CsTag.valueSuggestionOptions` (`List<String>`) |
| `getTagsDiff` | `CsTagEditor.getTagsDiff` |
| `ref.focus()` | `GlobalKey<CsTagEditorState>` + `focus()` |
