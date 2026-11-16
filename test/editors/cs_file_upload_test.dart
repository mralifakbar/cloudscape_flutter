import 'package:cloudscape_flutter/src/editors/editors.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _a = CsFile(name: 'server.crt', size: 2048, type: 'application/x-x509-ca-cert');
const _b = CsFile(name: 'chain.pem', size: 4096, type: 'application/x-pem-file');

Widget _upload({
  List<CsFile> value = const [],
  bool multiple = false,
  ValueChanged<List<CsFile>>? onChange,
  List<CsFile>? pick,
  String? errorText,
  String? warningText,
  List<String?>? fileErrors,
  bool dropzoneActive = false,
}) => SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: CsFileUpload(
      value: value,
      multiple: multiple,
      constraintText: 'PEM or CRT, up to 1 MB.',
      errorText: errorText,
      warningText: warningText,
      fileErrors: fileErrors,
      showFileSize: true,
      dropzoneActive: dropzoneActive,
      onPick: (_) async => pick ?? [_b],
      onChange: onChange,
    ),
  ),
);

void main() {
  testWidgets('renders in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          _upload(value: [_a], errorText: 'Upload failed.'),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
    expect(find.text('Choose file'), findsOneWidget);
    expect(find.text('PEM or CRT, up to 1 MB.'), findsOneWidget);
    expect(find.text('Upload failed.'), findsOneWidget);
  });

  testWidgets('single replaces, multiple appends', (tester) async {
    List<CsFile>? next;
    await pumpCs(tester, _upload(value: [_a], onChange: (v) => next = v));
    await tester.tap(find.text('Choose file'));
    await tester.pumpAndSettle();
    expect(next, [_b]);
    await pumpCs(tester, _upload(value: [_a], multiple: true, onChange: (v) => next = v));
    expect(find.text('Choose files'), findsOneWidget);
    await tester.tap(find.text('Choose files'));
    await tester.pumpAndSettle();
    expect(next, [_a, _b]);
  });

  testWidgets('removing a token drops it from the value', (tester) async {
    List<CsFile>? next;
    await pumpCs(tester, _upload(value: [_a, _b], multiple: true, onChange: (v) => next = v));
    await tester.tap(find.bySemanticsLabel('Remove file 1'));
    expect(next, [_b]);
  });

  testWidgets('warning shows only without an error; file errors show per token', (tester) async {
    await pumpCs(
      tester,
      _upload(value: [_a], warningText: 'Expires in 10 days.', fileErrors: ['Invalid certificate.']),
    );
    expect(find.text('Expires in 10 days.'), findsOneWidget);
    expect(find.text('Invalid certificate.'), findsOneWidget);
    await pumpCs(tester, _upload(errorText: 'Required.', warningText: 'Expires in 10 days.'));
    expect(find.text('Expires in 10 days.'), findsNothing);
  });

  testWidgets('dropzoneActive swaps the button for the dropzone', (tester) async {
    await pumpCs(tester, _upload(dropzoneActive: true));
    expect(find.byType(CsFileDropzone), findsOneWidget);
    expect(find.text('Drop file to upload'), findsOneWidget);
    expect(find.text('Choose file'), findsNothing);
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, _upload(value: [_a, _b], multiple: true, errorText: 'Upload failed.'), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
