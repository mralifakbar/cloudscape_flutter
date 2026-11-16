import 'package:cloudscape_flutter/src/feedback/feedback.dart';
import 'package:cloudscape_flutter/src/layout/cs_box.dart';
import 'package:cloudscape_flutter/src/layout/cs_space_between.dart';
import 'package:cloudscape_flutter/src/overlays/overlays.dart';
import 'package:cloudscape_flutter/src/system/system.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  group('CsBox', () {
    testWidgets('variants map to the Cloudscape type scale', (tester) async {
      await pumpCs(
        tester,
        const Column(
          children: [
            CsBox(variant: CsBoxVariant.h1, text: 'H1'),
            CsBox(variant: CsBoxVariant.small, text: 'Small'),
            CsBox(variant: CsBoxVariant.awsuiKeyLabel, text: 'Key'),
            CsBox(variant: CsBoxVariant.awsuiValueLarge, text: '42'),
            CsBox(variant: CsBoxVariant.awsuiInlineCode, text: 'ls'),
            CsBox(variant: CsBoxVariant.p, color: CsBoxColor.textStatusError, text: 'Error'),
          ],
        ),
      );
      TextStyle style(String t) => tester.widget<Text>(find.text(t)).style!;
      expect(style('H1').fontSize, 24);
      expect(style('H1').fontWeight, FontWeight.w700);
      expect(style('Small').fontSize, 12);
      expect(style('Key').fontWeight, FontWeight.w700);
      expect(style('42').fontSize, 42);
      expect(style('Error').color, CsColorSchemes.light.textStatusError);
      expect(find.bySemanticsLabel('H1'), findsOneWidget);
    });

    testWidgets('padding and font overrides', (tester) async {
      await pumpCs(
        tester,
        const CsBox(
          text: 'x',
          fontSize: CsTypeScale.headingL,
          fontWeight: CsBoxFontWeight.light,
          padding: CsBoxSpacing.all(CsSpacingSize.l),
        ),
      );
      expect(tester.widget<Text>(find.text('x')).style!.fontSize, 20);
      expect(tester.widget<Text>(find.text('x')).style!.fontWeight, FontWeight.w300);
      expect(
        find.byWidgetPredicate((w) => w is Padding && w.padding == const EdgeInsetsDirectional.all(20)),
        findsOneWidget,
      );
    });
  });

  testWidgets('CsSpaceBetween gaps and skips empty children', (tester) async {
    await pumpCs(
      tester,
      const CsSpaceBetween(size: CsSpacingSize.l, children: [Text('a'), SizedBox.shrink(), Text('b')]),
    );
    final a = tester.getBottomLeft(find.text('a')).dy;
    final b = tester.getTopLeft(find.text('b')).dy;
    expect(b - a, 20);
  });

  testWidgets('CsSpinner sizes, label and stops when removed', (tester) async {
    await pumpCs(tester, const CsSpinner(size: CsSpinnerSize.large), settle: false);
    expect(tester.getSize(find.byType(CustomPaint).last), const Size(48, 48));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('CsTooltip shows on long press', (tester) async {
    await pumpCs(tester, const CsTooltip(content: 'Copy ARN', child: SizedBox(width: 40, height: 40)));
    await tester.longPress(find.byType(SizedBox).last);
    await tester.pumpAndSettle();
    expect(find.text('Copy ARN'), findsOneWidget);
  });

  testWidgets('CsPressable: press, disabled, keyboard', (tester) async {
    var n = 0;
    await pumpCs(
      tester,
      CsPressable(onPress: () => n++, semanticLabel: 'Row', child: const SizedBox(width: 80, height: 20)),
    );
    await tester.tap(find.bySemanticsLabel('Row'));
    expect(n, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(n, 2);
    await pumpCs(tester, CsPressable(onPress: () => n++, disabled: true, child: const SizedBox(width: 80, height: 20)));
    await tester.tap(find.byType(CsPressable), warnIfMissed: false);
    expect(n, 2);
  });

  testWidgets('CsPopupSurface and CsMenuRow render in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpCs(
        tester,
        CsMenuPanel(
          children: [
            CsMenuRow(label: 'Edit', onPress: () {}),
            CsMenuRow(label: 'Selected', selected: true, onPress: () {}),
            const CsMenuSeparator(),
            const CsMenuGroupLabel('Group'),
            const CsMenuRow(label: 'Disabled', disabled: true),
          ],
        ),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('CsStrings overrides through CsLocale', (tester) async {
    late String close;
    await pumpCs(
      tester,
      CsLocale(
        strings: const CsStrings(close: 'Tutup'),
        child: Builder(
          builder: (context) {
            close = context.csStrings.close;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(close, 'Tutup');
  });
}
