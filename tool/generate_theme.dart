// Regenerates the Cloudscape design tokens as Dart.
//
//   dart run tool/generate_theme.dart [--version 3.0.1413]
//
// Source: the visual-refresh theme preset that ships inside
// @cloudscape-design/components (internal/generated/theming/index.js, Apache
// 2.0). It holds every token the components use (the public
// @cloudscape-design/design-tokens package exposes about half of them), each
// with its light/dark, comfortable/compact or default/disabled values and the
// eight visual contexts (top navigation, header, flashbar, alert and others).
// Descriptions come from the public design-tokens package.
//
// Writes:
//   lib/src/theme/generated/cs_colors.g.dart   CsColor, CsColorScheme, light/dark, context overrides
//   lib/src/theme/generated/cs_tokens.g.dart   spacing, density, radii, borders, type, motion, shadows
import 'dart:convert';
import 'dart:io';

const _defaultVersion = '3.0.1413';
const _tokensVersion = '3.0.117';

late final Map<String, dynamic> _tokens;
late final Map<String, dynamic> _modeMap;
late final Map<String, dynamic> _contexts;
final Map<String, String> _descriptions = {};

Future<void> main(List<String> args) async {
  final vi = args.indexOf('--version');
  final version = vi >= 0 ? args[vi + 1] : _defaultVersion;
  final js = await _fetch(
    'https://cdn.jsdelivr.net/npm/@cloudscape-design/components@$version/internal/generated/theming/index.js',
  );
  final start = js.indexOf('{');
  final end = js.lastIndexOf('}');
  final preset = jsonDecode(js.substring(start, end + 1)) as Map<String, dynamic>;
  final theme = preset['theme'] as Map<String, dynamic>;
  if (theme['id'] != 'visual-refresh') throw StateError('expected the visual-refresh preset, got ${theme['id']}');
  _tokens = theme['tokens'] as Map<String, dynamic>;
  _modeMap = theme['tokenModeMap'] as Map<String, dynamic>;
  _contexts = theme['contexts'] as Map<String, dynamic>;

  final publicJson = jsonDecode(
    await _fetch('https://cdn.jsdelivr.net/npm/@cloudscape-design/design-tokens@$_tokensVersion/index-visual-refresh.json'),
  );
  for (final e in (publicJson['tokens'] as Map<String, dynamic>).entries) {
    final d = (e.value as Map<String, dynamic>)[r'$description'] as String?;
    if (d != null) _descriptions[_camel(e.key)] = d;
  }

  File('lib/src/theme/generated/cs_colors.g.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(_colorsFile(version));
  File('lib/src/theme/generated/cs_tokens.g.dart').writeAsStringSync(_tokensFile(version));
  stdout.writeln('Generated tokens from @cloudscape-design/components@$version');
}

Future<String> _fetch(String url) async {
  final cache = File('.dart_tool/cloudscape_cache/${Uri.parse(url).pathSegments.join('_')}');
  if (cache.existsSync()) return cache.readAsStringSync();
  final client = HttpClient();
  final res = await (await client.getUrl(Uri.parse(url))).close();
  if (res.statusCode != 200) throw HttpException('${res.statusCode} for $url');
  final body = await res.transform(utf8.decoder).join();
  client.close();
  cache
    ..createSync(recursive: true)
    ..writeAsStringSync(body);
  return body;
}

String _camel(String kebab) {
  final parts = kebab.split('-');
  return parts.first + parts.skip(1).map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)).join();
}

/// Resolves [name] for a state such as {color: dark, density: compact, motion: default}.
String _resolve(String name, Map<String, String> state, {String? context}) {
  final ctxTokens = context == null ? null : (_contexts[context]['tokens'] as Map<String, dynamic>);
  final raw = ctxTokens?[name] ?? _tokens[name];
  if (raw == null) throw StateError('unknown token $name');
  String value;
  if (raw is String) {
    value = raw;
  } else {
    final map = raw as Map<String, dynamic>;
    final mode = _modeMap[name] as String?;
    final key = mode != null && map.containsKey(state[mode]) ? state[mode]! : map.keys.first;
    value = map[key] as String;
  }
  return value.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => _resolve(m[1]!, state, context: context));
}

Map<String, String> _state({String color = 'light', String density = 'comfortable', String motion = 'default'}) =>
    {'color': color, 'density': density, 'motion': motion};

// ---------------------------------------------------------------------------
// Colors

final _gradientTokens = {'colorBackgroundAvatarGenAi', 'colorBackgroundLoadingBarGenAi'};
bool _isColorToken(String name) => _modeMap[name] == 'color' && !name.startsWith('shadow');

int? _parseColor(String v) {
  v = v.trim();
  if (v == 'transparent') return 0x00000000;
  if (v.startsWith('#')) {
    var hex = v.substring(1);
    if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
    if (hex.length == 6) return 0xFF000000 | int.parse(hex, radix: 16);
    if (hex.length == 8) {
      final rgb = int.parse(hex.substring(0, 6), radix: 16);
      final a = int.parse(hex.substring(6), radix: 16);
      return (a << 24) | rgb;
    }
  }
  final m = RegExp(r'rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)').firstMatch(v);
  if (m != null) {
    final a = m[4] == null ? 1.0 : double.parse(m[4]!);
    return ((a * 255).round() << 24) |
        (double.parse(m[1]!).round() << 16) |
        (double.parse(m[2]!).round() << 8) |
        double.parse(m[3]!).round();
  }
  return null;
}

String _hex(int argb) => '0x${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';

String _member(String name) {
  // colorTextBodyDefault -> textBodyDefault; palette and chart tokens keep
  // their group (colorGrey500 -> grey500, colorChartsRed300 -> chartsRed300).
  final s = name.substring('color'.length);
  return s[0].toLowerCase() + s.substring(1);
}

String _doc(String name, String fallback) {
  final d = _descriptions[name];
  return (d ?? fallback).replaceAll('\n', ' ').trim();
}

String _colorsFile(String version) {
  final names = _tokens.keys.where(_isColorToken).where((n) {
    if (_gradientTokens.contains(n)) return false;
    final light = _resolve(n, _state());
    return _parseColor(light) != null;
  }).toList();
  final skipped = _tokens.keys.where(_isColorToken).where((n) => !names.contains(n)).toList();

  List<int> scheme(String color, {String? context}) => [
    for (final n in names) _parseColor(_resolve(n, _state(color: color), context: context)) ?? 0x00000000,
  ];

  final light = scheme('light');
  final dark = scheme('dark');
  final b = StringBuffer()
    ..writeln('// GENERATED by tool/generate_theme.dart. Do not edit.')
    ..writeln('// Source: @cloudscape-design/components@$version theming preset (visual refresh), Apache-2.0.')
    ..writeln('// Not generated (non-solid values, handled in code): ${skipped.join(', ')}.')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln("import 'dart:ui' show Brightness, Color;")
    ..writeln()
    ..writeln('/// Every Cloudscape color token. Names drop the `color` prefix of the')
    ..writeln('/// design token: `colorTextBodyDefault` is [CsColor.textBodyDefault].')
    ..writeln('enum CsColor {');
  for (final n in names) {
    final doc = _doc(n, _paletteDoc(n));
    b.writeln('  /// $doc');
    b.writeln('  ${_member(n)},');
    b.writeln();
  }
  b.writeln('}');
  b.writeln();
  b
    ..writeln('/// A resolved set of Cloudscape colors for one mode. Read a token with')
    ..writeln('/// its getter (`colors.textBodyDefault`) or by enum (`colors[CsColor.textBodyDefault]`).')
    ..writeln('class CsColorScheme {')
    ..writeln('  const CsColorScheme(this.values);')
    ..writeln()
    ..writeln('  /// One color per [CsColor], in enum order.')
    ..writeln('  final List<Color> values;')
    ..writeln()
    ..writeln('  Color operator [](CsColor token) => values[token.index];')
    ..writeln()
    ..writeln('  /// A copy with some tokens replaced, for brand theming:')
    ..writeln('  /// `CsColorSchemes.light.copyWith({CsColor.backgroundButtonPrimaryDefault: myBlue})`.')
    ..writeln('  CsColorScheme copyWith(Map<CsColor, Color> overrides) {')
    ..writeln('    if (overrides.isEmpty) return this;')
    ..writeln('    final next = List<Color>.of(values);')
    ..writeln('    overrides.forEach((token, color) => next[token.index] = color);')
    ..writeln('    return CsColorScheme(List.unmodifiable(next));')
    ..writeln('  }')
    ..writeln()
    ..writeln('  static CsColorScheme lerp(CsColorScheme a, CsColorScheme b, double t) {')
    ..writeln('    if (identical(a, b)) return a;')
    ..writeln('    return CsColorScheme([for (var i = 0; i < a.values.length; i++) Color.lerp(a.values[i], b.values[i], t)!]);')
    ..writeln('  }')
    ..writeln()
    ..writeln('  @override')
    ..writeln('  bool operator ==(Object other) {')
    ..writeln('    if (identical(this, other)) return true;')
    ..writeln('    if (other is! CsColorScheme || other.values.length != values.length) return false;')
    ..writeln('    for (var i = 0; i < values.length; i++) {')
    ..writeln('      if (values[i] != other.values[i]) return false;')
    ..writeln('    }')
    ..writeln('    return true;')
    ..writeln('  }')
    ..writeln()
    ..writeln('  @override')
    ..writeln('  int get hashCode => Object.hashAll(values);')
    ..writeln();
  for (final n in names) {
    b.writeln('  /// ${_doc(n, _paletteDoc(n))}');
    b.writeln('  Color get ${_member(n)} => values[${names.indexOf(n)}];');
  }
  b.writeln('}');
  b.writeln();

  // Contexts: only the tokens that differ from the base scheme of the same mode.
  const contextNames = {
    'top-navigation': 'topNavigation',
    'header': 'header',
    'app-layout-toolbar': 'appLayoutToolbar',
    'flashbar': 'flashbar',
    'flashbar-warning': 'flashbarWarning',
    'alert': 'alert',
    'alert-header': 'alertHeader',
  };
  b
    ..writeln('/// Places in the UI where Cloudscape recolors part of its tokens, such as')
    ..writeln('/// the dark top navigation bar or the dark high-contrast page header.')
    ..writeln('/// Apply one to a subtree with `CsVisualContext`.')
    ..writeln('enum CsVisualContextName {');
  const contextDocs = {
    'topNavigation': 'The top navigation bar: always dark.',
    'header': 'The high-contrast page header (`ContentLayout headerVariant="high-contrast"`): always dark.',
    'appLayoutToolbar': 'The app layout toolbar background.',
    'flashbar': 'Inside a flash message on a colored background.',
    'flashbarWarning': 'Inside a warning flash message (dark text on yellow).',
    'alert': 'Inside an alert.',
    'alertHeader': 'The header of an alert.',
  };
  for (final c in contextNames.values) {
    b.writeln('  /// ${contextDocs[c]}');
    b.writeln('  $c,');
  }
  b.writeln('}');
  b.writeln();
  b
    ..writeln('/// The generated light and dark schemes and their context overrides.')
    ..writeln('abstract final class CsColorSchemes {')
    ..writeln('  /// Cloudscape light mode.')
    ..writeln('  static const CsColorScheme light = CsColorScheme([');
  for (final v in light) {
    b.writeln('    Color(${_hex(v)}),');
  }
  b
    ..writeln('  ]);')
    ..writeln()
    ..writeln('  /// Cloudscape dark mode.')
    ..writeln('  static const CsColorScheme dark = CsColorScheme([');
  for (final v in dark) {
    b.writeln('    Color(${_hex(v)}),');
  }
  b
    ..writeln('  ]);')
    ..writeln();
  final contextOverrides = <String, Map<String, Map<int, int>>>{};
  for (final e in contextNames.entries) {
    for (final mode in ['light', 'dark']) {
      final defaultMode = _contexts[e.key]['defaultMode'] as String?;
      final effective = defaultMode ?? mode;
      final ctx = scheme(effective, context: e.key);
      final base = mode == 'light' ? light : dark;
      final diff = <int, int>{};
      for (var i = 0; i < names.length; i++) {
        if (ctx[i] != base[i]) diff[i] = ctx[i];
      }
      (contextOverrides[e.value] ??= {})[mode] = diff;
    }
  }
  for (final e in contextOverrides.entries) {
    for (final mode in ['light', 'dark']) {
      final diff = e.value[mode]!;
      final cap = mode[0].toUpperCase() + mode.substring(1);
      b.writeln('  static const Map<CsColor, Color> _${e.key}$cap = {');
      for (final d in diff.entries) {
        b.writeln('    CsColor.${_member(names[d.key])}: Color(${_hex(d.value)}),');
      }
      b.writeln('  };');
    }
  }
  b
    ..writeln()
    ..writeln('  /// The tokens [context] overrides in [brightness] mode, relative to')
    ..writeln('  /// [light] or [dark]. Contexts with a fixed dark look (top navigation,')
    ..writeln('  /// header) return dark values in light mode too.')
    ..writeln('  static Map<CsColor, Color> contextOverrides(CsVisualContextName context, Brightness brightness) {')
    ..writeln('    final dark = brightness == Brightness.dark;')
    ..writeln('    return switch (context) {');
  for (final c in contextNames.values) {
    b.writeln('      CsVisualContextName.$c => dark ? _${c}Dark : _${c}Light,');
  }
  b
    ..writeln('    };')
    ..writeln('  }')
    ..writeln('}');
  return b.toString();
}

String _paletteDoc(String name) {
  final m = _member(name);
  if (m.startsWith('charts')) return 'Data visualization color `$name`.';
  return 'Cloudscape color token `$name`.';
}

// ---------------------------------------------------------------------------
// Non-color tokens

double _px(String v) {
  v = v.trim();
  if (v == '0' || v == 'none') return 0;
  final m = RegExp(r'^(-?[\d.]+)px$').firstMatch(v);
  if (m == null) throw FormatException('not a px value: $v');
  return double.parse(m[1]!);
}

String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

String _tokensFile(String version) {
  final b = StringBuffer()
    ..writeln('// GENERATED by tool/generate_theme.dart. Do not edit.')
    ..writeln('// Source: @cloudscape-design/components@$version theming preset (visual refresh), Apache-2.0.')
    ..writeln()
    ..writeln("import 'package:flutter/animation.dart';")
    ..writeln("import 'package:flutter/foundation.dart' show immutable;")
    ..writeln("import 'package:flutter/painting.dart';")
    ..writeln();

  // Spacing and sizes. Tokens with the same value in both densities (and in
  // the compact-table context) are constants; the rest live on
  // CsDensityTokens, read from the theme.
  final measured = _tokens.keys
      .where((n) => (n.startsWith('space') || n.startsWith('size')) && _tryPx(_resolve(n, _state())) != null)
      .toList();
  bool varies(String n) {
    final c = _resolve(n, _state());
    return c != _resolve(n, _state(density: 'compact')) || c != _resolve(n, _state(), context: 'compact-table');
  }

  final invariant = measured.where((n) => !varies(n)).toList();
  final densityFields = measured.where(varies).toList();
  for (final (cls, prefix, doc) in [
    (
      'CsSpace',
      'space',
      'Cloudscape spacing that is the same in comfortable and compact density.\n'
          '/// The t-shirt steps ([xxxs] 2px to [xxxl] 40px) are the base scale; the\n'
          '/// named tokens are what specific components use. Density-dependent\n'
          '/// spacing (`space-scaled-*`) is on `context.cs.space`.',
    ),
    ('CsSize', 'size', 'Fixed component sizes (`size-*` tokens) that do not change with density.'),
  ]) {
    b
      ..writeln('/// $doc')
      ..writeln('abstract final class $cls {');
    for (final n in invariant.where((n) => n.startsWith(prefix))) {
      final name = n == 'spaceNone' ? 'none' : _lowerFirst(n.substring(prefix.length));
      b.writeln('  /// `$n`.');
      b.writeln('  static const double $name = ${_num(_tryPx(_resolve(n, _state()))!)};');
    }
    b
      ..writeln('}')
      ..writeln();
  }

  b
    ..writeln('/// Spacing and sizes that change with content density. Read them from')
    ..writeln('/// the theme (`context.cs.space.scaledM`) so compact mode applies.')
    ..writeln('@immutable')
    ..writeln('class CsDensityTokens {')
    ..writeln('  const CsDensityTokens({');
  for (final n in densityFields) {
    b.writeln('    required this.${_densityName(n)},');
  }
  b.writeln('  });');
  b.writeln();
  for (final n in densityFields) {
    final c = _resolve(n, _state());
    final k = _resolve(n, _state(density: 'compact'));
    final t = _resolve(n, _state(), context: 'compact-table');
    b.writeln('  /// `$n`: $c comfortable, $k compact, $t in compact tables.');
    b.writeln('  final double ${_densityName(n)};');
  }
  void densityConst(String label, String doc, Map<String, String> state, {String? context}) {
    b.writeln();
    b.writeln('  /// $doc');
    b.writeln('  static const CsDensityTokens $label = CsDensityTokens(');
    for (final n in densityFields) {
      b.writeln('    ${_densityName(n)}: ${_num(_tryPx(_resolve(n, state, context: context))!)},');
    }
    b.writeln('  );');
  }

  densityConst('comfortable', 'Comfortable density, the default.', _state());
  densityConst('compact', 'Compact density: tighter vertical rhythm for data-heavy pages.', _state(density: 'compact'));
  densityConst(
    'compactTable',
    'The compact-table context: what a table with `contentDensity: compact` uses inside.',
    _state(),
    context: 'compact-table',
  );
  b
    ..writeln('}')
    ..writeln();

  // Radii, borders.
  void group(String cls, String prefix, String doc, {String Function(String)? rename}) {
    b
      ..writeln('/// $doc')
      ..writeln('abstract final class $cls {');
    for (final n in _tokens.keys.where((n) => n.startsWith(prefix) && _modeMap[n] != 'color')) {
      final v = _tryPx(_resolve(n, _state()));
      if (v == null) continue;
      final name = rename?.call(n) ?? _lowerFirst(n.substring(prefix.length));
      b.writeln('  /// `$n`.');
      b.writeln('  static const double $name = ${_num(v)};');
    }
    b
      ..writeln('}')
      ..writeln();
  }

  group('CsBorderRadius', 'borderRadius', 'Corner radii. Cloudscape rounds buttons fully (20px) and containers at 16px.');
  group('CsBorderWidth', 'borderWidth', 'Border widths in logical pixels.');
  b
    ..writeln('/// Line widths that are not `borderWidth*` tokens (dividers, focus outlines).')
    ..writeln('abstract final class CsBorderLine {');
  for (final n in _tokens.keys.where(
    (n) => n.startsWith('border') && !n.startsWith('borderRadius') && !n.startsWith('borderWidth'),
  )) {
    final v = _tryPx(_resolve(n, _state()));
    if (v == null) continue;
    b.writeln('  /// `$n`.');
    b.writeln('  static const double ${_lowerFirst(n.substring('border'.length))} = ${_num(v)};');
  }
  b
    ..writeln('}')
    ..writeln();

  // Typography raw values.
  b
    ..writeln('/// Raw type tokens. Prefer the styles on `context.cs` (`text`, `heading`).')
    ..writeln('abstract final class CsFontTokens {');
  for (final n in _tokens.keys.where(
    (n) => n.startsWith('fontSize') || n.startsWith('lineHeight') || n.startsWith('letterSpacing'),
  )) {
    final raw = _resolve(n, _state());
    double? v = _tryPx(raw);
    if (v == null && raw.endsWith('em')) v = double.parse(raw.replaceAll('em', ''));
    if (v == null && raw == 'normal') v = 0;
    if (v == null) continue;
    b.writeln('  /// `$n`: $raw.');
    b.writeln('  static const double ${_lowerFirst(n)} = ${_num(v)};');
  }
  for (final n in _tokens.keys.where((n) => n.startsWith('fontWeight'))) {
    final raw = _resolve(n, _state());
    final w = int.tryParse(raw);
    if (w == null) continue;
    b.writeln('  /// `$n`: $raw.');
    b.writeln('  static const FontWeight ${_lowerFirst(n)} = FontWeight.w$w;');
  }
  for (final n in _tokens.keys.where((n) => n.startsWith('fontFamily'))) {
    b.writeln('  /// `$n`.');
    b.writeln("  static const String ${_lowerFirst(n)} = ${jsonEncode(_resolve(n, _state()))};");
  }
  b
    ..writeln('}')
    ..writeln();

  // Motion.
  b
    ..writeln('/// Cloudscape motion durations (`motionDuration*`). All collapse to zero')
    ..writeln('/// when motion is disabled; use `CsMotion.duration(context, ...)`.')
    ..writeln('abstract final class CsDurations {');
  for (final n in _tokens.keys.where((n) => n.startsWith('motionDuration'))) {
    final raw = _resolve(n, _state());
    final ms = double.tryParse(raw.replaceAll('ms', ''));
    if (ms == null) continue;
    b.writeln('  /// `$n`: $raw.');
    b.writeln('  static const Duration ${_lowerFirst(n.substring('motionDuration'.length))} = Duration(milliseconds: ${ms.round()});');
  }
  b
    ..writeln('}')
    ..writeln()
    ..writeln('/// Cloudscape easing curves (`motionEasing*`).')
    ..writeln('abstract final class CsCurves {');
  for (final n in _tokens.keys.where((n) => n.startsWith('motionEasing'))) {
    final raw = _resolve(n, _state());
    final curve = _curve(raw);
    if (curve == null) continue;
    b.writeln('  /// `$n`: $raw.');
    b.writeln('  static const Curve ${_lowerFirst(n.substring('motionEasing'.length))} = $curve;');
  }
  b
    ..writeln('}')
    ..writeln();

  // Shadows.
  final shadowNames = _tokens.keys.where((n) => n.startsWith('shadow')).toList();
  b
    ..writeln('/// Elevation shadows for one mode. Cloudscape keeps most surfaces flat;')
    ..writeln('/// shadows mark things that float (dropdowns, popovers, modals) and')
    ..writeln('/// sticky headers.')
    ..writeln('@immutable')
    ..writeln('class CsShadows {')
    ..writeln('  const CsShadows({');
  for (final n in shadowNames) {
    b.writeln('    required this.${_lowerFirst(n.substring('shadow'.length))},');
  }
  b.writeln('  });');
  b.writeln();
  for (final n in shadowNames) {
    b.writeln('  /// `$n`.');
    b.writeln('  final List<BoxShadow> ${_lowerFirst(n.substring('shadow'.length))};');
  }
  for (final mode in ['light', 'dark']) {
    b.writeln();
    b.writeln('  /// Shadows in $mode mode.');
    b.writeln('  static const CsShadows $mode = CsShadows(');
    for (final n in shadowNames) {
      b.writeln('    ${_lowerFirst(n.substring('shadow'.length))}: ${_shadows(_resolve(n, _state(color: mode)))},');
    }
    b.writeln('  );');
  }
  b.writeln('}');
  return b.toString();
}

double? _tryPx(String v) {
  try {
    return _px(v);
  } on FormatException {
    return null;
  }
}

String _lowerFirst(String s) => s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

String _densityName(String n) {
  for (final p in ['space', 'size']) {
    if (n.startsWith(p)) {
      final rest = _lowerFirst(n.substring(p.length));
      return p == 'size' ? 'size${rest[0].toUpperCase()}${rest.substring(1)}' : rest;
    }
  }
  return _lowerFirst(n);
}

String? _curve(String raw) {
  switch (raw.trim()) {
    case 'linear':
      return 'Curves.linear';
    case 'ease-out':
      return 'Cubic(0, 0, 0.58, 1)';
    case 'ease-in':
      return 'Cubic(0.42, 0, 1, 1)';
    case 'ease-in-out':
      return 'Cubic(0.42, 0, 0.58, 1)';
    case 'ease':
      return 'Cubic(0.25, 0.1, 0.25, 1)';
  }
  final m = RegExp(r'cubic-bezier\(([^)]*)\)').firstMatch(raw);
  if (m == null) return null;
  final p = m[1]!.split(',').map((s) => double.parse(s.trim())).toList();
  return 'Cubic(${p.map(_num).join(', ')})';
}

String _shadows(String raw) {
  if (raw.trim() == 'none') return '[]';
  // Split on commas that are not inside parentheses.
  final parts = <String>[];
  var depth = 0;
  var cur = StringBuffer();
  for (final ch in raw.split('')) {
    if (ch == '(') depth++;
    if (ch == ')') depth--;
    if (ch == ',' && depth == 0) {
      parts.add(cur.toString());
      cur = StringBuffer();
    } else {
      cur.write(ch);
    }
  }
  parts.add(cur.toString());
  final out = <String>[];
  for (final p in parts) {
    final colorMatch = RegExp(r'(#[0-9a-fA-F]+|rgba?\([^)]*\))').firstMatch(p)!;
    final color = _parseColor(colorMatch[0]!)!;
    final nums = p.replaceFirst(colorMatch[0]!, '').trim().split(RegExp(r'\s+')).map(_px).toList();
    final x = nums[0], y = nums[1];
    final blur = nums.length > 2 ? nums[2] : 0.0;
    final spread = nums.length > 3 ? nums[3] : 0.0;
    out.add(
      'BoxShadow(offset: Offset(${_num(x)}, ${_num(y)}), blurRadius: ${_num(blur)}, spreadRadius: ${_num(spread)}, color: Color(${_hex(color)}))',
    );
  }
  return '[${out.join(', ')}]';
}
