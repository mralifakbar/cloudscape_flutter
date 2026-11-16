import 'package:cloudscape_flutter/src/onboarding/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';
import 'onboarding_fixture.dart';

void main() {
  test('step info resolves global indexes across tasks', () {
    final tasks = bucketTutorial.tasks;
    expect(bucketTutorial.totalStepCount, 3);
    final first = CsTutorialStepInfo.of(tasks, 0);
    expect(first.step!.hotspotId, 'name');
    expect(first.taskIndex, 0);
    final third = CsTutorialStepInfo.of(tasks, 2);
    expect(third.step!.hotspotId, 'create');
    expect(third.taskIndex, 1);
    expect(third.localIndex, 0);
    expect(CsTutorialStepInfo.of(tasks, 3).step, isNull);
    expect(CsTutorialStepInfo.of(tasks, -1).step, isNull);
  });

  test('default strings match Cloudscape', () {
    const s = CsAnnotationI18nStrings();
    expect(s.nextButtonText, 'Next');
    expect(s.previousButtonText, 'Previous');
    expect(s.finishButtonText, 'Finish');
    expect(s.labelDismissAnnotation, 'Dismiss annotation');
    expect(s.labelHotspot(false, 0, 3), 'Annotation for step 1 of 3');
    expect(s.stepCounterText(1, 3), 'Step 2 of 3');
    expect(s.taskTitle(0, 'Name the bucket'), 'Task 1: Name the bucket');
  });

  testWidgets('maybeOf is null outside and shares the tutorial inside', (tester) async {
    CsAnnotationContextData? outside;
    CsAnnotationContextData? inside;
    await pumpCs(
      tester,
      Column(
        children: [
          Builder(builder: (c) => Text('${outside = CsAnnotationContext.maybeOf(c)}')),
          CsAnnotationContext(
            currentTutorial: bucketTutorial,
            onStartTutorial: (_) {},
            onExitTutorial: (_) {},
            child: Builder(builder: (c) => Text('${inside = CsAnnotationContext.maybeOf(c)}')),
          ),
        ],
      ),
    );
    expect(outside, isNull);
    expect(inside!.currentTutorial, same(bucketTutorial));
    expect(inside!.currentStepIndex, 0);
    expect(inside!.slotFor('unused'), isNull);
    expect(inside!.slotFor('region')!.open, isFalse);
  });

  testWidgets('custom strings reach the popover', (tester) async {
    await pumpCs(
      tester,
      CsAnnotationContext(
        currentTutorial: bucketTutorial,
        pulseHotspots: false,
        onStartTutorial: (_) {},
        onExitTutorial: (_) {},
        i18nStrings: CsAnnotationI18nStrings(
          nextButtonText: 'Weiter',
          stepCounterText: (i, n) => 'Schritt ${i + 1} von $n',
        ),
        child: const Column(
          children: [
            SizedBox(height: 300),
            CsHotspot(hotspotId: 'name', child: Text('Name')),
            CsHotspot(hotspotId: 'region', child: Text('Region')),
          ],
        ),
      ),
      center: false,
    );
    expect(find.text('Weiter'), findsOneWidget);
    expect(find.text('Schritt 1 von 2'), findsOneWidget);
  });

  testWidgets('a new tutorial starts at its first step, open', (tester) async {
    final key = GlobalKey<OnboardingHarnessState>();
    await pumpCs(tester, OnboardingHarness(key: key, withPanel: false, initial: bucketTutorial), center: false);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Choose the region closest to your users.'), findsOneWidget);
    key.currentState!.setTutorial(null);
    await tester.pumpAndSettle();
    expect(find.text('Choose the region closest to your users.'), findsNothing);
    key.currentState!.setTutorial(bucketTutorial);
    await tester.pumpAndSettle();
    expect(find.text('Type example-bucket.'), findsOneWidget);
  });
}
