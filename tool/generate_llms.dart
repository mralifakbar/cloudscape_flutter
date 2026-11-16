// Regenerates llms.txt (index) and llms-full.txt (every doc page in one file).
//
//   dart run tool/generate_llms.dart
import 'dart:io';

void main() {
  final guides = _pages('doc/guides');
  final components = _pages('doc/components');

  final index = StringBuffer()
    ..writeln('# cloudscape_flutter')
    ..writeln()
    ..writeln(
      '> Unofficial Flutter port of AWS Cloudscape Design System: every visual-refresh token in light, dark and '
      'compact density, 148 Cloudscape icons, and accessible, touch-ready components. Not affiliated with AWS.',
    )
    ..writeln()
    ..writeln(
      'Import `package:cloudscape_flutter/cloudscape_flutter.dart`, wrap the app in `CsThemeProvider`, read the '
      'theme with `context.cs`. Widgets are prefixed `Cs`; props follow Cloudscape names (`variant`, `value`/`onChange`, '
      '`visible`/`onDismiss`, `items`); colors are `CsColor` tokens (`context.cs.colors.textBodyDefault`); spacing is '
      '`CsSpace` (fixed) and `context.cs.space` (density-aware); content text is body-m, 14px on 20px.',
    )
    ..writeln()
    ..writeln('## Guides')
    ..writeln();
  for (final p in guides) {
    index.writeln('- [${_title(p)}](${p.path}): ${_summary(p)}');
  }
  index
    ..writeln()
    ..writeln('## Components')
    ..writeln();
  for (final p in components) {
    index.writeln('- [${_title(p)}](${p.path}): ${_summary(p)}');
  }
  File('llms.txt').writeAsStringSync(index.toString());

  final full = StringBuffer()..writeln(index.toString());
  for (final p in [...guides, ...components]) {
    full
      ..writeln()
      ..writeln('---')
      ..writeln('source: ${p.path}')
      ..writeln('---')
      ..writeln()
      ..writeln(p.readAsStringSync().trim());
  }
  File('llms-full.txt').writeAsStringSync(full.toString());
  stdout.writeln('llms.txt: ${guides.length} guides, ${components.length} components');
}

List<File> _pages(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) return [];
  return d.listSync().whereType<File>().where((f) => f.path.endsWith('.md')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

String _title(File f) {
  final line = f.readAsLinesSync().firstWhere((l) => l.startsWith('# '), orElse: () => f.path);
  return line.replaceFirst('# ', '').trim();
}

String _summary(File f) {
  final lines = f.readAsLinesSync();
  final start = lines.indexWhere((l) => l.startsWith('# '));
  var inFence = false;
  for (final l in lines.skip(start + 1)) {
    final t = l.trim();
    if (t.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence || t.isEmpty || t.startsWith('Cloudscape reference') || t.startsWith('#')) continue;
    return t;
  }
  return '';
}
