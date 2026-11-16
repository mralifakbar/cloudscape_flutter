import 'dart:ui';

import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders every variant expanded and collapsed in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          SingleChildScrollView(
            child: Column(
              children: [
                for (final v in CsExpandableSectionVariant.values)
                  for (final e in [true, false])
                    CsExpandableSection(
                      variant: v,
                      headerText: '${v.name} $e',
                      headerCounter: '(2)',
                      headerDescription: 'Description',
                      headerInfo: const Text('Info'),
                      headerActions: const Text('Act'),
                      defaultExpanded: e,
                      child: const Text('Content'),
                    ),
              ],
            ),
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('uncontrolled: tap toggles and reports onChange', (tester) async {
    final changes = <bool>[];
    await pumpCs(
      tester,
      CsExpandableSection(headerText: 'Additional settings', onChange: changes.add, child: const Text('Body')),
    );
    expect(find.text('Body'), findsNothing);
    await tester.tap(find.text('Additional settings'));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOneWidget);
    expect(changes, [true]);
    await tester.tap(find.text('Additional settings'));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);
    expect(changes, [true, false]);
  });

  testWidgets('controlled: reflects expanded and does not change by itself', (tester) async {
    bool? next;
    await pumpCs(
      tester,
      CsExpandableSection(headerText: 'H', expanded: true, onChange: (v) => next = v, child: const Text('Body')),
    );
    expect(find.text('Body'), findsOneWidget);
    await tester.tap(find.text('H'));
    await tester.pumpAndSettle();
    expect(next, false);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('animates the reveal and snaps under reduced motion', (tester) async {
    await pumpCs(
      tester,
      const CsExpandableSection(
        headerText: 'H',
        child: SizedBox(height: 100, child: Text('Body')),
      ),
    );
    await tester.tap(find.text('H'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final mid = tester.getSize(find.byType(CsExpandableSection)).height;
    await tester.pumpAndSettle();
    final end = tester.getSize(find.byType(CsExpandableSection)).height;
    expect(mid, lessThan(end));

    await pumpCs(
      tester,
      const CsExpandableSection(
        key: ValueKey('reduced'),
        headerText: 'H',
        child: SizedBox(height: 100, child: Text('Body')),
      ),
      disableAnimations: true,
    );
    await tester.tap(find.text('H'));
    await tester.pump();
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('navigation variant toggles from the caret only', (tester) async {
    var n = 0;
    await pumpCs(
      tester,
      CsExpandableSection(
        variant: CsExpandableSectionVariant.navigation,
        headerText: 'Group',
        onChange: (_) => n++,
        child: const Text('Links'),
      ),
    );
    await tester.tap(find.text('Group'));
    await tester.pumpAndSettle();
    expect(n, 0);
    await tester.tap(find.bySemanticsLabel('Group').first);
    await tester.pumpAndSettle();
    expect(n, 1);
  });

  testWidgets('header actions do not toggle the container variant', (tester) async {
    var n = 0;
    var acted = 0;
    await pumpCs(
      tester,
      CsExpandableSection(
        variant: CsExpandableSectionVariant.container,
        headerText: 'Tags',
        headerActions: GestureDetector(onTap: () => acted++, child: const Text('Edit')),
        onChange: (_) => n++,
        child: const Text('Body'),
      ),
      size: csDesktopSize,
    );
    await tester.tap(find.text('Edit'));
    expect(acted, 1);
    expect(n, 0);
    await tester.tap(find.text('Tags'));
    expect(n, 1);
  });

  testWidgets('exposes expanded state and toggles with Enter', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsExpandableSection(headerText: 'Advanced', child: Text('Body')));
    expect(tester.getSemantics(find.text('Advanced')).flagsCollection.isExpanded, isNot(Tristate.isTrue));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(
      tester,
      const CsExpandableSection(
        variant: CsExpandableSectionVariant.container,
        headerText: 'Distribution origin settings',
        headerDescription: 'Origins and behaviors',
        defaultExpanded: true,
        child: Text('Content'),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
