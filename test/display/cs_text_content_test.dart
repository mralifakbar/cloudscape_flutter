import 'package:cloudscape_flutter/src/display/display.dart';
import 'package:cloudscape_flutter/src/navigation/cs_link.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _md = '''
# Distributions

Serve **static** and *dynamic* content with `PriceClass_All`. See [pricing](https://example.com/pricing).

## Steps

1. Create an origin
2. Choose a price class
  - All edge locations
  - North America and Europe
3. Review

<small>Prices are sample data.</small>

```
aws example create-distribution --origin example-bucket
```
''';

void main() {
  testWidgets('renders every block in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          SingleChildScrollView(child: CsTextContent.markdown(_md)),
          brightness: b,
          density: d,
          center: false,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Distributions'), findsOneWidget);
      }
    }
  });

  test('markdown parser builds headings, paragraphs, nested lists, small and pre', () {
    final blocks = parseCsMarkdown(_md);
    expect(blocks[0], isA<CsTextHeading>().having((h) => h.level, 'level', CsTextHeadingLevel.h1));
    expect(blocks[1], isA<CsTextParagraph>());
    final p = (blocks[1] as CsTextParagraph).spans!;
    expect(p.whereType<CsTextRun>().where((r) => r.bold).single.text, 'static');
    expect(p.whereType<CsTextRun>().where((r) => r.italic).single.text, 'dynamic');
    expect(p.whereType<CsTextCode>().single.text, 'PriceClass_All');
    expect(p.whereType<CsTextLink>().single.external, isTrue);
    expect(blocks[2], isA<CsTextHeading>().having((h) => h.level, 'level', CsTextHeadingLevel.h2));
    final list = blocks[3] as CsTextList;
    expect(list.ordered, isTrue);
    expect(list.items, hasLength(3));
    expect(list.items[1].nested!.items, hasLength(2));
    expect(list.items[1].nested!.ordered, isFalse);
    expect(blocks[4], isA<CsTextSmall>());
    expect((blocks[5] as CsTextPre).code, contains('create-distribution'));
  });

  testWidgets('headings use heading styles and are headers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      const CsTextContent(
        blocks: [
          CsTextHeading('Title', level: CsTextHeadingLevel.h1),
          CsTextHeading('Section', level: CsTextHeadingLevel.h3),
          CsTextParagraph(text: 'Body'),
          CsTextSmall(text: 'Fine print'),
        ],
      ),
    );
    final h1 = tester.widget<Text>(find.text('Title')).style!;
    expect(h1.fontSize, CsTypeScale.headingXl.fontSize);
    expect(h1.fontWeight, FontWeight.w700);
    expect(tester.widget<Text>(find.text('Section')).style!.fontSize, CsTypeScale.headingM.fontSize);
    final ctx = tester.element(find.text('Fine print'));
    expect(tester.widget<Text>(find.text('Fine print')).style!.color, ctx.cs.colors.textSmall);
    expect(tester.getSemantics(find.text("Title")), matchesSemantics(label: "Title", isHeader: true));
    // 4px above and below every heading and paragraph.
    expect(tester.getTopLeft(find.text('Section')).dy - tester.getBottomLeft(find.text('Title')).dy, 8);
    handle.dispose();
  });

  testWidgets('links follow on tap and Enter and are primary', (tester) async {
    final followed = <String>[];
    await pumpCs(tester, CsTextContent.markdown('Open [the bucket](example-bucket) now.', onFollowLink: followed.add));
    expect(CsLinkDefaults.of(tester.element(find.text('the bucket'))), CsLinkVariant.primary);
    await tester.tap(find.text('the bucket'));
    expect(followed, ['example-bucket']);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(followed, ['example-bucket', 'example-bucket']);
  });

  testWidgets('lists number items and indent nested lists', (tester) async {
    await pumpCs(
      tester,
      const CsTextContent(
        blocks: [
          CsTextList(
            ordered: true,
            items: [
              CsTextListItem(text: 'First'),
              CsTextListItem(
                text: 'Second',
                nested: CsTextList(items: [CsTextListItem(text: 'Nested')]),
              ),
            ],
          ),
        ],
      ),
    );
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('•'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Nested')).dx, greaterThan(tester.getTopLeft(find.text('Second')).dx));
  });

  testWidgets('2x text at 390px and long code do not overflow', (tester) async {
    await pumpCs(tester, SingleChildScrollView(child: CsTextContent.markdown(_md)), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
  });
}
