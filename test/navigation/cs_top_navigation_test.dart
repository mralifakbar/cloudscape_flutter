import 'package:cloudscape_flutter/src/forms/forms.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/navigation/navigation.dart';
import 'package:cloudscape_flutter/src/overlays/overlays.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _logo = SizedBox(width: 32, height: 32, child: Placeholder());

List<CsTopNavigationUtility> _utilities({List<String>? log}) => [
  CsTopNavigationButton(
    text: 'New feature',
    href: '/new',
    external: true,
    onFollow: () => log?.add('follow new'),
    onClick: () => log?.add('click new'),
  ),
  CsTopNavigationButton(
    icon: CsIcons.notification,
    ariaLabel: 'Notifications (2 unread)',
    badge: true,
    disableUtilityCollapse: true,
    onClick: () => log?.add('notifications'),
  ),
  CsTopNavigationMenuDropdown(
    icon: CsIcons.settings,
    text: 'Settings',
    title: 'Settings',
    items: const [
      CsTopNavigationMenuItem(id: 'preferences', text: 'Preferences'),
      CsTopNavigationMenuItem(id: 'region', text: 'Region', description: 'us-east-1'),
    ],
    onItemClick: (item) => log?.add('settings ${item.id}'),
  ),
  CsTopNavigationMenuDropdown(
    icon: CsIcons.userProfile,
    text: 'Jane Doe',
    description: 'jane@example.com',
    items: const [
      CsTopNavigationMenuItem(id: 'profile', text: 'Profile'),
      CsTopNavigationMenuItem(
        id: 'support-group',
        text: 'Support',
        items: [
          CsTopNavigationMenuItem(id: 'docs', text: 'Documentation', href: '/docs', external: true),
          CsTopNavigationMenuItem(id: 'feedback', text: 'Feedback', href: '/feedback'),
        ],
      ),
      CsTopNavigationMenuItem(id: 'signout', text: 'Sign out'),
    ],
    onItemClick: (item) => log?.add('user ${item.id}'),
    onItemFollow: (item) => log?.add('follow ${item.id}'),
  ),
];

Widget _bar({List<String>? log, Widget? search = const SizedBox(height: 32, child: Placeholder())}) => Align(
  alignment: Alignment.topCenter,
  child: CsTopNavigation(
    identity: CsTopNavigationIdentity(href: '/', title: 'Cloud console', logo: _logo, onFollow: () => log?.add('home')),
    search: search,
    utilities: _utilities(log: log),
  ),
);

void main() {
  group('responsive states', () {
    test('match Cloudscape', () {
      final states = CsTopNavigationResponsiveState.statesFor(_utilities(), hasSearch: true, hasTitleWithLogo: true);
      expect(states.length, 7);
      expect(states[1].hideUtilityText, isTrue);
      expect(states[2].hideSearch, isTrue);
      // The notifications utility opts out of collapsing.
      expect(states[3].hideUtilities, [0]);
      expect(states[5].hideUtilities, [0, 2, 3]);
      expect(states.last.hideTitle, isTrue);
    });
  });

  testWidgets('renders dark in light and dark mode, comfortable and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(tester, _bar(), brightness: b, density: d, size: csDesktopSize, center: false);
        final ctx = tester.element(find.text('Cloud console'));
        expect(ctx.cs.isDark, isTrue);
        expect(ctx.cs.visualContext, CsVisualContextName.topNavigation);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('desktop shows everything; 56px tall', (tester) async {
    await pumpCs(tester, _bar(), size: const Size(1600, 800), center: false);
    expect(find.text('Cloud console'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('More'), findsNothing);
    expect(tester.getSize(find.byType(CsTopNavigation)).height, 57, reason: '56px bar plus the 1px bottom border');
  });

  testWidgets('identity and button utilities fire their callbacks', (tester) async {
    final log = <String>[];
    await pumpCs(tester, _bar(log: log), size: const Size(1600, 800), center: false);
    await tester.tap(find.text('Cloud console'));
    await tester.tap(find.text('New feature'));
    await tester.tap(find.bySemanticsLabel('Notifications (2 unread)'));
    expect(log, ['home', 'follow new', 'click new', 'notifications']);
  });

  testWidgets('menu dropdown opens, picks an item and closes', (tester) async {
    final log = <String>[];
    await pumpCs(tester, _bar(log: log), size: const Size(1600, 800), center: false);
    await tester.tap(find.text('Jane Doe'));
    await tester.pumpAndSettle();
    expect(find.text('jane@example.com'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();
    expect(log, ['user feedback', 'follow feedback']);
    expect(find.text('Profile'), findsNothing);
  });

  testWidgets('Escape closes a menu dropdown', (tester) async {
    await pumpCs(tester, _bar(), size: const Size(1600, 800), center: false);
    await tester.tap(find.text('Jane Doe'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsNothing);
  });

  testWidgets('phone: texts hide, search becomes a button, utilities move to More', (tester) async {
    await pumpCs(tester, _bar(), center: false);
    expect(find.text('Jane Doe'), findsNothing);
    expect(find.text('More'), findsOneWidget);
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
    expect(find.bySemanticsLabel('Notifications (2 unread)'), findsOneWidget);
    expect(tester.getSize(find.byType(CsTopNavigation)).height, 41);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search button expands the search over the bar', (tester) async {
    await pumpCs(
      tester,
      _bar(
        search: CsInput(value: '', onChange: (_) {}),
      ),
      center: false,
    );
    expect(find.byType(CsInput), findsNothing);
    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();
    expect(find.byType(CsInput), findsOneWidget);
    expect(find.text('Cloud console'), findsNothing);
    expect(tester.testTextInput.hasAnyClients, isTrue);
    await tester.tap(find.bySemanticsLabel('Close search'));
    await tester.pumpAndSettle();
    expect(find.byType(CsInput), findsNothing);
  });

  testWidgets('overflow menu opens full screen with submenus', (tester) async {
    final log = <String>[];
    await pumpCs(tester, _bar(log: log), center: false);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    await tester.tap(find.text('Jane Doe'));
    await tester.pumpAndSettle();
    expect(find.text('jane@example.com'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('All'), findsOneWidget);
    await tester.tap(find.text('Jane Doe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(log, ['user signout']);
    expect(find.text('All'), findsNothing);
  });

  testWidgets('overflow menu closes with the close button and Escape', (tester) async {
    await pumpCs(tester, _bar(), center: false);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Close menu'));
    await tester.pumpAndSettle();
    expect(find.text('All'), findsNothing);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('All'), findsNothing);
  });

  testWidgets('visualContext none uses page colors; custom content', (tester) async {
    await pumpCs(
      tester,
      const CsTopNavigation(
        identity: CsTopNavigationIdentity(href: '/', title: 'Console'),
        visualContext: CsTopNavigationVisualContext.none,
      ),
      center: false,
    );
    expect(tester.element(find.text('Console')).cs.isDark, isFalse);
    await pumpCs(tester, const CsTopNavigation(child: Text('Custom bar')), center: false);
    expect(find.text('Custom bar'), findsOneWidget);
  });

  testWidgets('menu on a phone opens as a sheet', (tester) async {
    await pumpCs(
      tester,
      const CsTopNavigation(
        identity: CsTopNavigationIdentity(href: '/', title: 'Console'),
        utilities: [
          CsTopNavigationMenuDropdown(
            icon: CsIcons.userProfile,
            ariaLabel: 'Account',
            disableUtilityCollapse: true,
            items: [CsTopNavigationMenuItem(id: 'p', text: 'Profile')],
          ),
        ],
      ),
      center: false,
    );
    await tester.tap(find.bySemanticsLabel('Account'));
    await tester.pumpAndSettle();
    expect(find.byType(CsSheet), findsOneWidget);
  });

  testWidgets('2x text at 390px without overflow', (tester) async {
    await pumpCs(tester, _bar(), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
  });
}
