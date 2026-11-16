# CsAlert

Cloudscape's `Alert`: a short, important message in the context of a page or form, such as a warning before a destructive action or a constraint the user should know about.

Cloudscape reference: https://cloudscape.design/components/alert/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsAlert(
  type: CsAlertType.warning,
  header: 'Instance is running',
  content: 'Stop i-0abc123 before you change its instance type.',
)
```

## When to use / when not to

Use an alert for a message tied to the content around it that stays until the situation changes. For feedback on an action the user just took (created, deleted, failed) use `CsFlashbar` at the top of the page. For field validation use the `errorText` of `CsFormField`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `type` | `CsAlertType` | `info` | `success`, `error`, `warning`, `info` |
| `header` | `String?` | | Bold heading |
| `headerWidget` | `Widget?` | | Rich content in place of `header` |
| `content` | `String?` | | Message text |
| `child` | `Widget?` | | Rich message in place of `content` |
| `action` | `Widget?` | | An action next to the message (a button) |
| `buttonText` | `String?` | | Shows a normal button as the action; ignored when `action` is set |
| `onButtonPress` | `VoidCallback?` | | Pressed `buttonText` button |
| `dismissible` | `bool` | `false` | Shows a close button |
| `onDismiss` | `VoidCallback?` | | Close button pressed |
| `dismissAriaLabel` | `String?` | `'Dismiss alert'` | Close button name (i18nStrings wins) |
| `statusIconAriaLabel` | `String?` | type name | Status icon name (i18nStrings wins) |
| `visible` | `bool` | `true` | Hidden alerts take no space |
| `i18nStrings` | `CsAlertI18nStrings?` | | `successIconAriaLabel`, `errorIconAriaLabel`, `warningIconAriaLabel`, `infoIconAriaLabel`, `dismissAriaLabel` |
| `focusNode` | `FocusNode?` | | Lets the page move focus to the message (Cloudscape `ref.focus()`) |

## Examples

### Every type

```dart
Column(
  children: [
    for (final t in CsAlertType.values)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CsAlert(type: t, content: 'Sample ${t.name} message about example-bucket.'),
      ),
  ],
)
```

### Action and dismiss

```dart
CsAlert(
  type: CsAlertType.error,
  header: 'Could not delete bucket',
  content: 'example-bucket is not empty.',
  action: CsButton(text: 'Empty bucket', onPress: () {}),
  dismissible: true,
  onDismiss: () {},
)
```

## Accessibility

The status icon carries the type name ("Warning") so status is never color alone. The message is a semantics group; the header is marked as a heading. Alerts are not announced on their own, as in Cloudscape: move focus to them with `focusNode` after a failed submit, or wrap them in a `CsLiveRegion`. The close button has an accessible name.

## Motion

The alert fades in over Cloudscape's 180ms `motion-duration-show-paced` whenever it becomes visible; reduced motion shows it at once.

## Mobile

The action sits beside the message while the message keeps at least 70% of the width and moves below it otherwise (indented under the text), as Cloudscape's flex-wrap does. At 390px with a button action it wraps. Text wraps; nothing has a fixed height.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `type`, `action`, `buttonText`, `dismissible`, `onDismiss`, `dismissAriaLabel`, `statusIconAriaLabel`, `visible`, `i18nStrings` | same names |
| `header` | `header` / `headerWidget` |
| `children` | `content` / `child` |
| `onButtonClick` | `onButtonPress` |
| `ref.focus()` | `focusNode` |
| `persistenceConfig`, `analyticsMetadata`, `style` | not applicable |
