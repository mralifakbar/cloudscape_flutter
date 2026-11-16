import 'package:cloudscape_flutter/src/genai/genai.dart';
import 'package:flutter_test/flutter_test.dart';

CsCodeViewTokenType? typeOf(List<CsCodeViewToken> tokens, String text) =>
    tokens.where((t) => t.text.trim() == text).map((t) => t.type).firstOrNull;

void main() {
  test('resolves aliases and rejects unknown languages', () {
    expect(CsCodeViewHighlighter.resolve('ts'), 'typescript');
    expect(CsCodeViewHighlighter.resolve('bash'), 'sh');
    expect(CsCodeViewHighlighter.resolve('yml'), 'yaml');
    expect(CsCodeViewHighlighter.supports('cobol'), isFalse);
    expect(CsCodeViewHighlighter.tokenize('x', 'cobol'), [const CsCodeViewToken(CsCodeViewTokenType.plain, 'x')]);
  });

  test('round-trips the source for every language', () {
    const samples = {
      'json': '{"a": [1, true, null]}',
      'javascript': 'const a = await fetch(`/x`); // done',
      'typescript': 'interface Bucket { name: string }',
      'python': 'def handler(event):\n    return {"ok": True}  # done',
      'yaml': 'Resources:\n  Bucket:\n    Type: AWS::S3::Bucket\n    Count: 2',
      'sh': 'export REGION=us-east-1\naws s3 ls --recursive "\$REGION" | grep log',
      'html': '<div class="panel"><!-- note --><b>Hi</b></div>',
    };
    for (final e in samples.entries) {
      expect(CsCodeViewHighlighter.tokenize(e.value, e.key).map((t) => t.text).join(), e.value, reason: e.key);
    }
  });

  test('colors the main token types', () {
    final json = CsCodeViewHighlighter.tokenize('{"Bucket": "example", "n": 3}', 'json');
    expect(typeOf(json, '"Bucket"'), CsCodeViewTokenType.property);
    expect(typeOf(json, '"example"'), CsCodeViewTokenType.string);
    expect(typeOf(json, '3'), CsCodeViewTokenType.number);

    final ts = CsCodeViewHighlighter.tokenize('const size: number = getSize();', 'ts');
    expect(typeOf(ts, 'const'), CsCodeViewTokenType.keyword);
    expect(typeOf(ts, 'number'), CsCodeViewTokenType.type);
    expect(typeOf(ts, 'getSize'), CsCodeViewTokenType.function);

    final py = CsCodeViewHighlighter.tokenize('def run():  # go', 'python');
    expect(typeOf(py, 'def'), CsCodeViewTokenType.keyword);
    expect(typeOf(py, '# go'), CsCodeViewTokenType.comment);

    final yaml = CsCodeViewHighlighter.tokenize('Type: bucket', 'yaml');
    expect(typeOf(yaml, 'Type'), CsCodeViewTokenType.property);

    final sh = CsCodeViewHighlighter.tokenize('aws s3 ls --recursive', 'sh');
    expect(typeOf(sh, 'aws'), CsCodeViewTokenType.function);
    expect(typeOf(sh, '--recursive'), CsCodeViewTokenType.attribute);

    final html = CsCodeViewHighlighter.tokenize('<a href="/x">', 'html');
    expect(typeOf(html, '<a'), CsCodeViewTokenType.tag);
    expect(typeOf(html, 'href'), CsCodeViewTokenType.attribute);
  });

  test('splitLines keeps one list per line', () {
    final lines = CsCodeViewHighlighter.splitLines(CsCodeViewHighlighter.tokenize('a\n\nb', 'js'));
    expect(lines.length, 3);
    expect(lines[1], isEmpty);
  });
}
