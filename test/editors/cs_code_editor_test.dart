import 'package:cloudscape_flutter/src/editors/editors.dart';
import 'package:cloudscape_flutter/src/overlays/overlays.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _json = '{\n  "Version": "2012-10-17",\n  "Statement": []\n}';

class _Host extends StatefulWidget {
  const _Host({this.initial = _json, this.language = 'json', this.validator, this.annotations});

  final String initial;
  final String language;
  final CsCodeEditorValidator? validator;
  final List<CsCodeEditorAnnotation>? annotations;

  @override
  State<_Host> createState() => _HostState();
}

String? lastValue;
CsCodeEditorPreferences? lastPrefs;

class _HostState extends State<_Host> {
  late String value = widget.initial;
  CsCodeEditorPreferences prefs = const CsCodeEditorPreferences();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: CsCodeEditor(
      value: value,
      language: widget.language,
      validator: widget.validator,
      annotations: widget.annotations,
      preferences: prefs,
      editorContentHeight: 200,
      onEditorContentResize: (_) {},
      onPreferencesChange: (p) => setState(() => prefs = lastPrefs = p),
      onChange: (v) => setState(() => value = lastValue = v),
    ),
  );
}

void main() {
  setUp(() {
    lastValue = null;
    lastPrefs = null;
  });

  testWidgets('renders every language in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final lang in ['json', 'yaml', 'javascript', 'python', 'sh', 'text']) {
          await pumpCs(
            tester,
            _Host(language: lang),
            brightness: b,
            density: d,
            size: csDesktopSize,
          );
          expect(tester.takeException(), isNull);
        }
      }
    }
    expect(find.text('Text'), findsOneWidget);
  });

  testWidgets('shows line numbers, language and cursor position', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    for (final n in ['1', '2', '3', '4']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(find.text('JSON'), findsOneWidget);
    expect(find.text('Ln 1, Col 1'), findsOneWidget);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    editable.controller.selection = const TextSelection.collapsed(offset: 6);
    await tester.pump();
    expect(find.text('Ln 2, Col 5'), findsOneWidget);
  });

  testWidgets('typing calls onChange; Tab inserts spaces', (tester) async {
    await pumpCs(tester, const _Host(initial: 'a'), size: csDesktopSize);
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    editable.controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(lastValue, '  a');
    await tester.enterText(find.byType(EditableText), 'x = 1');
    expect(lastValue, 'x = 1');
  });

  testWidgets('highlights syntax with token colors', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    final span = editable.controller.buildTextSpan(
      context: tester.element(find.byType(EditableText)),
      withComposing: false,
    );
    final colors = <Color?>{};
    span.visitChildren((s) {
      colors.add(s.style?.color);
      return true;
    });
    expect(colors.length, greaterThan(2));
  });

  testWidgets('validator counts errors and the pane lists them', (tester) async {
    await pumpCs(
      tester,
      const _Host(initial: '{\n  "a": \n}', validator: CsCodeEditor.jsonValidator),
      size: csDesktopSize,
    );
    expect(find.text('Errors: 1'), findsOneWidget);
    expect(find.text('Warnings: 0'), findsOneWidget);
    await tester.tap(find.text('Errors: 1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ln 3'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Close'), findsNothing);
  });

  testWidgets('annotations take precedence and show warnings', (tester) async {
    await pumpCs(
      tester,
      const _Host(
        validator: CsCodeEditor.jsonValidator,
        annotations: [
          CsCodeEditorAnnotation(row: 1, text: 'Deprecated version', type: CsCodeEditorAnnotationType.warning),
        ],
      ),
      size: csDesktopSize,
    );
    expect(find.text('Errors: 0'), findsOneWidget);
    expect(find.text('Warnings: 1'), findsOneWidget);
  });

  testWidgets('preferences menu toggles wrap lines and theme', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.tap(find.bySemanticsLabel('Preferences'));
    await tester.pumpAndSettle();
    expect(find.byType(CsMenuRow), findsNWidgets(4));
    await tester.tap(find.text('Wrap lines'));
    await tester.pumpAndSettle();
    expect(lastPrefs!.wrapLines, isFalse);
    await tester.tap(find.bySemanticsLabel('Preferences'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark theme'));
    await tester.pumpAndSettle();
    expect(lastPrefs!.theme, CsCodeEditorTheme.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading state', (tester) async {
    await pumpCs(tester, const CsCodeEditor(value: '', language: 'json', loading: true), settle: false);
    expect(find.text('Loading code editor'), findsOneWidget);
  });

  testWidgets('resize handle drags the height when uncontrolled', (tester) async {
    await pumpCs(
      tester,
      const Padding(
        padding: EdgeInsets.all(8),
        child: CsCodeEditor(value: 'a', language: 'text'),
      ),
      size: csDesktopSize,
    );
    final before = tester.getSize(find.byType(CsCodeEditor)).height;
    await tester.drag(find.bySemanticsLabel('Resize handle'), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(CsCodeEditor)).height, lessThan(before));
  });

  test('jsonValidator finds the error position', () {
    expect(CsCodeEditor.jsonValidator('{"a": 1}'), isEmpty);
    final errors = CsCodeEditor.jsonValidator('{\n  "a": ,\n}');
    expect(errors.single.row, 1);
  });

  test('highlighter round-trips text', () {
    const code = 'def f(x):\n    return x + 1  # one\n';
    final tokens = CsCodeEditorHighlighter.tokenize(code, 'py');
    expect(tokens.map((t) => t.text).join(), code);
    expect(tokens.any((t) => t.type == CsCodeEditorTokenType.keyword), isTrue);
    expect(CsCodeEditorHighlighter.supports('bash'), isTrue);
    expect(CsCodeEditorHighlighter.supports('cobol'), isFalse);
  });

  testWidgets('phone width and 2x text do not overflow; compact tabs show counts', (tester) async {
    await pumpCs(tester, const _Host(validator: CsCodeEditor.jsonValidator), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('0'), findsNWidgets(2));
  });
}
