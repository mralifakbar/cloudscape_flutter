import 'dart:ui';

import 'package:cloudscape_flutter/src/navigation/navigation.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

List<String> _visibleLabels(WidgetTester tester) => tester
    .widgetList<Text>(find.descendant(of: find.byType(CsPagination), matching: find.byType(Text)))
    .map((t) => t.data ?? '')
    .where((s) => s.isNotEmpty)
    .toList();

void main() {
  group('window', () {
    String render(int current, int count, {bool openEnd = false}) {
      final w = CsPaginationWindow.of(current, count, openEnd: openEnd);
      return [
        1,
        if (w.leftDots) '...',
        for (var i = w.leftIndex; i <= w.rightIndex; i++) i,
        if (w.rightDots) '...',
        if (!openEnd && count > 1) count,
      ].join(' ');
    }

    test('matches Cloudscape', () {
      expect(render(1, 5), '1 2 3 4 5');
      expect(render(1, 20), '1 2 3 4 5 6 7 ... 20');
      expect(render(10, 20), '1 ... 8 9 10 11 12 ... 20');
      expect(render(20, 20), '1 ... 14 15 16 17 18 19 20');
      expect(render(1, 1), '1');
      expect(render(3, 3, openEnd: true), '1 2 3 ...');
    });
  });

  testWidgets('renders in light, dark and compact, disabled too', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final disabled in [false, true]) {
          await pumpCs(
            tester,
            CsPagination(currentPageIndex: 5, pagesCount: 20, disabled: disabled, onChange: (_) {}),
            brightness: b,
            density: d,
            size: csDesktopSize,
          );
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('page buttons and arrows call onChange', (tester) async {
    final changes = <int>[];
    final next = <CsPaginationPageClickDetail>[];
    final prev = <CsPaginationPageClickDetail>[];
    await pumpCs(
      tester,
      CsPagination(
        currentPageIndex: 2,
        pagesCount: 5,
        onChange: changes.add,
        onNextPageClick: next.add,
        onPreviousPageClick: prev.add,
      ),
      size: csDesktopSize,
    );
    await tester.tap(find.text('4'));
    await tester.tap(find.bySemanticsLabel('Next page'));
    await tester.tap(find.bySemanticsLabel('Previous page'));
    expect(changes, [4, 3, 1]);
    expect(next.single.requestedPageIndex, 3);
    expect(next.single.requestedPageAvailable, isTrue);
    expect(prev.single.requestedPageIndex, 1);
  });

  testWidgets('arrows disable at the ends; disabled blocks everything', (tester) async {
    final changes = <int>[];
    await pumpCs(tester, CsPagination(currentPageIndex: 1, pagesCount: 1, onChange: changes.add), size: csDesktopSize);
    await tester.tap(find.bySemanticsLabel('Previous page'), warnIfMissed: false);
    await tester.tap(find.bySemanticsLabel('Next page'), warnIfMissed: false);
    expect(changes, isEmpty);
    await pumpCs(
      tester,
      CsPagination(currentPageIndex: 2, pagesCount: 5, disabled: true, onChange: changes.add),
      size: csDesktopSize,
    );
    await tester.tap(find.text('3'), warnIfMissed: false);
    expect(changes, isEmpty);
  });

  testWidgets('open end: next is never disabled and reports unavailable pages', (tester) async {
    final next = <CsPaginationPageClickDetail>[];
    await pumpCs(
      tester,
      CsPagination(currentPageIndex: 3, pagesCount: 3, openEnd: true, onChange: (_) {}, onNextPageClick: next.add),
      size: csDesktopSize,
    );
    expect(find.text('...'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Next page'));
    expect(next.single.requestedPageAvailable, isFalse);
    expect(next.single.requestedPageIndex, 4);
  });

  testWidgets('compact variant shows "N of M" and "+" when open ended', (tester) async {
    await pumpCs(
      tester,
      CsPagination(
        currentPageIndex: 3,
        pagesCount: 12,
        pagesVariant: CsPaginationPagesVariant.compact,
        onChange: (_) {},
      ),
    );
    expect(find.text('3 of 12'), findsOneWidget);
    await pumpCs(
      tester,
      CsPagination(
        currentPageIndex: 3,
        pagesCount: 12,
        openEnd: true,
        pagesVariant: CsPaginationPagesVariant.compact,
        onChange: (_) {},
      ),
    );
    expect(find.text('3 of 12+'), findsOneWidget);
  });

  testWidgets('switches to compact when the pages do not fit a phone', (tester) async {
    await pumpCs(tester, CsPagination(currentPageIndex: 10, pagesCount: 20, onChange: (_) {}));
    expect(find.text('10 of 20'), findsOneWidget);
    await pumpCs(tester, CsPagination(currentPageIndex: 10, pagesCount: 20, onChange: (_) {}), size: csDesktopSize);
    expect(_visibleLabels(tester), ['1', '...', '8', '9', '10', '11', '12', '...', '20']);
  });

  testWidgets('semantics: page labels and the current page is selected', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      CsPagination(
        currentPageIndex: 2,
        pagesCount: 3,
        onChange: (_) {},
        ariaLabels: CsPaginationAriaLabels(paginationLabel: 'Instances pages', pageLabel: (n) => 'Go to page $n'),
      ),
      size: csDesktopSize,
    );
    expect(find.bySemanticsLabel('Instances pages'), findsOneWidget);
    final node = tester.getSemantics(find.bySemanticsLabel('Go to page 2'));
    expect(node.flagsCollection.isSelected == Tristate.isTrue, isTrue);
    handle.dispose();
  });

  testWidgets('keyboard: Tab to a page and press Enter', (tester) async {
    final changes = <int>[];
    await pumpCs(tester, CsPagination(currentPageIndex: 1, pagesCount: 3, onChange: changes.add), size: csDesktopSize);
    // Previous is disabled, so the first Tab lands on page 1, then 2.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(changes, [2]);
  });

  testWidgets('jump to page: navigates, and out of range goes to the last page with an error', (tester) async {
    final changes = <int>[];
    final key = GlobalKey<CsPaginationState>();
    Widget build(int page) => CsPagination(
      key: key,
      currentPageIndex: page,
      pagesCount: 10,
      jumpToPage: const CsPaginationJumpToPage(),
      onChange: changes.add,
    );
    await pumpCs(tester, build(1), size: csDesktopSize);
    await tester.enterText(find.byType(EditableText), '7');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Jump to page'));
    await tester.pumpAndSettle();
    expect(changes, [7]);
    await tester.enterText(find.byType(EditableText), '42');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(changes, [7, 10]);
    expect(find.text('Page out of range. Showing last available page.'), findsOneWidget);
    key.currentState!.setError(false);
    await tester.pumpAndSettle();
    expect(find.text('Page out of range. Showing last available page.'), findsNothing);
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    await pumpCs(
      tester,
      CsPagination(currentPageIndex: 5, pagesCount: 50, jumpToPage: const CsPaginationJumpToPage(), onChange: (_) {}),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
