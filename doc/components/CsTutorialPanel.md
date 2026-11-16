# CsTutorialPanel

Lists the available tutorials and, while one runs, its tasks, steps and progress; place it in the help or tools panel under a `CsAnnotationContext`.

Cloudscape reference: https://cloudscape.design/components/tutorial-panel/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

Widget panel(List<CsTutorial> tutorials) => CsTutorialPanel(
  tutorials: tutorials,
  i18nStrings: const CsTutorialPanelI18nStrings(
    tutorialListDescription: 'Walkthroughs of common tasks in this console.',
  ),
);
```

## When to use / when not to

- Use it as the entry point to hands-on tutorials, in the tools panel or a drawer.
- It reads the running tutorial and current step from the nearest `CsAnnotationContext`; without one it only lists tutorials.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `tutorials` | `List<CsTutorial>` | required | All tutorials. |
| `loading` | `bool` | `false` | Shows a spinner with `loadingText` instead of the list. |
| `onDownload` | `VoidCallback?` | `null` | Shows the "Download PDF version" link. |
| `onFeedbackClick` | `ValueChanged<CsTutorial>?` | `null` | Shows a "Feedback" link on the completion screen. |
| `i18nStrings` | `CsTutorialPanelI18nStrings` | English | All copy (see below). |

`CsTutorialPanelI18nStrings` fields (defaults from Cloudscape): `loadingText`, `tutorialListTitle` ("Choose a tutorial"), `tutorialListDescription` (empty hides it), `tutorialListDownloadLinkText`, `labelTutorialListDownloadLink`, `tutorialCompletedText`, `learnMoreLinkText`, `labelLearnMoreLink`, `labelLearnMoreExternalIcon`, `startTutorialButtonText`, `restartTutorialButtonText`, `completionScreenTitle`, `feedbackLinkText`, `dismissTutorialButtonText`, `labelExitTutorial`, `taskTitle(taskIndex, title)`, `stepTitle(stepIndex, title)`, `labelTotalSteps(count)`, `labelTaskStatusPending`, `labelTaskStatusInProgress`, `labelTaskStatusSuccess`.

## Examples

### Loading

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';

const loadingPanel = CsTutorialPanel(tutorials: [], loading: true);
```

## Accessibility

Each tutorial is a group with an h3 title and an expand button that reports its state. In the detail view, each task has a status icon labeled "Success", "In progress" or "Pending" and an expandable step list labeled with the task title and step count. The back arrow is labeled `labelExitTutorial`. The completion screen is a live region, so finishing is announced.

## Motion

Tutorial details and step lists expand and collapse from the top over 180ms (`motion-duration-show-paced`); the step list caret rotates. Reduced motion switches instantly.

## Mobile

Everything stacks in one column and wraps; titles and buttons wrap at 2x text. Use it inside a scrolling panel or sheet.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `tutorials` | `tutorials` |
| `loading` | `loading` |
| `downloadUrl` | `onDownload` |
| `onFeedbackClick` (`detail.tutorial`) | `onFeedbackClick` (the tutorial) |
| `i18nStrings` | `i18nStrings` (`CsTutorialPanelI18nStrings`); `labelsTaskStatus` is split into three fields |
