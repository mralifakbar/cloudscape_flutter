# CsWizard

A multi-page form that walks people through a complex task, such as launching an instance, one step at a time.

Cloudscape reference: https://cloudscape.design/components/wizard/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsWizard(
  submitButtonText: 'Launch instance',
  onCancel: () {},
  onSubmit: () {},
  steps: const [
    CsWizardStep(title: 'Choose an image', content: Text('Image settings')),
    CsWizardStep(title: 'Configure storage', isOptional: true, content: Text('Storage settings')),
    CsWizardStep(title: 'Review and launch', content: Text('Summary')),
  ],
)
```

## When to use / when not to

- Use for long or complex creation flows that are easier to finish in sections, with a review step at the end.
- Do not use for short forms that fit one page (use a form in a `CsContainer`), or to show progress of a system process (use `CsSteps`).
- Put each step's form in containers (`CsContainer` with `CsFormField`s), like a regular form page.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `steps` | `List<CsWizardStep>` | required | The steps. |
| `activeStepIndex` | `int?` | `null` | The current step, from 0. Null makes the wizard track the step itself. |
| `onNavigate` | `ValueChanged<CsWizardNavigateDetail>?` | `null` | `requestedStepIndex` and `reason` (`next`, `previous`, `step`, `skip`). Update `activeStepIndex` here when controlled. |
| `onCancel` | `VoidCallback?` | `null` | Cancel button. Confirm with a modal if the person entered data. |
| `onSubmit` | `VoidCallback?` | `null` | The last step's primary button. |
| `isLoadingNextStep` | `bool` | `false` | Spins the primary button and locks navigation, for server-side validation. |
| `allowSkipTo` | `bool` | `false` | Shows "Skip to" over optional steps ahead and makes them reachable from the list. |
| `submitButtonText` | `String?` | `i18nStrings.submitButton` | Text of the last step's primary button. |
| `secondaryActions` | `Widget?` | `null` | Start-aligned actions, such as "Save draft". |
| `customPrimaryActions` | `Widget?` | `null` | Replaces Cancel, Skip to, Previous and Next or Submit. |
| `i18nStrings` | `CsWizardI18nStrings` | English | `stepNumberLabel(n)`, `collapsedStepsLabel(n, count)`, `skipToButtonLabel(step, n)`, `navigationAriaLabel`, `errorIconAriaLabel`, `cancelButton`, `previousButton`, `nextButton`, `submitButton`, `optional`, `nextButtonLoadingAnnouncement`, `submitButtonLoadingAnnouncement`. |

`CsWizardStep`: `title`, `content`, `info` (an info link), `description` / `descriptionWidget`, `errorText` / `errorWidget` (a page-level error alert), `isOptional`.

`CsWizardStepStatus.of(...)` exposes how the step list decides which steps are reachable.

## Examples

### Controlled with server-side validation

```dart
class LaunchWizard extends StatefulWidget {
  const LaunchWizard({super.key});

  @override
  State<LaunchWizard> createState() => _LaunchWizardState();
}

class _LaunchWizardState extends State<LaunchWizard> {
  int step = 0;
  bool validating = false;
  String? error;

  Future<void> _navigate(CsWizardNavigateDetail detail) async {
    if (detail.reason == CsWizardNavigationReason.next) {
      setState(() => validating = true);
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => validating = false);
    }
    setState(() {
      error = null;
      step = detail.requestedStepIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CsWizard(
      activeStepIndex: step,
      isLoadingNextStep: validating,
      allowSkipTo: true,
      onNavigate: _navigate,
      onCancel: () {},
      onSubmit: () {},
      submitButtonText: 'Launch instance',
      steps: [
        CsWizardStep(title: 'Choose an image', errorText: error, content: const Text('Image settings')),
        const CsWizardStep(title: 'Add tags', isOptional: true, content: Text('Tags')),
        const CsWizardStep(title: 'Review and launch', content: Text('Summary')),
      ],
    );
  }
}
```

## Accessibility

- The step list is a labeled container ("Steps"). Each step is a button named "Step 2: Configure storage"; optional steps add "optional" as a hint. The active step is marked selected; unreachable steps are disabled and leave the Tab order.
- On every step change focus moves to the new heading and the title is announced.
- The error alert is a live region with an error icon named by `errorIconAriaLabel`.
- The loading primary button announces `nextButtonLoadingAnnouncement` or `submitButtonLoadingAnnouncement`.

## Motion

On phones the step list expands and collapses with Cloudscape's expandable motion and its caret turns 90 degrees. Reduced motion makes both instant.

## Mobile

Below 688px of width the step list collapses into a "Step 1 of 4" toggle above the heading, as Cloudscape's small-container layout; the actions wrap onto several lines when needed.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `steps` (`title`, `info`, `description`, `content`, `errorText`, `isOptional`) | `steps` (`CsWizardStep`) |
| `activeStepIndex` | `activeStepIndex` |
| `onNavigate` (`requestedStepIndex`, `reason`) | `onNavigate` (`CsWizardNavigateDetail`) |
| `onCancel`, `onSubmit` | `onCancel`, `onSubmit` |
| `isLoadingNextStep` | `isLoadingNextStep` |
| `allowSkipTo` | `allowSkipTo` |
| `submitButtonText` | `submitButtonText` |
| `secondaryActions`, `customPrimaryActions` | same names |
| `i18nStrings` | `i18nStrings` |
| `analyticsMetadata`, step `analyticsMetadata` | not applicable |
