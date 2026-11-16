# CsFlashbar

Cloudscape's `Flashbar`: page-level messages about the result of an action (an instance launched, a deletion failed) or an ongoing process, shown at the top of the page, optionally collapsed into a stack with a notification bar.

Cloudscape reference: https://cloudscape.design/components/flashbar/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsFlashbar(
  items: [
    CsFlashbarItem(
      id: 'deleted',
      type: CsFlashbarType.success,
      content: 'Bucket example-bucket deleted.',
      dismissible: true,
      onDismiss: () {},
    ),
  ],
)
```

## When to use / when not to

Use a flashbar for feedback on something the user did or started: success, failure, a long operation in progress. Remove success messages when the user dismisses them or navigates. For messages tied to a part of the page that stay while a condition holds, use `CsAlert`. For field validation use `CsFormField`'s `errorText`.

## Parameters

### CsFlashbar

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<CsFlashbarItem>` | required | Messages, newest first |
| `stackItems` | `bool` | `false` | Collapse two or more messages into a stack with a notification bar |
| `i18nStrings` | `CsFlashbarI18nStrings` | English | `ariaLabel` (`'Notifications'`), `notificationBarAriaLabel` (`'All notifications'`), `notificationBarText` (`'Notifications'`), and `errorIconAriaLabel`, `warningIconAriaLabel`, `successIconAriaLabel`, `infoIconAriaLabel`, `inProgressIconAriaLabel` (default to `CsStrings`) |

### CsFlashbarItem

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `id` | `String?` | | Identifies the message so the right one animates out. Always set it |
| `type` | `CsFlashbarType` | `info` | `success`, `error`, `warning`, `info`, `inProgress` |
| `header` / `headerWidget` | `String?` / `Widget?` | | Bold heading |
| `content` / `contentWidget` | `String?` / `Widget?` | | Message; `contentWidget` takes a `CsProgressBar(variant: CsProgressBarVariant.flash)` |
| `loading` | `bool` | `false` | Spinner instead of the icon, info colors, counted as in progress |
| `dismissible` | `bool` | `false` | Close button |
| `dismissLabel` | `String?` | `'Dismiss'` | Close button name |
| `onDismiss` | `VoidCallback?` | | Close button pressed; remove the item in response |
| `statusIconAriaLabel` | `String?` | type name | Status icon name |
| `ariaRole` | `CsFlashbarAriaRole?` | | `alert` announces assertively, `status` (and null) politely |
| `action` | `Widget?` | | An action button |
| `buttonText` / `onButtonPress` | `String?` / `VoidCallback?` | | A normal button as the action; ignored when `action` is set |

`CsFlash(item: ...)` renders a single message on its own.

## Examples

### Message types

```dart
CsFlashbar(
  items: const [
    CsFlashbarItem(id: '1', type: CsFlashbarType.success, header: 'Instance launched', content: 'i-0abc123 is starting.'),
    CsFlashbarItem(id: '2', type: CsFlashbarType.error, header: 'Launch failed', content: 'You reached the instance limit.'),
    CsFlashbarItem(id: '3', type: CsFlashbarType.warning, content: 'The certificate expires in 7 days.'),
    CsFlashbarItem(id: '4', type: CsFlashbarType.info, content: 'Maintenance is scheduled for Sunday.'),
    CsFlashbarItem(id: '5', loading: true, content: 'Creating distribution d111111abcdef8'),
  ],
)
```

### Progress inside a flash

```dart
CsFlashbar(
  items: [
    CsFlashbarItem(
      id: 'snapshot',
      type: CsFlashbarType.inProgress,
      contentWidget: const CsProgressBar(
        variant: CsProgressBarVariant.flash,
        label: 'Creating snapshot of vol-0abc123',
        value: 42,
      ),
      buttonText: 'View snapshot',
      onButtonPress: () {},
    ),
  ],
)
```

### Stacked

```dart
CsFlashbar(
  stackItems: true,
  items: [
    CsFlashbarItem(id: 'a', type: CsFlashbarType.error, content: 'Could not delete example-bucket.', dismissible: true, onDismiss: () {}),
    CsFlashbarItem(id: 'b', type: CsFlashbarType.success, content: 'Instance i-0abc123 stopped.', dismissible: true, onDismiss: () {}),
    CsFlashbarItem(id: 'c', type: CsFlashbarType.info, content: 'A new console version is available.', dismissible: true, onDismiss: () {}),
  ],
)
```

## Accessibility

The flashbar is a semantics group named `ariaLabel`. Each message is a group with its status icon name ("Error"), so status is never color alone. Messages added after the first render are announced with their full text (assertively for `ariaRole: alert`). The notification bar is a button named `notificationBarAriaLabel`, exposes its expanded state, and carries the counts per type as its value; count changes are announced. Collapsed messages behind the top one are hidden from screen readers until the stack expands.

## Motion

- New messages fade in while sliding 20px down over Cloudscape's 250ms complex motion with the expressive easing.
- Removed messages fade out while sliding 20px up over 115ms, then their space closes.
- In a stack, every message moves between its stacked and listed position over 115ms (responsive) when the notification bar expands or collapses, the stack's colored edges widen into full messages, and the chevron turns 180 degrees.
- Reduced motion makes all of it instant.

## Mobile

Text wraps and nothing has a fixed height. The action moves below the message when the message would keep less than 70% of the width, indented under the text, as Cloudscape's flex-wrap does at phone widths. The notification bar's content wraps and stays centered with a 30px margin on each side.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items`, `stackItems`, `i18nStrings` | same names |
| item `header`, `content` | `header` / `headerWidget`, `content` / `contentWidget` |
| item `type="in-progress"` | `type: CsFlashbarType.inProgress` |
| item `ariaRole` | `ariaRole: CsFlashbarAriaRole.alert` / `.status` |
| item `onButtonClick` | `onButtonPress` |
| item `id`, `loading`, `dismissible`, `dismissLabel`, `statusIconAriaLabel`, `action`, `buttonText`, `onDismiss` | same names |
| item `persistenceConfig`, `analyticsMetadata`, `style` | not applicable |
