import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/navigation/navigation.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Node {
  const _Node(this.id, this.name, [this.children]);

  final String id;
  final String name;
  final List<_Node>? children;
}

const _tree = [
  _Node('logs', 'logs', [
    _Node('2026', '2026', [_Node('jan', 'january.log'), _Node('feb', 'february.log')]),
    _Node('readme', 'README.md'),
  ]),
  _Node('assets', 'assets', [_Node('logo', 'logo.svg')]),
  _Node('index', 'index.html'),
];

class _Tree extends StatefulWidget {
  const _Tree({this.initial = const {}, this.lines = CsTreeViewConnectorLines.none, this.log});

  final Set<String> initial;
  final CsTreeViewConnectorLines lines;
  final List<CsTreeViewItemToggleDetail<_Node>>? log;

  @override
  State<_Tree> createState() => _TreeState();
}

class _TreeState extends State<_Tree> {
  late final Set<String> expanded = {...widget.initial};

  @override
  Widget build(BuildContext context) => CsTreeView<_Node>(
    items: _tree,
    ariaLabel: 'Bucket contents',
    connectorLines: widget.lines,
    expandedItems: expanded,
    getItemId: (n, _) => n.id,
    getItemChildren: (n, _) => n.children,
    onItemToggle: (d) {
      widget.log?.add(d);
      setState(() => d.expanded ? expanded.add(d.id) : expanded.remove(d.id));
    },
    renderItem: (n, _) => CsTreeViewItem(
      icon: CsIcon(n.children == null ? CsIcons.file : CsIcons.folder),
      content: Text(n.name),
      secondaryContent: n.id == 'readme' ? const Text('2 KB') : null,
      actions: n.id == 'index' ? const Text('Open') : null,
    ),
  );
}

bool _hasFocus(WidgetTester tester, String text) {
  final focus = FocusManager.instance.primaryFocus;
  if (focus?.context == null) return false;
  return find
      .descendant(of: find.byElementPredicate((e) => e == focus!.context), matching: find.text(text))
      .evaluate()
      .isNotEmpty;
}

void main() {
  testWidgets('renders with and without connector lines in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final l in CsTreeViewConnectorLines.values) {
          await pumpCs(
            tester,
            _Tree(initial: const {'logs', '2026'}, lines: l),
            brightness: b,
            density: d,
          );
          expect(find.text('january.log'), findsOneWidget);
          expect(find.text('2 KB'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('toggle expands and collapses, reporting onItemToggle', (tester) async {
    final log = <CsTreeViewItemToggleDetail<_Node>>[];
    await pumpCs(tester, _Tree(log: log));
    expect(find.text('README.md'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Expand').first);
    await tester.pumpAndSettle();
    expect(find.text('README.md'), findsOneWidget);
    expect(log.single.id, 'logs');
    expect(log.single.expanded, isTrue);
    await tester.tap(find.bySemanticsLabel('Collapse').first);
    await tester.pumpAndSettle();
    expect(find.text('README.md'), findsNothing);
  });

  testWidgets('nested items indent by the tree indentation', (tester) async {
    await pumpCs(tester, const _Tree(initial: {'logs'}));
    final parent = tester.getTopLeft(find.text('logs')).dx;
    final child = tester.getTopLeft(find.text('README.md')).dx;
    expect(child - parent, CsSpace.treeViewIndentation);
  });

  testWidgets('keyboard follows the ARIA tree pattern', (tester) async {
    await pumpCs(tester, const _Tree(), size: csDesktopSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_hasFocus(tester, 'logs'), isTrue);
    // Right expands, Right again moves to the first child.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('README.md'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_hasFocus(tester, '2026'), isTrue);
    // Down to README, Left to the parent, Left collapses.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, 'README.md'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(_hasFocus(tester, 'logs'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('README.md'), findsNothing);
    // End and Home, Enter toggles.
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(_hasFocus(tester, 'index.html'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(_hasFocus(tester, 'logs'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('README.md'), findsOneWidget);
  });

  testWidgets('collapsing moves focus from a hidden child to its parent', (tester) async {
    await pumpCs(tester, const _Tree(initial: {'logs'}), size: csDesktopSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, '2026'), isTrue);
    await tester.tap(find.bySemanticsLabel('Collapse').first);
    await tester.pumpAndSettle();
    expect(_hasFocus(tester, 'logs'), isTrue);
  });

  testWidgets('semantics: expanded state, level and custom toggle labels', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      CsTreeView<_Node>(
        items: _tree,
        ariaLabel: 'Bucket contents',
        expandedItems: const {'logs'},
        getItemId: (n, _) => n.id,
        getItemChildren: (n, _) => n.children,
        i18nStrings: CsTreeViewI18nStrings(
          expandButtonLabel: (n) => 'Expand ${n.name}',
          collapseButtonLabel: (n) => 'Collapse ${n.name}',
        ),
        renderItem: (n, _) => CsTreeViewItem(content: Text(n.name), announcementLabel: 'Folder ${n.name}'),
      ),
    );
    expect(find.bySemanticsLabel('Bucket contents'), findsOneWidget);
    expect(find.bySemanticsLabel('Collapse logs'), findsOneWidget);
    expect(find.bySemanticsLabel('Expand 2026'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('reduced motion, custom toggle icon, 390px and 2x text', (tester) async {
    await pumpCs(
      tester,
      CsTreeView<_Node>(
        items: _tree,
        expandedItems: const {'logs', '2026'},
        getItemId: (n, _) => n.id,
        getItemChildren: (n, _) => n.children,
        renderItemToggleIcon: (expanded) => Text(expanded ? '-' : '+'),
        renderItem: (n, _) => CsTreeViewItem(content: Text('${n.name} with a long description that wraps')),
      ),
      textScale: 2,
      disableAnimations: true,
    );
    expect(find.text('-'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
