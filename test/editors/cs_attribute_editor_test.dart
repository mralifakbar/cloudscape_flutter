import 'package:cloudscape_flutter/src/buttons/buttons.dart';
import 'package:cloudscape_flutter/src/editors/editors.dart';
import 'package:cloudscape_flutter/src/forms/forms.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Var {
  _Var(this.key, this.value);
  String key;
  String value;
}

CsAttributeEditor<_Var> _editor(
  List<_Var> items, {
  VoidCallback? onAdd,
  ValueChanged<int>? onRemove,
  int? itemLimit,
  bool disableAdd = false,
  Key? key,
  List<CsAttributeEditorGridLayout>? gridLayout,
  bool Function(_Var)? removable,
}) {
  return CsAttributeEditor<_Var>(
    key: key,
    items: items,
    addButtonText: 'Add variable',
    empty: const Text('No variables.'),
    additionalInfo: const Text('You can add up to 5 variables.'),
    itemLimit: itemLimit,
    disableAddButton: disableAdd,
    gridLayout: gridLayout,
    isItemRemovable: removable,
    removeButtonAriaLabel: (v) => 'Remove ${v.key}',
    onAddButtonClick: onAdd,
    onRemoveButtonClick: onRemove,
    definition: [
      CsAttributeEditorField(
        label: 'Key',
        control: (v, i) => CsInput(value: v.key, onChange: (s) => v.key = s),
        errorText: (v, i) => v.key.isEmpty ? 'Enter a key.' : null,
      ),
      CsAttributeEditorField(
        label: 'Value',
        control: (v, i) => CsInput(value: v.value),
        constraintText: (v, i) => 'Up to 256 characters.',
      ),
    ],
  );
}

Widget _wrap(Widget child) => SingleChildScrollView(
  child: Padding(padding: const EdgeInsets.all(16), child: child),
);

void main() {
  testWidgets('renders in light, dark, comfortable and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(tester, _wrap(_editor([_Var('STAGE', 'prod'), _Var('', '')])), brightness: b, density: d);
        expect(tester.takeException(), isNull);
      }
    }
    expect(find.text('Enter a key.'), findsOneWidget);
    expect(find.text('Up to 256 characters.'), findsNWidgets(2));
  });

  testWidgets('add and remove fire callbacks', (tester) async {
    var added = 0;
    int? removed;
    await pumpCs(
      tester,
      _wrap(_editor([_Var('A', '1'), _Var('B', '2')], onAdd: () => added++, onRemove: (i) => removed = i)),
    );
    await tester.tap(find.text('Add variable'));
    await tester.tap(find.text('Remove').last);
    expect(added, 1);
    expect(removed, 1);
  });

  testWidgets('add is disabled at the item limit or when disabled', (tester) async {
    var added = 0;
    await pumpCs(tester, _wrap(_editor([_Var('A', '1')], onAdd: () => added++, itemLimit: 1)));
    await tester.tap(find.text('Add variable'), warnIfMissed: false);
    await pumpCs(tester, _wrap(_editor([], onAdd: () => added++, disableAdd: true)));
    await tester.tap(find.text('Add variable'), warnIfMissed: false);
    expect(added, 0);
  });

  testWidgets('shows empty state and additional info', (tester) async {
    await pumpCs(tester, _wrap(_editor([])));
    expect(find.text('No variables.'), findsOneWidget);
    expect(find.text('You can add up to 5 variables.'), findsOneWidget);
  });

  testWidgets('isItemRemovable hides the remove button', (tester) async {
    await pumpCs(tester, _wrap(_editor([_Var('A', '1'), _Var('B', '2')], removable: (v) => v.key != 'A')));
    expect(find.text('Remove'), findsOneWidget);
  });

  testWidgets('remove button has an accessible name', (tester) async {
    await pumpCs(tester, _wrap(_editor([_Var('STAGE', 'prod')])));
    expect(find.bySemanticsLabel('Remove STAGE'), findsOneWidget);
  });

  testWidgets('desktop keeps one line, phone stacks fields with a divider', (tester) async {
    await pumpCs(tester, _wrap(_editor([_Var('A', '1'), _Var('B', '2')])), size: csDesktopSize);
    final keyDesktop = tester.getTopLeft(find.byType(CsInput).at(0));
    final valueDesktop = tester.getTopLeft(find.byType(CsInput).at(1));
    expect(keyDesktop.dy, valueDesktop.dy);
    // Labels show once on a single line layout.
    expect(find.text('Key'), findsOneWidget);

    await pumpCs(tester, _wrap(_editor([_Var('A', '1'), _Var('B', '2')])), size: const Size(320, 800));
    final keyPhone = tester.getTopLeft(find.byType(CsInput).at(0));
    final valuePhone = tester.getTopLeft(find.byType(CsInput).at(1));
    expect(valuePhone.dy, greaterThan(keyPhone.dy));
    expect(find.text('Key'), findsNWidgets(2));
  });

  testWidgets('custom grid layout is honored', (tester) async {
    await pumpCs(
      tester,
      _wrap(
        _editor(
          [_Var('A', '1')],
          gridLayout: const [
            CsAttributeEditorGridLayout(
              rows: [
                [1],
                [1],
              ],
            ),
          ],
        ),
      ),
      size: csDesktopSize,
    );
    expect(
      tester.getTopLeft(find.byType(CsInput).at(1)).dy,
      greaterThan(tester.getTopLeft(find.byType(CsInput).at(0)).dy),
    );
  });

  testWidgets('focusAddButton and focusRemoveButton move focus', (tester) async {
    final key = GlobalKey<CsAttributeEditorState<_Var>>();
    await pumpCs(tester, _wrap(_editor([_Var('A', '1')], key: key, onAdd: () {}, onRemove: (_) {})));
    key.currentState!.focusAddButton();
    await tester.pump();
    final addFocus = FocusManager.instance.primaryFocus;
    expect(addFocus?.debugLabel, contains('add'));
    key.currentState!.focusRemoveButton(0);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, contains('remove 0'));
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, _wrap(_editor([_Var('STAGE', 'prod'), _Var('', '')])), textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add button is a CsButton', (tester) async {
    await pumpCs(tester, _wrap(_editor([])));
    expect(find.widgetWithText(CsButton, 'Add variable'), findsOneWidget);
  });
}
