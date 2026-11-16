import 'package:cloudscape_flutter/src/collections/collections.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

Future<List<CsS3Bucket>> _buckets() async => [
  for (var i = 1; i <= 12; i++)
    CsS3Bucket(name: 'example-bucket-$i', creationDate: '2024-0${i % 9 + 1}-01', region: 'us-east-1'),
];

Future<List<CsS3Object>> _objects(String bucket, String path) async => path.isEmpty
    ? const [
        CsS3Object(key: 'logs', isFolder: true),
        CsS3Object(key: 'report.csv', size: 2048, lastModified: '2024-05-01'),
      ]
    : const [CsS3Object(key: 'app.log', size: 10, lastModified: '2024-05-02')];

Future<List<CsS3Version>> _versions(String bucket, String path) async => const [
  CsS3Version(versionId: 'v-001', size: 2048, lastModified: '2024-05-01'),
  CsS3Version(versionId: 'v-002', size: 1024, lastModified: '2024-05-03'),
];

class _Host extends StatefulWidget {
  const _Host({this.types = const {CsS3SelectableItems.objects}, this.initial = const CsS3Resource(uri: '')});

  final Set<CsS3SelectableItems> types;
  final CsS3Resource initial;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late CsS3Resource resource = widget.initial;
  String? error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        CsS3ResourceSelector(
          resource: resource,
          selectableItemsTypes: widget.types,
          fetchBuckets: _buckets,
          fetchObjects: _objects,
          fetchVersions: _versions,
          onChange: (c) => setState(() {
            resource = c.resource;
            error = c.errorText;
          }),
        ),
        Text('uri=${resource.uri} version=${resource.versionId} error=$error'),
        const Focus(child: SizedBox(width: 10, height: 10)),
      ],
    ),
  );
}

void main() {
  test('URI validation', () {
    expect(csS3ValidateUri(''), isNull);
    expect(csS3ValidateUri('example-bucket'), contains('s3://'));
    expect(csS3ValidateUri('s3://-bucket'), contains('lowercase character'));
    expect(csS3ValidateUri('s3://bUcket'), contains('uppercase'));
    expect(csS3ValidateUri('s3://ab'), contains('3 to 63'));
    expect(csS3ValidateUri('s3://a..b'), contains('DNS'));
    expect(csS3ValidateUri('s3://example-bucket/logs/app.log'), isNull);
    expect(csS3SplitUri('s3://example-bucket/logs/app.log'), ('example-bucket', 'logs/app.log'));
    expect(csS3FormatSize(0), '0 Bytes');
    expect(csS3FormatSize(2048), '2 KB');
    expect(csS3FormatSize(1536), '1.5 KB');
    expect(csS3FormatSize(null), '-');
  });

  testWidgets('renders in light, dark and compact on desktop and phone', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final size in [csDesktopSize, csPhoneSize]) {
          await pumpCs(
            tester,
            const _Host(types: {CsS3SelectableItems.objects, CsS3SelectableItems.versions}),
            brightness: b,
            density: d,
            size: size,
          );
          expect(find.text('S3 URI'), findsOneWidget);
          expect(find.text('Browse S3'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('typing validates after the first blur', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.enterText(find.byType(EditableText), 'bucket');
    await tester.pump();
    expect(find.textContaining('error=null'), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.textContaining('must begin with s3://'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 's3://bUcket');
    await tester.pump();
    expect(find.textContaining('uppercase'), findsOneWidget);
  });

  testWidgets('browse: drill into a bucket and choose an object', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.tap(find.text('Browse S3'));
    await tester.pumpAndSettle();
    expect(find.text('Choose an object in S3'), findsOneWidget);
    expect(find.text('example-bucket-1'), findsOneWidget);
    // Ten per page; the pager moves to the rest.
    expect(find.text('example-bucket-12'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('example-bucket-12'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Previous page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('example-bucket-1'));
    await tester.pumpAndSettle();
    expect(find.text('report.csv'), findsOneWidget);
    await tester.tap(find.text('logs'));
    await tester.pumpAndSettle();
    expect(find.text('app.log'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Select item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(find.textContaining('uri=s3://example-bucket-1/logs/app.log'), findsOneWidget);
  });

  testWidgets('browse: filtering, breadcrumbs and cancel', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.tap(find.text('Browse S3'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, 'bucket-12');
    await tester.pumpAndSettle();
    expect(find.text('1 match'), findsOneWidget);
    await tester.enterText(find.byType(EditableText).last, 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);
    await tester.tap(find.text('Clear filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('example-bucket-2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('S3 buckets'));
    await tester.pumpAndSettle();
    expect(find.text('example-bucket-3'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Choose an object in S3'), findsNothing);
    expect(find.textContaining('uri= '), findsOneWidget);
  });

  testWidgets('buckets are disabled unless selectable', (tester) async {
    await pumpCs(tester, const _Host(types: {CsS3SelectableItems.buckets}), size: csDesktopSize);
    await tester.tap(find.text('Browse S3'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Select item').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(find.textContaining('uri=s3://example-bucket-1 '), findsOneWidget);
  });

  testWidgets('versions: choose a version in the modal and with the version picker', (tester) async {
    await pumpCs(
      tester,
      const _Host(types: {CsS3SelectableItems.objects, CsS3SelectableItems.versions}),
      size: csDesktopSize,
    );
    await tester.tap(find.text('Browse S3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('example-bucket-1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('report.csv'));
    await tester.pumpAndSettle();
    expect(find.text('v-002'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Select item').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(find.textContaining('uri=s3://example-bucket-1/report.csv version=v-002'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Object version').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('v-001').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('version=v-001'), findsOneWidget);
  });

  testWidgets('390px with 2x text', (tester) async {
    await pumpCs(tester, const _Host(types: {CsS3SelectableItems.objects, CsS3SelectableItems.versions}), textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Browse S3'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('an initial URI loads its versions into the picker', (tester) async {
    await pumpCs(
      tester,
      const _Host(
        types: {CsS3SelectableItems.objects, CsS3SelectableItems.versions},
        initial: CsS3Resource(uri: 's3://example-bucket-1/report.csv'),
      ),
      size: csDesktopSize,
    );
    await tester.tap(find.bySemanticsLabel('Object version').last);
    await tester.pumpAndSettle();
    expect(find.text('v-002'), findsOneWidget);
  });
}
