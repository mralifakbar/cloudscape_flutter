import 'package:cloudscape_flutter/src/onboarding/onboarding.dart';
import 'package:flutter/material.dart';

const CsTutorial bucketTutorial = CsTutorial(
  title: 'Create a bucket',
  description: Text('Store objects in a new bucket.'),
  completedScreenDescription: Text('You created example-bucket.'),
  tasks: [
    CsTutorialTask(
      title: 'Name the bucket',
      steps: [
        CsTutorialStep(title: 'Enter a name', content: Text('Type example-bucket.'), hotspotId: 'name'),
        CsTutorialStep(
          title: 'Pick a region',
          content: Text('Choose the region closest to your users.'),
          warningAlert: Text('Region cannot change later.'),
          hotspotId: 'region',
        ),
      ],
    ),
    CsTutorialTask(
      title: 'Create it',
      steps: [CsTutorialStep(title: 'Create', content: Text('Press Create bucket.'), hotspotId: 'create')],
    ),
  ],
);

const CsTutorial lockedTutorial = CsTutorial(
  title: 'Enable logging',
  description: Text('Deliver access logs to logs-bucket.'),
  completedScreenDescription: Text('Logging is on.'),
  prerequisitesNeeded: true,
  prerequisitesAlert: Text('Create a bucket first.'),
  tasks: [
    CsTutorialTask(
      title: 'Logging',
      steps: [CsTutorialStep(title: 'Turn on', content: Text('Turn logging on.'), hotspotId: 'logging')],
    ),
  ],
);

/// A small app: annotation context, three hotspots and the tutorial panel.
class OnboardingHarness extends StatefulWidget {
  const OnboardingHarness({super.key, this.showRegion = true, this.events, this.withPanel = true, this.initial});

  final bool showRegion;
  final bool withPanel;
  final List<String>? events;
  final CsTutorial? initial;

  @override
  State<OnboardingHarness> createState() => OnboardingHarnessState();
}

class OnboardingHarnessState extends State<OnboardingHarness> {
  late CsTutorial? tutorial = widget.initial;

  void setTutorial(CsTutorial? t) => setState(() => tutorial = t);

  @override
  Widget build(BuildContext context) {
    return CsAnnotationContext(
      currentTutorial: tutorial,
      pulseHotspots: false,
      onStartTutorial: (t) {
        widget.events?.add('start:${t.title}');
        setState(() => tutorial = t.copyWith(completed: false));
      },
      onExitTutorial: (t) {
        widget.events?.add('exit:${t.title}');
        setState(() => tutorial = null);
      },
      onStepChange: (step, reason) => widget.events?.add('step:$step:${reason.name}'),
      onFinish: () {
        widget.events?.add('finish');
        setState(() => tutorial = tutorial!.copyWith(completed: true));
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 260),
              const CsHotspot(hotspotId: 'name', child: Text('Bucket name')),
              if (widget.showRegion)
                const CsHotspot(hotspotId: 'region', side: CsHotspotSide.left, child: Text('Region')),
              const Row(
                children: [
                  Text('Create'),
                  CsHotspot(hotspotId: 'create'),
                ],
              ),
              if (widget.withPanel) const CsTutorialPanel(tutorials: [bucketTutorial, lockedTutorial]),
            ],
          ),
        ),
      ),
    );
  }
}
