import 'package:cloudscape_flutter/src/buttons/buttons.dart';
import 'package:cloudscape_flutter/src/feedback/feedback.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({
    this.size = CsModalSize.medium,
    this.hideDismissButton = false,
    this.position = CsModalPosition.center,
    this.longContent = false,
    this.height,
  });

  final CsModalSize size;
  final bool hideDismissButton;
  final CsModalPosition position;
  final bool longContent;
  final double? height;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool visible = false;
  final reasons = <CsModalDismissReason>[];

  void hide() => setState(() => visible = false);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CsButton(text: 'Open', onPress: () => setState(() => visible = true)),
        CsModal(
          visible: visible,
          size: widget.size,
          position: widget.position,
          height: widget.height,
          hideDismissButton: widget.hideDismissButton,
          header: 'Delete instance',
          onDismiss: (r) => setState(() {
            reasons.add(r);
            visible = false;
          }),
          footerActions: [
            CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () => setState(() => visible = false)),
            CsButton(text: 'Delete', variant: CsButtonVariant.primary, onPress: () {}),
          ],
          child: widget.longContent
              ? Column(children: [for (var i = 0; i < 60; i++) Text('Line $i')])
              : const Text('Permanently delete i-0abc123?'),
        ),
      ],
    );
  }
}

Future<_HostState> _open(
  WidgetTester tester, {
  _Host host = const _Host(),
  Size size = csPhoneSize,
  Brightness b = Brightness.light,
  CsDensity d = CsDensity.comfortable,
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  await pumpCs(
    tester,
    host,
    size: size,
    brightness: b,
    density: d,
    textScale: textScale,
    disableAnimations: disableAnimations,
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return tester.state<_HostState>(find.byType(_Host));
}

void main() {
  testWidgets('stays mounted and hidden until visible', (tester) async {
    await pumpCs(tester, const _Host());
    expect(find.text('Delete instance'), findsNothing);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete instance'), findsOneWidget);
    expect(find.text('Permanently delete i-0abc123?'), findsOneWidget);
  });

  testWidgets('renders in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await _open(tester, b: b, d: d);
        expect(tester.takeException(), isNull);
        expect(find.text('Delete'), findsOneWidget);
      }
    }
  });

  testWidgets('reports closeButton, overlay and keyboard reasons', (tester) async {
    var state = await _open(tester);
    await tester.tap(find.bySemanticsLabel('Close modal'));
    await tester.pumpAndSettle();
    expect(state.reasons, [CsModalDismissReason.closeButton]);
    expect(find.text('Delete instance'), findsNothing);

    state = await _open(tester);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(state.reasons.last, CsModalDismissReason.overlay);

    state = await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(state.reasons.last, CsModalDismissReason.keyboard);
    expect(find.text('Delete instance'), findsNothing);
  });

  testWidgets('system back asks to dismiss instead of popping the page', (tester) async {
    final state = await _open(tester);
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(state.reasons.last, CsModalDismissReason.keyboard);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('animates out instead of disappearing', (tester) async {
    final state = await _open(tester);
    state.hide();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('Delete instance'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Delete instance'), findsNothing);
  });

  testWidgets('focus moves to the close button and Tab stays inside', (tester) async {
    await _open(tester);
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(focused.findAncestorWidgetOfExactType<CsModal>(), isNotNull);
    }
  });

  testWidgets('hideDismissButton removes the close button', (tester) async {
    await _open(tester, host: const _Host(hideDismissButton: true));
    expect(find.bySemanticsLabel('Close modal'), findsNothing);
  });

  testWidgets('phones get the full width minus 12px gutters', (tester) async {
    await _open(tester);
    final surface = tester.getSize(find.byType(ClipRRect).last);
    expect(surface.width, 390 - 24);
  });

  testWidgets('sizes cap the width on desktop', (tester) async {
    await _open(
      tester,
      host: const _Host(size: CsModalSize.small),
      size: csDesktopSize,
    );
    expect(tester.getSize(find.byType(ClipRRect).last).width, 320);
    await _open(
      tester,
      host: const _Host(size: CsModalSize.max),
      size: csDesktopSize,
    );
    expect(tester.getSize(find.byType(ClipRRect).last).width, 1280 - 120);
  });

  testWidgets('long content scrolls while the footer stays visible at 2x text', (tester) async {
    await _open(tester, host: const _Host(longContent: true), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('Delete'), findsOneWidget);
    expect(tester.getBottomLeft(find.text('Delete')).dy, lessThan(844));
  });

  testWidgets('fixed height and top position', (tester) async {
    await _open(
      tester,
      host: const _Host(height: 300, position: CsModalPosition.top),
      size: csDesktopSize,
    );
    expect(tester.getSize(find.byType(ClipRRect).last).height, 300);
    expect(tester.getTopLeft(find.byType(ClipRRect).last).dy, 12);
  });

  testWidgets('reduced motion opens instantly', (tester) async {
    await pumpCs(tester, const _Host(), disableAnimations: true);
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Delete instance'), findsOneWidget);
  });

  testWidgets('header is announced as the dialog name', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester);
    expect(find.bySemanticsLabel('Delete instance'), findsWidgets);
    handle.dispose();
  });

  testWidgets('showCsModal returns the popped value', (tester) async {
    bool? result;
    await pumpCs(
      tester,
      Builder(
        builder: (context) => CsButton(
          text: 'Launch',
          onPress: () async {
            result = await showCsModal<bool>(
              context: context,
              header: 'Delete bucket',
              builder: (_) => const Text('Permanently delete example-bucket?'),
              footerBuilder: (context) => CsButton(text: 'Confirm', onPress: () => Navigator.of(context).pop(true)),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Launch'));
    await tester.pumpAndSettle();
    expect(find.text('Delete bucket'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.text('Delete bucket'), findsNothing);
  });

  testWidgets('showCsModal with dismissible false ignores Escape and the backdrop', (tester) async {
    await pumpCs(
      tester,
      Builder(
        builder: (context) => CsButton(
          text: 'Launch',
          onPress: () => showCsModal<void>(
            context: context,
            header: 'Required choice',
            dismissible: false,
            builder: (_) => const Text('Pick one'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Launch'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('Required choice'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close modal'));
    await tester.pumpAndSettle();
    expect(find.text('Required choice'), findsNothing);
  });
}
