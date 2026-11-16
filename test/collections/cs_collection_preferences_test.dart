import 'package:cloudscape_flutter/src/collections/collections.dart';
import 'package:cloudscape_flutter/src/collections/cs_collection_internal.dart';
import 'package:cloudscape_flutter/src/controls/cs_checkbox.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _options = [
  CsContentDisplayOption(id: 'id', label: 'Instance ID', alwaysVisible: true),
  CsContentDisplayOption(id: 'name', label: 'Name'),
  CsContentDisplayOption(id: 'state', label: 'State'),
];

Widget _prefs({
  CsCollectionPreferencesValue<bool> value = const CsCollectionPreferencesValue(pageSize: 10),
  ValueChanged<CsCollectionPreferencesValue<bool>>? onConfirm,
  VoidCallback? onCancel,
  bool disabled = false,
  bool content = true,
  bool filtering = false,
  bool visible = false,
}) => CsCollectionPreferences<bool>(
  preferences: value,
  onConfirm: onConfirm,
  onCancel: onCancel,
  disabled: disabled,
  pageSizePreference: const CsPageSizePreference(
    options: [
      CsPageSizeOption(value: 10, label: '10 instances'),
      CsPageSizeOption(value: 20, label: '20 instances'),
    ],
  ),
  wrapLinesPreference: const CsCheckboxPreference(),
  stripedRowsPreference: const CsCheckboxPreference(),
  contentDensityPreference: const CsCheckboxPreference(),
  stickyColumnsPreference: const CsStickyColumnsPreference(
    firstColumns: CsStickyColumnPreference(
      title: 'Stick first column(s)',
      description: 'Keep the first column(s) visible while horizontally scrolling.',
      options: [(label: 'None', value: 0), (label: 'First column', value: 1)],
    ),
  ),
  contentDisplayPreference: content
      ? CsContentDisplayPreference(options: _options, enableColumnFiltering: filtering)
      : null,
  visibleContentPreference: visible
      ? const CsVisibleContentPreference(
          title: 'Select visible content',
          options: [
            CsVisibleContentOptionsGroup(
              label: 'Instance properties',
              options: [
                CsVisibleContentOption(id: 'id', label: 'Instance ID', editable: false),
                CsVisibleContentOption(id: 'type', label: 'Type'),
              ],
            ),
          ],
        )
      : null,
  customPreference: (context, value, set) => CsCheckbox(checked: value ?? false, label: 'Show tags', onChange: set),
);

Finder _toggle(String label) => find.byWidgetPredicate((w) => w is CsCollectionToggle && w.semanticLabel == label);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Preferences'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('trigger renders in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(tester, _prefs(), brightness: b, density: d, size: csDesktopSize);
        await _open(tester);
        expect(find.text('Column preferences'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('confirm reports every configured preference', (tester) async {
    CsCollectionPreferencesValue<bool>? confirmed;
    await pumpCs(tester, _prefs(onConfirm: (v) => confirmed = v), size: csDesktopSize);
    await _open(tester);
    await tester.tap(find.text('20 instances'));
    await tester.tap(find.text('Wrap lines'));
    await tester.tap(find.text('Compact mode'));
    await tester.tap(find.text('First column'));
    await tester.tap(find.text('Show tags'));
    await tester.tap(_toggle('Name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Column preferences'), findsNothing);
    final v = confirmed!;
    expect(v.pageSize, 20);
    expect(v.wrapLines, isTrue);
    expect(v.stripedRows, isFalse);
    expect(v.contentDensity, CsDensity.compact);
    expect(v.stickyColumns, const CsStickyColumns(first: 1));
    expect(v.custom, isTrue);
    expect(v.contentDisplay!.firstWhere((d) => d.id == 'name').visible, isFalse);
    expect(v.contentDisplay!.length, 3);
  });

  testWidgets('cancel and Escape discard changes', (tester) async {
    var canceled = 0;
    CsCollectionPreferencesValue<bool>? confirmed;
    await pumpCs(
      tester,
      _prefs(onCancel: () => canceled++, onConfirm: (v) => confirmed = v),
      size: csDesktopSize,
    );
    await _open(tester);
    await tester.tap(find.text('20 instances'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(canceled, 1);
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(canceled, 2);
    expect(confirmed, isNull);
  });

  testWidgets('always visible columns cannot be hidden', (tester) async {
    await pumpCs(tester, _prefs(), size: csDesktopSize);
    await _open(tester);
    expect(tester.widget<CsCollectionToggle>(_toggle('Instance ID')).disabled, isTrue);
    expect(tester.widget<CsCollectionToggle>(_toggle('Instance ID')).checked, isTrue);
  });

  testWidgets('keyboard reorders columns', (tester) async {
    CsCollectionPreferencesValue<bool>? confirmed;
    await pumpCs(tester, _prefs(onConfirm: (v) => confirmed = v), size: csDesktopSize);
    await _open(tester);
    final handles = find.bySemanticsLabel('Drag handle');
    expect(handles, findsNWidgets(3));
    final focus = tester.widget<Focus>(find.ancestor(of: handles.at(2), matching: find.byType(Focus)).first);
    (focus.focusNode ?? Focus.of(tester.element(handles.at(2)))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(confirmed!.contentDisplay!.map((d) => d.id), ['id', 'state', 'name']);
  });

  testWidgets('drag reorders columns', (tester) async {
    CsCollectionPreferencesValue<bool>? confirmed;
    await pumpCs(tester, _prefs(onConfirm: (v) => confirmed = v), size: csDesktopSize);
    await _open(tester);
    final handle = find.bySemanticsLabel('Drag handle').at(0);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 50));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 50));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(confirmed!.contentDisplay!.first.id, isNot('id'));
  });

  testWidgets('column filtering narrows the list', (tester) async {
    await pumpCs(tester, _prefs(filtering: true), size: csDesktopSize);
    await _open(tester);
    await tester.enterText(find.byType(EditableText), 'stat');
    await tester.pumpAndSettle();
    expect(find.text('1 match'), findsOneWidget);
    expect(find.text('Name'), findsNothing);
    await tester.enterText(find.byType(EditableText), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No matches found'), findsOneWidget);
    await tester.tap(find.text('Clear filter'));
    await tester.pumpAndSettle();
    expect(find.text('Name'), findsOneWidget);
  });

  testWidgets('visible content preference toggles ids', (tester) async {
    CsCollectionPreferencesValue<bool>? confirmed;
    await pumpCs(
      tester,
      _prefs(
        content: false,
        visible: true,
        value: const CsCollectionPreferencesValue(visibleContent: ['id']),
        onConfirm: (v) => confirmed = v,
      ),
      size: csDesktopSize,
    );
    await _open(tester);
    await tester.tap(_toggle('Type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(confirmed!.visibleContent, ['id', 'type']);
  });

  testWidgets('disabled trigger does not open', (tester) async {
    await pumpCs(tester, _prefs(disabled: true), size: csDesktopSize);
    await tester.tap(find.bySemanticsLabel('Preferences'));
    await tester.pumpAndSettle();
    expect(find.text('Column preferences'), findsNothing);
  });

  testWidgets('phone: columns stack, no overflow at 2x text', (tester) async {
    await pumpCs(tester, _prefs(), textScale: 2);
    await _open(tester);
    expect(tester.takeException(), isNull);
    final page = tester.getTopLeft(find.text('Page size'));
    final columns = tester.getTopLeft(find.text('Column preferences'));
    expect(columns.dy, greaterThan(page.dy));
  });
}
