import 'package:cloudscape_flutter/src/display/display.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders every color in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Wrap(
            children: [for (final c in CsBadgeColor.values) CsBadge(text: c.name, color: c)],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('severityCritical'), findsOneWidget);
      }
    }
  });

  testWidgets('uses the badge tokens of its color', (tester) async {
    await pumpCs(tester, const CsBadge(text: 'New', color: CsBadgeColor.blue));
    final ctx = tester.element(find.text('New'));
    final c = ctx.cs.colors;
    final box = tester.widget<DecoratedBox>(
      find.ancestor(of: find.text('New'), matching: find.byType(DecoratedBox)).last,
    );
    expect((box.decoration as BoxDecoration).color, c.backgroundBadgeBlue);
    expect(DefaultTextStyle.of(ctx).style.color, c.textBadgeBlue);
    expect(DefaultTextStyle.of(ctx).style.fontSize, CsTypeScale.bodyS.fontSize);
  });

  testWidgets('is 20px tall with 8px side padding and grey by default', (tester) async {
    await pumpCs(tester, const CsBadge(text: '3'));
    final size = tester.getSize(find.byType(CsBadge));
    expect(size.height, 20);
    final ctx = tester.element(find.text('3'));
    expect(DefaultTextStyle.of(ctx).style.color, ctx.cs.colors.textBadgeGrey);
    expect(size.width, tester.getSize(find.text('3')).width + 16);
  });

  testWidgets('style overrides colors, radius, border and padding', (tester) async {
    const style = CsBadgeStyle(
      background: Color(0xFF000000),
      color: Color(0xFFFFFFFF),
      borderColor: Color(0xFFFF0000),
      borderWidth: 1,
      borderRadius: 10,
      paddingInline: 4,
      paddingBlock: 2,
    );
    await pumpCs(tester, const CsBadge(text: 'Beta', style: style));
    final ctx = tester.element(find.text('Beta'));
    expect(DefaultTextStyle.of(ctx).style.color, const Color(0xFFFFFFFF));
    expect(tester.getSize(find.byType(CsBadge)).height, 20 + 2 * 2 + 2);
    expect(
      style,
      const CsBadgeStyle(
        background: Color(0xFF000000),
        color: Color(0xFFFFFFFF),
        borderColor: Color(0xFFFF0000),
        borderWidth: 1,
        borderRadius: 10,
        paddingInline: 4,
        paddingBlock: 2,
      ),
    );
  });

  testWidgets('semantic label replaces the text', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsBadge(text: '3', semanticLabel: '3 unread'));
    expect(find.bySemanticsLabel('3 unread'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('custom child, 2x text and 390px width do not overflow', (tester) async {
    await pumpCs(
      tester,
      const SizedBox(
        width: 200,
        child: CsBadge(child: Text('A very long badge label that has to wrap onto more lines')),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
