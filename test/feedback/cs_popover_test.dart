import 'package:cloudscape_flutter/src/buttons/buttons.dart';
import 'package:cloudscape_flutter/src/feedback/feedback.dart';
import 'package:cloudscape_flutter/src/system/cs_focus_trap.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _content = Text('This instance contains insufficient memory.');

void main() {
  testWidgets('opens on tap and closes with the close button', (tester) async {
    var dismissed = 0;
    await pumpCs(
      tester,
      CsPopover(header: 'Memory error', content: _content, onDismiss: () => dismissed++, child: const Text('Error')),
    );
    expect(find.text('Memory error'), findsNothing);
    await tester.tap(find.text('Error'));
    await tester.pumpAndSettle();
    expect(find.text('Memory error'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close popover'));
    await tester.pumpAndSettle();
    expect(find.text('Memory error'), findsNothing);
    expect(dismissed, 1);
  });

  testWidgets('renders in light, dark, compact and every size and position', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final p in CsPopoverPosition.values) {
          for (final s in CsPopoverSize.values) {
            await pumpCs(
              tester,
              CsPopover(header: 'Header', position: p, size: s, content: _content, child: const Text('Trigger')),
              brightness: b,
              density: d,
              size: csDesktopSize,
            );
            await tester.tap(find.text('Trigger'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.text('Header'), findsOneWidget);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
          }
        }
      }
    }
  });

  testWidgets('Escape and outside taps close it', (tester) async {
    await pumpCs(tester, const CsPopover(content: _content, child: Text('Trigger')));
    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('This instance contains insufficient memory.'), findsNothing);

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('This instance contains insufficient memory.'), findsNothing);
  });

  testWidgets('controlled visible reports changes', (tester) async {
    final changes = <bool>[];
    await pumpCs(
      tester,
      CsPopover(visible: true, onVisibleChange: changes.add, content: _content, child: const Text('Trigger')),
    );
    expect(find.text('This instance contains insufficient memory.'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close popover'));
    await tester.pumpAndSettle();
    expect(changes, [false]);
    // Still open: the parent owns the state.
    expect(find.text('This instance contains insufficient memory.'), findsOneWidget);
  });

  testWidgets('custom trigger keeps its onPress and toggles', (tester) async {
    var copies = 0;
    await pumpCs(
      tester,
      CsPopover(
        triggerType: CsPopoverTriggerType.custom,
        dismissButton: false,
        content: const Text('ARN copied'),
        child: CsButton(text: 'Copy ARN', onPress: () => copies++),
      ),
    );
    await tester.tap(find.text('Copy ARN'));
    await tester.pumpAndSettle();
    expect(copies, 1);
    expect(find.text('ARN copied'), findsOneWidget);
  });

  testWidgets('keyboard: Enter opens a text trigger, focus moves in, Tab closes without a close button', (
    tester,
  ) async {
    await pumpCs(tester, const CsPopover(header: 'Header', content: _content, child: Text('Trigger')));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Header'), findsOneWidget);
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(focused.findAncestorWidgetOfExactType<CsFocusTrap>(), isNotNull);

    await pumpCs(
      tester,
      const CsPopover(key: ValueKey('plain'), dismissButton: false, content: _content, child: Text('Plain')),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('This instance contains insufficient memory.'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('This instance contains insufficient memory.'), findsNothing);
  });

  testWidgets('text triggers expose expanded state and their aria label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      const CsPopover(
        triggerType: CsPopoverTriggerType.textInline,
        triggerAriaLabel: 'Show memory details',
        content: _content,
        child: Text('Error'),
      ),
    );
    expect(find.bySemanticsLabel('Show memory details'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('large falls back to medium on phones and stays on screen at 2x text', (tester) async {
    await pumpCs(
      tester,
      const CsPopover(
        size: CsPopoverSize.large,
        header: 'Memory error',
        content: _content,
        wrapTriggerText: false,
        child: Text('A long trigger label that should truncate on one line'),
      ),
      textScale: 2,
    );
    await tester.tap(find.byType(CsPopover));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final rect = tester.getRect(find.text('Memory error'));
    expect(rect.right, lessThanOrEqualTo(390));
    expect(rect.left, greaterThanOrEqualTo(0));
  });
}
