# CsCodeView

A read-only code snippet with optional line numbers, line wrapping, syntax highlighting and a copy button.

Cloudscape reference: https://cloudscape.design/components/code-view/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const String policy = '{\n  "Bucket": "example-bucket",\n  "Versioning": true\n}';

CsCodeView(
  content: policy,
  lineNumbers: true,
  highlight: CsCodeViewHighlighter.of('json'),
  actions: const CsCodeViewCopyButton(content: policy),
)
```

## When to use / when not to

- Use for code people read or copy: CLI commands, policies, configuration, responses from an assistant.
- Use a code editor when people need to edit the code.
- Use `CsBox(variant: CsBoxVariant.code)` for short inline code in a sentence.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `content` | `String` | required | The code. |
| `lineNumbers` | `bool` | `false` | Shows a line number column, separated by a divider. Without `wrapLines` it stays fixed while code scrolls. |
| `wrapLines` | `bool` | `false` | Wraps long lines instead of scrolling horizontally. |
| `highlight` | `CsCodeViewHighlight?` | `null` | `List<CsCodeViewToken> Function(String code)`. Use `CsCodeViewHighlighter.of(lang)`; null shows plain text. |
| `actions` | `Widget?` | `null` | Top end slot, usually `CsCodeViewCopyButton`. Adds end padding so code never runs under it. |
| `ariaLabel` | `String?` | `null` | Makes the snippet a labelled region. |
| `i18nStrings` | `CsCodeViewI18nStrings?` | `null` | `lineNumberLabel` and `codeLabel`. With both, line numbers are read by screen readers; otherwise they are hidden. |

`CsCodeViewHighlighter` supports `json`, `javascript` (`js`, `jsx`), `typescript` (`ts`, `tsx`), `python` (`py`), `yaml` (`yml`), `sh` (`bash`, `shell`, `zsh`) and `html` (`xml`, `svg`); other names render plain text. `CsCodeViewHighlighter.tokenize(code, lang)` and `splitLines(tokens)` are public, and `CsCodeViewColors.of(context.cs)` gives the token colors.

`CsCodeViewCopyButton`: `content` (`String`, required), `i18nStrings` (`CsCodeViewCopyButtonI18nStrings`: `copyButtonAriaLabel`, `copySuccessText`, `copyErrorText`; default to `CsStrings.copy`, `copied`, `copyFailed`), `onCopy` (`ValueChanged<bool>?`). It writes to the clipboard with `Clipboard.setData`, shows the result in a tooltip for 1.5 seconds and announces it.

## Examples

### Shell command with wrapped lines

```dart
const String command = 'aws s3 cp ./build s3://example-bucket/releases/ --recursive --exclude "*.map"';

CsCodeView(
  content: command,
  wrapLines: true,
  highlight: CsCodeViewHighlighter.of('sh'),
  ariaLabel: 'Upload command',
  actions: const CsCodeViewCopyButton(
    content: command,
    i18nStrings: CsCodeViewCopyButtonI18nStrings(copySuccessText: 'Command copied'),
  ),
)
```

### Custom highlight function

```dart
CsCodeView(
  content: 'TODO: rotate keys',
  highlight: (code) => [CsCodeViewToken(CsCodeViewTokenType.comment, code)],
)
```

## Accessibility

- With `ariaLabel` the snippet is a labelled region.
- Line numbers are hidden from screen readers unless `i18nStrings` has both labels.
- The copy button is an icon button with a label and announces the result.

## Motion

Only the copy confirmation tooltip animates (with the tooltip motion tokens).

## Mobile

Without `wrapLines` long lines scroll horizontally inside the snippet (the page never scrolls sideways); with it they wrap and line numbers align to the first line of each wrapped line. Code is always laid out left to right, also in RTL apps (`dir="ltr"`).

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `content` | `content` |
| `lineNumbers` | `lineNumbers` |
| `wrapLines` | `wrapLines` |
| `highlight` | `highlight` (returns tokens instead of React nodes) |
| `actions` | `actions` |
| `ariaLabel` | `ariaLabel` |
| `ariaLabelledby` | not applicable (web only); use `ariaLabel` |
| `i18nStrings` | `i18nStrings` |
| `@cloudscape-design/code-view/highlight/*` | `CsCodeViewHighlighter.of('<language>')` |
