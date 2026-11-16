import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/selection/selection.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _items = [
  CsTokenGroupItem(label: 'example-bucket', description: 'us-east-1', icon: CsIcons.folder),
  CsTokenGroupItem(label: 'logs-bucket', labelTag: '12 GB', tags: ['Versioned']),
  CsTokenGroupItem(label: 'archive-bucket', disabled: true),
];

void main() {
  testWidgets('renders in light, dark, compact, both alignments', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final a in CsTokenGroupAlignment.values) {
          await pumpCs(
            tester,
            CsTokenGroup(items: _items, alignment: a, onDismiss: (_) {}),
            brightness: b,
            density: d,
          );
          expect(find.byType(CsToken), findsNWidgets(3));
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('dismiss reports the index; disabled tokens do not dismiss', (tester) async {
    final dismissed = <int>[];
    await pumpCs(tester, CsTokenGroup(items: _items, onDismiss: dismissed.add));
    await tester.tap(find.bySemanticsLabel('Remove logs-bucket'));
    await tester.tap(find.bySemanticsLabel('Remove archive-bucket'), warnIfMissed: false);
    expect(dismissed, [1]);
  });

  testWidgets('without onDismiss and readOnly there is no active dismiss', (tester) async {
    await pumpCs(tester, const CsTokenGroup(items: _items));
    expect(find.bySemanticsLabel('Remove logs-bucket'), findsNothing);
    var n = 0;
    await pumpCs(tester, CsTokenGroup(items: _items, readOnly: true, onDismiss: (_) => n++));
    await tester.tap(find.bySemanticsLabel('Remove logs-bucket'), warnIfMissed: false);
    expect(n, 0);
  });

  testWidgets('limit hides tokens behind Show more', (tester) async {
    await pumpCs(
      tester,
      const CsTokenGroup(
        items: _items,
        limit: 1,
        i18nStrings: CsTokenGroupI18nStrings(limitShowMore: 'More', limitShowFewer: 'Fewer'),
      ),
    );
    expect(find.byType(CsToken), findsOneWidget);
    await tester.tap(find.text('More (+2)'));
    await tester.pumpAndSettle();
    expect(find.byType(CsToken), findsNWidgets(3));
    await tester.tap(find.text('Fewer'));
    await tester.pumpAndSettle();
    expect(find.byType(CsToken), findsOneWidget);
  });

  testWidgets('limit 0 hides every token', (tester) async {
    await pumpCs(tester, const CsTokenGroup(items: _items, limit: 0));
    expect(find.byType(CsToken), findsNothing);
    expect(find.text('Show more (3)'), findsOneWidget);
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    await pumpCs(tester, CsTokenGroup(items: _items, onDismiss: (_) {}), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
