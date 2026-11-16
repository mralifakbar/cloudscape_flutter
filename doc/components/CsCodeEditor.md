# CsCodeEditor

Cloudscape's `CodeEditor`, rebuilt in Flutter without Ace: a monospace editor with line numbers, syntax highlighting, an active line marker, validation and Cloudscape's status bar.

Cloudscape reference: https://cloudscape.design/components/code-editor/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsCodeEditor(
  value: policy,
  language: 'json',
  validator: CsCodeEditor.jsonValidator,
  preferences: prefs,
  onPreferencesChange: (p) => setState(() => prefs = p),
  onChange: (v) => setState(() => policy = v),
)
```

## When to use / when not to

Use it when users write or edit code or structured documents (policies, templates, scripts, queries). To show code read-only, use a code view. For short free text use a textarea.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | |
| `language` | `String` | required | `json`, `yaml`, `javascript`, `typescript`, `python`, `sh` are highlighted; others show plain text |
| `onChange` | `ValueChanged<String>?` | | Every edit |
| `onDelayedChange` | `ValueChanged<String>?` | | 500ms after the last edit |
| `onValidate` | `ValueChanged<List<CsCodeEditorAnnotation>>?` | | When the problems found change |
| `languageLabel` | `String?` | readable language name | Status bar label |
| `preferences` | `CsCodeEditorPreferences?` | wrap lines, app theme | `wrapLines`, `theme` (`auto`, `light`, `dark`) |
| `onPreferencesChange` | `ValueChanged<CsCodeEditorPreferences>?` | | Shows the preferences button |
| `loading` | `bool` | `false` | Loading state in place of the editor |
| `readOnly` | `bool` | `false` | |
| `annotations` | `List<CsCodeEditorAnnotation>?` | | Problems to show; take precedence over `validator` |
| `validator` | `CsCodeEditorValidator?` | | `(value) => annotations`, run on every change |
| `editorContentHeight` | `double?` | 480 (240 on phones) | Height of the editing area |
| `onEditorContentResize` | `ValueChanged<double>?` | | Controls the height from the resize handle |
| `ariaLabel` | `String?` | | |
| `focusNode` | `FocusNode?` | | |
| `i18nStrings` | `CsCodeEditorI18nStrings` | English | `loadingState`, `cursorPosition(row, column)`, `errorsTab`, `warningsTab`, `preferencesButtonAriaLabel`, `paneCloseButtonAriaLabel`, preference labels, `resizeHandleAriaLabel`, ... |

`CsCodeEditorAnnotation`: `row` and `column` (zero-based), `text`, `type` (`error`, `warning`, `info`). `CsCodeEditor.jsonValidator` reports the first JSON syntax error. `CsCodeEditorHighlighter.tokenize(code, language)` exposes the tokenizer.

## Examples

### Custom annotations

```dart
CsCodeEditor(
  value: template,
  language: 'yaml',
  annotations: const [
    CsCodeEditorAnnotation(row: 3, column: 4, text: 'Versioning is off.', type: CsCodeEditorAnnotationType.warning),
  ],
  onChange: (v) {},
)
```

### Fixed height, dark editor

```dart
CsCodeEditor(
  value: script,
  language: 'sh',
  editorContentHeight: 200,
  preferences: const CsCodeEditorPreferences(wrapLines: false, theme: CsCodeEditorTheme.dark),
  onChange: (v) {},
)
```

### Loading

```dart
const CsCodeEditor(value: '', language: 'json', loading: true)
```

## Accessibility

The editor is a labelled group ("Code editor") holding a multi-line text field. Tab inserts two spaces; Escape closes the errors pane or moves focus out of the editor, so keyboard users are never trapped; Shift+Tab moves focus back. The status bar is a group: the cursor position is a live region, the errors and warnings tabs announce their counts and selected state and open a pane whose rows ("Ln 3, Col 5: message") move the cursor to the problem. The resize handle responds to Up and Down while focused.

## Motion

None beyond `CsDropdown` for the preferences menu. Hover colors in the status bar switch instantly.

## Mobile

The default height drops to 240px below 688px. With `wrapLines` (the default) there is no horizontal scrolling; without it the code area scrolls sideways while the gutter stays put. Below 500px of width the errors and warnings tabs show their counts only.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value`, `language`, `languageLabel`, `loading`, `editorContentHeight`, `ariaLabel`, `i18nStrings` | same names |
| `onChange`, `onDelayedChange` (`detail.value`) | `ValueChanged<String>` |
| `onValidate` (`detail.annotations`) | `onValidate` + `annotations` / `validator` |
| `preferences`, `onPreferencesChange` | `CsCodeEditorPreferences` (`theme` is `auto`, `light` or `dark`, Cloudscape's two editor themes) |
| `onEditorContentResize` (`detail.height`) | `ValueChanged<double>` |
| `themes` | not supported (two themes) |
| `ace`, `onRecoveryClick` | not applicable (no Ace to load) |
| preferences modal | preferences menu |
