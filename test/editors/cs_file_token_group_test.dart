import 'package:cloudscape_flutter/src/editors/editors.dart';
import 'package:cloudscape_flutter/src/feedback/cs_spinner.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

final _files = [
  CsFile(
    name: 'invoice-2024-01.pdf',
    size: 482133,
    lastModified: DateTime(2024, 1, 15, 13, 45),
    type: 'application/pdf',
  ),
  const CsFile(name: 'diagram.png', size: 1200000, type: 'image/png'),
  const CsFile(name: 'notes.txt', size: 512, type: 'text/plain'),
];

Widget _group({
  List<CsFileTokenGroupItem>? items,
  ValueChanged<int>? onDismiss,
  int? limit,
  bool readOnly = false,
  CsFileTokenGroupAlignment alignment = CsFileTokenGroupAlignment.vertical,
}) => SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: CsFileTokenGroup(
      items: items ?? [for (final f in _files) CsFileTokenGroupItem(file: f)],
      showFileSize: true,
      showFileLastModified: true,
      showFileThumbnail: true,
      onDismiss: onDismiss ?? (_) {},
      limit: limit,
      readOnly: readOnly,
      alignment: alignment,
    ),
  ),
);

void main() {
  testWidgets('renders in every theme with metadata', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(tester, _group(), brightness: b, density: d);
        expect(tester.takeException(), isNull);
      }
    }
    expect(find.text('482.13 KB'), findsOneWidget);
    expect(find.text('1.20 MB'), findsOneWidget);
    expect(find.text('2024-01-15T13:45:00'), findsOneWidget);
  });

  testWidgets('dismiss reports the index and has a label', (tester) async {
    int? dismissed;
    await pumpCs(tester, _group(onDismiss: (i) => dismissed = i));
    expect(find.bySemanticsLabel('Remove file 2, diagram.png'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Remove file 2, diagram.png'));
    expect(dismissed, 1);
  });

  testWidgets('read-only tokens cannot be dismissed', (tester) async {
    int? dismissed;
    await pumpCs(tester, _group(readOnly: true, onDismiss: (i) => dismissed = i));
    await tester.tap(find.bySemanticsLabel('Remove file 1, invoice-2024-01.pdf'), warnIfMissed: false);
    expect(dismissed, isNull);
  });

  testWidgets('loading, error and warning states', (tester) async {
    await pumpCs(
      tester,
      _group(
        items: [
          CsFileTokenGroupItem(file: _files[0], loading: true),
          CsFileTokenGroupItem(file: _files[1], errorText: 'File is larger than 1 MB.'),
          CsFileTokenGroupItem(file: _files[2], warningText: 'Plain text files are not encrypted.'),
        ],
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CsSpinner), findsOneWidget);
    expect(find.text('File is larger than 1 MB.'), findsOneWidget);
    expect(find.text('Plain text files are not encrypted.'), findsOneWidget);
  });

  testWidgets('limit hides tokens behind a show more toggle', (tester) async {
    await pumpCs(tester, _group(limit: 1));
    expect(find.text('notes.txt'), findsNothing);
    expect(find.text('Show more (+2)'), findsOneWidget);
    await tester.tap(find.text('Show more (+2)'));
    await tester.pumpAndSettle();
    expect(find.text('notes.txt'), findsOneWidget);
    expect(find.text('Show fewer'), findsOneWidget);
  });

  testWidgets('horizontal tokens are 230px wide on desktop and full width on phones', (tester) async {
    await pumpCs(tester, _group(alignment: CsFileTokenGroupAlignment.horizontal), size: csDesktopSize);
    final desktop = tester.getSize(find.ancestor(of: find.text('notes.txt'), matching: find.byType(SizedBox)).first);
    expect(desktop.width, 230);
    await pumpCs(tester, _group(alignment: CsFileTokenGroupAlignment.horizontal));
    final phoneToken = tester.getRect(
      find.ancestor(of: find.text('notes.txt'), matching: find.byType(Container)).first,
    );
    expect(phoneToken.width, greaterThan(300));
  });

  testWidgets('dismissing moves focus to the next token', (tester) async {
    var items = [for (final f in _files) CsFileTokenGroupItem(file: f)];
    late StateSetter set;
    await pumpCs(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          set = setState;
          return _group(items: items, onDismiss: (i) => set(() => items = [...items]..removeAt(i)));
        },
      ),
    );
    await tester.tap(find.bySemanticsLabel('Remove file 1, invoice-2024-01.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('invoice-2024-01.pdf'), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, contains('dismiss 0'));
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, _group(), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
