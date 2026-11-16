import 'package:cloudscape_flutter/src/feedback/cs_spinner.dart';
import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  Widget drawer({bool loading = false, ValueChanged<CsDrawerCloseMethod>? onClose}) => SizedBox(
    width: 320,
    height: 500,
    child: CsDrawer(
      header: const Text('Instance details'),
      headerActions: const Text('Act'),
      footer: const Text('Footer'),
      loading: loading,
      onClose: onClose,
      child: const Text('i-0abc123'),
    ),
  );

  testWidgets('renders header, content and footer in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          drawer(onClose: (_) {}),
          brightness: b,
          density: d,
        );
        expect(find.text('Instance details'), findsOneWidget);
        expect(find.text('i-0abc123'), findsOneWidget);
        expect(find.text('Footer'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('sticky footer sits at the bottom of the drawer', (tester) async {
    await pumpCs(tester, drawer());
    final drawerBottom = tester.getRect(find.byType(CsDrawer)).bottom;
    expect(tester.getBottomLeft(find.text('Footer')).dy, greaterThan(drawerBottom - 40));
  });

  testWidgets('loading shows a spinner and the loading text', (tester) async {
    await pumpCs(tester, drawer(loading: true), settle: false);
    await tester.pump();
    expect(find.byType(CsSpinner), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    expect(find.text('i-0abc123'), findsNothing);
  });

  testWidgets('close button reports closeAction and only shows with onClose', (tester) async {
    CsDrawerCloseMethod? m;
    await pumpCs(tester, drawer());
    expect(find.bySemanticsLabel('Close'), findsNothing);
    await pumpCs(tester, drawer(onClose: (v) => m = v));
    await tester.tap(find.bySemanticsLabel('Close'));
    expect(m, CsDrawerCloseMethod.closeAction);
  });

  testWidgets('fixed drawer slides in, closes with Escape and backdrop', (tester) async {
    final methods = <CsDrawerCloseMethod>[];
    Widget build(bool open) => CsDrawer(
      position: CsDrawerPosition.fixed,
      open: open,
      backdrop: true,
      header: const Text('Filters'),
      onClose: methods.add,
      child: const Text('Body'),
    );
    await pumpCs(tester, build(false), size: csDesktopSize);
    expect(find.text('Body'), findsNothing);
    await pumpCs(tester, build(true), size: csDesktopSize);
    expect(find.text('Body'), findsOneWidget);
    expect(tester.getSize(find.byType(SizedBox).last).width, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(methods, contains(CsDrawerCloseMethod.escape));
    await tester.tapAt(const Offset(20, 400));
    expect(methods, contains(CsDrawerCloseMethod.backdropClick));
    await pumpCs(tester, build(false), size: csDesktopSize);
    expect(find.text('Body'), findsNothing);
  });

  testWidgets('fixed drawer takes the full width on phones', (tester) async {
    await pumpCs(
      tester,
      const CsDrawer(position: CsDrawerPosition.fixed, header: Text('Filters'), child: Text('Body')),
    );
    expect(tester.getSize(find.text('Body')).width, lessThan(390));
    expect(tester.getRect(find.byType(DecoratedBox).last).width, 390);
  });

  testWidgets('absolute drawer covers its parent from the start edge', (tester) async {
    await pumpCs(
      tester,
      const SizedBox(
        width: 600,
        height: 400,
        child: Stack(
          children: [
            Positioned.fill(
              child: CsDrawer(
                position: CsDrawerPosition.absolute,
                placement: CsDrawerPlacement.start,
                size: 200,
                child: Text('Body'),
              ),
            ),
          ],
        ),
      ),
      size: csDesktopSize,
    );
    expect(tester.getTopLeft(find.text('Body')).dx, lessThan(tester.getCenter(find.byType(Stack).first).dx));
  });

  testWidgets('header is a heading', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, drawer());
    expect(tester.getSemantics(find.text('Instance details')).flagsCollection.isHeader, isTrue);
    handle.dispose();
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, drawer(onClose: (_) {}), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
