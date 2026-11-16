import 'dart:ui';

import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/navigation/navigation.dart';
import 'package:cloudscape_flutter/src/overlays/overlays.dart';
import 'package:cloudscape_flutter/src/system/system.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _storage = CsSideNavigationSection(
  text: 'Storage',
  items: [
    CsSideNavigationLink(text: 'Buckets', href: '/buckets'),
    CsSideNavigationLink(text: 'Access points', href: '/access-points'),
  ],
);

const _instances = CsSideNavigationExpandableLinkGroup(
  text: 'Instances',
  href: '/instances',
  items: [
    CsSideNavigationLink(text: 'Launch templates', href: '/launch-templates'),
    CsSideNavigationLink(text: 'Spot requests', href: '/spot'),
  ],
);

const _items = <CsSideNavigationItem>[
  CsSideNavigationLink(text: 'Dashboard', href: '/dashboard', info: Text('New')),
  _storage,
  _instances,
  CsSideNavigationLinkGroup(
    text: 'Distributions',
    href: '/distributions',
    items: [CsSideNavigationLink(text: 'Origins', href: '/origins')],
  ),
  CsSideNavigationSectionGroup(
    title: 'Settings',
    items: [CsSideNavigationLink(text: 'Preferences', href: '/preferences')],
  ),
  CsSideNavigationDivider(),
  CsSideNavigationLink(text: 'Documentation', href: 'https://example.com/docs', external: true),
];

Widget _nav({
  String? active,
  ValueChanged<CsSideNavigationFollowDetail>? onFollow,
  ValueChanged<CsSideNavigationChangeDetail>? onChange,
  List<CsSideNavigationItem> items = _items,
  bool collapsed = false,
}) => SingleChildScrollView(
  child: CsSideNavigation(
    header: const CsSideNavigationHeader(text: 'Service', href: '/'),
    activeHref: active,
    items: items,
    collapsed: collapsed,
    onFollow: onFollow,
    onChange: onChange,
  ),
);

void main() {
  testWidgets('renders every item type in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          _nav(active: '/buckets'),
          brightness: b,
          density: d,
          center: false,
        );
        expect(find.text('Service'), findsOneWidget);
        expect(find.text('Buckets'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('New'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('onFollow reports links, groups, external links and the header', (tester) async {
    final followed = <CsSideNavigationFollowDetail>[];
    await pumpCs(tester, _nav(onFollow: followed.add), center: false);
    await tester.tap(find.text('Buckets'));
    await tester.tap(find.text('Distributions'));
    await tester.tap(find.textContaining('Documentation', findRichText: true));
    await tester.tap(find.text('Service'));
    expect(followed.map((d) => d.href), ['/buckets', '/distributions', 'https://example.com/docs', '/']);
    expect(followed.map((d) => d.type), [
      CsSideNavigationFollowType.link,
      CsSideNavigationFollowType.linkGroup,
      CsSideNavigationFollowType.link,
      CsSideNavigationFollowType.header,
    ]);
    expect(followed[2].external, isTrue);
  });

  testWidgets('the active link is bold and selected', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, _nav(active: '/buckets'), center: false);
    final style = tester
        .widget<RichText>(find.descendant(of: find.bySemanticsLabel('Buckets'), matching: find.byType(RichText)))
        .text
        .style!;
    expect(style.fontWeight, FontWeight.w700);
    expect(tester.getSemantics(find.bySemanticsLabel('Buckets')).flagsCollection.isSelected == Tristate.isTrue, isTrue);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Access points')).flagsCollection.isSelected == Tristate.isTrue,
      isFalse,
    );
    handle.dispose();
  });

  testWidgets('sections collapse and report onChange', (tester) async {
    final changes = <CsSideNavigationChangeDetail>[];
    await pumpCs(tester, _nav(onChange: changes.add), center: false);
    expect(find.text('Buckets'), findsOneWidget);
    await tester.tap(find.text('Storage'));
    await tester.pumpAndSettle();
    expect(find.text('Buckets'), findsNothing);
    expect(changes.single.item, _storage);
    expect(changes.single.expanded, isFalse);
    await tester.tap(find.text('Storage'));
    await tester.pumpAndSettle();
    expect(find.text('Buckets'), findsOneWidget);
  });

  testWidgets('expandable link groups open for an active child and on follow', (tester) async {
    final changes = <CsSideNavigationChangeDetail>[];
    await pumpCs(tester, _nav(onChange: changes.add), center: false);
    expect(find.text('Spot requests'), findsNothing);
    await tester.tap(find.text('Instances'));
    await tester.pumpAndSettle();
    expect(find.text('Spot requests'), findsOneWidget);
    expect(changes.single.expanded, isTrue);
    await pumpCs(tester, _nav(active: '/spot'), center: false);
    expect(find.text('Spot requests'), findsOneWidget);
  });

  testWidgets('the caret toggles an expandable link group with the keyboard', (tester) async {
    await pumpCs(tester, _nav(), center: false);
    final caret = find.byWidgetPredicate(
      (w) => w is CsPressable && w.expanded != null && w.semanticLabel == 'Instances',
    );
    expect(caret, findsOneWidget);
    tester.widget<Focus>(find.descendant(of: caret, matching: find.byType(Focus)).first).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Spot requests'), findsOneWidget);
  });

  testWidgets('collapsed shows only items with icons, with tooltips', (tester) async {
    const items = <CsSideNavigationItem>[
      CsSideNavigationLink(text: 'Dashboard', href: '/dashboard', icon: CsIcons.gridView),
      CsSideNavigationLink(text: 'Buckets', href: '/buckets', icon: CsIcons.folder),
      CsSideNavigationLink(text: 'No icon', href: '/plain'),
    ];
    final followed = <String>[];
    await pumpCs(
      tester,
      _nav(items: items, collapsed: true, active: '/buckets', onFollow: (d) => followed.add(d.href)),
      center: false,
    );
    expect(find.text('Service'), findsNothing);
    expect(find.text('Dashboard'), findsNothing);
    expect(find.byType(CsTooltip), findsNWidgets(2));
    await tester.tap(find.byType(CsIcon).first);
    expect(followed, ['/dashboard']);
  });

  testWidgets('items control slot and reduced motion', (tester) async {
    await pumpCs(
      tester,
      const CsSideNavigation(items: _items, itemsControl: Text('Region: us-east-1')),
      disableAnimations: true,
      center: false,
    );
    expect(find.text('Region: us-east-1'), findsOneWidget);
    await tester.tap(find.text('Storage'));
    await tester.pump();
    expect(find.text('Buckets'), findsNothing);
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    await pumpCs(tester, _nav(active: '/buckets'), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
  });
}
