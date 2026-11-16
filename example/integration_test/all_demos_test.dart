import 'package:cloudscape_flutter_example/gallery/categories.dart';
import 'package:cloudscape_flutter_example/gallery/category_page.dart';
import 'package:cloudscape_flutter_example/main.dart';
import 'package:cloudscape_flutter_example/sample/console_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Runs on a device or simulator: opens every demo, one by one, in light and
/// dark, scrolls it from top to bottom and fails on any exception; then
/// opens every page of the sample console and walks the real navigation from
/// the home page into every category.
///
///   flutter test integration_test -d DEVICE_ID
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> show(WidgetTester tester, Widget home, {required bool dark}) async {
    // Unmount the previous demo first, so focus requests from its autofocus
    // fields settle before the next app replaces it.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(
      _Mode(
        dark: dark,
        child: GalleryApp(key: UniqueKey(), home: home),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isEmpty) return;
    for (var i = 0; i < 8; i++) {
      await tester.drag(scrollables.first, const Offset(0, -600), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull);
    }
  }

  for (final category in galleryCategories) {
    testWidgets('${category.title}: every demo in light and dark', (tester) async {
      for (final demo in category.demos) {
        for (final dark in [false, true]) {
          await show(tester, DemoPage(demo: demo), dark: dark);
        }
      }
    });
  }

  testWidgets('sample console: every page in light and dark', (tester) async {
    for (final section in ConsoleSection.values) {
      for (final dark in [false, true]) {
        await show(tester, ConsoleApp(initialSection: section), dark: dark);
      }
    }
  });

  testWidgets('home opens every category through the real navigation', (tester) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();
    for (final c in galleryCategories) {
      await tester.scrollUntilVisible(find.text(c.title), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text(c.title));
      // Pages with spinners never settle, so pump past the route transition.
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(CategoryPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump(const Duration(milliseconds: 600));
    }
  });
}

/// Forces the platform brightness the gallery's system mode follows.
class _Mode extends StatelessWidget {
  const _Mode({required this.dark, required this.child});

  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(platformBrightness: dark ? Brightness.dark : Brightness.light),
    child: child,
  );
}
