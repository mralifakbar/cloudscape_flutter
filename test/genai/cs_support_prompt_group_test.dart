import 'package:cloudscape_flutter/src/genai/genai.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _items = [
  CsSupportPrompt(id: 'a', text: 'Why did my bill go up?', icon: CsIcons.search),
  CsSupportPrompt(
    id: 'b',
    text: 'Scale my instances',
    icon: CsIcons.genAi,
    iconPosition: CsSupportPromptIconPosition.right,
  ),
  CsSupportPrompt(id: 'c', text: 'Summarize alarms'),
];

void main() {
  testWidgets('renders both alignments in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final a in CsSupportPromptAlignment.values) {
          await pumpCs(
            tester,
            CsSupportPromptGroup(ariaLabel: 'Prompts', items: _items, alignment: a, onItemClick: (_) {}),
            brightness: b,
            density: d,
          );
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('tap fires onItemClick with the id', (tester) async {
    final clicked = <String>[];
    await pumpCs(tester, CsSupportPromptGroup(ariaLabel: 'Prompts', items: _items, onItemClick: clicked.add));
    await tester.tap(find.text('Scale my instances'));
    expect(clicked, ['b']);
  });

  testWidgets('empty items render nothing', (tester) async {
    await pumpCs(tester, CsSupportPromptGroup(ariaLabel: 'Prompts', items: const [], onItemClick: (_) {}));
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('one tab stop, arrows move and wrap, Home and End jump, Enter activates', (tester) async {
    final clicked = <String>[];
    await pumpCs(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CsSupportPromptGroup(ariaLabel: 'Prompts', items: _items, onItemClick: clicked.add),
          const Focus(child: Text('after')),
        ],
      ),
    );
    FocusNode? focused() => FocusManager.instance.primaryFocus;
    String? label() => focused()?.debugLabel;

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(label(), 'CsSupportPrompt a');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(label(), 'CsSupportPrompt b');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(label(), 'CsSupportPrompt a');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(label(), 'CsSupportPrompt c');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(label(), 'CsSupportPrompt a');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(label(), 'CsSupportPrompt c');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(clicked, ['c']);

    // Tab leaves the group instead of visiting every prompt.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(label(), isNot(startsWith('CsSupportPrompt')));
    // Shift+Tab comes back to the last focused prompt.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(label(), 'CsSupportPrompt c');
  });

  testWidgets('focus(id) moves focus through a GlobalKey', (tester) async {
    final key = GlobalKey<CsSupportPromptGroupState>();
    await pumpCs(tester, CsSupportPromptGroup(key: key, ariaLabel: 'Prompts', items: _items, onItemClick: (_) {}));
    key.currentState!.focus('b');
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'CsSupportPrompt b');
  });

  testWidgets('semantics: buttons inside a labelled group, custom aria labels', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      CsSupportPromptGroup(
        ariaLabel: 'Suggested prompts',
        items: const [CsSupportPrompt(id: 'a', text: 'Bill', ariaLabel: 'Ask about my bill')],
        onItemClick: (_) {},
      ),
    );
    expect(find.bySemanticsLabel('Suggested prompts'), findsOneWidget);
    expect(tester.getSemantics(find.byType(CsSupportPromptGroup).last), isNotNull);
    expect(find.bySemanticsLabel('Ask about my bill'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('wraps without overflow at 390px and 2x text', (tester) async {
    await pumpCs(
      tester,
      CsSupportPromptGroup(
        ariaLabel: 'Prompts',
        items: _items,
        alignment: CsSupportPromptAlignment.horizontal,
        onItemClick: (_) {},
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
