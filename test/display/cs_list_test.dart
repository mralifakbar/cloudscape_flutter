import 'package:cloudscape_flutter/src/display/display.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _buckets = ['example-bucket', 'logs-bucket', 'backup-bucket'];

CsListItem _render(String name) => CsListItem(
  id: name,
  content: Text(name),
  secondaryContent: Text('Bucket in us-east-1 holding $name objects'),
  icon: const CsIcon(CsIcons.folder),
  actions: const Text('Open'),
);

class _Sortable extends StatefulWidget {
  const _Sortable({this.onChange, this.sortDisabled = false});
  final ValueChanged<List<String>>? onChange;
  final bool sortDisabled;
  @override
  State<_Sortable> createState() => _SortableState();
}

class _SortableState extends State<_Sortable> {
  List<String> items = List.of(_buckets);
  @override
  Widget build(BuildContext context) => CsList<String>(
    items: items,
    sortable: true,
    sortDisabled: widget.sortDisabled,
    renderItem: (s) => CsListItem(id: s, content: Text(s)),
    onSortingChange: (next) {
      setState(() => items = next);
      widget.onChange?.call(next);
    },
  );
}

void main() {
  testWidgets('renders plain and sortable in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CsList<String>(items: _buckets, renderItem: _render),
              CsList<String>(items: _buckets, renderItem: _render, sortable: true),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('example-bucket'), findsNWidgets(2));
      }
    }
  });

  testWidgets('items are padded by space-scaled-xs and separated by dividers', (tester) async {
    await pumpCs(
      tester,
      CsList<String>(
        items: _buckets,
        renderItem: (s) => CsListItem(id: s, content: Text(s)),
      ),
    );
    final first = tester.getRect(find.text('example-bucket'));
    final second = tester.getRect(find.text('logs-bucket'));
    // 8px bottom padding, 1px divider, 8px top padding.
    expect(second.top - first.bottom, 17);
    await pumpCs(
      tester,
      CsList<String>(
        items: _buckets,
        disableItemPaddings: true,
        renderItem: (s) => CsListItem(id: s, content: Text(s)),
      ),
    );
    expect(tester.getRect(find.text('logs-bucket')).top - tester.getRect(find.text('example-bucket')).bottom, 1);
  });

  testWidgets('disablePaddings removes the outer padding only', (tester) async {
    await pumpCs(
      tester,
      CsList<String>(
        items: _buckets,
        disablePaddings: true,
        renderItem: (s) => CsListItem(id: s, content: Text(s)),
      ),
    );
    expect(tester.getTopLeft(find.text('example-bucket')).dy, tester.getTopLeft(find.byType(CsList<String>)).dy);
  });

  testWidgets('secondary content uses small secondary text', (tester) async {
    await pumpCs(tester, const CsList<String>(items: _buckets, renderItem: _render));
    final ctx = tester.element(find.textContaining('holding example-bucket'));
    expect(DefaultTextStyle.of(ctx).style.color, ctx.cs.colors.textBodySecondary);
    expect(DefaultTextStyle.of(ctx).style.fontSize, CsTypeScale.bodyS.fontSize);
  });

  testWidgets('drag handle reorders by pointer', (tester) async {
    List<String>? result;
    await pumpCs(tester, _Sortable(onChange: (v) => result = v));
    final handles = find.byWidgetPredicate((w) => w is CsIcon && w.icon == CsIcons.dragIndicator);
    expect(handles, findsNWidgets(3));
    final start = tester.getCenter(handles.first);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 9));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(result, ['logs-bucket', 'backup-bucket', 'example-bucket']);
  });

  testWidgets('keyboard reorders: Space picks up, arrows move, Enter drops', (tester) async {
    List<String>? result;
    final handle = tester.ensureSemantics();
    await pumpCs(tester, _Sortable(onChange: (v) => result = v));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('example-bucket')).dy,
      greaterThan(tester.getTopLeft(find.text('backup-bucket')).dy),
    );
    expect(result, isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(result, ['logs-bucket', 'backup-bucket', 'example-bucket']);
    handle.dispose();
  });

  testWidgets('Escape discards a keyboard move', (tester) async {
    List<String>? result;
    await pumpCs(tester, _Sortable(onChange: (v) => result = v));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(tester.getTopLeft(find.text('example-bucket')).dy, lessThan(tester.getTopLeft(find.text('logs-bucket')).dy));
  });

  testWidgets('sortDisabled ignores the keyboard', (tester) async {
    List<String>? result;
    await pumpCs(tester, _Sortable(sortDisabled: true, onChange: (v) => result = v));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('drag handles carry label, hint and the item name; ordered lists give positions', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const _Sortable());
    expect(find.bySemanticsLabel(RegExp('Drag handle, logs-bucket')), findsOneWidget);
    final data = tester.getSemantics(find.bySemanticsLabel(RegExp('Drag handle, logs-bucket'))).getSemanticsData();
    expect(data.hint, contains('arrow keys'));
    await pumpCs(
      tester,
      const CsList<String>(items: _buckets, renderItem: _render, ordered: true, ariaLabel: 'Buckets'),
    );
    expect(find.bySemanticsLabel('Buckets'), findsOneWidget);
    handle.dispose();
  });

  test('default announcements match Cloudscape', () {
    const s = CsListI18nStrings();
    expect(s.liveAnnouncementDndStarted(1, 3), 'Picked up item at position 1 of 3');
    expect(s.liveAnnouncementDndItemReordered(1, 2, 3), 'Moving item to position 2 of 3');
    expect(s.liveAnnouncementDndItemReordered(2, 2, 3), 'Moving item back to position 2 of 3');
    expect(s.liveAnnouncementDndItemCommitted(1, 3, 3), 'Item moved from position 1 to position 3 of 3');
    expect(s.liveAnnouncementDndItemCommitted(2, 2, 3), 'Item moved back to its original position 2 of 3');
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, const CsList<String>(items: _buckets, renderItem: _render, sortable: true), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
