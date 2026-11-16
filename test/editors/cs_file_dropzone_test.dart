import 'package:cloudscape_flutter/src/editors/editors.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _a = CsFile(name: 'report.pdf', size: 482133, type: 'application/pdf');

Color? _background(WidgetTester tester) {
  final box = tester
      .widgetList<Container>(find.descendant(of: find.byType(CsFileDropzone), matching: find.byType(Container)))
      .map((c) => c.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.color != null);
  return box.color;
}

void main() {
  testWidgets('renders idle and active in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final active in [false, true]) {
        await pumpCs(
          tester,
          CsFileDropzone(active: active, child: const Text('Drop files to upload')),
          brightness: b,
        );
        expect(tester.takeException(), isNull);
        final c = (b == Brightness.dark ? CsThemeData.dark() : CsThemeData.light()).colors;
        expect(_background(tester), active ? c.dropzoneBackgroundHover : c.dropzoneBackgroundDefault);
      }
    }
  });

  testWidgets('tap opens the picker and reports files', (tester) async {
    List<CsFile>? got;
    await pumpCs(
      tester,
      CsFileDropzone(
        semanticLabel: 'Choose files',
        onPick: (_) async => [_a],
        onChange: (f) => got = f,
        child: const Text('Drop files to upload'),
      ),
    );
    await tester.tap(find.text('Drop files to upload'));
    await tester.pumpAndSettle();
    expect(got, [_a]);
    expect(find.bySemanticsLabel('Choose files'), findsOneWidget);
  });

  testWidgets('in-app drags light it up and drop files', (tester) async {
    List<CsFile>? got;
    await pumpCs(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Draggable<CsFile>(data: _a, feedback: SizedBox(width: 10, height: 10), child: Text('report.pdf')),
          const SizedBox(height: 40),
          SizedBox(
            width: 300,
            child: CsFileDropzone(onChange: (f) => got = f, child: const Text('Drop here')),
          ),
        ],
      ),
    );
    final gesture = await tester.startGesture(tester.getCenter(find.text('report.pdf')));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(find.text('Drop here')));
    await tester.pump();
    expect(_background(tester), CsThemeData.light().colors.dropzoneBackgroundHover);
    await gesture.up();
    await tester.pump();
    expect(got, [_a]);
    expect(_background(tester), CsThemeData.light().colors.dropzoneBackgroundDefault);
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(
      tester,
      const CsFileDropzone(child: Text('Drop files to upload, or choose them from your device')),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
