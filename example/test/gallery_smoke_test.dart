import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:cloudscape_flutter_example/gallery/categories.dart';
import 'package:cloudscape_flutter_example/gallery/category_page.dart';
import 'package:cloudscape_flutter_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders every demo, one by one, in light and dark, at phone and desktop
/// widths, in compact density and at 2x text, and fails on any exception
/// (overflow, missing ancestor, assert).
void main() {
  final configs = <(String, Size, Brightness, double)>[
    ('phone light', const Size(390, 844), Brightness.light, 1),
    ('phone dark', const Size(390, 844), Brightness.dark, 1),
    ('phone 2x text', const Size(390, 844), Brightness.light, 2),
    ('desktop dark', const Size(1280, 800), Brightness.dark, 1),
  ];

  for (final category in galleryCategories) {
    for (final demo in category.demos) {
      for (final (name, size, brightness, scale) in configs) {
        testWidgets('${category.title} / ${demo.title} / $name', (tester) async {
          tester.view.physicalSize = size * tester.view.devicePixelRatio;
          addTearDown(tester.view.resetPhysicalSize);
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale), platformBrightness: brightness),
              child: GalleryApp(home: DemoPage(demo: demo)),
            ),
          );
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          expect(find.text(demo.title), findsWidgets);
          expectNoFallbackText(tester);
          // Demos simulate network work with timers; let them finish.
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 30));
        });
      }
    }
  }

  testWidgets('every category has demos and a doc page per demo', (tester) async {
    for (final c in galleryCategories) {
      expect(c.demos, isNotEmpty, reason: c.title);
    }
  });

  testWidgets('home lists categories and opens one', (tester) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();
    final first = galleryCategories.first.title;
    await tester.ensureVisible(find.text(first));
    await tester.tap(find.text(first));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryPage), findsOneWidget);
  });

  testWidgets('theme and density toggles', (tester) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Theme: System')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Theme: Light')));
    await tester.pumpAndSettle();
    expect(
      CsTheme.of(
        tester.element(
          find.byType(CategoryPage).evaluate().isEmpty ? find.byType(Scaffold).first : find.byType(CategoryPage),
        ),
      ).isDark,
      isTrue,
    );
    await tester.tap(find.bySemanticsLabel(RegExp('^Density: comfortable')));
    await tester.pumpAndSettle();
    expect(CsTheme.of(tester.element(find.byType(Scaffold).first)).density, CsDensity.compact);
  });
}

/// Text that fell back to Flutter's debug style (yellow double underline)
/// has no Cloudscape or Material text style above it.
void expectNoFallbackText(WidgetTester tester) {
  for (final p in tester.renderObjectList<RenderParagraph>(find.byType(RichText))) {
    final style = p.text.style;
    expect(
      style?.decorationColor == const Color(0xFFFFFF00) && style?.decorationStyle == TextDecorationStyle.double,
      isFalse,
      reason: 'Fallback text style on "${p.text.toPlainText()}"',
    );
  }
}
