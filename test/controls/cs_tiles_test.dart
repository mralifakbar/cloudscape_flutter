import 'package:cloudscape_flutter/src/controls/controls.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _items = [
  CsTilesItem(value: 'mysql', label: 'MySQL', description: 'Open-source relational database.'),
  CsTilesItem(value: 'postgres', label: 'PostgreSQL', description: 'Extensible relational database.'),
  CsTilesItem(value: 'oracle', label: 'Oracle', disabled: true),
  CsTilesItem(
    value: 'mariadb',
    label: 'MariaDB',
    image: SizedBox(width: 40, height: 40, key: ValueKey('image')),
  ),
];

class _Host extends StatefulWidget {
  const _Host({this.initial, this.columns, this.onChange});

  final String? initial;
  final int? columns;
  final ValueChanged<String>? onChange;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String? value = widget.initial;

  @override
  Widget build(BuildContext context) => CsTiles(
    value: value,
    columns: widget.columns,
    items: _items,
    ariaLabel: 'Engine',
    onChange: (v) {
      widget.onChange?.call(v);
      setState(() => value = v);
    },
  );
}

void main() {
  for (final brightness in Brightness.values) {
    for (final density in CsDensity.values) {
      testWidgets('renders in $brightness $density', (tester) async {
        await pumpCs(
          tester,
          const _Host(initial: 'mysql'),
          brightness: brightness,
          density: density,
        );
        expect(find.text('MySQL'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('default columns follow the item count', () {
    expect([0, 1, 2, 3, 4, 5, 6, 8, 9].map(CsTiles.defaultColumns), [1, 1, 2, 3, 2, 3, 3, 2, 3]);
    expect(CsTiles.columnsAt(400, 3), 1);
    expect(CsTiles.columnsAt(600, 3), 2);
    expect(CsTiles.columnsAt(900, 4), 4);
  });

  testWidgets('tapping anywhere on a tile selects it', (tester) async {
    final changes = <String>[];
    await pumpCs(tester, _Host(onChange: changes.add));
    await tester.tap(find.byKey(const ValueKey('image')));
    await tester.tap(find.text('Oracle'));
    await tester.pumpAndSettle();
    expect(changes, ['mariadb']);
  });

  testWidgets('phone shows one column, desktop puts tiles side by side', (tester) async {
    await pumpCs(tester, const _Host(columns: 4), center: false);
    expect(tester.getTopLeft(find.text('PostgreSQL')).dy, greaterThan(tester.getTopLeft(find.text('MySQL')).dy));
    await pumpCs(tester, const _Host(columns: 4), size: csDesktopSize, center: false);
    expect(tester.getTopLeft(find.text('PostgreSQL')).dy, tester.getTopLeft(find.text('MySQL')).dy);
  });

  testWidgets('semantics and arrow keys', (tester) async {
    final handle = tester.ensureSemantics();
    final changes = <String>[];
    await pumpCs(tester, _Host(initial: 'mysql', onChange: changes.add));
    final node = tester.getSemantics(find.text('MySQL'));
    expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(changes, ['postgres', 'mariadb']);
    handle.dispose();
  });

  testWidgets('read-only does not change and 2x text fits', (tester) async {
    var calls = 0;
    await pumpCs(
      tester,
      CsTiles(value: 'mysql', readOnly: true, items: _items, onChange: (_) => calls++),
      textScale: 2,
      disableAnimations: true,
    );
    await tester.tap(find.text('PostgreSQL'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });
}
