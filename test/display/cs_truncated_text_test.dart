import 'package:cloudscape_flutter/src/display/display.dart';
import 'package:cloudscape_flutter/src/overlays/cs_popup_surface.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _long = 'arn:aws:s3:::example-bucket/logs/2026/11/16/distribution-d111111abcdef8-000123.gz';

Widget _box(Widget child, {double width = 160}) => SizedBox(width: width, child: child);

void main() {
  testWidgets('renders in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(tester, _box(const CsTruncatedText(_long)), brightness: b, density: d);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('truncates to one line with an ellipsis', (tester) async {
    await pumpCs(tester, _box(const CsTruncatedText(_long)));
    final text = tester.widget<Text>(find.text(_long));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.byType(CsTruncatedText)).height, 20);
  });

  testWidgets('maxLines clamps to several lines', (tester) async {
    await pumpCs(tester, _box(const CsTruncatedText(_long, maxLines: 2), width: 120));
    expect(tester.getSize(find.byType(CsTruncatedText)).height, 40);
  });

  testWidgets('hover shows the full text, leaving hides it', (tester) async {
    await pumpCs(tester, _box(const CsTruncatedText(_long, tooltipText: 'Full log path')));
    expect(find.byType(CsPopupSurface), findsNothing);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(CsTruncatedText)));
    await tester.pumpAndSettle();
    expect(find.text('Full log path'), findsOneWidget);
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(find.text('Full log path'), findsNothing);
  });

  testWidgets('keyboard focus shows it and Escape hides it', (tester) async {
    await pumpCs(tester, _box(const CsTruncatedText(_long, tooltipText: 'Full log path')));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Full log path'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Full log path'), findsNothing);
  });

  testWidgets('tap toggles it on touch screens', (tester) async {
    await pumpCs(tester, _box(const CsTruncatedText(_long, tooltipText: 'Full log path')));
    await tester.tap(find.byType(CsTruncatedText));
    await tester.pumpAndSettle();
    expect(find.text('Full log path'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Full log path'), findsNothing);
  });

  testWidgets('text that fits is plain: not focusable, no tooltip', (tester) async {
    await pumpCs(tester, _box(const CsTruncatedText('example-bucket', tooltipText: 'tip'), width: 300));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.tap(find.text('example-bucket'));
    await tester.pumpAndSettle();
    expect(find.text('tip'), findsNothing);
    expect(find.byType(Focus).evaluate().where((e) => (e.widget as Focus).debugLabel == 'CsTruncatedText'), isEmpty);
  });

  testWidgets('screen readers get the full text', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, _box(const CsTruncatedText(_long)));
    expect(find.bySemanticsLabel(_long), findsOneWidget);
    handle.dispose();
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, const CsTruncatedText(_long), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
