import 'package:cloudscape_flutter/src/selection/selection.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({this.onDelayed});
  final ValueChanged<String>? onDelayed;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String text = '';
  @override
  Widget build(BuildContext context) => CsTextFilter(
    filteringText: text,
    filteringPlaceholder: 'Find instances',
    countText: '2 matches',
    onDelayedChange: widget.onDelayed,
    onChange: (v) => setState(() => text = v),
  );
}

void main() {
  testWidgets('renders in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          const CsTextFilter(filteringText: 'web', countText: '3 matches'),
          brightness: b,
          density: d,
        );
        expect(find.text('3 matches'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('onChange on every edit; count shows only with text', (tester) async {
    await pumpCs(tester, const _Host());
    expect(find.text('2 matches'), findsNothing);
    await tester.enterText(find.byType(EditableText), 'web');
    await tester.pump();
    expect(find.text('2 matches'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Clear'));
    await tester.pump();
    expect(find.text('2 matches'), findsNothing);
  });

  testWidgets('onDelayedChange fires after the pause', (tester) async {
    final delayed = <String>[];
    await pumpCs(tester, _Host(onDelayed: delayed.add));
    await tester.enterText(find.byType(EditableText), 'w');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(EditableText), 'we');
    await tester.pump(const Duration(milliseconds: 500));
    expect(delayed, ['we']);
  });

  testWidgets('disabled hides the count and blocks input', (tester) async {
    await pumpCs(tester, const CsTextFilter(filteringText: 'web', countText: '3 matches', disabled: true));
    expect(find.text('3 matches'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);
  });

  testWidgets('semantics: text field with the placeholder as label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsTextFilter(filteringText: '', filteringPlaceholder: 'Find instances'));
    expect(find.bySemanticsLabel('Find instances'), findsWidgets);
    handle.dispose();
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    await pumpCs(tester, const CsTextFilter(filteringText: 'web-server', countText: '25+ matches'), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
