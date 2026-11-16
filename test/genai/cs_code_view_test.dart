import 'package:cloudscape_flutter/src/buttons/buttons.dart';
import 'package:cloudscape_flutter/src/genai/genai.dart';
import 'package:cloudscape_flutter/src/overlays/overlays.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _json = '{\n  "Bucket": "example-bucket",\n  "Versioning": true,\n  "Objects": 128\n}';

String _plain(InlineSpan span) => span.toPlainText();

void main() {
  testWidgets('renders every combination in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final numbers in [false, true]) {
          for (final wrap in [false, true]) {
            await pumpCs(
              tester,
              CsCodeView(
                content: _json,
                lineNumbers: numbers,
                wrapLines: wrap,
                highlight: CsCodeViewHighlighter.of('json'),
                actions: const CsCodeViewCopyButton(content: _json),
              ),
              brightness: b,
              density: d,
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    }
  });

  testWidgets('shows line numbers only when asked', (tester) async {
    await pumpCs(tester, const CsCodeView(content: 'a\nb\nc'));
    expect(find.text('3'), findsNothing);
    await pumpCs(tester, const CsCodeView(content: 'a\nb\nc', lineNumbers: true));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('colors tokens with the highlight function', (tester) async {
    late CsThemeData theme;
    await pumpCs(
      tester,
      Builder(
        builder: (context) {
          theme = context.cs;
          return CsCodeView(content: _json, highlight: CsCodeViewHighlighter.of('json'));
        },
      ),
    );
    final colors = CsCodeViewColors.of(theme);
    final line = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere((r) => _plain(r.text).contains('Bucket'));
    final spans = <TextSpan>[];
    line.text.visitChildren((s) {
      if (s is TextSpan && s.text != null) spans.add(s);
      return true;
    });
    expect(spans.firstWhere((s) => s.text == '"Bucket"').style!.color, colors.property);
    expect(spans.firstWhere((s) => s.text == '"example-bucket"').style!.color, colors.string);
  });

  testWidgets('long lines scroll without wrap and wrap with wrapLines', (tester) async {
    const long = 'aws s3 cp ./build s3://example-bucket/releases/v1.2.3/ --recursive --exclude "*.map" --acl private';
    await pumpCs(tester, const CsCodeView(content: long, lineNumbers: true));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await pumpCs(tester, const CsCodeView(content: long, lineNumbers: true, wrapLines: true), textScale: 2);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aria label makes a labelled region; line numbers hidden by default', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsCodeView(content: 'echo hi', ariaLabel: 'Install script', lineNumbers: true));
    expect(find.bySemanticsLabel('Install script'), findsOneWidget);
    expect(find.bySemanticsLabel('1'), findsNothing);
    await pumpCs(
      tester,
      const CsCodeView(
        content: 'echo hi',
        lineNumbers: true,
        i18nStrings: CsCodeViewI18nStrings(lineNumberLabel: 'Line', codeLabel: 'Code'),
      ),
    );
    expect(find.bySemanticsLabel('Line 1'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('copy button writes to the clipboard and confirms', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    bool? result;
    await pumpCs(
      tester,
      CsCodeView(
        content: 'echo hi',
        actions: CsCodeViewCopyButton(
          content: 'echo hi',
          i18nStrings: const CsCodeViewCopyButtonI18nStrings(copySuccessText: 'Code copied'),
          onCopy: (ok) => result = ok,
        ),
      ),
    );
    await tester.tap(find.byType(CsButton));
    await tester.pumpAndSettle();
    expect(copied, 'echo hi');
    expect(result, isTrue);
    expect(find.text('Code copied'), findsOneWidget);
    await tester.pump(CsCodeViewCopyButton.messageDuration);
    await tester.pumpAndSettle();
    expect(find.text('Code copied'), findsNothing);
    expect(find.byType(CsTooltip), findsOneWidget);
  });

  testWidgets('copy button is reachable with Tab and Enter', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    bool? result;
    await pumpCs(
      tester,
      CsCodeView(
        content: 'x',
        actions: CsCodeViewCopyButton(content: 'x', onCopy: (ok) => result = ok),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(result, isTrue);
    await tester.pump(CsCodeViewCopyButton.messageDuration);
    await tester.pumpAndSettle();
  });

  testWidgets('stays left to right in an RTL app', (tester) async {
    await pumpCs(tester, const CsCodeView(content: 'ls -la'), textDirection: TextDirection.rtl);
    final dir = tester.widget<Directionality>(
      find.ancestor(of: find.byType(DecoratedBox).first, matching: find.byType(Directionality)).first,
    );
    expect(dir.textDirection, TextDirection.ltr);
  });
}
