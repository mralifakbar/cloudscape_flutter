import 'package:cloudscape_flutter/src/forms/forms.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

Widget _field({String? errorText, String? warningText, Widget? secondary, bool stretch = false}) => Padding(
  padding: const EdgeInsets.all(16),
  child: CsFormField(
    label: 'Bucket name',
    info: const Text('Info'),
    description: 'Must be unique across all accounts.',
    constraintText: 'Use 3 to 63 characters.',
    characterCountText: '12/63',
    errorText: errorText,
    warningText: warningText,
    secondaryControl: secondary,
    stretch: stretch,
    child: CsInput(value: 'example-bucket', invalid: errorText != null, onChange: (_) {}),
  ),
);

void main() {
  for (final brightness in Brightness.values) {
    for (final density in CsDensity.values) {
      testWidgets('renders in $brightness $density', (tester) async {
        await pumpCs(
          tester,
          _field(errorText: 'Name is taken.'),
          brightness: brightness,
          density: density,
        );
        expect(find.text('Bucket name'), findsOneWidget);
        expect(find.text('Use 3 to 63 characters. 12/63'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('error replaces warning and is announced', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, _field(errorText: 'Name is taken.', warningText: 'Name is long.'));
    expect(find.text('Name is taken.'), findsOneWidget);
    expect(find.text('Name is long.'), findsNothing);
    final node = tester.getSemantics(find.bySemanticsLabel('Error. Name is taken.'));
    expect(node.flagsCollection.isLiveRegion, isTrue);
    await pumpCs(tester, _field(warningText: 'Name is long.'));
    expect(find.bySemanticsLabel('Warning. Name is long.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('control takes 2/3 on desktop unless stretched, full width on phone', (tester) async {
    await pumpCs(tester, _field(), size: csDesktopSize, center: false);
    final full = tester.getSize(find.byType(CsFormField)).width;
    expect(tester.getSize(find.byType(CsInput)).width, closeTo(full * 0.66, 1));
    await pumpCs(tester, _field(stretch: true), size: csDesktopSize, center: false);
    expect(tester.getSize(find.byType(CsInput)).width, closeTo(full, 1));
    await pumpCs(tester, _field(), center: false);
    expect(tester.getSize(find.byType(CsInput)).width, tester.getSize(find.byType(CsFormField)).width);
  });

  testWidgets('secondary control sits beside on desktop and below on phone', (tester) async {
    const remove = Text('Remove');
    await pumpCs(tester, _field(secondary: remove), size: csDesktopSize);
    expect(tester.getTopLeft(find.text('Remove')).dy, lessThan(tester.getBottomLeft(find.byType(CsInput)).dy));
    await pumpCs(tester, _field(secondary: remove));
    expect(tester.getTopLeft(find.text('Remove')).dy, greaterThan(tester.getBottomLeft(find.byType(CsInput)).dy));
  });

  testWidgets('hidden label stays in semantics; 2x text fits', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      CsFormField(
        label: 'Search',
        labelHidden: true,
        child: CsInput(value: '', onChange: (_) {}),
      ),
      textScale: 2,
    );
    expect(find.text('Search'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Search')), findsWidgets);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
