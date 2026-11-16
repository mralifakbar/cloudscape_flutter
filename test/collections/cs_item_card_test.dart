import 'dart:ui' show Tristate;

import 'package:cloudscape_flutter/src/buttons/cs_button.dart';
import 'package:cloudscape_flutter/src/collections/collections.dart';
import 'package:cloudscape_flutter/src/icons/cs_icon.dart';
import 'package:cloudscape_flutter/src/icons/cs_icons.g.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

Widget _card({
  CsItemCardVariant variant = CsItemCardVariant.defaultVariant,
  bool highlighted = false,
  VoidCallback? onPress,
  VoidCallback? onAction,
  bool fitHeight = false,
}) => Padding(
  padding: const EdgeInsets.all(16),
  child: CsItemCard(
    variant: variant,
    highlighted: highlighted,
    onPress: onPress,
    semanticLabel: 'example-bucket card',
    fitHeight: fitHeight,
    icon: const CsIcon(CsIcons.folder),
    header: const Text('example-bucket'),
    description: const Text('us-east-1'),
    actions: CsButton(
      icon: CsIcons.ellipsis,
      variant: CsButtonVariant.icon,
      semanticLabel: 'Actions',
      onPress: onAction,
    ),
    footer: const Text('Updated 2 hours ago'),
    child: const Text('Versioning enabled'),
  ),
);

void main() {
  testWidgets('renders every slot in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final v in CsItemCardVariant.values) {
          await pumpCs(
            tester,
            _card(variant: v),
            brightness: b,
            density: d,
          );
          expect(find.text('example-bucket'), findsOneWidget);
          expect(find.text('us-east-1'), findsOneWidget);
          expect(find.text('Versioning enabled'), findsOneWidget);
          expect(find.text('Updated 2 hours ago'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('header is announced as a heading', (tester) async {
    await pumpCs(tester, _card());
    final node = tester.getSemantics(find.text('example-bucket'));
    expect(node.flagsCollection.isHeader, isTrue);
  });

  testWidgets('actions are pressable', (tester) async {
    var pressed = 0;
    await pumpCs(tester, _card(onAction: () => pressed++));
    await tester.tap(find.bySemanticsLabel('Actions'));
    expect(pressed, 1);
  });

  testWidgets('pressable card fires onPress and exposes selected state', (tester) async {
    var pressed = 0;
    await pumpCs(tester, _card(onPress: () => pressed++, highlighted: true));
    await tester.tap(find.text('Versioning enabled'));
    expect(pressed, 1);
    final node = tester.getSemantics(find.bySemanticsLabel('example-bucket card'));
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
  });

  testWidgets('fit height fills a bounded height and pushes the footer down', (tester) async {
    await pumpCs(tester, SizedBox(height: 400, child: _card(fitHeight: true)));
    final footer = tester.getBottomLeft(find.text('Updated 2 hours ago'));
    expect(footer.dy, greaterThan(300));
  });

  testWidgets('390px with 2x text does not overflow', (tester) async {
    await pumpCs(tester, _card(), textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('style overrides apply', (tester) async {
    await pumpCs(
      tester,
      const CsItemCard(
        header: Text('Styled'),
        style: CsItemCardStyle(
          background: Color(0xFFFFEEDD),
          borderRadius: 4,
          footerDividerColor: Color(0xFF000000),
          contentPadding: EdgeInsets.all(2),
        ),
        footer: Text('Footer'),
        child: Text('Body'),
      ),
      disableAnimations: true,
    );
    expect(find.text('Body'), findsOneWidget);
  });
}
