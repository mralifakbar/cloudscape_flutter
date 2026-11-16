# CsTextContent

Long-form text with Cloudscape's typography and spacing: headings, paragraphs, small print, inline code, code blocks, links and lists, for help panels and "How it works" sections.

Cloudscape reference: https://cloudscape.design/components/text-content/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';

const help = CsTextContent(
  blocks: [
    CsTextHeading('Price class', level: CsTextHeadingLevel.h3),
    CsTextParagraph(text: 'The price class sets which edge locations serve your content.'),
    CsTextList(items: [
      CsTextListItem(text: 'All edge locations'),
      CsTextListItem(text: 'North America and Europe only'),
    ]),
  ],
);
```

## When to use / when not to

- Use it for running text that mixes headings, paragraphs and lists, such as help panel content, empty-state explanations or a details page introduction.
- For a single styled line (a heading, a label, a value) use `CsBox`.
- Cloudscape styles raw HTML. Flutter has no HTML, so pass a list of blocks, or Markdown through `CsTextContent.markdown`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `blocks` | `List<CsTextBlock>` | required | The content, top to bottom. |

`CsTextContent.markdown(String source, {ValueChanged<String>? onFollowLink})` parses a Markdown subset: `#` to `#####` headings, paragraphs separated by blank lines, `-`/`*` and `1.` lists (indent two spaces to nest), fenced code blocks, paragraphs starting with `<small>`, and inline `**bold**`, `*italic*`, `` `code` `` and `[text](target)`. `parseCsMarkdown` and `parseCsInlineMarkdown` return the blocks and spans.

Blocks (`CsTextBlock`):

| Block | HTML | Look |
| --- | --- | --- |
| `CsTextHeading(text, level: CsTextHeadingLevel.h1..h5)` | `h1` to `h5` | heading-xl to heading-xs, bold, heading color, 4px above and below |
| `CsTextParagraph(text:, spans:)` | `p` | body-m, 4px above and below |
| `CsTextSmall(text:, spans:)` | `small` | body-s in `color-text-small` |
| `CsTextPre(code)` | `pre` | monospace body-m, scrolls sideways |
| `CsTextList(items:, ordered:)` with `CsTextListItem(text:, spans:, nested:)` | `ul`, `ol` | 20px indent, `space-scaled-xs` above and below, `space-scaled-xxs` between items |
| `CsTextCustom(child)` | any element | any widget |

Inline spans (`CsTextSpan`): `CsTextRun(text, bold:, italic:)`, `CsTextCode(text)` (monospace body-s), `CsTextLink(text, onFollow:, external:)` (an underlined `CsLink`), `CsTextWidget(child)`.

## Examples

### Mixed inline content

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

Widget intro(VoidCallback openPricing) => CsTextContent(
  blocks: [
    CsTextParagraph(spans: [
      const CsTextRun('Use '),
      const CsTextCode('PriceClass_All'),
      const CsTextRun(' to serve from '),
      const CsTextRun('every', bold: true),
      const CsTextRun(' edge location. '),
      CsTextLink('Pricing', onFollow: openPricing, external: true),
    ]),
  ],
);
```

### Markdown

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

Widget steps(ValueChanged<String> open) => CsTextContent.markdown(
  '''
## Create a distribution

1. Choose an origin such as `example-bucket`
2. Pick a price class
3. Review and [create](create)

<small>Changes take a few minutes to deploy.</small>
''',
  onFollowLink: open,
);
```

## Accessibility

Headings are semantic headers. Links are focusable `CsLink`s (Tab reaches them, Enter follows) in the underlined primary variant. List markers are hidden from screen readers; each item is its own node.

## Motion

None.

## Mobile

Text wraps and scales with the platform text size. Code blocks keep their line breaks and scroll sideways instead of overflowing. Links sit in the line as a unit, so a long link moves to the next line rather than breaking.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` (HTML) | `blocks`, or `CsTextContent.markdown` |
| `h1`...`h5`, `p`, `small`, `code`, `pre`, `a`, `strong`, `em`, `ul`, `ol` | `CsTextHeading`, `CsTextParagraph`, `CsTextSmall`, `CsTextCode`, `CsTextPre`, `CsTextLink`, `CsTextRun(bold:/italic:)`, `CsTextList` |
