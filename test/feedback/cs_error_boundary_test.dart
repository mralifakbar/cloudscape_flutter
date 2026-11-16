import 'package:cloudscape_flutter/src/feedback/feedback.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Boom extends StatelessWidget {
  const _Boom({this.fail = true});

  final bool fail;

  @override
  Widget build(BuildContext context) {
    if (fail) throw StateError('instance details failed');
    return const Text('Instance i-0abc123');
  }
}

/// Pumps until the boundary switches and swallows the reported build error.
Future<Object?> _settle(WidgetTester tester) async {
  final error = tester.takeException();
  await tester.pumpAndSettle();
  return error;
}

void main() {
  testWidgets('renders the child when nothing fails', (tester) async {
    final errors = <CsErrorBoundaryErrorDetail>[];
    await pumpCs(tester, CsErrorBoundary(onError: errors.add, child: const _Boom(fail: false)));
    expect(find.text('Instance i-0abc123'), findsOneWidget);
    expect(errors, isEmpty);
  });

  testWidgets('a descendant that throws in build shows the fallback and reports once', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        final errors = <CsErrorBoundaryErrorDetail>[];
        await pumpCs(
          tester,
          CsErrorBoundary(
            errorBoundaryId: 'details',
            onError: errors.add,
            child: const Padding(padding: EdgeInsets.all(16), child: _Boom()),
          ),
          brightness: b,
          density: d,
          settle: false,
        );
        expect(await _settle(tester), isA<StateError>());
        expect(find.text('Unexpected error, content failed to show'), findsOneWidget);
        expect(find.text('Refresh to try again.'), findsOneWidget);
        expect(find.text('Refresh'), findsOneWidget);
        expect(find.byType(CsAlert), findsOneWidget);
        expect(errors, hasLength(1));
        expect(errors.single.error, isA<StateError>());
        expect(errors.single.errorBoundaryId, 'details');
        expect(errors.single.details, isNotNull);
        // Unmount so the next iteration starts fresh.
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('Refresh clears the error and builds the content again', (tester) async {
    var fail = true;
    var refreshed = 0;
    await pumpCs(
      tester,
      StatefulBuilder(
        builder: (context, setState) => CsErrorBoundary(
          onError: (_) => setState(() => fail = false),
          onRefresh: () => refreshed++,
          builder: (context) => _Boom(fail: fail),
        ),
      ),
      settle: false,
    );
    await _settle(tester);
    expect(find.text('Refresh'), findsOneWidget);
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(refreshed, 1);
    expect(find.text('Instance i-0abc123'), findsOneWidget);
  });

  testWidgets('errors thrown by the builder itself are caught', (tester) async {
    final errors = <CsErrorBoundaryErrorDetail>[];
    await pumpCs(
      tester,
      CsErrorBoundary(onError: errors.add, builder: (context) => throw ArgumentError('bad config')),
      settle: false,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Unexpected error, content failed to show'), findsOneWidget);
    expect(errors.single.error, isA<ArgumentError>());
    expect(errors.single.details, isNull);
  });

  testWidgets('i18n strings and renderFallback replace the default copy', (tester) async {
    await pumpCs(
      tester,
      CsErrorBoundary(
        onError: (_) {},
        i18nStrings: CsErrorBoundaryI18nStrings(
          headerText: 'Could not load the instance',
          descriptionText: 'Try again.',
          refreshActionText: 'Reload',
          feedbackText: 'Report a problem',
          feedbackBuilder: (context, text) => Text('[$text]'),
        ),
        child: const _Boom(),
      ),
      settle: false,
    );
    await _settle(tester);
    expect(find.text('Could not load the instance'), findsOneWidget);
    expect(find.text('Reload'), findsOneWidget);
    expect(find.text('[Report a problem]'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await pumpCs(
      tester,
      CsErrorBoundary(
        onError: (_) {},
        renderFallback: (context, slots) => Column(children: [slots.header, const Text('Custom fallback')]),
        child: const _Boom(),
      ),
      settle: false,
    );
    await _settle(tester);
    expect(find.text('Custom fallback'), findsOneWidget);
    expect(find.text('Unexpected error, content failed to show'), findsOneWidget);
    expect(find.byType(CsAlert), findsNothing);
  });

  testWidgets('the nearest boundary catches; suppressNested sends errors up', (tester) async {
    final outer = <CsErrorBoundaryErrorDetail>[];
    final inner = <CsErrorBoundaryErrorDetail>[];
    await pumpCs(
      tester,
      CsErrorBoundary(
        errorBoundaryId: 'outer',
        onError: outer.add,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Page header'),
            CsErrorBoundary(errorBoundaryId: 'inner', onError: inner.add, child: const _Boom()),
          ],
        ),
      ),
      settle: false,
    );
    await _settle(tester);
    expect(inner, hasLength(1));
    expect(outer, isEmpty);
    expect(find.text('Page header'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    outer.clear();
    inner.clear();
    await pumpCs(
      tester,
      CsErrorBoundary(
        suppressNested: true,
        onError: outer.add,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Page header'),
            CsErrorBoundary(suppressible: true, onError: inner.add, child: const _Boom()),
          ],
        ),
      ),
      settle: false,
    );
    await _settle(tester);
    expect(outer, hasLength(1));
    expect(inner, isEmpty);
    expect(find.text('Page header'), findsNothing);
  });

  testWidgets('forceError and reset drive the fallback from a key', (tester) async {
    final key = GlobalKey<CsErrorBoundaryState>();
    final errors = <CsErrorBoundaryErrorDetail>[];
    await pumpCs(tester, CsErrorBoundary(key: key, onError: errors.add, child: const Text('Bucket list')));
    key.currentState!.forceError();
    await tester.pumpAndSettle();
    expect(find.text('Bucket list'), findsNothing);
    expect(key.currentState!.hasError, isTrue);
    expect(errors, isEmpty);
    key.currentState!.reset();
    await tester.pumpAndSettle();
    expect(find.text('Bucket list'), findsOneWidget);
  });

  testWidgets('restores the previous ErrorWidget.builder when the last boundary unmounts', (tester) async {
    final before = ErrorWidget.builder;
    await pumpCs(tester, CsErrorBoundary(onError: (_) {}, child: const Text('a')));
    expect(identical(ErrorWidget.builder, before), isFalse);
    await tester.pumpWidget(const SizedBox());
    expect(identical(ErrorWidget.builder, before), isTrue);
  });

  testWidgets('without a boundary above, failures use the previous error widget', (tester) async {
    await pumpCs(
      tester,
      Column(
        children: [
          CsErrorBoundary(onError: (_) {}, child: const Text('Guarded')),
          const SizedBox(height: 40, width: 200, child: _Boom()),
        ],
      ),
      settle: false,
    );
    expect(tester.takeException(), isA<StateError>());
    expect(find.byType(ErrorWidget), findsOneWidget);
    expect(find.text('Guarded'), findsOneWidget);
  });

  testWidgets('the fallback survives 2x text at 390px', (tester) async {
    await pumpCs(tester, CsErrorBoundary(onError: (_) {}, child: const _Boom()), textScale: 2, settle: false);
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Refresh'), findsOneWidget);
  });
}
