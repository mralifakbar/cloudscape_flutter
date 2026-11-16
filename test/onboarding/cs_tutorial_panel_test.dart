import 'package:cloudscape_flutter/src/onboarding/onboarding.dart';
import 'package:cloudscape_flutter/src/status/status.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';
import 'onboarding_fixture.dart';

void main() {
  testWidgets('lists tutorials in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(tester, const OnboardingHarness(), brightness: b, density: d, center: false);
        expect(tester.takeException(), isNull);
        expect(find.text('Choose a tutorial'), findsOneWidget);
        expect(find.text('Create a bucket'), findsOneWidget);
        expect(find.text('Enable logging'), findsOneWidget);
      }
    }
  });

  testWidgets('tutorials with prerequisites start collapsed and disabled', (tester) async {
    await pumpCs(tester, const OnboardingHarness(), center: false);
    // The bucket tutorial is expanded with a start button; logging is collapsed.
    expect(find.text('Store objects in a new bucket.'), findsOneWidget);
    expect(find.text('Deliver access logs to logs-bucket.'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Enable logging').last);
    await tester.pumpAndSettle();
    expect(find.text('Create a bucket first.'), findsOneWidget);
    expect(find.text('Start tutorial'), findsNWidgets(2));
  });

  testWidgets('start shows the task list, dismiss returns to the list', (tester) async {
    final events = <String>[];
    await pumpCs(tester, OnboardingHarness(events: events), center: false);
    await tester.ensureVisible(find.text('Start tutorial').first);
    await tester.tap(find.text('Start tutorial').first);
    await tester.pumpAndSettle();
    expect(events, ['start:Create a bucket']);
    expect(find.text('Task 1: Name the bucket'), findsWidgets);
    expect(find.text('Task 2: Create it'), findsOneWidget);
    expect(find.text('Total steps: 2'), findsOneWidget);
    expect(find.text('Step 1: Enter a name'), findsOneWidget);
    // The current task is in progress and expanded; the next one is pending and collapsed.
    final statuses = tester.widgetList<CsStatusIndicator>(find.byType(CsStatusIndicator)).map((s) => s.type).toList();
    expect(statuses, containsAllInOrder([CsStatusType.inProgress, CsStatusType.pending]));
    expect(find.text('Step 1: Create'), findsNothing);
    await tester.tap(find.text('Total steps: 1'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1: Create'), findsOneWidget);
    await tester.ensureVisible(find.text('Dismiss tutorial'));
    await tester.tap(find.text('Dismiss tutorial'));
    await tester.pumpAndSettle();
    expect(events.last, 'exit:Create a bucket');
    expect(find.text('Choose a tutorial'), findsOneWidget);
  });

  testWidgets('progress marks finished tasks and finishing shows the completion screen', (tester) async {
    await pumpCs(tester, const OnboardingHarness(initial: bucketTutorial), center: false);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    final statuses = tester.widgetList<CsStatusIndicator>(find.byType(CsStatusIndicator)).map((s) => s.type).toList();
    expect(statuses, containsAllInOrder([CsStatusType.success, CsStatusType.inProgress]));
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.text('Congratulations! You completed the tutorial.'), findsOneWidget);
    expect(find.text('You created example-bucket.'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Dismiss tutorial'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a tutorial'), findsOneWidget);
  });

  testWidgets('completed tutorials show the status and a restart button', (tester) async {
    await pumpCs(
      tester,
      CsAnnotationContext(
        currentTutorial: null,
        onStartTutorial: (_) {},
        onExitTutorial: (_) {},
        child: CsTutorialPanel(tutorials: [bucketTutorial.copyWith(completed: true)]),
      ),
    );
    expect(find.text('Tutorial completed'), findsOneWidget);
    expect(find.text('Restart tutorial'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Create a bucket').last);
    await tester.pumpAndSettle();
    expect(find.text('Restart tutorial'), findsOneWidget);
  });

  testWidgets('loading, download and learn more', (tester) async {
    var downloads = 0;
    var learn = 0;
    await pumpCs(
      tester,
      CsTutorialPanel(tutorials: const [], loading: true, onDownload: () => downloads++),
      settle: false,
    );
    expect(find.text('Loading'), findsOneWidget);
    await tester.tap(find.text('Download PDF version'));
    expect(downloads, 1);
    await pumpCs(
      tester,
      CsTutorialPanel(
        tutorials: [
          CsTutorial(
            title: 'Tour',
            description: const Text('A tour.'),
            completedScreenDescription: const Text('Done.'),
            tasks: const [],
            onLearnMore: () => learn++,
          ),
        ],
        i18nStrings: const CsTutorialPanelI18nStrings(tutorialListDescription: 'Walkthroughs of common tasks.'),
      ),
    );
    expect(find.text('Walkthroughs of common tasks.'), findsOneWidget);
    await tester.tap(find.textContaining('Learn more', findRichText: true));
    expect(learn, 1);
  });

  testWidgets('feedback link on the completion screen', (tester) async {
    CsTutorial? feedback;
    await pumpCs(
      tester,
      CsAnnotationContext(
        currentTutorial: bucketTutorial.copyWith(completed: true),
        onStartTutorial: (_) {},
        onExitTutorial: (_) {},
        child: CsTutorialPanel(tutorials: const [bucketTutorial], onFeedbackClick: (t) => feedback = t),
      ),
    );
    await tester.tap(find.text('Feedback'));
    expect(feedback!.title, 'Create a bucket');
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, const OnboardingHarness(), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
    await pumpCs(tester, const OnboardingHarness(initial: bucketTutorial), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
  });
}
