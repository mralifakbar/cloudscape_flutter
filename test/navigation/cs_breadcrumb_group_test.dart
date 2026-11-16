import 'package:cloudscape_flutter/src/navigation/navigation.dart';
import 'package:cloudscape_flutter/src/overlays/overlays.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _items = [
  CsBreadcrumbGroupItem(text: 'Service', href: '/'),
  CsBreadcrumbGroupItem(text: 'Buckets', href: '/buckets'),
  CsBreadcrumbGroupItem(text: 'example-bucket', href: '/buckets/example-bucket'),
  CsBreadcrumbGroupItem(text: 'Permissions', href: '/buckets/example-bucket/permissions'),
];

void main() {
  testWidgets('renders in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          CsBreadcrumbGroup(items: _items, onFollow: (_) {}),
          brightness: b,
          density: d,
          size: csDesktopSize,
        );
        expect(find.text('Service'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('follows an item; the current page is not a link', (tester) async {
    final followed = <String>[];
    final clicked = <String>[];
    await pumpCs(
      tester,
      CsBreadcrumbGroup(items: _items, onFollow: (i) => followed.add(i.href), onClick: (i) => clicked.add(i.text)),
      size: csDesktopSize,
    );
    await tester.tap(find.text('Buckets'));
    await tester.tap(find.text('Permissions'));
    expect(followed, ['/buckets']);
    expect(clicked, ['Buckets']);
  });

  testWidgets('collapsed count follows Cloudscape', (tester) async {
    expect(CsBreadcrumbGroup.collapsedCount([100, 100, 100], 400), 0);
    expect(CsBreadcrumbGroup.collapsedCount([100, 100, 100, 100], 300), 2);
    expect(CsBreadcrumbGroup.collapsedCount([100, 100, 100], 10), 2);
  });

  testWidgets('middle items collapse into an ellipsis menu', (tester) async {
    final followed = <String>[];
    await pumpCs(
      tester,
      SizedBox(
        width: 330,
        child: CsBreadcrumbGroup(
          items: _items,
          onFollow: (i) => followed.add(i.text),
          presentation: CsPresentation.popover,
        ),
      ),
      size: csDesktopSize,
    );
    expect(find.text('...'), findsOneWidget);
    expect(find.text('Buckets'), findsNothing);
    await tester.tap(find.text('...'));
    await tester.pumpAndSettle();
    expect(find.text('Buckets'), findsOneWidget);
    await tester.tap(find.text('Buckets'));
    await tester.pumpAndSettle();
    expect(followed, ['Buckets']);
    expect(find.text('Buckets'), findsNothing);
  });

  testWidgets('on a narrow screen the whole path opens from the current page title in a sheet', (tester) async {
    final followed = <String>[];
    await pumpCs(
      tester,
      SizedBox(
        width: 160,
        child: CsBreadcrumbGroup(items: _items, onFollow: (i) => followed.add(i.text)),
      ),
    );
    expect(find.text('Service'), findsNothing);
    await tester.tap(find.text('Permissions'));
    await tester.pumpAndSettle();
    expect(find.byType(CsSheet), findsOneWidget);
    await tester.tap(find.text('Service'));
    await tester.pumpAndSettle();
    expect(followed, ['Service']);
    expect(find.byType(CsSheet), findsNothing);
  });

  testWidgets('semantics: group label and expand label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      SizedBox(
        width: 330,
        child: CsBreadcrumbGroup(
          items: _items,
          ariaLabel: 'Bucket path',
          i18nStrings: const CsBreadcrumbGroupI18nStrings(expandAriaLabel: 'Show full path'),
          onFollow: (_) {},
        ),
      ),
      size: csDesktopSize,
    );
    expect(find.bySemanticsLabel('Bucket path'), findsOneWidget);
    expect(find.bySemanticsLabel('Show full path'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('single item and empty list', (tester) async {
    await pumpCs(
      tester,
      const CsBreadcrumbGroup(
        items: [CsBreadcrumbGroupItem(text: 'Home', href: '/')],
      ),
    );
    expect(find.text('Home'), findsOneWidget);
    await pumpCs(tester, const CsBreadcrumbGroup(items: []));
    expect(tester.takeException(), isNull);
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    await pumpCs(tester, CsBreadcrumbGroup(items: _items, onFollow: (_) {}), textScale: 2);
    expect(tester.takeException(), isNull);
    await pumpCs(
      tester,
      const CsBreadcrumbGroup(
        items: [
          CsBreadcrumbGroupItem(text: 'Home', href: '/'),
          CsBreadcrumbGroupItem(text: 'A very long current page title that cannot fit on a phone', href: '/x'),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
