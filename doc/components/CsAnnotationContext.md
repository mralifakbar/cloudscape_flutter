# CsAnnotationContext

Runs a tutorial over the app: wrap the page in it so `CsHotspot`s below open the current step's annotation popover and a `CsTutorialPanel` shows progress.

Cloudscape reference: https://cloudscape.design/components/annotation-context/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

class Console extends StatefulWidget {
  const Console({super.key, required this.tutorials, required this.page});

  final List<CsTutorial> tutorials;
  final Widget page;

  @override
  State<Console> createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  CsTutorial? _tutorial;

  @override
  Widget build(BuildContext context) => CsAnnotationContext(
    currentTutorial: _tutorial,
    onStartTutorial: (t) => setState(() => _tutorial = t.copyWith(completed: false)),
    onExitTutorial: (_) => setState(() => _tutorial = null),
    onFinish: () => setState(() => _tutorial = _tutorial!.copyWith(completed: true)),
    child: Row(
      children: [
        Expanded(child: widget.page),
        SizedBox(width: 320, child: CsTutorialPanel(tutorials: widget.tutorials)),
      ],
    ),
  );
}
```

## When to use / when not to

- Use it with `CsHotspot` and `CsTutorialPanel` for hands-on tutorials that guide users through real tasks in the app.
- Keep tutorials short: a few tasks of a few steps each.
- Do not use it for one-off hints (use a popover) or for product announcements.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `currentTutorial` | `CsTutorial?` | required | The running tutorial, or null. |
| `onStartTutorial` | `ValueChanged<CsTutorial>` | required | The user started a tutorial from the panel. Set `currentTutorial`. |
| `onExitTutorial` | `ValueChanged<CsTutorial>` | required | The user left the tutorial. Set `currentTutorial` to null. |
| `child` | `Widget` | required | The page. |
| `onStepChange` | `void Function(int step, CsStepChangeReason reason)?` | `null` | Current step changed: `next`, `previous`, `open` (a marker was pressed) or `autoFallback`. |
| `onFinish` | `VoidCallback?` | `null` | Finish pressed on the last step. Mark the tutorial completed. |
| `i18nStrings` | `CsAnnotationI18nStrings` | English | `nextButtonText`, `previousButtonText`, `finishButtonText`, `labelDismissAnnotation`, `labelHotspot(open, stepIndex, total)`, `stepCounterText(stepIndex, total)`, `taskTitle(taskIndex, title)`. Indexes are 0-based. |
| `pulseHotspots` | `bool` | `true` | The current step's marker pulses a few times when it becomes current. |

Tutorial data:

| Class | Fields |
| --- | --- |
| `CsTutorial` | `title`, `description` (`Widget`), `tasks`, `completedScreenDescription` (`Widget`), `completed` (`false`), `prerequisitesNeeded` (`false`), `prerequisitesAlert` (`Widget?`), `onLearnMore` (`VoidCallback?`); `copyWith(completed:, prerequisitesNeeded:)`, `totalStepCount` |
| `CsTutorialTask` | `title`, `steps` |
| `CsTutorialStep` | `title`, `content` (`Widget`), `hotspotId`, `warningAlert` (`Widget?`) |

`CsAnnotationContext.maybeOf(context)` returns `CsAnnotationContextData` (current tutorial, current step, and the actions hotspots and the panel use). `CsTutorialStepInfo.of(tasks, index)` resolves a global step index to its task and step.

## Examples

### Tutorial data

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

const createBucket = CsTutorial(
  title: 'Create a bucket',
  description: Text('Store objects in a new bucket.'),
  completedScreenDescription: Text('You created a bucket. Upload objects next.'),
  tasks: [
    CsTutorialTask(
      title: 'Name the bucket',
      steps: [
        CsTutorialStep(title: 'Enter a name', content: Text('Type a globally unique name.'), hotspotId: 'bucket-name'),
        CsTutorialStep(
          title: 'Choose a region',
          content: Text('Pick the region closest to your users.'),
          warningAlert: Text('The region cannot change later.'),
          hotspotId: 'bucket-region',
        ),
      ],
    ),
  ],
);
```

## Accessibility

The context itself renders nothing. Its popovers are dialogs named by the task title and step counter; the hotspot markers are buttons with `labelHotspot` labels and an expanded state.

## Motion

None of its own; see `CsHotspot` for the popover and pulse.

## Mobile

Popovers flip and shift to stay on screen, are at most 310px wide, and scroll when the content is taller than the room available.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `currentTutorial` | `currentTutorial` |
| `onStartTutorial` / `onExitTutorial` (`detail.tutorial`) | `onStartTutorial` / `onExitTutorial` (the tutorial) |
| `onStepChange` (`detail.step`, `detail.reason`) | `onStepChange(step, reason)`; `'auto-fallback'` is `CsStepChangeReason.autoFallback` |
| `onFinish` | `onFinish` |
| `i18nStrings` | `i18nStrings` (`CsAnnotationI18nStrings`) |
| `children` | `child` |
| tutorial `learnMoreUrl` | `CsTutorial.onLearnMore` |
