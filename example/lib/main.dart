import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/material.dart';

import 'gallery/categories.dart';
import 'gallery/category_page.dart';
import 'gallery/foundations/colors_page.dart';
import 'gallery/foundations/icons_page.dart';
import 'gallery/foundations/typography_page.dart';
import 'gallery/home_page.dart';
import 'gallery/settings_scope.dart';
import 'sample/console_app.dart';

void main() => runApp(const GalleryApp());

/// The cloudscape_flutter gallery: every component with live demos, plus the
/// foundations (colors, type, icons) and a sample cloud console.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key, this.home});

  /// Overrides the start page, for tests and screenshots.
  final Widget? home;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  CsThemeMode _mode = CsThemeMode.system;
  CsDensity _density = CsDensity.comfortable;

  @override
  Widget build(BuildContext context) {
    return GallerySettings(
      mode: _mode,
      density: _density,
      onModeChange: (m) => setState(() => _mode = m),
      onDensityChange: (d) => setState(() => _density = d),
      child: CsThemeProvider(
        mode: _mode,
        density: _density,
        child: Builder(
          builder: (context) => MaterialApp(
            title: 'cloudscape_flutter',
            debugShowCheckedModeBanner: false,
            theme: csMaterialTheme(context.cs),
            home: widget.home ?? _startPage(),
          ),
        ),
      ),
    );
  }
}

/// Start page chosen with `--dart-define=CS_GALLERY_START=<page>`, for
/// screenshots: `console`, `console:dashboard`, `console:launch`, `colors`,
/// `typography`, `icons`, a category title (`Forms`) or `demo:<ClassName>`.
Widget _startPage() {
  const start = String.fromEnvironment('CS_GALLERY_START');
  if (start.isEmpty) return const HomePage(sampleApp: _console);
  if (start == 'console') return const ConsoleApp();
  if (start == 'console:dashboard') return const ConsoleApp(initialSection: ConsoleSection.dashboard);
  if (start == 'console:launch') return const ConsoleApp(initialSection: ConsoleSection.launch);
  if (start == 'colors') return const ColorsPage();
  if (start == 'typography') return const TypographyPage();
  if (start == 'icons') return const IconsPage();
  for (final c in galleryCategories) {
    if (c.title == start) return CategoryPage(category: c);
    for (final d in c.demos) {
      if ('demo:${d.title}' == start) return DemoPage(demo: d);
    }
  }
  return const HomePage(sampleApp: _console);
}

Widget _console(BuildContext context) => const ConsoleApp();
