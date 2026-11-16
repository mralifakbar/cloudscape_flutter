import 'package:cloudscape_flutter/src/editors/editors.dart';
import 'package:cloudscape_flutter/src/overlays/overlays.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

/// Holds the tags like an app would and records the last change.
class _Host extends StatefulWidget {
  const _Host({required this.initial, this.editorKey, this.tagLimit = 50, this.keysRequest, this.valuesRequest});

  final List<CsTag> initial;
  final GlobalKey<CsTagEditorState>? editorKey;
  final int tagLimit;
  final Future<List<String>> Function(String)? keysRequest;
  final Future<List<String>> Function(String, String)? valuesRequest;

  @override
  State<_Host> createState() => _HostState();
}

CsTagEditorChange? lastChange;

class _HostState extends State<_Host> {
  late List<CsTag> tags = widget.initial;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: CsTagEditor(
        key: widget.editorKey,
        tags: tags,
        tagLimit: widget.tagLimit,
        keysRequest: widget.keysRequest,
        valuesRequest: widget.valuesRequest,
        onChange: (c) => setState(() {
          lastChange = c;
          tags = c.tags;
        }),
      ),
    ),
  );
}

void main() {
  setUp(() => lastChange = null);

  testWidgets('renders tags in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          const _Host(
            initial: [
              CsTag(key: 'environment', value: 'prod', existing: true),
              CsTag(key: 'team'),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
    expect(find.text('You can add up to 48 more tags.'), findsOneWidget);
  });

  testWidgets('empty and loading states', (tester) async {
    await pumpCs(tester, const _Host(initial: []));
    expect(find.text('No tags associated with the resource.'), findsOneWidget);
    expect(find.text('You can add up to 50 tags.'), findsOneWidget);
    await pumpCs(tester, const CsTagEditor(loading: true), settle: false);
    expect(find.text('Loading tags that are associated with this resource'), findsOneWidget);
  });

  testWidgets('add creates an empty tag and focuses its key', (tester) async {
    await pumpCs(tester, const _Host(initial: []));
    await tester.tap(find.text('Add new tag'));
    await tester.pumpAndSettle();
    expect(lastChange!.tags, [const CsTag(key: '')]);
    expect(FocusManager.instance.primaryFocus?.debugLabel, contains('key 0'));
  });

  testWidgets('typing updates the key and validates', (tester) async {
    await pumpCs(tester, const _Host(initial: [CsTag(key: '')]));
    await tester.enterText(find.byType(EditableText).first, 'aws:name');
    await tester.pumpAndSettle();
    expect(lastChange!.valid, isFalse);
    expect(find.text('Cannot start with aws:'), findsOneWidget);
    await tester.enterText(find.byType(EditableText).first, 'name');
    await tester.pumpAndSettle();
    expect(lastChange!.valid, isTrue);
    await tester.enterText(find.byType(EditableText).first, '');
    await tester.pumpAndSettle();
    expect(find.text('You must specify a tag key'), findsOneWidget);
  });

  testWidgets('duplicate keys and invalid characters are errors', (tester) async {
    await pumpCs(
      tester,
      const _Host(
        initial: [
          CsTag(key: 'team'),
          CsTag(key: 'team'),
          CsTag(key: 'ok', value: 'a{b}'),
        ],
      ),
    );
    expect(find.text('You must specify a unique tag key.'), findsNWidgets(2));
    expect(find.textContaining('Invalid value.'), findsOneWidget);
  });

  testWidgets('removing an existing tag marks it and undo restores it', (tester) async {
    await pumpCs(
      tester,
      const _Host(
        initial: [CsTag(key: 'environment', value: 'prod', existing: true)],
      ),
    );
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(lastChange!.tags.single.markedForRemoval, isTrue);
    expect(find.text('This tag will be removed upon saving changes'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, contains('undo 0'));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(lastChange!.tags.single.markedForRemoval, isFalse);
    expect(find.text('Remove'), findsOneWidget);
  });

  testWidgets('removing a new tag drops it', (tester) async {
    await pumpCs(
      tester,
      const _Host(
        initial: [CsTag(key: 'team', value: 'web')],
      ),
    );
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(lastChange!.tags, isEmpty);
  });

  testWidgets('tag limit disables add and shows the reached message', (tester) async {
    await pumpCs(
      tester,
      const _Host(
        initial: [
          CsTag(key: 'a'),
          CsTag(key: 'b'),
        ],
        tagLimit: 2,
      ),
    );
    expect(find.text('You have reached the limit of 2 tags.'), findsOneWidget);
    await tester.tap(find.text('Add new tag'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(lastChange, isNull);
    await pumpCs(
      tester,
      const _Host(
        initial: [
          CsTag(key: 'a'),
          CsTag(key: 'b'),
        ],
        tagLimit: 1,
      ),
    );
    expect(find.text('You have exceeded the limit of 1 tag.'), findsOneWidget);
  });

  testWidgets('key suggestions load on focus, filter and pick with the keyboard', (tester) async {
    await pumpCs(
      tester,
      _Host(
        initial: const [CsTag(key: '')],
        keysRequest: (q) async => ['environment', 'team', 'cost-center'],
      ),
      size: csDesktopSize,
    );
    await tester.tap(find.byType(EditableText).first);
    await tester.pumpAndSettle();
    expect(find.byType(CsMenuRow), findsNWidgets(3));
    await tester.enterText(find.byType(EditableText).first, 'te');
    await tester.pumpAndSettle();
    // "Use: te", then the suggestions that contain "te": team, cost-center.
    expect(find.text('Use: "te"'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(lastChange!.tags.single.key, 'team');
    expect(find.byType(CsMenuRow), findsNothing);
  });

  testWidgets('value suggestions come from valuesRequest', (tester) async {
    await pumpCs(
      tester,
      _Host(
        initial: const [CsTag(key: 'environment')],
        valuesRequest: (k, v) async => k == 'environment' ? ['prod', 'staging'] : throw Exception('no'),
      ),
      size: csDesktopSize,
    );
    await tester.tap(find.byType(EditableText).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('staging'));
    await tester.pumpAndSettle();
    expect(lastChange!.tags.single.value, 'staging');
  });

  testWidgets('focus() moves to the first error', (tester) async {
    final key = GlobalKey<CsTagEditorState>();
    await pumpCs(
      tester,
      _Host(
        initial: const [
          CsTag(key: 'ok'),
          CsTag(key: 'aws:x'),
        ],
        editorKey: key,
      ),
    );
    key.currentState!.focus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, contains('key 1'));
  });

  testWidgets('Escape closes the suggestion list', (tester) async {
    await pumpCs(
      tester,
      _Host(
        initial: const [CsTag(key: '')],
        keysRequest: (q) async => ['environment'],
      ),
      size: csDesktopSize,
    );
    await tester.tap(find.byType(EditableText).first);
    await tester.pumpAndSettle();
    expect(find.byType(CsMenuRow), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(CsMenuRow), findsNothing);
  });

  testWidgets('renders with reduced motion', (tester) async {
    await pumpCs(tester, const _Host(initial: [CsTag(key: 'team')]), disableAnimations: true);
    expect(tester.takeException(), isNull);
  });

  test('getTagsDiff reports created and removed keys', () {
    const initial = [
      CsTag(key: 'a', value: '1', existing: true),
      CsTag(key: 'b', value: '2', existing: true),
      CsTag(key: 'c', value: '3', existing: true),
    ];
    const tags = [
      CsTag(key: 'a', value: '1', existing: true),
      CsTag(key: 'b', value: '2', existing: true, markedForRemoval: true),
      CsTag(key: 'c', value: '30', existing: true),
      CsTag(key: 'd', value: '4'),
    ];
    final diff = CsTagEditor.getTagsDiff(initial, tags);
    expect(diff.created, {'d': '4', 'c': '30'});
    expect(diff.removed, ['b', 'c']);
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(
      tester,
      const _Host(
        initial: [
          CsTag(key: 'environment', value: 'prod', existing: true, markedForRemoval: true),
          CsTag(key: ''),
        ],
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
