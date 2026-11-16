import 'dart:ui';

import 'package:cloudscape_flutter/src/navigation/navigation.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _anchors = [
  CsAnchorNavigationAnchor(text: 'Overview', href: '#overview'),
  CsAnchorNavigationAnchor(text: 'Pricing', href: '#pricing'),
  CsAnchorNavigationAnchor(text: 'On-demand', href: '#on-demand', level: 2, info: 'Updated'),
  CsAnchorNavigationAnchor(text: 'Limits', href: '#limits'),
];

bool _isSelected(WidgetTester tester, String label) =>
    tester.getSemantics(find.bySemanticsLabel(RegExp('^$label'))).flagsCollection.isSelected == Tristate.isTrue;

/// A scrollable page with one 600px section per anchor and the navigation
/// beside it.
class _Page extends StatefulWidget {
  const _Page({this.onActive});

  final ValueChanged<CsAnchorNavigationAnchor>? onActive;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  final controller = ScrollController();
  final keys = {for (final a in _anchors) a.href: GlobalKey()};
  late final spy = CsAnchorScrollSpy(controller: controller, sections: keys);

  @override
  void dispose() {
    spy.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 200,
        child: CsAnchorNavigation(anchors: _anchors, scrollSpy: spy, onActiveHrefChange: widget.onActive),
      ),
      Expanded(
        child: SingleChildScrollView(
          controller: controller,
          child: Column(
            children: [
              for (final a in _anchors) SizedBox(key: keys[a.href], height: 600, child: Text('Section ${a.text}')),
            ],
          ),
        ),
      ),
    ],
  );
}

void main() {
  testWidgets('renders in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          const CsAnchorNavigation(anchors: _anchors, activeHref: '#pricing'),
          brightness: b,
          density: d,
        );
        expect(find.text('Updated'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('controlled activeHref is selected and reported', (tester) async {
    final handle = tester.ensureSemantics();
    final reported = <String>[];
    await pumpCs(
      tester,
      CsAnchorNavigation(anchors: _anchors, activeHref: '#pricing', onActiveHrefChange: (a) => reported.add(a.href)),
    );
    expect(_isSelected(tester, 'Pricing'), isTrue);
    expect(_isSelected(tester, 'Overview'), isFalse);
    expect(reported, ['#pricing']);
    await pumpCs(
      tester,
      CsAnchorNavigation(anchors: _anchors, activeHref: '#limits', onActiveHrefChange: (a) => reported.add(a.href)),
    );
    expect(reported, ['#pricing', '#limits']);
    handle.dispose();
  });

  testWidgets('nested anchors indent by level', (tester) async {
    await pumpCs(tester, const SizedBox(width: 300, child: CsAnchorNavigation(anchors: _anchors)));
    final top = tester.getTopLeft(find.textContaining('Pricing', findRichText: true)).dx;
    final nested = tester.getTopLeft(find.textContaining('On-demand', findRichText: true)).dx;
    expect(nested - top, 16);
  });

  testWidgets('tap and Enter call onFollow', (tester) async {
    final followed = <String>[];
    await pumpCs(tester, CsAnchorNavigation(anchors: _anchors, onFollow: (a) => followed.add(a.href)));
    await tester.tap(find.textContaining('Limits', findRichText: true));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(followed, ['#limits', '#overview']);
  });

  testWidgets('scroll spy follows the scroll position', (tester) async {
    final handle = tester.ensureSemantics();
    final reported = <String>[];
    await pumpCs(tester, _Page(onActive: (a) => reported.add(a.href)), size: csDesktopSize, center: false);
    await tester.pumpAndSettle();
    expect(_isSelected(tester, 'Overview'), isTrue);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1250));
    await tester.pumpAndSettle();
    expect(_isSelected(tester, 'On-demand'), isTrue);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(_isSelected(tester, 'Limits'), isTrue);
    expect(reported.first, '#overview');
    expect(reported.last, '#limits');
    handle.dispose();
  });

  testWidgets('following an anchor scrolls to its section', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const _Page(), size: csDesktopSize, center: false);
    await tester.tap(
      find.descendant(
        of: find.byType(CsAnchorNavigation),
        matching: find.textContaining('Pricing', findRichText: true),
      ),
    );
    await tester.pumpAndSettle();
    final state = tester.state<_PageState>(find.byType(_Page));
    expect(state.controller.offset, 600);
    expect(_isSelected(tester, 'Pricing'), isTrue);
    handle.dispose();
  });

  testWidgets('reduced motion and 2x text at 390px', (tester) async {
    await pumpCs(
      tester,
      const CsAnchorNavigation(anchors: _anchors, activeHref: '#on-demand'),
      disableAnimations: true,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
