import 'dart:ui';

import 'package:cloudscape_flutter/src/navigation/navigation.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _steps = [
  CsWizardStep(title: 'Choose an image', description: 'Pick the operating system.', content: Text('Image form')),
  CsWizardStep(title: 'Configure storage', isOptional: true, content: Text('Storage form')),
  CsWizardStep(title: 'Add tags', isOptional: true, content: Text('Tags form')),
  CsWizardStep(title: 'Review and launch', content: Text('Review')),
];

Widget _scroll(Widget child) => SingleChildScrollView(padding: const EdgeInsets.all(16), child: child);

class _Controlled extends StatefulWidget {
  const _Controlled({required this.log, this.allowSkipTo = false});

  final List<CsWizardNavigateDetail> log;
  final bool allowSkipTo;

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  int step = 0;

  @override
  Widget build(BuildContext context) => _scroll(
    CsWizard(
      steps: _steps,
      activeStepIndex: step,
      allowSkipTo: widget.allowSkipTo,
      submitButtonText: 'Launch instance',
      onNavigate: (d) {
        widget.log.add(d);
        setState(() => step = d.requestedStepIndex);
      },
    ),
  );
}

void main() {
  test('step status follows Cloudscape', () {
    CsWizardStepStatus status(int index, {int active = 0, int farthest = 0, bool skip = false, bool loading = false}) =>
        CsWizardStepStatus.of(
          index: index,
          activeStepIndex: active,
          farthestStepIndex: farthest,
          isLoadingNextStep: loading,
          allowSkipTo: skip,
          steps: _steps,
        );
    expect(status(0), CsWizardStepStatus.active);
    expect(status(1), CsWizardStepStatus.unvisited);
    expect(status(1, skip: true), CsWizardStepStatus.next);
    expect(status(3, skip: true), CsWizardStepStatus.next);
    expect(status(3), CsWizardStepStatus.unvisited);
    expect(status(3, active: 1, skip: true), CsWizardStepStatus.next);
    expect(status(0, active: 2, farthest: 2), CsWizardStepStatus.visited);
    expect(status(0, active: 2, farthest: 2, loading: true), CsWizardStepStatus.unvisited);
  });

  testWidgets('renders wide and narrow in light, dark and compact', (tester) async {
    for (final size in [csDesktopSize, csPhoneSize]) {
      for (final b in Brightness.values) {
        for (final d in CsDensity.values) {
          await pumpCs(
            tester,
            _scroll(const CsWizard(steps: _steps)),
            brightness: b,
            density: d,
            size: size,
            center: false,
          );
          expect(find.text('Image form'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('uncontrolled: next, previous, step list and submit', (tester) async {
    final log = <CsWizardNavigateDetail>[];
    var submitted = 0;
    await pumpCs(
      tester,
      _scroll(CsWizard(steps: _steps, onNavigate: log.add, onSubmit: () => submitted++)),
      size: csDesktopSize,
      center: false,
    );
    expect(find.text('Previous'), findsNothing);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Storage form'), findsOneWidget);
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Image form'), findsOneWidget);
    // The visited step is reachable from the list.
    await tester.tap(find.text('Configure storage'));
    await tester.pumpAndSettle();
    expect(find.text('Storage form'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Submit'), findsOneWidget);
    await tester.tap(find.text('Submit'));
    expect(submitted, 1);
    expect(log.map((d) => d.reason), [
      CsWizardNavigationReason.next,
      CsWizardNavigationReason.previous,
      CsWizardNavigationReason.step,
      CsWizardNavigationReason.next,
      CsWizardNavigationReason.next,
    ]);
  });

  testWidgets('unvisited steps are not reachable; cancel fires', (tester) async {
    final log = <CsWizardNavigateDetail>[];
    var cancelled = 0;
    await pumpCs(
      tester,
      _scroll(CsWizard(steps: _steps, onNavigate: log.add, onCancel: () => cancelled++)),
      size: csDesktopSize,
      center: false,
    );
    await tester.tap(find.text('Review and launch'), warnIfMissed: false);
    await tester.tap(find.text('Cancel'));
    expect(log, isEmpty);
    expect(cancelled, 1);
  });

  testWidgets('controlled with skip-to over optional steps', (tester) async {
    final log = <CsWizardNavigateDetail>[];
    await pumpCs(tester, _Controlled(log: log, allowSkipTo: true), size: csDesktopSize, center: false);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Skip to Review and launch'), findsOneWidget);
    await tester.tap(find.text('Skip to Review and launch'));
    await tester.pumpAndSettle();
    expect(find.text('Launch instance'), findsOneWidget);
    expect(log.last.reason, CsWizardNavigationReason.skip);
    expect(log.last.requestedStepIndex, 3);
  });

  testWidgets('optional label, description, info and error text', (tester) async {
    await pumpCs(
      tester,
      _scroll(
        const CsWizard(
          activeStepIndex: 1,
          steps: [
            CsWizardStep(title: 'One', content: SizedBox()),
            CsWizardStep(
              title: 'Configure storage',
              isOptional: true,
              info: Text('Info'),
              description: 'Volumes attached at launch.',
              errorText: 'The volume size exceeds your quota.',
              content: SizedBox(),
            ),
          ],
        ),
      ),
      size: csDesktopSize,
      center: false,
    );
    expect(find.textContaining('- optional', findRichText: true), findsWidgets);
    expect(find.text('Volumes attached at launch.'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
    expect(find.text('The volume size exceeds your quota.'), findsOneWidget);
  });

  testWidgets('loading next step locks navigation', (tester) async {
    final log = <CsWizardNavigateDetail>[];
    await pumpCs(
      tester,
      _scroll(CsWizard(steps: _steps, activeStepIndex: 1, isLoadingNextStep: true, onNavigate: log.add)),
      size: csDesktopSize,
      center: false,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Previous'), warnIfMissed: false);
    await tester.tap(find.text('Choose an image'), warnIfMissed: false);
    expect(log, isEmpty);
  });

  testWidgets('phone: collapsed "Step 1 of 4" expands the step list', (tester) async {
    await pumpCs(tester, _scroll(const CsWizard(steps: _steps)), center: false);
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('Step 2 - optional', findRichText: true), findsNothing);
    await tester.tap(find.text('Step 1 of 4'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Step 2', findRichText: true), findsWidgets);
    expect(find.text('Configure storage'), findsOneWidget);
  });

  testWidgets('semantics: active step selected, unvisited disabled', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, _scroll(const CsWizard(steps: _steps)), size: csDesktopSize, center: false);
    final active = tester.getSemantics(find.bySemanticsLabel('Step 1: Choose an image'));
    expect(active.flagsCollection.isSelected == Tristate.isTrue, isTrue);
    final unvisited = tester.getSemantics(find.bySemanticsLabel('Step 4: Review and launch'));
    expect(unvisited.flagsCollection.isEnabled == Tristate.isTrue, isFalse);
    handle.dispose();
  });

  testWidgets('custom strings and actions', (tester) async {
    await pumpCs(
      tester,
      _scroll(
        CsWizard(
          steps: _steps,
          secondaryActions: const Text('Save draft'),
          i18nStrings: CsWizardI18nStrings(nextButton: 'Continue', stepNumberLabel: (n) => 'Part $n'),
        ),
      ),
      size: csDesktopSize,
      center: false,
    );
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Save draft'), findsOneWidget);
    expect(find.text('Part 1'), findsOneWidget);
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    await pumpCs(tester, _scroll(const CsWizard(steps: _steps, allowSkipTo: true)), textScale: 2, center: false);
    await tester.tap(find.text('Step 1 of 4'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
