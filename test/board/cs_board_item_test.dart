import 'package:cloudscape_flutter/src/board/board.dart';
import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          const CsBoardItem(
            header: CsHeader(title: 'Instance health'),
            footer: Text('Updated just now'),
            settings: Text('...'),
            child: Text('12 of 12 healthy'),
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Instance health'), findsOneWidget);
        expect(find.text('Updated just now'), findsOneWidget);
      }
    }
  });

  testWidgets('standalone items take their natural height and hide the resize handle', (tester) async {
    await pumpCs(tester, const CsBoardItem(header: Text('Alarms'), child: Text('None')));
    expect(tester.getSize(find.byType(CsBoardItem)).height, lessThan(200));
    expect(find.bySemanticsLabel('Resize handle'), findsNothing);
  });

  testWidgets('fills a fixed-height slot', (tester) async {
    await pumpCs(
      tester,
      const SizedBox(
        width: 300,
        height: 212,
        child: CsBoardItem(header: Text('Alarms'), child: Text('None')),
      ),
    );
    expect(tester.getSize(find.byType(CsBoardItem)), const Size(300, 212));
  });

  testWidgets('content paddings can be removed', (tester) async {
    await pumpCs(
      tester,
      const SizedBox(width: 300, child: CsBoardItem(disableContentPaddings: true, child: Text('Chart'))),
    );
    final padded = tester.getTopLeft(find.text('Chart')).dx - tester.getTopLeft(find.byType(CsBoardItem)).dx;
    expect(padded, 0);
  });

  testWidgets('drag handle exposes its label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      const CsBoardItem(
        header: Text('Alarms'),
        i18nStrings: CsBoardItemI18nStrings(dragHandleAriaLabel: 'Move Alarms'),
      ),
    );
    expect(find.bySemanticsLabel('Move Alarms'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('no overflow at 390px with 2x text', (tester) async {
    await pumpCs(
      tester,
      const CsBoardItem(
        header: CsHeader(title: 'Distribution d111111abcdef8 requests per minute'),
        child: Text('Requests are within the expected range for this time of day.'),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
