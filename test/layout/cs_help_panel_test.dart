import 'package:cloudscape_flutter/src/feedback/cs_spinner.dart';
import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  Widget panel({bool loading = false}) => CsHelpPanel(
    header: 'Instances',
    loading: loading,
    footer: const Text('Learn more'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CsHelpPanel.heading('Overview', first: true),
        CsHelpPanel.paragraph('View your instances.'),
        CsHelpPanel.list(const ['Running', 'Stopped']),
        CsHelpPanel.divider(),
        CsHelpPanel.code('aws ec2 describe-instances'),
      ],
    ),
  );

  testWidgets('renders header, content and footer in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          SingleChildScrollView(child: panel()),
          brightness: b,
          density: d,
        );
        expect(find.text('Instances'), findsOneWidget);
        expect(find.text('Running'), findsOneWidget);
        expect(find.text('Learn more'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('loading replaces the content with a spinner and text', (tester) async {
    await pumpCs(tester, panel(loading: true), settle: false);
    await tester.pump();
    expect(find.byType(CsSpinner), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    expect(find.text('Running'), findsNothing);
  });

  testWidgets('custom loading text', (tester) async {
    await pumpCs(tester, const CsHelpPanel(loading: true, loadingText: 'Fetching help'), settle: false);
    await tester.pump();
    expect(find.text('Fetching help'), findsOneWidget);
  });

  testWidgets('header is a heading', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, panel());
    expect(tester.getSemantics(find.text('Instances')).flagsCollection.isHeader, isTrue);
    handle.dispose();
  });

  testWidgets('content uses the secondary body color', (tester) async {
    await pumpCs(tester, const CsHelpPanel(child: Text('Body')));
    final style = DefaultTextStyle.of(tester.element(find.text('Body'))).style;
    expect(style.color, CsThemeData.light().colors.textBodySecondary);
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, SingleChildScrollView(child: panel()), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
