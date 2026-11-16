// The lexer and grammars are adapted from kumo_flutter's
// `KumoCodeHighlighter` (MIT, same author).
import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// What a run of source text is, for coloring.
enum CsCodeEditorTokenType {
  /// Identifiers, whitespace and anything without a more specific type.
  plain,

  /// Language and shell keywords.
  keyword,

  /// String literals, and plain YAML values.
  string,

  /// Numbers, booleans and `null`.
  number,

  /// Comments.
  comment,

  /// Function names at a call or declaration, shell commands, decorators.
  function,

  /// Type names (capitalized identifiers, built-in types).
  type,

  /// Object keys, properties after a dot, YAML and JSON keys.
  property,

  /// JSX tag names.
  tag,

  /// JSX attributes and shell flags.
  attribute,

  /// Operators.
  operator,

  /// Brackets, separators and other punctuation.
  punctuation,

  /// Shell variables and YAML anchors.
  variable,

  /// Decorators, YAML document markers and tags.
  meta,
}

/// One run of source text and its [type].
@immutable
class CsCodeEditorToken {
  const CsCodeEditorToken(this.type, this.text);

  final CsCodeEditorTokenType type;
  final String text;

  @override
  bool operator ==(Object other) => other is CsCodeEditorToken && other.type == type && other.text == text;

  @override
  int get hashCode => Object.hash(type, text);

  @override
  String toString() => '${type.name}(${text.replaceAll('\n', r'\n')})';
}

/// Syntax colors for the code editor, from Cloudscape's visual accent text
/// tokens so they hold contrast in light and dark mode.
@immutable
class CsCodeEditorColors {
  const CsCodeEditorColors(this._colors);

  /// The palette for [theme].
  factory CsCodeEditorColors.of(CsThemeData theme) {
    final c = theme.colors;
    return CsCodeEditorColors({
      CsCodeEditorTokenType.plain: c.textBodyDefault,
      CsCodeEditorTokenType.keyword: c.textVisualAccentViolet,
      CsCodeEditorTokenType.string: c.textVisualAccentGreen,
      CsCodeEditorTokenType.number: c.textVisualAccentOrange,
      CsCodeEditorTokenType.comment: c.textBodySecondary,
      CsCodeEditorTokenType.function: c.textVisualAccentBlue,
      CsCodeEditorTokenType.type: c.textVisualAccentTeal,
      CsCodeEditorTokenType.property: c.textVisualAccentIndigo,
      CsCodeEditorTokenType.tag: c.textVisualAccentTeal,
      CsCodeEditorTokenType.attribute: c.textVisualAccentPurple,
      CsCodeEditorTokenType.operator: c.textBodyDefault,
      CsCodeEditorTokenType.punctuation: c.textBodyDefault,
      CsCodeEditorTokenType.variable: c.textVisualAccentMagenta,
      CsCodeEditorTokenType.meta: c.textBodySecondary,
    });
  }

  final Map<CsCodeEditorTokenType, Color> _colors;

  /// The color for a token [type].
  Color of(CsCodeEditorTokenType type) => _colors[type]!;
}

/// A small, dependency-free tokenizer for the code editor's languages.
///
/// Supported (aliases in brackets): javascript [js, jsx], typescript [ts,
/// tsx], json, yaml [yml], python [py] and sh [bash, shell, zsh]. Anything
/// else (`text`, `plain_text`) is a single plain token.
///
/// ```dart
/// final tokens = CsCodeEditorHighlighter.tokenize('const a = 1;', 'javascript');
/// ```
abstract final class CsCodeEditorHighlighter {
  /// Canonical name for [lang], or null when it is not highlighted.
  static String? resolve(String? lang) {
    if (lang == null) return null;
    final key = lang.trim().toLowerCase();
    final canonical = _aliases[key] ?? key;
    return _grammars.containsKey(canonical) ? canonical : null;
  }

  /// Whether [lang] (or one of its aliases) gets colors.
  static bool supports(String? lang) => resolve(lang) != null;

  /// Splits [code] into tokens. Joining every token's text gives back [code].
  static List<CsCodeEditorToken> tokenize(String code, String? lang) {
    final name = resolve(lang);
    if (name == null || code.isEmpty) return [CsCodeEditorToken(CsCodeEditorTokenType.plain, code)];
    return _Lexer(_grammars[name]!, code).run();
  }

  static const Map<String, String> _aliases = {
    'js': 'javascript',
    'mjs': 'javascript',
    'cjs': 'javascript',
    'ts': 'typescript',
    'yml': 'yaml',
    'py': 'python',
    'bash': 'sh',
    'shell': 'sh',
    'zsh': 'sh',
  };

  static final Map<String, _Grammar> _grammars = {
    'javascript': _jsGrammar(typescript: false, jsx: false),
    'jsx': _jsGrammar(typescript: false, jsx: true),
    'typescript': _jsGrammar(typescript: true, jsx: false),
    'tsx': _jsGrammar(typescript: true, jsx: true),
    'json': _jsonGrammar(comments: false),
    'sh': _bashGrammar(),
    'yaml': _yamlGrammar(),
    'python': _pythonGrammar(),
  };
}

typedef _Guard = bool Function(_Lexer lexer);

class _Rule {
  _Rule(String pattern, this.type, {this.push, this.pop = false, this.when, bool caseSensitive = true})
    : pattern = RegExp(pattern, caseSensitive: caseSensitive);

  final RegExp pattern;
  final CsCodeEditorTokenType type;

  /// State to enter after this token.
  final String? push;

  /// Leave the current state after this token.
  final bool pop;
  final _Guard? when;
}

class _Grammar {
  const _Grammar(this.states);
  final Map<String, List<_Rule>> states;
}

class _Lexer {
  _Lexer(this.grammar, this.src);

  final _Grammar grammar;
  final String src;
  int pos = 0;
  final List<String> _stack = ['root'];
  final List<CsCodeEditorToken> _out = [];

  /// The last token that is not whitespace.
  CsCodeEditorToken? prev;

  /// Only spaces and tabs sit between the last line break and [pos].
  bool get atLineStart {
    for (var i = pos - 1; i >= 0; i--) {
      final ch = src.codeUnitAt(i);
      if (ch == 0x0A) return true;
      if (ch != 0x20 && ch != 0x09) return false;
    }
    return true;
  }

  /// [prev] is on the current line.
  bool get prevOnLine {
    if (prev == null) return false;
    for (var i = pos - 1; i >= 0; i--) {
      final ch = src.codeUnitAt(i);
      if (ch == 0x0A) return false;
      if (ch != 0x20 && ch != 0x09) return true;
    }
    return false;
  }

  bool get afterSpace => pos == 0 || _isSpace(src.codeUnitAt(pos - 1));

  bool prevIs(Set<String> texts) => prev != null && texts.contains(prev!.text);

  static bool _isSpace(int ch) => ch == 0x20 || ch == 0x09 || ch == 0x0A || ch == 0x0D;

  List<CsCodeEditorToken> run() {
    while (pos < src.length) {
      final rules = grammar.states[_stack.last] ?? grammar.states['root']!;
      var matched = false;
      for (final rule in rules) {
        if (rule.when != null && !rule.when!(this)) continue;
        final m = rule.pattern.matchAsPrefix(src, pos);
        if (m == null || m.end == pos) continue;
        _emit(rule.type, m[0]!);
        pos = m.end;
        if (rule.pop && _stack.length > 1) _stack.removeLast();
        if (rule.push != null) _stack.add(rule.push!);
        matched = true;
        break;
      }
      if (!matched) {
        _emit(CsCodeEditorTokenType.plain, src[pos]);
        pos++;
      }
    }
    return _out;
  }

  void _emit(CsCodeEditorTokenType type, String text) {
    final token = CsCodeEditorToken(type, text);
    if (text.trim().isNotEmpty) prev = token;
    if (_out.isNotEmpty && _out.last.type == type) {
      _out[_out.length - 1] = CsCodeEditorToken(type, _out.last.text + text);
    } else {
      _out.add(token);
    }
  }
}

const _t = CsCodeEditorTokenType.plain;
const _kw = CsCodeEditorTokenType.keyword;
const _str = CsCodeEditorTokenType.string;
const _num = CsCodeEditorTokenType.number;
const _com = CsCodeEditorTokenType.comment;
const _fn = CsCodeEditorTokenType.function;
const _ty = CsCodeEditorTokenType.type;
const _prop = CsCodeEditorTokenType.property;
const _tag = CsCodeEditorTokenType.tag;
const _attr = CsCodeEditorTokenType.attribute;
const _op = CsCodeEditorTokenType.operator;
const _punc = CsCodeEditorTokenType.punctuation;
const _var = CsCodeEditorTokenType.variable;
const _meta = CsCodeEditorTokenType.meta;

String _words(Iterable<String> words) => '\\b(?:${words.join('|')})\\b';

final _ws = _Rule(r'\s+', _t);
final _dq = _Rule(r'"(?:\\.|[^"\\\n])*"?', _str);
final _sq = _Rule(r"'(?:\\.|[^'\\\n])*'?", _str);
final _lineComment = _Rule(r'//[^\n]*', _com);
final _blockComment = _Rule(r'/\*[\s\S]*?(?:\*/|$)', _com);
final _hashComment = _Rule(r'#[^\n]*', _com);
final _cNumber = _Rule(
  r'(?:0[xX][\da-fA-F_]+|0[bB][01_]+|0[oO][0-7_]+|(?:\d[\d_]*(?:\.\d[\d_]*)?|\.\d[\d_]*)(?:[eE][+-]?\d+)?n?)\b',
  _num,
);
final _cOperator = _Rule(r'=>|\?\?=?|\?\.|\.\.\.|[=!]==?|[<>]=?|&&=?|\|\|=?|[-+*/%&|^~!?:]=?|=', _op);
final _memberAccess = _Rule(r'[A-Za-z_$][\w$]*', _prop, when: (l) => l.prevIs(const {'.', '?.'}));

_Grammar _jsGrammar({required bool typescript, required bool jsx}) {
  const keywords = [
    'const', 'let', 'var', 'function', 'return', 'if', 'else', 'for', 'while', 'do', 'switch', 'case', //
    'break', 'continue', 'new', 'delete', 'typeof', 'instanceof', 'in', 'of', 'class', 'extends', 'super',
    'this', 'import', 'export', 'from', 'default', 'async', 'await', 'yield', 'try', 'catch', 'finally',
    'throw', 'void', 'static', 'get', 'set', 'with', 'debugger',
  ];
  const tsKeywords = [
    'interface', 'type', 'enum', 'implements', 'public', 'private', 'protected', 'readonly', 'as', //
    'satisfies', 'keyof', 'declare', 'namespace', 'abstract', 'is', 'infer', 'module', 'override',
  ];
  const tsTypes = ['string', 'number', 'boolean', 'any', 'unknown', 'never', 'object', 'bigint', 'symbol'];
  final expressionStart = {'(', '[', '{', ',', '=', ':', '?', '&&', '||', '??', '=>', 'return', '>'};
  final root = <_Rule>[
    _ws,
    _lineComment,
    _blockComment,
    if (jsx) ...[
      _Rule(r'</?>', _tag),
      // A closing tag is unambiguous; an opening one must start an expression.
      _Rule(r'</[A-Za-z][\w.:-]*', _tag, push: 'jsxTag'),
      _Rule(
        r'<[A-Za-z][\w.:-]*',
        _tag,
        push: 'jsxTag',
        when: (l) => l.prev == null || !l.prevOnLine || l.prevIs(expressionStart),
      ),
    ],
    _Rule(r'`(?:\\[\s\S]|[^\\`])*`?', _str),
    _dq,
    _sq,
    _cNumber,
    _Rule(_words(typescript ? [...keywords, ...tsKeywords] : keywords), _kw),
    _Rule(_words(['true', 'false', 'null', 'undefined', 'NaN', 'Infinity']), _num),
    if (typescript) _Rule(_words(tsTypes), _ty),
    _Rule(r'@[A-Za-z_]\w*', _meta),
    _memberAccess,
    _Rule(r'[A-Za-z_$][\w$]*(?=\s*(?:<[\w\s,.<>\[\]|]*>)?\()', _fn),
    _Rule(r'[A-Z][\w$]*', _ty),
    _Rule(r'[A-Za-z_$][\w$]*(?=\??\s*:)', _prop, when: (l) => l.atLineStart || l.prevIs(const {'{', ','})),
    _Rule(r'[A-Za-z_$][\w$]*', _t),
    _Rule(r'\{', _punc, push: 'root'),
    _Rule(r'\}', _punc, pop: true),
    _cOperator,
    _Rule(r'[()\[\];,.]', _punc),
  ];
  return _Grammar({
    'root': root,
    if (jsx)
      'jsxTag': [
        _ws,
        _Rule(r'/?>', _tag, pop: true),
        _Rule(r'[A-Za-z_][\w:-]*', _attr),
        _Rule(r'=', _op),
        _dq,
        _sq,
        _Rule(r'\{', _punc, push: 'root'),
      ],
  });
}

_Grammar _pythonGrammar() {
  const keywords = [
    'and', 'as', 'assert', 'async', 'await', 'break', 'class', 'continue', 'def', 'del', 'elif', 'else', //
    'except', 'finally', 'for', 'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'nonlocal', 'not',
    'or', 'pass', 'raise', 'return', 'try', 'while', 'with', 'yield', 'match', 'case', 'self',
  ];
  return _Grammar({
    'root': [
      _ws,
      _hashComment,
      _Rule(r'''[rRbBfFuU]{0,2}"""[\s\S]*?(?:"""|$)''', _str),
      _Rule(r"""[rRbBfFuU]{0,2}'''[\s\S]*?(?:'''|$)""", _str),
      _Rule(r'''[rRbBfFuU]{1,2}"(?:\\.|[^"\\\n])*"?''', _str),
      _Rule(r"""[rRbBfFuU]{1,2}'(?:\\.|[^'\\\n])*'?""", _str),
      _dq,
      _sq,
      _cNumber,
      _Rule(_words(keywords), _kw),
      _Rule(_words(['True', 'False', 'None']), _num),
      _Rule(r'@[A-Za-z_][\w.]*', _meta),
      _memberAccess,
      _Rule(r'[A-Za-z_]\w*(?=\s*\()', _fn),
      _Rule(r'[A-Z]\w*', _ty),
      _Rule(r'[A-Za-z_]\w*', _t),
      _Rule(r'->|\*\*=?|//=?|[<>!=]=|[-+*/%&|^~<>]=?|:=|=', _op),
      _Rule(r'[{}()\[\];,.:]', _punc),
    ],
  });
}

_Grammar _jsonGrammar({required bool comments}) => _Grammar({
  'root': [
    _ws,
    if (comments) ...[_lineComment, _blockComment],
    _Rule(r'"(?:\\.|[^"\\\n])*"(?=\s*:)', _prop),
    _dq,
    _Rule(r'-?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?', _num),
    _Rule(_words(['true', 'false', 'null']), _num),
    _Rule(r'[{}\[\],:]', _punc),
  ],
});

_Grammar _bashGrammar() {
  const keywords = [
    'if', 'then', 'else', 'elif', 'fi', 'for', 'while', 'until', 'do', 'done', 'case', 'esac', 'in', //
    'function', 'select', 'return', 'exit', 'export', 'local', 'readonly', 'declare', 'unset', 'source',
    'alias',
  ];
  const commandAfter = {'|', '||', '&&', ';', r'$(', r'$', '(', '`', 'then', 'do', 'else', 'sudo', 'exec', 'time'};
  bool commandPosition(_Lexer l) => !l.prevOnLine || l.prevIs(commandAfter);
  return _Grammar({
    'root': [
      _Rule(r'[ \t]+|\n', _t),
      _Rule(r'#[^\n]*', _com, when: (l) => l.afterSpace),
      _Rule(r'"(?:\\[\s\S]|[^"\\])*"?', _str),
      _Rule(r"\$'(?:\\.|[^'\\])*'?", _str),
      _Rule(r"'[^']*'?", _str),
      _Rule(r'\$\{[^}\n]*\}?|\$\(|\$[A-Za-z_]\w*|\$[0-9@#?$!*-]', _var),
      _Rule(_words(keywords), _kw, when: commandPosition),
      _Rule(
        r'[A-Za-z_]\w*(?==)',
        _var,
        when: (l) => commandPosition(l) || l.prevIs(const {'export', 'local', 'readonly', 'declare'}),
      ),
      _Rule(r'--?[A-Za-z0-9][\w-]*', _attr, when: (l) => l.afterSpace),
      _Rule(r'[A-Za-z_./~][\w./~:+@-]*', _fn, when: commandPosition),
      _Rule(r'\d+\b', _num),
      _Rule(r'&&|\|\||>>|<<|[|&;<>]|=', _op),
      _Rule(r'[(){}\[\]]', _punc),
      _Rule('[^\\s"\'\$|&;<>(){}\\[\\]=#]+', _t),
    ],
  });
}

_Grammar _yamlGrammar() {
  // A key sits at the start of a line, after a list dash, or inside a flow map.
  bool keyPosition(_Lexer l) => l.atLineStart || (l.prevOnLine && l.prevIs(const {'-', '{', ','}));
  bool valuePosition(_Lexer l) => l.prevOnLine && l.prevIs(const {':', '-'});
  const valueEnd = r'(?=[ \t]+#|[ \t]*(?:\n|$)|\s*[,\]}])';
  return _Grammar({
    'root': [
      _Rule(r'[ \t]+|\n', _t),
      _Rule(r'#[^\n]*', _com, when: (l) => l.afterSpace),
      _Rule(r'---|\.\.\.', _meta, when: (l) => l.atLineStart),
      _Rule(r'-(?=\s|$)', _punc),
      _Rule(
        r'''(?:"(?:\\.|[^"\\\n])*"|'[^'\n]*'|[^\s#:,\[\]{}"'-][^\n:#]*?|-[^\s:][^\n:#]*?)(?=[ \t]*:(?:\s|$))''',
        _prop,
        when: keyPosition,
      ),
      _Rule(r'[&*][\w-]+', _var),
      _Rule(r'![\w!/.-]*', _meta),
      _dq,
      _Rule(r"'(?:''|[^'])*'?", _str),
      _Rule(r'[|>][-+]?\d*(?=[ \t]*(?:#|\n|$))', _op),
      _Rule('(?:true|false|yes|no|on|off|null|~)$valueEnd', _num, when: valuePosition),
      _Rule('[-+]?(?:\\d[\\d_]*(?:\\.\\d+)?(?:[eE][+-]?\\d+)?|0x[\\da-fA-F]+|\\.inf|\\.nan)$valueEnd', _num),
      _Rule('[^\\s#,\\[\\]{}][^\\n#]*?$valueEnd', _str, when: valuePosition),
      _Rule(r'[:,\[\]{}?]', _punc),
      _Rule(r'[^\s:#,\[\]{}]+', _str),
    ],
  });
}
