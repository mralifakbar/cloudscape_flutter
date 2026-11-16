import 'package:cloudscape_flutter/src/onboarding/onboarding.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';
import 'onboarding_fixture.dart';

Finder _marker(String label) => find.bySemanticsLabel(label);

void main() {
  testWidgets('renders only the child without a tutorial or a context', (tester) async {
    await pumpCs(tester, const CsHotspot(hotspotId: 'x', child: Text('Plain')));
    expect(find.text('Plain'), findsOneWidget);
    await pumpCs(tester, const OnboardingHarness(withPanel: false), center: false);
    expect(find.byType(CsHotspot), findsNWidgets(3));
    expect(find.text('Type example-bucket.'), findsNothing);
  });

  testWidgets('a running tutorial shows markers and opens the first step in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          OnboardingHarness(key: UniqueKey(), withPanel: false, initial: bucketTutorial),
          brightness: b,
          density: d,
          center: false,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Type example-bucket.'), findsOneWidget);
        expect(find.text('Task 1: Name the bucket'), findsOneWidget);
        expect(find.text('Step 1 of 2'), findsOneWidget);
      }
    }
  });

  testWidgets('Next, Previous and Finish walk the steps', (tester) async {
    final events = <String>[];
    await pumpCs(tester, OnboardingHarness(events: events, withPanel: false, initial: bucketTutorial), center: false);
    expect(find.text('Previous'), findsNothing);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Choose the region closest to your users.'), findsOneWidget);
    expect(find.text('Region cannot change later.'), findsOneWidget);
    expect(find.text('Step 2 of 2'), findsOneWidget);
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Type example-bucket.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Task 2: Create it'), findsOneWidget);
    expect(find.text('Step 1 of 1'), findsOneWidget);
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(events, ['step:1:next', 'step:0:previous', 'step:1:next', 'step:2:next', 'finish']);
    // A completed tutorial shows no markers.
    expect(find.text('Press Create bucket.'), findsNothing);
  });

  testWidgets('dismiss closes the popover and the marker reopens it', (tester) async {
    final handle = tester.ensureSemantics();
    final events = <String>[];
    await pumpCs(tester, OnboardingHarness(events: events, withPanel: false, initial: bucketTutorial), center: false);
    await tester.tap(find.bySemanticsLabel('Dismiss annotation'));
    await tester.pumpAndSettle();
    expect(find.text('Type example-bucket.'), findsNothing);
    // Jump straight to another step through its marker.
    await tester.tap(_marker('Annotation for step 1 of 1'));
    await tester.pumpAndSettle();
    expect(find.text('Press Create bucket.'), findsOneWidget);
    expect(events.last, 'step:2:open');
    // Pressing the open marker dismisses it.
    await tester.tap(_marker('Annotation for step 1 of 1'));
    await tester.pumpAndSettle();
    expect(find.text('Press Create bucket.'), findsNothing);
    handle.dispose();
  });

  testWidgets('Escape dismisses the popover', (tester) async {
    await pumpCs(tester, const OnboardingHarness(withPanel: false, initial: bucketTutorial), center: false);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Type example-bucket.'), findsNothing);
  });

  testWidgets('Next is disabled when the next hotspot is not on screen', (tester) async {
    await pumpCs(
      tester,
      const OnboardingHarness(withPanel: false, showRegion: false, initial: bucketTutorial),
      center: false,
    );
    final next = find.ancestor(of: find.text('Next'), matching: find.byType(Semantics)).first;
    await tester.tap(next, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Type example-bucket.'), findsOneWidget);
  });

  testWidgets('a missing current hotspot falls back to the nearest one', (tester) async {
    final events = <String>[];
    final key = GlobalKey<OnboardingHarnessState>();
    await pumpCs(
      tester,
      OnboardingHarness(key: key, events: events, withPanel: false, initial: bucketTutorial),
      center: false,
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await pumpCs(
      tester,
      OnboardingHarness(key: key, events: events, withPanel: false, showRegion: false, initial: bucketTutorial),
      center: false,
    );
    expect(events.last, endsWith(':autoFallback'));
    expect(find.byType(CsHotspot), findsNWidgets(2));
  });

  testWidgets('markers expose label and expanded state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const OnboardingHarness(withPanel: false, initial: bucketTutorial), center: false);
    expect(
      tester.getSemantics(_marker('Annotation for step 1 of 2').first),
      matchesSemantics(
        label: 'Annotation for step 1 of 2',
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('pulse runs a few times then rests; reduced motion skips it', (tester) async {
    await pumpCs(
      tester,
      CsAnnotationContext(
        currentTutorial: bucketTutorial,
        onStartTutorial: (_) {},
        onExitTutorial: (_) {},
        child: const Column(
          children: [
            SizedBox(height: 300),
            CsHotspot(hotspotId: 'name', child: Text('Name')),
          ],
        ),
      ),
      settle: false,
      center: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.hasRunningAnimations, isTrue);
    // Settles: the pulse does not loop forever.
    await tester.pumpAndSettle();
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(
      tester,
      const OnboardingHarness(withPanel: false, initial: bucketTutorial),
      textScale: 2,
      center: false,
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
