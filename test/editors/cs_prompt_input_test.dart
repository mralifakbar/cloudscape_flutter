import 'package:cloudscape_flutter/src/buttons/buttons.dart';
import 'package:cloudscape_flutter/src/editors/editors.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({this.initial = '', this.minRows = 1, this.maxRows = 3, this.onAction, this.disabled = false});

  final String initial;
  final int minRows;
  final int maxRows;
  final ValueChanged<String>? onAction;
  final bool disabled;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String value = widget.initial;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: CsPromptInput(
      value: value,
      placeholder: 'Ask a question',
      actionButtonIcon: CsIcons.send,
      minRows: widget.minRows,
      maxRows: widget.maxRows,
      disabled: widget.disabled,
      onChange: (v) => setState(() => value = v),
      onAction: widget.onAction,
    ),
  );
}

void main() {
  testWidgets('renders every state in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                CsPromptInput(value: '', placeholder: 'Ask', actionButtonIcon: CsIcons.send, onAction: (_) {}),
                const CsPromptInput(value: 'Hello', invalid: true, actionButtonIcon: CsIcons.send),
                const CsPromptInput(value: 'Hello', warning: true, readOnly: true),
                const CsPromptInput(value: 'Hello', disabled: true, actionButtonIcon: CsIcons.send),
                CsPromptInput(
                  value: '',
                  actionButtonIcon: CsIcons.send,
                  secondaryActions: CsButton(
                    icon: CsIcons.upload,
                    variant: CsButtonVariant.icon,
                    semanticLabel: 'Attach',
                    onPress: () {},
                  ),
                  secondaryContent: const Text('report.pdf'),
                ),
              ],
            ),
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('typing calls onChange; the action button sends', (tester) async {
    String? sent;
    await pumpCs(tester, _Host(onAction: (v) => sent = v));
    await tester.enterText(find.byType(EditableText), 'List my buckets');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Submit prompt'));
    expect(sent, 'List my buckets');
  });

  testWidgets('Enter sends, Shift+Enter inserts a newline', (tester) async {
    String? sent;
    await pumpCs(tester, _Host(initial: 'abc', onAction: (v) => sent = v));
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(sent, isNull);
    expect(tester.widget<EditableText>(find.byType(EditableText)).controller.text, contains('\n'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(sent, contains('\n'));
  });

  testWidgets('disabled and disableActionButton block the action', (tester) async {
    var sent = 0;
    await pumpCs(tester, _Host(initial: 'x', disabled: true, onAction: (_) => sent++));
    await tester.tap(find.bySemanticsLabel('Submit prompt'), warnIfMissed: false);
    await pumpCs(
      tester,
      CsPromptInput(value: 'x', actionButtonIcon: CsIcons.send, disableActionButton: true, onAction: (_) => sent++),
    );
    await tester.tap(find.bySemanticsLabel('Submit prompt'), warnIfMissed: false);
    expect(sent, 0);
  });

  testWidgets('grows from minRows to maxRows', (tester) async {
    await pumpCs(tester, const _Host(minRows: 1, maxRows: 3));
    final one = tester.getSize(find.byType(EditableText)).height;
    await tester.enterText(find.byType(EditableText), 'a\nb');
    await tester.pump();
    final two = tester.getSize(find.byType(EditableText)).height;
    expect(two, greaterThan(one));
    await tester.enterText(find.byType(EditableText), 'a\nb\nc\nd\ne\nf');
    await tester.pump();
    final capped = tester.getSize(find.byType(EditableText)).height;
    expect(capped, closeTo(one * 3, 1));
  });

  testWidgets('secondary actions put the send button in the action stripe', (tester) async {
    await pumpCs(
      tester,
      CsPromptInput(
        value: '',
        actionButtonIcon: CsIcons.send,
        onAction: (_) {},
        secondaryActions: CsButton(
          icon: CsIcons.upload,
          variant: CsButtonVariant.icon,
          semanticLabel: 'Attach file',
          onPress: () {},
        ),
      ),
    );
    final send = tester.getCenter(find.bySemanticsLabel('Submit prompt'));
    final attach = tester.getCenter(find.bySemanticsLabel('Attach file'));
    expect(send.dy, closeTo(attach.dy, 6));
    expect(tester.getTopLeft(find.byType(EditableText)).dy, lessThan(attach.dy));
  });

  testWidgets('custom label for the action button', (tester) async {
    await pumpCs(
      tester,
      CsPromptInput(
        value: '',
        actionButtonIcon: CsIcons.send,
        i18nStrings: const CsPromptInputI18nStrings(actionButtonAriaLabel: 'Send message'),
        onAction: (_) {},
      ),
    );
    expect(find.bySemanticsLabel('Send message'), findsOneWidget);
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, const _Host(initial: 'A long prompt that wraps over several lines on a phone'), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
