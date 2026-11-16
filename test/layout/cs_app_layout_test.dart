import 'dart:ui';

import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  const drawers = [
    CsAppLayoutDrawer(
      id: 'security',
      icon: null,
      badge: true,
      resizable: true,
      ariaLabels: CsAppLayoutDrawerLabels(drawerName: 'Security'),
      content: Text('Security drawer'),
    ),
  ];

  Widget layout({
    bool toolbar = false,
    bool? navOpen,
    ValueChanged<bool>? onNav,
    bool? toolsOpen,
    ValueChanged<bool>? onTools,
    String? drawer,
    ValueChanged<String?>? onDrawer,
    CsAppLayoutContentType contentType = CsAppLayoutContentType.defaultVariant,
    CsAppLayoutHeaderVariant headerVariant = CsAppLayoutHeaderVariant.defaultVariant,
    bool sticky = false,
    Widget content = const Text('Instances table'),
  }) {
    const nav = Text('Side navigation');
    const tools = Text('Help content');
    return toolbar
        ? CsAppLayoutToolbar(
            navigation: nav,
            navigationOpen: navOpen,
            onNavigationChange: onNav,
            tools: tools,
            toolsOpen: toolsOpen,
            onToolsChange: onTools,
            breadcrumbs: const Text('Crumbs'),
            notifications: const Text('Flash'),
            stickyNotifications: sticky,
            drawers: drawers,
            activeDrawerId: drawer,
            onDrawerChange: onDrawer,
            contentType: contentType,
            headerVariant: headerVariant,
            contentHeader: const Text('Page header'),
            content: content,
          )
        : CsAppLayout(
            navigation: nav,
            navigationOpen: navOpen,
            onNavigationChange: onNav,
            tools: tools,
            toolsOpen: toolsOpen,
            onToolsChange: onTools,
            breadcrumbs: const Text('Crumbs'),
            notifications: const Text('Flash'),
            stickyNotifications: sticky,
            drawers: drawers,
            activeDrawerId: drawer,
            onDrawerChange: onDrawer,
            contentType: contentType,
            headerVariant: headerVariant,
            contentHeader: const Text('Page header'),
            content: content,
          );
  }

  for (final toolbar in [false, true]) {
    final name = toolbar ? 'CsAppLayoutToolbar' : 'CsAppLayout';

    testWidgets('$name renders wide and narrow in every theme', (tester) async {
      for (final b in Brightness.values) {
        for (final d in CsDensity.values) {
          for (final size in [csDesktopSize, csPhoneSize]) {
            await pumpCs(
              tester,
              layout(toolbar: toolbar),
              brightness: b,
              density: d,
              size: size,
              center: false,
            );
            expect(find.text('Instances table'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        }
      }
    });

    testWidgets('$name shows navigation beside content on desktop and closes it', (tester) async {
      await pumpCs(tester, layout(toolbar: toolbar), size: csDesktopSize, center: false);
      expect(find.text('Side navigation'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Side navigation')).dx,
        lessThan(tester.getTopLeft(find.text('Instances table')).dx),
      );
      if (toolbar) {
        await tester.tap(find.bySemanticsLabel('Open navigation drawer'));
      } else {
        await tester.tap(find.bySemanticsLabel('Close navigation drawer'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Side navigation'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Open navigation drawer'));
      await tester.pumpAndSettle();
      expect(find.text('Side navigation'), findsOneWidget);
    });

    testWidgets('$name opens navigation as a full-screen overlay on phones', (tester) async {
      await pumpCs(tester, layout(toolbar: toolbar), center: false);
      expect(find.text('Side navigation'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Open navigation drawer'));
      await tester.pumpAndSettle();
      expect(find.text('Side navigation'), findsOneWidget);
      final panel = find.ancestor(of: find.text('Side navigation'), matching: find.byType(DecoratedBox)).first;
      expect(tester.getSize(panel).width, 390);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Side navigation'), findsNothing);
    });

    testWidgets('$name opens tools and drawers from triggers', (tester) async {
      final tools = <bool>[];
      final drawerIds = <String?>[];
      await pumpCs(
        tester,
        layout(toolbar: toolbar, onTools: tools.add, onDrawer: drawerIds.add),
        size: csDesktopSize,
        center: false,
      );
      await tester.tap(find.bySemanticsLabel('Open help panel'));
      await tester.pumpAndSettle();
      expect(find.text('Help content'), findsOneWidget);
      expect(tools, [true]);
      await tester.tap(find.bySemanticsLabel('Security'));
      await tester.pumpAndSettle();
      expect(find.text('Security drawer'), findsOneWidget);
      expect(find.text('Help content'), findsNothing);
      expect(drawerIds.last, 'security');
      await tester.tap(find.bySemanticsLabel('Close Security'));
      await tester.pumpAndSettle();
      expect(find.text('Security drawer'), findsNothing);
      expect(drawerIds.last, isNull);
    });

    testWidgets('$name opens tools full screen on phones', (tester) async {
      await pumpCs(tester, layout(toolbar: toolbar), center: false);
      await tester.tap(find.bySemanticsLabel('Open help panel'));
      await tester.pumpAndSettle();
      expect(find.text('Help content'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Close help panel'));
      await tester.pumpAndSettle();
      expect(find.text('Help content'), findsNothing);
    });
  }

  testWidgets('controlled navigation reports changes without changing itself', (tester) async {
    bool? next;
    await pumpCs(tester, layout(navOpen: true, onNav: (v) => next = v), size: csDesktopSize, center: false);
    await tester.tap(find.bySemanticsLabel('Close navigation drawer'));
    await tester.pumpAndSettle();
    expect(next, false);
    expect(find.text('Side navigation'), findsOneWidget);
  });

  testWidgets('form content type starts with navigation closed and caps the width', (tester) async {
    await pumpCs(
      tester,
      layout(
        contentType: CsAppLayoutContentType.form,
        content: const SizedBox(height: 10, width: double.infinity),
      ),
      size: csDesktopSize,
      center: false,
    );
    expect(find.text('Side navigation'), findsNothing);
    expect(tester.getSize(find.byType(SizedBox).last).width, lessThanOrEqualTo(800));
  });

  testWidgets('drawer resizes by dragging its handle', (tester) async {
    await pumpCs(tester, layout(drawer: 'security'), size: csDesktopSize, center: false);
    final before = tester.getTopLeft(find.text('Security drawer')).dx;
    await tester.drag(find.bySemanticsLabel('Resize Security'), const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Security drawer')).dx, lessThan(before));
  });

  testWidgets('sticky notifications stay outside the scroll view', (tester) async {
    await pumpCs(
      tester,
      layout(sticky: true, content: const SizedBox(height: 3000, child: Text('Long'))),
      size: csDesktopSize,
      center: false,
    );
    final y = tester.getTopLeft(find.text('Flash')).dy;
    await tester.drag(find.text('Long'), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Flash')).dy, y);
  });

  testWidgets('high contrast header renders the dark band', (tester) async {
    await pumpCs(
      tester,
      layout(headerVariant: CsAppLayoutHeaderVariant.highContrast),
      size: csDesktopSize,
      center: false,
    );
    expect(CsTheme.of(tester.element(find.text('Page header'))).visualContext, CsVisualContextName.header);
  });

  testWidgets('drawer trigger shows a badge and selected state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, layout(drawer: 'security'), size: csDesktopSize, center: false);
    final toggled = [
      for (final e in find.bySemanticsLabel('Security').evaluate())
        tester.getSemantics(find.byElementPredicate((x) => x == e)).flagsCollection.isToggled,
    ];
    expect(toggled, contains(Tristate.isTrue));
    handle.dispose();
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, layout(), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
    await pumpCs(tester, layout(toolbar: true), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
  });
}
