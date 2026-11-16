import 'package:flutter/widgets.dart';

import '../navigation/cs_link.dart';
import '../theme/theme.dart';

/// A run of inline content inside a [CsTextBlock]: plain text, bold or
/// italic text, inline code, a link, or small text.
sealed class CsTextSpan {
  const CsTextSpan();
}

/// Plain text, optionally bold (`<strong>`) or italic (`<em>`).
class CsTextRun extends CsTextSpan {
  const CsTextRun(this.text, {this.bold = false, this.italic = false});

  final String text;
  final bool bold;
  final bool italic;
}

/// Inline code (`<code>`): monospace body-s.
class CsTextCode extends CsTextSpan {
  const CsTextCode(this.text);

  final String text;
}

/// An inline link (`<a>`): underlined link color, focusable, Enter follows.
class CsTextLink extends CsTextSpan {
  const CsTextLink(this.text, {this.onFollow, this.external = false});

  final String text;
  final VoidCallback? onFollow;

  /// Adds the external icon and announces that it opens a new window.
  final bool external;
}

/// Any widget placed inline on the text baseline, such as a badge.
class CsTextWidget extends CsTextSpan {
  const CsTextWidget(this.child);

  final Widget child;
}

/// Heading levels of [CsTextHeading], `h1` to `h5`.
enum CsTextHeadingLevel {
  /// 24/30 bold.
  h1(CsTypeScale.headingXl),

  /// 20/24 bold.
  h2(CsTypeScale.headingL),

  /// 18/22 bold.
  h3(CsTypeScale.headingM),

  /// 16/20 bold.
  h4(CsTypeScale.headingS),

  /// 14/18 bold.
  h5(CsTypeScale.headingXs);

  const CsTextHeadingLevel(this.scale);

  /// The type step of the level.
  final CsTypeScale scale;
}

/// One block of [CsTextContent]: a heading, paragraph, small print, code
/// block, list or any widget.
sealed class CsTextBlock {
  const CsTextBlock();
}

/// A heading (`<h1>` to `<h5>`).
class CsTextHeading extends CsTextBlock {
  const CsTextHeading(this.text, {this.level = CsTextHeadingLevel.h2});

  final String text;
  final CsTextHeadingLevel level;
}

/// A paragraph (`<p>`). Pass [text] for plain text or [spans] for mixed
/// inline content.
class CsTextParagraph extends CsTextBlock {
  const CsTextParagraph({this.text, this.spans}) : assert(text != null || spans != null, 'Pass text or spans');

  final String? text;
  final List<CsTextSpan>? spans;
}

/// Small print (`<small>`): body-s in `color-text-small`.
class CsTextSmall extends CsTextBlock {
  const CsTextSmall({this.text, this.spans}) : assert(text != null || spans != null, 'Pass text or spans');

  final String? text;
  final List<CsTextSpan>? spans;
}

/// A preformatted code block (`<pre>`): monospace body-m, whitespace kept,
/// scrolls sideways instead of wrapping.
class CsTextPre extends CsTextBlock {
  const CsTextPre(this.code);

  final String code;
}

/// One item of a [CsTextList]: inline content and an optional nested list.
class CsTextListItem {
  const CsTextListItem({this.text, this.spans, this.nested})
    : assert(text != null || spans != null, 'Pass text or spans');

  final String? text;
  final List<CsTextSpan>? spans;

  /// A list inside this item.
  final CsTextList? nested;
}

/// A bulleted (`<ul>`) or numbered (`<ol>`) list.
class CsTextList extends CsTextBlock {
  const CsTextList({required this.items, this.ordered = false});

  final List<CsTextListItem> items;
  final bool ordered;
}

/// Any widget as a block, such as an image or a `CsBox`.
class CsTextCustom extends CsTextBlock {
  const CsTextCustom(this.child);

  final Widget child;
}

/// Cloudscape's `TextContent`: long-form text with Cloudscape's typography
/// and spacing, such as help panel content or a "How it works" section.
///
/// Cloudscape styles raw HTML; Flutter has no HTML, so the content is a
/// list of blocks:
///
/// ```dart
/// CsTextContent(
///   blocks: [
///     const CsTextHeading('Distribution settings', level: CsTextHeadingLevel.h2),
///     const CsTextParagraph(text: 'Choose the price class for your distribution.'),
///     CsTextParagraph(spans: [
///       const CsTextRun('Use '),
///       const CsTextCode('PriceClass_All'),
///       const CsTextRun(' for every edge location. '),
///       CsTextLink('Pricing', onFollow: openPricing),
///     ]),
///     const CsTextList(items: [
///       CsTextListItem(text: 'All edge locations'),
///       CsTextListItem(text: 'North America and Europe only'),
///     ]),
///   ],
/// )
/// ```
///
/// [CsTextContent.markdown] builds the blocks from a small Markdown subset.
///
/// Spacing follows Cloudscape: headings and paragraphs have 4px above and
/// below (`space-xxs`), lists have `space-scaled-xs` above and below, a 20px
/// indent, and `space-scaled-xxs` between items.
class CsTextContent extends StatelessWidget {
  const CsTextContent({super.key, required this.blocks});

  /// Builds blocks from a Markdown subset: `#` to `#####` headings,
  /// paragraphs (separated by blank lines), `-`/`*` and `1.` lists (indent
  /// two spaces to nest), fenced code blocks, lines starting with `<small>`
  /// for small print, and inline `**bold**`, `*italic*`, `` `code` `` and
  /// `[text](target)` links. Following a link calls [onFollowLink] with its
  /// target.
  factory CsTextContent.markdown(String source, {Key? key, ValueChanged<String>? onFollowLink}) => CsTextContent(
    key: key,
    blocks: parseCsMarkdown(source, onFollowLink: onFollowLink),
  );

  final List<CsTextBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final base = DefaultTextStyle.of(context).style.merge(cs.body);
    return CsLinkDefaults(
      variant: CsLinkVariant.primary,
      child: DefaultTextStyle(
        style: base,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [for (final b in blocks) _block(context, b, base)],
        ),
      ),
    );
  }

  Widget _block(BuildContext context, CsTextBlock block, TextStyle base) {
    final cs = context.cs;
    const blockPad = EdgeInsets.symmetric(vertical: CsSpace.xxs);
    switch (block) {
      case CsTextHeading(:final text, :final level):
        return Padding(
          padding: blockPad,
          child: Semantics(header: true, child: Text(text, style: cs.text(level.scale))),
        );
      case CsTextParagraph(:final text, :final spans):
        return Padding(padding: blockPad, child: _rich(context, base, text, spans));
      case CsTextSmall(:final text, :final spans):
        final style = cs.text(CsTypeScale.bodyS, color: CsColor.textSmall);
        return Padding(
          padding: blockPad,
          child: DefaultTextStyle(style: style, child: _rich(context, style, text, spans)),
        );
      case CsTextPre(:final code):
        return Padding(
          padding: blockPad,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(code, style: cs.code().copyWith(color: base.color), softWrap: false),
          ),
        );
      case CsTextList():
        return Padding(
          padding: EdgeInsets.symmetric(vertical: cs.space.scaledXs),
          child: _list(context, block, base),
        );
      case CsTextCustom(:final child):
        return child;
    }
  }

  Widget _list(BuildContext context, CsTextList list, TextStyle base) {
    final cs = context.cs;
    final children = <Widget>[];
    for (var i = 0; i < list.items.length; i++) {
      final item = list.items[i];
      final marker = list.ordered ? '${i + 1}.' : '•';
      children.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : cs.space.scaledXxs),
          child: Semantics(
            container: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // `padding-inline-start: space-l` with an outside marker.
                SizedBox(
                  width: CsSpace.l,
                  child: ExcludeSemantics(
                    child: Text(marker, style: base, textAlign: TextAlign.end, maxLines: 1, softWrap: false),
                  ),
                ),
                const SizedBox(width: CsSpace.xxs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _rich(context, base, item.text, item.spans),
                      if (item.nested != null)
                        Padding(
                          padding: EdgeInsets.only(top: cs.space.scaledXxs),
                          child: _list(context, item.nested!, base),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _rich(BuildContext context, TextStyle base, String? text, List<CsTextSpan>? spans) {
    if (spans == null) return Text(text!, style: base);
    final cs = context.cs;
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          for (final s in spans)
            switch (s) {
              CsTextRun(:final text, :final bold, :final italic) => TextSpan(
                text: text,
                style: TextStyle(
                  fontWeight: bold ? CsTypography.bold : null,
                  fontStyle: italic ? FontStyle.italic : null,
                ),
              ),
              CsTextCode(:final text) => TextSpan(
                text: text,
                style: cs.code(scale: CsTypeScale.bodyS).copyWith(color: base.color, height: base.height),
              ),
              CsTextLink(:final text, :final onFollow, :final external) => WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: CsLink(text: text, onFollow: onFollow, external: external),
              ),
              CsTextWidget(:final child) => WidgetSpan(alignment: PlaceholderAlignment.middle, child: child),
            },
        ],
      ),
    );
  }
}

/// Parses the Markdown subset described on [CsTextContent.markdown].
List<CsTextBlock> parseCsMarkdown(String source, {ValueChanged<String>? onFollowLink}) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final blocks = <CsTextBlock>[];
  final paragraph = <String>[];

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    final text = paragraph.join(' ').trim();
    paragraph.clear();
    if (text.startsWith('<small>')) {
      final inner = text.replaceFirst('<small>', '').replaceFirst('</small>', '').trim();
      blocks.add(CsTextSmall(spans: parseCsInlineMarkdown(inner, onFollowLink: onFollowLink)));
    } else {
      blocks.add(CsTextParagraph(spans: parseCsInlineMarkdown(text, onFollowLink: onFollowLink)));
    }
  }

  final listItem = RegExp(r'^(\s*)([-*]|\d+[.)])\s+(.*)$');
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    final trimmed = line.trim();
    if (trimmed.startsWith('```')) {
      flushParagraph();
      final code = <String>[];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith('```')) {
        code.add(lines[i]);
        i++;
      }
      blocks.add(CsTextPre(code.join('\n')));
      i++;
      continue;
    }
    final heading = RegExp(r'^(#{1,5})\s+(.*)$').firstMatch(trimmed);
    if (heading != null) {
      flushParagraph();
      blocks.add(
        CsTextHeading(heading.group(2)!.trim(), level: CsTextHeadingLevel.values[heading.group(1)!.length - 1]),
      );
      i++;
      continue;
    }
    if (listItem.hasMatch(line)) {
      flushParagraph();
      final entries = <(int, bool, String)>[];
      while (i < lines.length && listItem.hasMatch(lines[i])) {
        final m = listItem.firstMatch(lines[i])!;
        entries.add((m.group(1)!.length, !(m.group(2) == '-' || m.group(2) == '*'), m.group(3)!));
        i++;
      }
      var pos = 0;
      CsTextList build(int indent) {
        final ordered = entries[pos].$2;
        final items = <CsTextListItem>[];
        while (pos < entries.length && entries[pos].$1 >= indent) {
          final (level, _, text) = entries[pos];
          if (level > indent) break;
          pos++;
          CsTextList? nested;
          if (pos < entries.length && entries[pos].$1 > indent) nested = build(entries[pos].$1);
          items.add(
            CsTextListItem(
              spans: parseCsInlineMarkdown(text, onFollowLink: onFollowLink),
              nested: nested,
            ),
          );
        }
        return CsTextList(items: items, ordered: ordered);
      }

      while (pos < entries.length) {
        blocks.add(build(entries[pos].$1));
      }
      continue;
    }
    if (trimmed.isEmpty) {
      flushParagraph();
    } else {
      paragraph.add(trimmed);
    }
    i++;
  }
  flushParagraph();
  return blocks;
}

/// Parses inline Markdown: `**bold**`, `*italic*`, `` `code` `` and
/// `[text](target)` links.
List<CsTextSpan> parseCsInlineMarkdown(String text, {ValueChanged<String>? onFollowLink}) {
  final spans = <CsTextSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`|\[(.+?)\]\((.+?)\)');
  var last = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > last) spans.add(CsTextRun(text.substring(last, m.start)));
    if (m.group(1) != null) {
      spans.add(CsTextRun(m.group(1)!, bold: true));
    } else if (m.group(2) != null) {
      spans.add(CsTextRun(m.group(2)!, italic: true));
    } else if (m.group(3) != null) {
      spans.add(CsTextCode(m.group(3)!));
    } else {
      final target = m.group(5)!;
      spans.add(
        CsTextLink(
          m.group(4)!,
          external: target.startsWith('http'),
          onFollow: onFollowLink == null ? null : () => onFollowLink(target),
        ),
      );
    }
    last = m.end;
  }
  if (last < text.length) spans.add(CsTextRun(text.substring(last)));
  return spans;
}
