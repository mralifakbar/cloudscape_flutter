# CsSteps

Shows the progress of a multi-step process, such as a deployment or a series of checks, with a status for each step.

Cloudscape reference: https://cloudscape.design/components/steps/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsSteps(
  ariaLabel: 'Launch progress',
  steps: [
    CsStepsStep(status: CsStatusType.success, header: 'Instance launched'),
    CsStepsStep(status: CsStatusType.loading, header: 'Running health checks', details: '2 of 3 checks complete'),
    CsStepsStep(status: CsStatusType.pending, header: 'Attach to load balancer'),
  ],
)
```

## When to use / when not to

- Use to report the state of steps the system runs (provisioning, a pipeline, a timeline of events).
- Do not use for steps a person fills in; use `CsWizard`.
- Do not use for a single status; use `CsStatusIndicator`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `steps` | `List<CsStepsStep>` | required | The steps in order. |
| `orientation` | `CsStepsOrientation` | `vertical` | `vertical` stacks the steps; `horizontal` lays them out in equal columns. |
| `connectorLines` | `CsStepsConnectorLines` | `visible` | `none` hides the lines between steps. |
| `renderStep` | `CsStepsRenderedStep Function(CsStepsStep)?` | `null` | Builds each step's header, details and icon yourself. |
| `ariaLabel` | `String?` | `null` | Accessible name of the list. |
| `minHorizontalStepWidth` | `double` | `120` | Horizontal steps lay out vertically when a column would be narrower. `0` keeps them horizontal. |

`CsStepsStep`:

| Name | Type | Description |
| --- | --- | --- |
| `status` | `CsStatusType` | Status icon and header color (same set as `CsStatusIndicator`). |
| `header` / `headerWidget` | `String?` / `Widget?` | Summary of the step. One is required. |
| `details` / `detailsWidget` | `String?` / `Widget?` | More information under the header. |
| `annotation` / `annotationWidget` | `String?` / `Widget?` | Content before the icon, such as a timestamp. |
| `statusIconAriaLabel` | `String?` | Spoken name of the icon. Defaults to the status name. |
| `data` | `Object?` | Any value of yours, for `renderStep`. |

## Examples

### Horizontal

```dart
const CsSteps(
  orientation: CsStepsOrientation.horizontal,
  steps: [
    CsStepsStep(status: CsStatusType.success, header: 'Build'),
    CsStepsStep(status: CsStatusType.inProgress, header: 'Test'),
    CsStepsStep(status: CsStatusType.notStarted, header: 'Deploy'),
  ],
)
```

### Timeline with annotations

```dart
const CsSteps(
  steps: [
    CsStepsStep(status: CsStatusType.info, annotation: '09:58', header: 'Change set created'),
    CsStepsStep(status: CsStatusType.warning, annotation: '10:01', header: 'Drift detected', details: '1 resource differs'),
    CsStepsStep(status: CsStatusType.success, annotation: '10:05', header: 'Stack updated'),
  ],
)
```

### Custom steps

```dart
CsSteps(
  steps: const [
    CsStepsStep(status: CsStatusType.success, header: 'example-bucket', data: 'Versioning enabled'),
    CsStepsStep(status: CsStatusType.pending, header: 'example-logs', data: 'Waiting for policy'),
  ],
  renderStep: (step) => CsStepsRenderedStep(
    header: Text(step.header!, style: const TextStyle(fontWeight: FontWeight.w700)),
    details: Text('${step.data}'),
  ),
)
```

## Accessibility

- The list is a container named by `ariaLabel`.
- Each step is one node that reads the status name (or `statusIconAriaLabel`) and then the header and details: "Error, Attach volume".
- Status is never color alone: every status has its own icon.

## Motion

The loading status shows a spinner while the step is loading; nothing else animates.

## Mobile

Vertical steps fit any width and wrap long headers. Horizontal steps switch to vertical when a column would be narrower than `minHorizontalStepWidth` (120px), which happens on phones with four or more steps. Annotations take at most half the width.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `steps` (`status`, `statusIconAriaLabel`, `header`, `details`, `annotation`) | `steps` (`CsStepsStep`, with string and widget forms) |
| `orientation` | `orientation` |
| `connectorLines` | `connectorLines` |
| `renderStep` (`header`, `details`, `icon`) | `renderStep` (`CsStepsRenderedStep`) |
| `ariaLabel` | `ariaLabel` |
| `ariaLabelledby`, `ariaDescribedby` | not applicable; use `ariaLabel` |
