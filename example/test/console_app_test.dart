import 'package:cloudscape_flutter_example/main.dart';
import 'package:cloudscape_flutter_example/sample/console_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (name, size) in [('phone', const Size(390, 844)), ('desktop', const Size(1280, 800))]) {
    for (final section in ConsoleSection.values) {
      testWidgets('console ${section.name} renders on $name in light and dark', (tester) async {
        tester.view.physicalSize = size * tester.view.devicePixelRatio;
        addTearDown(tester.view.resetPhysicalSize);
        for (final b in Brightness.values) {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(size: size, platformBrightness: b),
              child: GalleryApp(home: ConsoleApp(initialSection: section)),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  testWidgets('filtering the instances table narrows the rows', (tester) async {
    tester.view.physicalSize = const Size(1280, 800) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const GalleryApp(home: ConsoleApp()));
    await tester.pumpAndSettle();
    Finder counter(String text) => find.textContaining(text, findRichText: true);
    expect(counter('(46)'), findsWidgets);
    await tester.enterText(find.byType(EditableText).first, 'batch');
    await tester.pumpAndSettle();
    expect(counter('(46)'), findsNothing);
    expect(counter('(6)'), findsWidgets);
  });
}
