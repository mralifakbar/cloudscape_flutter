import 'dart:ui' show Tristate;

import 'package:cloudscape_flutter/src/collections/collections.dart';
import 'package:cloudscape_flutter/src/icons/cs_icon.dart';
import 'package:cloudscape_flutter/src/icons/cs_icons.g.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

Widget _card({
  VoidCallback? onPress,
  bool disabled = false,
  CsActionCardVariant variant = CsActionCardVariant.defaultVariant,
  CsActionCardIconVerticalAlignment align = CsActionCardIconVerticalAlignment.top,
  bool isLink = false,
  VoidCallback? onFollow,
}) => Padding(
  padding: const EdgeInsets.all(16),
  child: CsActionCard(
    header: const Text('Launch instance'),
    description: const Text('Start a virtual server from an image.'),
    icon: const CsIcon(CsIcons.angleRight),
    iconVerticalAlignment: align,
    variant: variant,
    disabled: disabled,
    isLink: isLink,
    onFollow: onFollow,
    ariaLabel: 'Launch instance',
    onPress: onPress,
    child: const Text('Free tier eligible'),
  ),
);

void main() {
  testWidgets('renders variants in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final v in CsActionCardVariant.values) {
          for (final a in CsActionCardIconVerticalAlignment.values) {
            await pumpCs(
              tester,
              _card(variant: v, align: a, onPress: () {}),
              brightness: b,
              density: d,
            );
            expect(find.text('Launch instance'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        }
      }
    }
  });

  testWidgets('press fires onPress', (tester) async {
    var pressed = 0;
    await pumpCs(tester, _card(onPress: () => pressed++));
    await tester.tap(find.text('Free tier eligible'));
    expect(pressed, 1);
  });

  testWidgets('disabled card ignores presses', (tester) async {
    var pressed = 0;
    await pumpCs(tester, _card(onPress: () => pressed++, disabled: true));
    await tester.tap(find.text('Launch instance'));
    expect(pressed, 0);
    final node = tester.getSemantics(find.bySemanticsLabel('Launch instance'));
    expect(node.flagsCollection.isEnabled, Tristate.isFalse);
  });

  testWidgets('semantics: button with label', (tester) async {
    await pumpCs(tester, _card(onPress: () {}));
    final node = tester.getSemantics(find.bySemanticsLabel('Launch instance'));
    expect(node.flagsCollection.isButton, isTrue);
  });

  testWidgets('link card follows', (tester) async {
    var followed = 0;
    await pumpCs(tester, _card(isLink: true, onFollow: () => followed++));
    await tester.tap(find.text('Launch instance'));
    expect(followed, 1);
    final node = tester.getSemantics(find.bySemanticsLabel('Launch instance'));
    expect(node.flagsCollection.isLink, isTrue);
  });

  testWidgets('keyboard: Tab focuses and Enter activates', (tester) async {
    var pressed = 0;
    await pumpCs(tester, _card(onPress: () => pressed++), tapTargetSize: CsTapTargetSize.shrinkWrap);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(pressed, 1);
  });

  testWidgets('390px with 2x text and reduced motion', (tester) async {
    await pumpCs(tester, _card(onPress: () {}), textScale: 2, disableAnimations: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fit height fills a bounded height', (tester) async {
    await pumpCs(
      tester,
      SizedBox(
        height: 300,
        child: CsActionCard(
          header: const Text('Create bucket'),
          fitHeight: true,
          onPress: () {},
          child: const Text('Body'),
        ),
      ),
    );
    expect(tester.getSize(find.byType(CsActionCard)).height, 300);
  });
}
