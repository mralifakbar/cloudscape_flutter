import 'package:cloudscape_flutter/src/buttons/buttons.dart';
import 'package:cloudscape_flutter/src/feedback/feedback.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

CsFlashbarItem _item(String id, CsFlashbarType type, {VoidCallback? onDismiss, bool loading = false}) => CsFlashbarItem(
  id: id,
  type: type,
  loading: loading,
  header: 'Header $id',
  content: 'Content $id',
  dismissible: onDismiss != null,
  onDismiss: onDismiss,
);

class _Host extends StatefulWidget {
  const _Host({this.stack = false, required this.initial});

  final bool stack;
  final List<CsFlashbarItem> initial;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<CsFlashbarItem> items = [...widget.initial];

  void remove(String id) => setState(() => items.removeWhere((i) => i.id == id));
  void add(CsFlashbarItem item) => setState(() => items.insert(0, item));

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: CsFlashbar(items: items, stackItems: widget.stack),
  );
}

List<Map<String, Object?>> _captureAnnouncements(WidgetTester tester) {
  final log = <Map<String, Object?>>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
    message,
  ) async {
    final map = (message as Map).cast<String, Object?>();
    if (map['type'] == 'announce') log.add((map['data'] as Map).cast<String, Object?>());
    return null;
  });
  addTearDown(
    () =>
        tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null),
  );
  return log;
}

void main() {
  testWidgets('renders every type in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          CsFlashbar(
            items: [
              for (final t in CsFlashbarType.values) _item(t.name, t, onDismiss: () {}),
              const CsFlashbarItem(id: 'loading', loading: true, content: 'Launching i-0abc123'),
            ],
          ),
          brightness: b,
          density: d,
          settle: false,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.text('Header error'), findsOneWidget);
      }
    }
  });

  testWidgets('dismiss and action buttons fire', (tester) async {
    var dismissed = 0;
    var pressed = 0;
    await pumpCs(
      tester,
      CsFlashbar(
        items: [
          CsFlashbarItem(
            id: 'a',
            content: 'Quota at 90%',
            dismissible: true,
            dismissLabel: 'Dismiss quota message',
            onDismiss: () => dismissed++,
            buttonText: 'Request increase',
            onButtonPress: () => pressed++,
          ),
        ],
      ),
    );
    await tester.tap(find.bySemanticsLabel('Dismiss quota message'));
    await tester.tap(find.text('Request increase'));
    expect(dismissed, 1);
    expect(pressed, 1);
  });

  testWidgets('removed items animate out and then leave the tree', (tester) async {
    await pumpCs(tester, _Host(initial: [_item('a', CsFlashbarType.success), _item('b', CsFlashbarType.error)]));
    final state = tester.state<_HostState>(find.byType(_Host));
    state.remove('a');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Header a'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Header a'), findsNothing);
    expect(find.text('Header b'), findsOneWidget);
  });

  testWidgets('added items fade in and are announced', (tester) async {
    final log = _captureAnnouncements(tester);
    await pumpCs(tester, _Host(initial: [_item('a', CsFlashbarType.info)]));
    expect(log, isEmpty);
    final state = tester.state<_HostState>(find.byType(_Host));
    state.add(
      const CsFlashbarItem(
        id: 'new',
        type: CsFlashbarType.error,
        header: 'Launch failed',
        content: 'Quota exceeded',
        ariaRole: CsFlashbarAriaRole.alert,
      ),
    );
    await tester.pump();
    await tester.pump();
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Launch failed'), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, lessThan(1));
    await tester.pumpAndSettle();
    expect(log.single['message'], contains('Launch failed'));
    expect(log.single['message'], contains('Quota exceeded'));
    expect(log.single['assertiveness'], 1);
  });

  testWidgets('stack collapses, shows counts and expands from the notification bar', (tester) async {
    await pumpCs(
      tester,
      _Host(
        stack: true,
        initial: [
          _item('1', CsFlashbarType.error),
          _item('2', CsFlashbarType.success),
          _item('3', CsFlashbarType.success),
          _item('4', CsFlashbarType.warning),
        ],
      ),
    );
    expect(find.text('Notifications'), findsOneWidget);
    // Only the newest message is readable while collapsed.
    expect(find.bySemanticsLabel(RegExp('Header 2')), findsNothing);
    final collapsedHeight = tester.getSize(find.byType(CsFlashbar)).height;

    await tester.tap(find.text('Notifications'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final midHeight = tester.getSize(find.byType(CsFlashbar)).height;
    await tester.pumpAndSettle();
    final expandedHeight = tester.getSize(find.byType(CsFlashbar)).height;
    expect(midHeight, greaterThan(collapsedHeight));
    expect(expandedHeight, greaterThan(midHeight));
    expect(tester.getTopLeft(find.text('Header 4')).dy, greaterThan(tester.getTopLeft(find.text('Header 1')).dy));

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(CsFlashbar)).height, collapsedHeight);
  });

  testWidgets('notification bar exposes expanded state and counts', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      CsFlashbar(stackItems: true, items: [_item('1', CsFlashbarType.error), _item('2', CsFlashbarType.info)]),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('All notifications'));
    expect(node.value, contains('Error 1'));
    expect(node.value, contains('Info 1'));
    expect(node.flagsCollection.isExpanded, isNot(true));
    handle.dispose();
  });

  testWidgets('a single stacked item shows no notification bar', (tester) async {
    await pumpCs(tester, CsFlashbar(stackItems: true, items: [_item('1', CsFlashbarType.error)]));
    expect(find.text('Notifications'), findsNothing);
    expect(find.text('Header 1'), findsOneWidget);
  });

  testWidgets('collapsed selection keeps every color represented', (tester) async {
    final items = [
      _item('1', CsFlashbarType.success),
      _item('2', CsFlashbarType.success),
      _item('3', CsFlashbarType.success),
      _item('4', CsFlashbarType.error),
      _item('5', CsFlashbarType.warning),
    ];
    // Three colors: depth three, the two later colors are promoted.
    expect(csCollapsedFlashSelection(items, 3), [0, 3, 4]);
    expect(csCollapsedFlashSelection(items.sublist(0, 3), 3), [0, 1, 2]);
  });

  testWidgets('fits 390px at 2x text with actions wrapping, and with reduced motion', (tester) async {
    await pumpCs(
      tester,
      CsFlashbar(
        stackItems: true,
        items: [
          CsFlashbarItem(
            id: 'x',
            type: CsFlashbarType.warning,
            header: 'Instance limit almost reached',
            content: 'You are using 19 of 20 instances in this Region.',
            action: CsButton(text: 'Request increase', onPress: () {}),
            dismissible: true,
            onDismiss: () {},
          ),
          _item('y', CsFlashbarType.inProgress, loading: true),
        ],
      ),
      textScale: 2,
      disableAnimations: true,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Notifications'));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    final header = tester.getTopLeft(find.text('Instance limit almost reached'));
    final action = tester.getTopLeft(find.text('Request increase'));
    expect(action.dy, greaterThan(header.dy));
  });

  testWidgets('CsFlash renders one message on its own', (tester) async {
    await pumpCs(
      tester,
      const CsFlash(
        item: CsFlashbarItem(type: CsFlashbarType.success, content: 'Bucket example-bucket created'),
      ),
    );
    expect(find.text('Bucket example-bucket created'), findsOneWidget);
    expect(find.bySemanticsLabel('Success'), findsOneWidget);
  });
}
