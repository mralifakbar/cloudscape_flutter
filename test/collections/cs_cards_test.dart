import 'package:cloudscape_flutter/src/collections/collections.dart';
import 'package:cloudscape_flutter/src/layout/cs_header.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Dist {
  const _Dist(this.id, this.domain, this.status);
  final String id;
  final String domain;
  final String status;
}

const _items = [
  _Dist('d111111abcdef8', 'd111111abcdef8.example.net', 'Deployed'),
  _Dist('d222222abcdef8', 'd222222abcdef8.example.net', 'In progress'),
  _Dist('d333333abcdef8', 'd333333abcdef8.example.net', 'Deployed'),
  _Dist('d444444abcdef8', 'd444444abcdef8.example.net', 'Disabled'),
];

final _definition = CsCardDefinition<_Dist>(
  header: (context, d) => Text(d.id),
  sections: [
    CsCardSection<_Dist>(id: 'domain', header: 'Domain name', content: (context, d) => Text(d.domain)),
    CsCardSection<_Dist>(id: 'status', header: 'Status', content: (context, d) => Text(d.status), width: 50),
    CsCardSection<_Dist>(
      id: 'origin',
      header: 'Origin',
      content: (context, d) => const Text('example-bucket'),
      width: 50,
    ),
  ],
);

Widget _cards({
  List<_Dist> items = _items,
  CsSelectionType? selectionType,
  List<_Dist> selected = const [],
  ValueChanged<List<_Dist>>? onSelectionChange,
  bool loading = false,
  List<String>? visibleSections,
  CsCardsVariant variant = CsCardsVariant.container,
  bool entireCardClickable = false,
  bool Function(_Dist)? isItemDisabled,
  Widget? pagination,
}) {
  return SingleChildScrollView(
    child: CsCards<_Dist>(
      header: const CsHeader(title: 'Distributions', counter: '(4)'),
      items: items,
      cardDefinition: _definition,
      trackBy: (d) => d.id,
      selectionType: selectionType,
      selectedItems: selected,
      onSelectionChange: onSelectionChange,
      loading: loading,
      loadingText: 'Loading distributions',
      empty: const Text('No distributions'),
      visibleSections: visibleSections,
      variant: variant,
      entireCardClickable: entireCardClickable,
      isItemDisabled: isItemDisabled,
      pagination: pagination,
      ariaLabels: CsCardsAriaLabels<_Dist>(
        itemSelectionLabel: (selected, d) => 'Select ${d.id}',
        selectionGroupLabel: 'Distribution selection',
        cardsLabel: 'Distributions',
      ),
    ),
  );
}

void main() {
  testWidgets('renders in light, dark, comfortable and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(tester, _cards(), brightness: b, density: d, size: csDesktopSize, center: false);
        expect(find.text('d111111abcdef8'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  test('cards per row follows Cloudscape breakpoints', () {
    expect(CsCardsLayout.cardsPerRow(390, CsCardsLayout.defaults), 1);
    expect(CsCardsLayout.cardsPerRow(800, CsCardsLayout.defaults), 2);
    expect(CsCardsLayout.cardsPerRow(1000, CsCardsLayout.defaults), 3);
    expect(CsCardsLayout.cardsPerRow(1250, CsCardsLayout.defaults), 4);
    expect(CsCardsLayout.cardsPerRow(2000, const []), 6);
    expect(CsCardsLayout.cardsPerRow(500, const [CsCardsLayout(cards: 2, minWidth: 400)]), 2);
  });

  testWidgets('desktop lays cards side by side; phone stacks them', (tester) async {
    await pumpCs(tester, _cards(), size: csDesktopSize, center: false);
    final a = tester.getTopLeft(find.text('d111111abcdef8'));
    final b = tester.getTopLeft(find.text('d222222abcdef8'));
    expect(a.dy, b.dy);
    await pumpCs(tester, _cards(), center: false, textScale: 2);
    expect(tester.takeException(), isNull);
    final c = tester.getTopLeft(find.text('d111111abcdef8'));
    final d = tester.getTopLeft(find.text('d222222abcdef8'));
    expect(c.dx, d.dx);
    expect(d.dy, greaterThan(c.dy));
  });

  testWidgets('cards in a row share a height', (tester) async {
    await pumpCs(tester, _cards(visibleSections: const ['domain']), size: csDesktopSize, center: false);
    final cards = find.byType(CsItemCard);
    expect(tester.getSize(cards.at(0)).height, tester.getSize(cards.at(1)).height);
  });

  testWidgets('multi selection and entire card clickable', (tester) async {
    var selected = <_Dist>[];
    await pumpCs(
      tester,
      StatefulBuilder(
        builder: (context, setState) => _cards(
          selectionType: CsSelectionType.multi,
          selected: selected,
          entireCardClickable: true,
          isItemDisabled: (d) => d.status == 'Disabled',
          onSelectionChange: (next) => setState(() => selected = next),
        ),
      ),
      size: csDesktopSize,
      center: false,
    );
    await tester.tap(find.bySemanticsLabel('Select d111111abcdef8').first);
    await tester.pumpAndSettle();
    expect(selected.map((d) => d.id), ['d111111abcdef8']);
    await tester.tap(find.text('d222222abcdef8.example.net'));
    await tester.pumpAndSettle();
    expect(selected.length, 2);
    await tester.tap(find.text('d444444abcdef8.example.net'));
    await tester.pumpAndSettle();
    expect(selected.length, 2);
  });

  testWidgets('single selection replaces the selected card', (tester) async {
    var selected = <_Dist>[];
    await pumpCs(
      tester,
      StatefulBuilder(
        builder: (context, setState) => _cards(
          selectionType: CsSelectionType.single,
          selected: selected,
          onSelectionChange: (next) => setState(() => selected = next),
        ),
      ),
      size: csDesktopSize,
      center: false,
    );
    await tester.tap(find.bySemanticsLabel('Select d111111abcdef8'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Select d333333abcdef8'));
    await tester.pumpAndSettle();
    expect(selected.single.id, 'd333333abcdef8');
  });

  testWidgets('visible sections filter the card content', (tester) async {
    await pumpCs(tester, _cards(visibleSections: const ['status']), size: csDesktopSize, center: false);
    expect(find.text('Domain name'), findsNothing);
    expect(find.text('Status'), findsWidgets);
  });

  testWidgets('loading and empty states', (tester) async {
    await pumpCs(tester, _cards(loading: true), size: csDesktopSize, center: false, settle: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Loading distributions'), findsOneWidget);
    await pumpCs(tester, _cards(items: const []), size: csDesktopSize, center: false);
    expect(find.text('No distributions'), findsOneWidget);
  });

  testWidgets('full page on phones moves pagination below the cards', (tester) async {
    await pumpCs(tester, _cards(variant: CsCardsVariant.fullPage, pagination: const Text('Page 1')), center: false);
    final page = tester.getTopLeft(find.text('Page 1'));
    final card = tester.getTopLeft(find.text('d444444abcdef8'));
    expect(page.dy, greaterThan(card.dy));
  });

  testWidgets('cards label is exposed', (tester) async {
    await pumpCs(tester, _cards(), size: csDesktopSize, center: false, disableAnimations: true);
    expect(find.bySemanticsLabel('Distributions'), findsWidgets);
  });
}
