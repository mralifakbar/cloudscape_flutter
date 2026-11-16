import 'package:cloudscape_flutter/src/genai/genai.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/overlays/overlays.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders every color and content in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          const Wrap(
            spacing: 8,
            children: [
              CsAvatar(ariaLabel: 'User'),
              CsAvatar(ariaLabel: 'Jane Doe', initials: 'JD'),
              CsAvatar(ariaLabel: 'Assistant', color: CsAvatarColor.genAi, icon: CsIcons.genAi),
              CsAvatar(ariaLabel: 'Assistant', color: CsAvatarColor.genAi, initials: 'AI', width: 48),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('shows at most two initials', (tester) async {
    await pumpCs(tester, const CsAvatar(ariaLabel: 'Jane', initials: 'JDX'));
    expect(find.text('JD'), findsOneWidget);
    expect(find.text('JDX'), findsNothing);
  });

  testWidgets('initials take precedence over the icon and loading over both', (tester) async {
    await pumpCs(tester, const CsAvatar(ariaLabel: 'Jane', initials: 'JD', icon: CsIcons.genAi));
    expect(find.byType(CsIcon), findsNothing);
    await pumpCs(tester, const CsAvatar(ariaLabel: 'Jane', initials: 'JD', loading: true), settle: false);
    expect(find.text('JD'), findsNothing);
  });

  testWidgets('width defaults to 28 and never goes below it', (tester) async {
    await pumpCs(tester, const CsAvatar(ariaLabel: 'A', width: 12));
    expect(tester.getSize(find.byType(ClipOval)), const Size(28, 28));
    await pumpCs(tester, const CsAvatar(ariaLabel: 'A', width: 64));
    expect(tester.getSize(find.byType(ClipOval)), const Size(64, 64));
  });

  testWidgets('exposes an image role with the aria label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsAvatar(ariaLabel: 'Avatar of Jane Doe', initials: 'JD'));
    expect(
      tester.getSemantics(find.byType(CsAvatar)),
      matchesSemantics(label: 'Avatar of Jane Doe', isImage: true, isFocusable: true, hasFocusAction: true),
    );
    handle.dispose();
  });

  testWidgets('loading animates only while loading and stops when done', (tester) async {
    await pumpCs(
      tester,
      const CsAvatar(ariaLabel: 'Assistant', color: CsAvatarColor.genAi, loading: true),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.hasRunningAnimations, isTrue);
    await pumpCs(tester, const CsAvatar(ariaLabel: 'Assistant', color: CsAvatarColor.genAi));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reduced motion keeps the dots still', (tester) async {
    await pumpCs(
      tester,
      const CsAvatar(ariaLabel: 'Assistant', color: CsAvatarColor.genAi, loading: true),
      disableAnimations: true,
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('tooltip shows on hover and keyboard focus', (tester) async {
    await pumpCs(tester, const CsAvatar(ariaLabel: 'Jane Doe', tooltipText: 'Jane Doe', initials: 'JD'));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.byType(CsAvatar)));
    await tester.pumpAndSettle();
    expect(find.text('Jane Doe'), findsOneWidget);
    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(find.text('Jane Doe'), findsNothing);
    await gesture.removePointer();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.byType(CsTooltip), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets('holds up at 390px with 2x text', (tester) async {
    await pumpCs(tester, const CsAvatar(ariaLabel: 'Jane', initials: 'JD'), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
