import 'package:cloudscape_flutter/src/editors/editors.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _a = CsFile(name: 'report.pdf', size: 482133, type: 'application/pdf');
const _b = CsFile(name: 'logo.png', size: 2048, type: 'image/png');

void main() {
  testWidgets('renders both variants in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CsFileInput(value: const [], text: 'Choose file', onPick: (_) async => null),
              CsFileInput(
                value: const [],
                variant: CsFileInputVariant.icon,
                ariaLabel: 'Upload file',
                onPick: (_) async => null,
              ),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('tapping asks the picker and reports the files', (tester) async {
    CsFilePickRequest? request;
    List<CsFile>? picked;
    await pumpCs(
      tester,
      CsFileInput(
        value: const [],
        text: 'Choose files',
        multiple: true,
        accept: 'image/*',
        onPick: (r) async {
          request = r;
          return [_a, _b];
        },
        onChange: (f) => picked = f,
      ),
    );
    await tester.tap(find.text('Choose files'));
    await tester.pumpAndSettle();
    expect(request!.multiple, isTrue);
    expect(request!.accept, 'image/*');
    expect(picked, [_a, _b]);
  });

  testWidgets('single mode keeps only the first file; cancel reports nothing', (tester) async {
    List<CsFile>? picked;
    var result = <CsFile>[_a, _b];
    await pumpCs(
      tester,
      CsFileInput(value: const [], text: 'Choose file', onPick: (_) async => result, onChange: (f) => picked = f),
    );
    await tester.tap(find.text('Choose file'));
    await tester.pumpAndSettle();
    expect(picked, [_a]);
    picked = null;
    result = [];
    await tester.tap(find.text('Choose file'));
    await tester.pumpAndSettle();
    expect(picked, isNull);
  });

  testWidgets('disabled does not open the picker', (tester) async {
    var calls = 0;
    await pumpCs(
      tester,
      CsFileInput(
        value: const [],
        text: 'Choose file',
        disabled: true,
        onPick: (_) async {
          calls++;
          return null;
        },
      ),
    );
    await tester.tap(find.text('Choose file'), warnIfMissed: false);
    expect(calls, 0);
  });

  testWidgets('icon variant exposes its label; Enter activates', (tester) async {
    var calls = 0;
    final node = FocusNode();
    addTearDown(node.dispose);
    await pumpCs(
      tester,
      CsFileInput(
        value: const [],
        variant: CsFileInputVariant.icon,
        ariaLabel: 'Upload certificate',
        focusNode: node,
        onPick: (_) async {
          calls++;
          return null;
        },
      ),
    );
    expect(find.bySemanticsLabel('Upload certificate'), findsOneWidget);
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('2x text does not overflow', (tester) async {
    await pumpCs(tester, CsFileInput(value: const [], text: 'Choose files', onPick: (_) async => null), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
