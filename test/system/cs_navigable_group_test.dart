import 'package:cloudscape_flutter/src/buttons/buttons.dart';
import 'package:cloudscape_flutter/src/system/system.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Fixture {
  final before = FocusNode(debugLabel: 'before');
  final after = FocusNode(debugLabel: 'after');
  final items = List.generate(4, (i) => FocusNode(debugLabel: 'item$i'));
  final key = GlobalKey<CsNavigableGroupState>();

  void dispose() {
    before.dispose();
    after.dispose();
    for (final n in items) {
      n.dispose();
    }
  }

  Widget build({
    CsNavigationDirection direction = CsNavigationDirection.horizontal,
    bool loop = false,
    bool disableThird = false,
    Axis axis = Axis.horizontal,
  }) {
    final labels = ['Start', 'Stop', 'Reboot', 'Terminate'];
    final buttons = [
      for (var i = 0; i < 4; i++)
        CsButton(text: labels[i], focusNode: items[i], disabled: disableThird && i == 2, onPress: () {}),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CsButton(text: 'Before', focusNode: before, onPress: () {}),
        CsNavigableGroup(
          key: key,
          navigationDirection: direction,
          loop: loop,
          semanticLabel: 'Instance actions',
          child: axis == Axis.horizontal
              ? Wrap(spacing: 8, children: buttons)
              : Column(mainAxisSize: MainAxisSize.min, children: buttons),
        ),
        CsButton(text: 'After', focusNode: after, onPress: () {}),
      ],
    );
  }
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders in every theme with a group label', (tester) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(tester, f.build(), brightness: b, density: d, size: csDesktopSize);
        expect(tester.takeException(), isNull);
      }
    }
    expect(find.bySemanticsLabel('Instance actions'), findsOneWidget);
  });

  testWidgets('the group is a single Tab stop', (tester) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await pumpCs(tester, f.build(), size: csDesktopSize);
    f.before.requestFocus();
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.tab);
    expect(f.items[0].hasPrimaryFocus, isTrue);
    await _key(tester, LogicalKeyboardKey.tab);
    expect(f.after.hasPrimaryFocus, isTrue);
  });

  testWidgets('arrows move focus, Home and End jump, Tab returns to the last focused', (tester) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await pumpCs(tester, f.build(), size: csDesktopSize);
    f.items[0].requestFocus();
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(f.items[1].hasPrimaryFocus, isTrue);
    await _key(tester, LogicalKeyboardKey.end);
    expect(f.items[3].hasPrimaryFocus, isTrue);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(f.items[2].hasPrimaryFocus, isTrue);
    await _key(tester, LogicalKeyboardKey.home);
    expect(f.items[0].hasPrimaryFocus, isTrue);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(f.items[1].hasPrimaryFocus, isTrue);

    // Leave and come back: the remembered control is the tab stop.
    await _key(tester, LogicalKeyboardKey.tab);
    expect(f.after.hasPrimaryFocus, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(f.items[1].hasPrimaryFocus, isTrue);
  });

  testWidgets('stops at the ends by default and wraps with loop', (tester) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await pumpCs(tester, f.build(), size: csDesktopSize);
    f.items[3].requestFocus();
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(f.items[3].hasPrimaryFocus, isTrue);

    await pumpCs(tester, f.build(loop: true), size: csDesktopSize);
    f.items[3].requestFocus();
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(f.items[0].hasPrimaryFocus, isTrue);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(f.items[3].hasPrimaryFocus, isTrue);
  });

  testWidgets('skips disabled controls', (tester) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await pumpCs(tester, f.build(disableThird: true), size: csDesktopSize);
    f.items[1].requestFocus();
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(f.items[3].hasPrimaryFocus, isTrue);
  });

  testWidgets('vertical direction uses up and down only', (tester) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await pumpCs(
      tester,
      f.build(direction: CsNavigationDirection.vertical, axis: Axis.vertical),
      size: csDesktopSize,
    );
    f.items[0].requestFocus();
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(f.items[0].hasPrimaryFocus, isTrue);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(f.items[1].hasPrimaryFocus, isTrue);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(f.items[0].hasPrimaryFocus, isTrue);
  });

  testWidgets('both directions use all four arrows', (tester) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await pumpCs(tester, f.build(direction: CsNavigationDirection.both), size: csDesktopSize);
    f.items[0].requestFocus();
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(f.items[1].hasPrimaryFocus, isTrue);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(f.items[2].hasPrimaryFocus, isTrue);
  });

  testWidgets('arrows follow the reading direction in RTL', (tester) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await pumpCs(tester, f.build(), size: csDesktopSize, textDirection: TextDirection.rtl);
    f.items[0].requestFocus();
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(f.items[1].hasPrimaryFocus, isTrue);
  });

  testWidgets('focus() focuses the remembered control', (tester) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await pumpCs(tester, f.build(), size: csDesktopSize);
    f.key.currentState!.focus();
    await tester.pumpAndSettle();
    expect(f.items[0].hasPrimaryFocus, isTrue);
    f.items[2].requestFocus();
    await tester.pumpAndSettle();
    f.after.requestFocus();
    await tester.pumpAndSettle();
    f.key.currentState!.focus();
    await tester.pumpAndSettle();
    expect(f.items[2].hasPrimaryFocus, isTrue);
  });

  testWidgets('wraps controls at 390px with 2x text', (tester) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await pumpCs(tester, f.build(), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
