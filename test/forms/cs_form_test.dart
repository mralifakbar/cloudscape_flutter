import 'package:cloudscape_flutter/src/forms/forms.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

Widget _form({String? errorText}) => Padding(
  padding: const EdgeInsets.all(16),
  child: CsForm(
    header: const Text('Create bucket'),
    errorText: errorText,
    secondaryActions: const SizedBox(width: 120, height: 32, child: Text('Save draft')),
    actions: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 100, height: 32, child: Text('Cancel')),
        SizedBox(width: 180, height: 32, child: Text('Create bucket now')),
      ],
    ),
    child: CsFormField(
      label: 'Bucket name',
      child: CsInput(value: 'example-bucket', onChange: (_) {}),
    ),
  ),
);

void main() {
  for (final brightness in Brightness.values) {
    for (final density in CsDensity.values) {
      testWidgets('renders in $brightness $density', (tester) async {
        await pumpCs(
          tester,
          _form(errorText: 'Bucket limit reached.'),
          brightness: brightness,
          density: density,
        );
        expect(find.text('Bucket limit reached.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('order: header, content, error, actions', (tester) async {
    await pumpCs(tester, _form(errorText: 'Bucket limit reached.'), size: csDesktopSize);
    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    expect(y('Create bucket'), lessThan(y('Bucket name')));
    expect(y('Bucket name'), lessThan(y('Bucket limit reached.')));
    expect(y('Bucket limit reached.'), lessThan(y('Cancel')));
  });

  testWidgets('desktop: primary actions at the end, secondary at the start of one row', (tester) async {
    await pumpCs(tester, _form(), size: csDesktopSize, center: false);
    expect(y(tester, 'Save draft'), y(tester, 'Cancel'));
    expect(tester.getTopLeft(find.text('Save draft')).dx, lessThan(tester.getTopLeft(find.text('Cancel')).dx));
    expect(tester.getTopRight(find.text('Create bucket now')).dx, closeTo(csDesktopSize.width - 16, 1));
  });

  testWidgets('phone: secondary actions wrap under the primary ones', (tester) async {
    await pumpCs(tester, _form(), center: false);
    expect(y(tester, 'Save draft'), greaterThan(y(tester, 'Cancel')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('error is a live region with the icon label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsForm(errorText: 'Bucket limit reached.', errorIconAriaLabel: 'Problem'));
    final node = tester.getSemantics(find.bySemanticsLabel('Problem, Bucket limit reached.'));
    expect(node.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });

  testWidgets('2x text', (tester) async {
    await pumpCs(tester, _form(errorText: 'Bucket limit reached.'), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}

double y(WidgetTester tester, String text) => tester.getTopLeft(find.text(text)).dy;
