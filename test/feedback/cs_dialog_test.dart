import 'package:cloudscape_flutter/src/buttons/buttons.dart';
import 'package:cloudscape_flutter/src/feedback/feedback.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool open = false;
  int dismissals = 0;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CsButton(text: 'Rename', onPress: () => setState(() => open = true)),
      if (open)
        CsDialog(
          header: 'Rename distribution',
          onDismiss: () => setState(() {
            dismissals++;
            open = false;
          }),
          footer: CsButton(text: 'Save', variant: CsButtonVariant.primary, onPress: () {}),
          child: const Text('d111111abcdef8'),
        ),
    ],
  );
}

void main() {
  testWidgets('renders header, content and footer in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          CsDialog(
            header: 'Rename distribution',
            headerActions: CsButton(
              variant: CsButtonVariant.icon,
              icon: CsIcons.settings,
              semanticLabel: 'Settings',
              onPress: () {},
            ),
            onDismiss: () {},
            footer: const Text('Footer'),
            child: const Text('Content'),
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Footer'), findsOneWidget);
        expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      }
    }
  });

  testWidgets('close button and Escape call onDismiss', (tester) async {
    await pumpCs(tester, const _Host());
    final state = tester.state<_HostState>(find.byType(_Host));
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Close dialog'));
    await tester.pumpAndSettle();
    expect(state.dismissals, 1);
    expect(find.text('Rename distribution'), findsNothing);

    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(state.dismissals, 2);
  });

  testWidgets('moves focus in on mount and restores it on unmount', (tester) async {
    await pumpCs(tester, const _Host());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final trigger = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Rename distribution'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, isNot(trigger));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Rename distribution'), findsNothing);
    expect(FocusManager.instance.primaryFocus, trigger);
  });

  testWidgets('dismiss label follows i18nStrings', (tester) async {
    await pumpCs(
      tester,
      CsDialog(
        header: 'Ubah nama',
        onDismiss: () {},
        i18nStrings: const CsDialogI18nStrings(dismissAriaLabel: 'Tutup dialog'),
      ),
    );
    expect(find.bySemanticsLabel('Tutup dialog'), findsOneWidget);
  });

  testWidgets('fits 390px at 2x text', (tester) async {
    await pumpCs(
      tester,
      CsDialog(
        header: 'Rename the distribution d111111abcdef8 used by the storefront',
        onDismiss: () {},
        child: const Text('Names can include letters, numbers and hyphens.'),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
