import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders horizontal, labelled and vertical in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CsDivider(),
              CsDivider(label: 'or'),
              SizedBox(height: 24, child: CsDivider(orientation: CsDividerOrientation.vertical)),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('horizontal line is 1px and full width', (tester) async {
    await pumpCs(tester, const Column(children: [CsDivider()]), center: false);
    final size = tester.getSize(find.byType(CsDivider));
    expect(size.width, csPhoneSize.width);
    expect(size.height, 1);
  });

  testWidgets('vertical line fills the given height', (tester) async {
    await pumpCs(tester, const SizedBox(height: 40, child: CsDivider(orientation: CsDividerOrientation.vertical)));
    expect(tester.getSize(find.byType(CsDivider)), const Size(1, 40));
  });

  testWidgets('uses the divider token color and the escape hatch', (tester) async {
    await pumpCs(tester, const CsDivider(dangerouslySetLineColor: Color(0xFFFF0000), lineWidth: 2));
    final box = tester.widget<ColoredBox>(
      find.descendant(of: find.byType(CsDivider), matching: find.byType(ColoredBox)),
    );
    expect(box.color, const Color(0xFFFF0000));
    expect(tester.getSize(find.byType(CsDivider)).height, 2);
  });

  testWidgets('label shows and survives 2x text at 390px', (tester) async {
    await pumpCs(tester, const CsDivider(label: 'Or continue with a long label text'), textScale: 2);
    expect(find.text('Or continue with a long label text'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
