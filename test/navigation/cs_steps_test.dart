import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/navigation/navigation.dart';
import 'package:cloudscape_flutter/src/status/status.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _steps = [
  CsStepsStep(status: CsStatusType.success, header: 'Instance launched', annotation: '10:02'),
  CsStepsStep(
    status: CsStatusType.loading,
    header: 'Running health checks',
    details: '2 of 3 checks complete',
    annotation: '10:04',
  ),
  CsStepsStep(status: CsStatusType.error, header: 'Attach volume', statusIconAriaLabel: 'Failed'),
  CsStepsStep(status: CsStatusType.pending, header: 'Register target'),
];

void main() {
  testWidgets('renders every orientation in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final o in CsStepsOrientation.values) {
          await pumpCs(
            tester,
            CsSteps(steps: _steps, orientation: o),
            brightness: b,
            density: d,
            size: csDesktopSize,
            settle: false,
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text('Attach volume'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('headers take the status color; details and annotations show', (tester) async {
    await pumpCs(tester, const CsSteps(steps: _steps), settle: false);
    final context = tester.element(find.byType(CsSteps));
    final style = tester.widget<Text>(find.text('Attach volume')).style!;
    expect(style.color, context.cs.colors.textStatusError);
    expect(find.text('2 of 3 checks complete'), findsOneWidget);
    expect(find.text('10:02'), findsOneWidget);
  });

  testWidgets('vertical steps stack; horizontal steps share a row', (tester) async {
    await pumpCs(tester, const CsSteps(steps: _steps), size: csDesktopSize, settle: false);
    expect(
      tester.getTopLeft(find.text('Register target')).dy,
      greaterThan(tester.getTopLeft(find.text('Attach volume')).dy),
    );
    await pumpCs(
      tester,
      const CsSteps(steps: _steps, orientation: CsStepsOrientation.horizontal),
      size: csDesktopSize,
      settle: false,
    );
    expect(tester.getTopLeft(find.text('Register target')).dy, tester.getTopLeft(find.text('Attach volume')).dy);
  });

  testWidgets('horizontal falls back to vertical on a phone', (tester) async {
    await pumpCs(tester, const CsSteps(steps: _steps, orientation: CsStepsOrientation.horizontal), settle: false);
    expect(
      tester.getTopLeft(find.text('Register target')).dy,
      greaterThan(tester.getTopLeft(find.text('Attach volume')).dy),
    );
  });

  testWidgets('renderStep replaces header, details and icon', (tester) async {
    await pumpCs(
      tester,
      CsSteps(
        steps: const [
          CsStepsStep(status: CsStatusType.success, header: 'a', data: 'bucket-a'),
          CsStepsStep(status: CsStatusType.info, header: 'b', data: 'bucket-b'),
        ],
        renderStep: (s) => CsStepsRenderedStep(
          header: Text('Create ${s.data}'),
          details: const Text('Custom details'),
          icon: const CsIcon(CsIcons.folder),
        ),
      ),
    );
    expect(find.text('Create bucket-a'), findsOneWidget);
    expect(find.text('Custom details'), findsNWidgets(2));
    expect(find.byType(CsIcon), findsNWidgets(2));
  });

  testWidgets('connector lines can be hidden', (tester) async {
    await pumpCs(tester, const CsSteps(steps: _steps, connectorLines: CsStepsConnectorLines.none), settle: false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('semantics: list label and the status is announced with the header', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsSteps(steps: _steps, ariaLabel: 'Launch progress'), settle: false);
    expect(find.bySemanticsLabel('Launch progress'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Failed\s+Attach volume')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Success\s+Instance launched')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    for (final o in CsStepsOrientation.values) {
      await pumpCs(
        tester,
        CsSteps(steps: _steps, orientation: o, minHorizontalStepWidth: 0),
        textScale: 2,
        settle: false,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
