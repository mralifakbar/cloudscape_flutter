import 'package:cloudscape_flutter/src/navigation/navigation.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

TextStyle _styleOf(WidgetTester tester, String text) {
  final rich = tester.widget<RichText>(find.descendant(of: find.byType(CsLink), matching: find.byType(RichText)).first);
  return rich.text.style!;
}

void main() {
  testWidgets('renders every variant and color in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Wrap(
            spacing: 8,
            children: [
              for (final v in CsLinkVariant.values) ...[
                CsLink(text: v.name, variant: v, onFollow: () {}),
                CsLink(text: '${v.name} inverted', variant: v, color: CsLinkColor.inverted, onFollow: () {}),
              ],
              CsLink(text: 'external', external: true, onFollow: () {}),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('onClick then onFollow fire on tap', (tester) async {
    final calls = <String>[];
    await pumpCs(
      tester,
      CsLink(text: 'Open bucket', onClick: () => calls.add('click'), onFollow: () => calls.add('follow')),
    );
    await tester.tap(find.text('Open bucket'));
    expect(calls, ['click', 'follow']);
  });

  testWidgets('defaults to secondary and follows CsLinkDefaults', (tester) async {
    await pumpCs(tester, CsLink(text: 'Plain', onFollow: () {}));
    expect(_styleOf(tester, 'Plain').decoration, TextDecoration.none);
    await pumpCs(
      tester,
      CsLinkDefaults(
        variant: CsLinkVariant.primary,
        child: CsLink(text: 'Inline', onFollow: () {}),
      ),
    );
    expect(_styleOf(tester, 'Inline').decoration, TextDecoration.underline);
  });

  testWidgets('secondary underlines on hover', (tester) async {
    await pumpCs(tester, CsLink(text: 'Hover me', onFollow: () {}));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('Hover me')));
    await tester.pump();
    expect(_styleOf(tester, 'Hover me').decoration, TextDecoration.underline);
  });

  testWidgets('info is bold body-s; value-large is display-l', (tester) async {
    await pumpCs(tester, CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: () {}));
    final info = _styleOf(tester, 'Info');
    expect(info.fontSize, CsTypeScale.bodyS.fontSize);
    expect(info.fontWeight, FontWeight.w700);
    await pumpCs(tester, CsLink(text: '42', variant: CsLinkVariant.awsuiValueLarge, onFollow: () {}));
    expect(_styleOf(tester, '42').fontSize, CsTypeScale.displayL.fontSize);
  });

  testWidgets('fontSize sets the type step', (tester) async {
    await pumpCs(tester, CsLink(text: 'Heading', fontSize: CsLinkFontSize.headingM, onFollow: () {}));
    expect(_styleOf(tester, 'Heading').fontSize, CsTypeScale.headingM.fontSize);
  });

  testWidgets('semantics: button without href, link with href or external', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, CsLink(text: 'Action', onFollow: () {}));
    expect(
      tester.getSemantics(find.byType(CsLink)),
      matchesSemantics(
        label: 'Action',
        isButton: true,
        hasTapAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasFocusAction: true,
      ),
    );
    await pumpCs(tester, CsLink(text: 'Docs', href: '/docs', external: true, onFollow: () {}));
    final node = tester.getSemantics(find.byType(CsLink));
    expect(node.flagsCollection.isLink, isTrue);
    expect(node.hint, 'Opens in a new window');
    handle.dispose();
  });

  testWidgets('ariaLabel replaces the text', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, CsLink(text: 'i-0abc123', ariaLabel: 'Instance i-0abc123', onFollow: () {}));
    expect(find.bySemanticsLabel('Instance i-0abc123'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Enter activates a focused link', (tester) async {
    var n = 0;
    final node = FocusNode();
    addTearDown(node.dispose);
    await pumpCs(tester, CsLink(text: 'Go', focusNode: node, onFollow: () => n++));
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(n, 1);
  });

  testWidgets('without callbacks it is inert text', (tester) async {
    await pumpCs(tester, const CsLink(text: 'Static'));
    expect(find.text('Static'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wraps at 390px with 2x text', (tester) async {
    await pumpCs(
      tester,
      CsLink(text: 'A long link text that has to wrap onto several lines on a phone', external: true, onFollow: () {}),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
