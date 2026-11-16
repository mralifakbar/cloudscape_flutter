import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  test('every icon parses into a non-empty path inside its viewBox', () {
    expect(CsIcons.all, hasLength(148));
    for (final icon in CsIcons.all) {
      for (final part in icon.parts) {
        final bounds = CsIconData.pathOf(part).getBounds();
        expect(bounds.isFinite, isTrue, reason: icon.name);
        expect(bounds.left >= -1 && bounds.right <= 17, isTrue, reason: '${icon.name} $bounds');
      }
    }
  });

  test('parser handles relative commands, arcs and shorthand curves', () {
    final p = parseSvgPath('m2 2h4v4h-4z M8 8a2 2 0 1 0 4 0 S10 12 8 12 q1 1 2 2 t2 2');
    expect(p.getBounds().isFinite, isTrue);
    expect(p.getBounds().left, 2);
  });

  test('byName finds icons by their Cloudscape name', () {
    expect(CsIcons.byName('status-positive'), CsIcons.statusPositive);
    expect(CsIcons.byName('nope'), isNull);
  });

  testWidgets('every icon renders at every size in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpCs(
        tester,
        SingleChildScrollView(
          child: Wrap(
            children: [
              for (final icon in CsIcons.all)
                for (final s in CsIconSize.values) CsIcon(icon, size: s),
            ],
          ),
        ),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('decorative unless labeled; badge renders', (tester) async {
    await pumpCs(tester, const CsIcon(CsIcons.notification, semanticLabel: 'Notifications', badge: true));
    expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
    expect(tester.getSize(find.byType(CustomPaint).first), const Size(16, 16));
  });

  testWidgets('directional icons mirror in RTL without errors', (tester) async {
    await pumpCs(tester, const CsIcon(CsIcons.arrowRight), textDirection: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    expect(CsIcons.arrowRight.matchTextDirection, isTrue);
    expect(CsIcons.settings.matchTextDirection, isFalse);
  });
}
