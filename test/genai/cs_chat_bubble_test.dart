import 'package:cloudscape_flutter/src/genai/genai.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _ai = CsAvatar(ariaLabel: 'Assistant', color: CsAvatarColor.genAi, icon: CsIcons.genAi);
const _me = CsAvatar(ariaLabel: 'Jane Doe', initials: 'JD');

void main() {
  testWidgets('renders both types in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          const Column(
            children: [
              CsChatBubble(type: CsChatBubbleType.outgoing, ariaLabel: 'Jane', avatar: _me, child: Text('Hi')),
              CsChatBubble(type: CsChatBubbleType.incoming, ariaLabel: 'AI', avatar: _ai, child: Text('Hello')),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('incoming is filled, outgoing is not', (tester) async {
    late CsThemeData theme;
    await pumpCs(
      tester,
      Builder(
        builder: (context) {
          theme = context.cs;
          return const Column(
            children: [
              CsChatBubble(type: CsChatBubbleType.incoming, ariaLabel: 'in', child: Text('in')),
              CsChatBubble(type: CsChatBubbleType.outgoing, ariaLabel: 'out', child: Text('out')),
            ],
          );
        },
      ),
    );
    BoxDecoration deco(String text) =>
        tester
                .widget<DecoratedBox>(find.ancestor(of: find.text(text), matching: find.byType(DecoratedBox)).first)
                .decoration
            as BoxDecoration;
    expect(deco('in').color, theme.colors.backgroundChatBubbleIncoming);
    expect(deco('out').color, theme.colors.backgroundChatBubbleOutgoing);
  });

  testWidgets('shows actions and the loading bar', (tester) async {
    await pumpCs(
      tester,
      const CsChatBubble(
        type: CsChatBubbleType.incoming,
        ariaLabel: 'AI',
        avatar: _ai,
        showLoadingBar: true,
        actions: Text('Copy'),
        child: Text('Generating'),
      ),
      settle: false,
    );
    expect(find.text('Copy'), findsOneWidget);
    expect(find.byType(CsLoadingBar), findsOneWidget);
  });

  testWidgets('hideAvatar keeps the space and removes it from semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      const CsChatBubble(type: CsChatBubbleType.incoming, ariaLabel: 'AI', avatar: _ai, child: Text('Hi')),
    );
    final shown = tester.getTopLeft(find.text('Hi'));
    expect(find.bySemanticsLabel('Assistant'), findsOneWidget);
    await pumpCs(
      tester,
      const CsChatBubble(
        type: CsChatBubbleType.incoming,
        ariaLabel: 'AI',
        avatar: _ai,
        hideAvatar: true,
        child: Text('Hi'),
      ),
    );
    expect(tester.getTopLeft(find.text('Hi')), shown);
    expect(find.bySemanticsLabel('Assistant'), findsNothing);
    handle.dispose();
  });

  testWidgets('align end puts the avatar after the bubble', (tester) async {
    await pumpCs(
      tester,
      const CsChatBubble(
        type: CsChatBubbleType.outgoing,
        ariaLabel: 'Jane',
        avatar: _me,
        align: CsChatBubbleAlign.end,
        child: Text('Hi'),
      ),
      center: false,
    );
    expect(tester.getCenter(find.byType(CsAvatar)).dx, greaterThan(tester.getCenter(find.text('Hi')).dx));
  });

  testWidgets('stretch fills the width', (tester) async {
    await pumpCs(
      tester,
      const CsChatBubble(type: CsChatBubbleType.incoming, ariaLabel: 'AI', stretch: true, child: Text('Hi')),
      center: false,
    );
    expect(tester.getSize(find.byType(DecoratedBox).last).width, 390);
  });

  testWidgets('group carries the aria label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      const CsChatBubble(type: CsChatBubbleType.incoming, ariaLabel: 'Assistant at 3:42pm', child: Text('Hi')),
    );
    expect(find.bySemanticsLabel('Assistant at 3:42pm'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('long messages wrap at 390px with 2x text', (tester) async {
    await pumpCs(
      tester,
      const CsChatBubble(
        type: CsChatBubbleType.incoming,
        ariaLabel: 'AI',
        avatar: _ai,
        child: Text('Instance i-0abc123 in us-east-1 is running with 4 vCPUs, and its root volume is 80 percent full.'),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
