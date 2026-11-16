import 'package:cloudscape_flutter/src/actions/actions.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

List<CsButtonGroupItemOrGroup> _items({bool liked = false}) => [
  CsButtonGroupGroup(
    text: 'Vote',
    items: [
      CsButtonGroupIconToggleButton(
        id: 'like',
        text: 'Like',
        icon: CsIcons.thumbsUp,
        pressedIcon: CsIcons.thumbsUpFilled,
        pressed: liked,
        pressedPopoverFeedback: 'Liked',
      ),
      const CsButtonGroupIconButton(
        id: 'refresh',
        text: 'Refresh',
        icon: CsIcons.refresh,
        popoverFeedback: 'Refreshed',
      ),
    ],
  ),
  const CsButtonGroupCopyToClipboard(
    id: 'copy',
    text: 'Copy',
    textToCopy: 'i-0abc123',
    copySuccessText: 'Copied',
    copyErrorText: 'Failed to copy',
  ),
  const CsButtonGroupIconButton(
    id: 'off',
    text: 'Delete',
    icon: CsIcons.remove,
    disabled: true,
    disabledReason: 'Read-only',
  ),
  const CsButtonGroupMenuDropdown(
    id: 'more',
    text: 'More actions',
    items: [CsButtonDropdownItem(id: 'share', text: 'Share')],
  ),
];

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
  });

  testWidgets('renders in light, dark, compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          CsButtonGroup(ariaLabel: 'Message actions', items: _items()),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('click reports ids, toggle reports pressed and shows feedback', (tester) async {
    final clicks = <CsButtonGroupItemClickDetails>[];
    await pumpCs(tester, CsButtonGroup(items: _items(), onItemClick: clicks.add));
    await tester.tap(find.bySemanticsLabel('Like'));
    await tester.pump();
    expect(clicks.single.id, 'like');
    expect(clicks.single.pressed, isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Liked'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Liked'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Refresh'));
    expect(clicks.last.id, 'refresh');
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('copy shows the result; disabled does nothing', (tester) async {
    final copied = <String>[];
    final clicks = <String>[];
    await pumpCs(
      tester,
      CsButtonGroup(items: _items(), onCopySuccess: copied.add, onItemClick: (d) => clicks.add(d.id)),
    );
    await tester.tap(find.bySemanticsLabel('Copy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(copied, ['copy']);
    expect(find.text('Copied'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Delete'), warnIfMissed: false);
    expect(clicks, isEmpty);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('menu dropdown reports the menu item id', (tester) async {
    final clicks = <String>[];
    await pumpCs(
      tester,
      CsButtonGroup(items: _items(), onItemClick: (d) => clicks.add(d.id)),
      size: csDesktopSize,
    );
    await tester.tap(find.bySemanticsLabel('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(clicks, ['share']);
  });

  testWidgets('semantics: group label and toggle state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, CsButtonGroup(ariaLabel: 'Message actions', items: _items(liked: true)));
    expect(find.bySemanticsLabel('Message actions'), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel('Like').first).flagsCollection.isToggled.name, 'isTrue');
    handle.dispose();
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    await pumpCs(tester, CsButtonGroup(items: _items()), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
