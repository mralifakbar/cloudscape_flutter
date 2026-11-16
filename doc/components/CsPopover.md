# CsPopover

Cloudscape's `Popover`: a small panel of extra detail that opens from a trigger on tap, such as the full status of a resource, the definition of a term or a confirmation after copying a value.

Cloudscape reference: https://cloudscape.design/components/popover/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsPopover(
  header: 'Memory error',
  content: const Text('This instance contains insufficient memory. Stop the instance and choose a larger type.'),
  child: const CsStatusIndicator(type: CsStatusType.error, text: 'Error'),
)
```

## When to use / when not to

Use a popover for information the user asks for by tapping something: detail behind a status, a definition, a small summary. For a short label on hover use `CsTooltip`. For a list of actions use `CsButtonDropdown`. For a task with inputs use `CsDialog` or `CsModal`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | The trigger |
| `content` | `Widget?` | | Body, in `color-text-body-secondary` |
| `header` | `String?` | | Heading (heading-xs) |
| `dismissButton` | `bool` | `true` | Close button; also moves focus into the popover and traps Tab |
| `dismissAriaLabel` | `String?` | `'Close popover'` | Accessible name of the close button |
| `position` | `CsPopoverPosition` | `right` | `top`, `right`, `bottom`, `left`; flips when there is no room. `left` and `right` are start and end in RTL |
| `size` | `CsPopoverSize` | `medium` | Maximum width: `small` 210, `medium` 310, `large` 482 (310 below 480px) |
| `fixedWidth` | `bool` | `false` | Always as wide as `size`; needed for content that cannot be measured intrinsically |
| `triggerType` | `CsPopoverTriggerType` | `text` | `text` (dashed line under the trigger), `textInline` (dashed text underline), `custom` (a button) |
| `triggerAriaLabel` | `String?` | | Accessible name of a text trigger |
| `wrapTriggerText` | `bool` | `true` | False keeps a text trigger on one line with an ellipsis |
| `visible` | `bool?` | | Controls the open state; null for uncontrolled |
| `onVisibleChange` | `ValueChanged<bool>?` | | Next open state on every toggle and dismissal |
| `onDismiss` | `VoidCallback?` | | Closed by the close button, Escape, Tab or an outside tap |

`CsPopoverState.dismiss()` (through a `GlobalKey<CsPopoverState>`) closes the popover from code.

## Examples

### Inline text trigger

```dart
Wrap(
  children: [
    const Text('Requests are routed through an '),
    CsPopover(
      triggerType: CsPopoverTriggerType.textInline,
      header: 'Origin',
      size: CsPopoverSize.small,
      content: const Text('The server CloudFront fetches content from, such as example-bucket.'),
      child: const Text('origin'),
    ),
  ],
)
```

### Custom trigger without a close button

```dart
CsPopover(
  triggerType: CsPopoverTriggerType.custom,
  dismissButton: false,
  size: CsPopoverSize.small,
  position: CsPopoverPosition.top,
  content: const CsStatusIndicator(type: CsStatusType.success, text: 'ARN copied'),
  child: CsButton(text: 'Copy ARN', icon: CsIcons.copy, onPress: () {}),
)
```

### Controlled

```dart
CsPopover(
  visible: true,
  onVisibleChange: (open) {},
  header: 'Instance type',
  fixedWidth: true,
  size: CsPopoverSize.large,
  content: const Text('m5.large: 2 vCPU, 8 GiB memory.'),
  child: const Text('m5.large'),
)
```

## Accessibility

Text triggers are buttons with the dashed underline Cloudscape uses, an `expanded` state and an optional `triggerAriaLabel`; Enter and Space open them. With `dismissButton`, focus moves into the popover, Tab cycles inside it and focus returns to the trigger on close. Without it, focus stays on the trigger, Tab closes the popover and its content is announced as a live region. Escape and an outside tap close it either way.

## Motion

The popover scales from 0.9 at the trigger and fades in, and leaves along the same path; the scale is a spring, so reopening mid-close turns around smoothly. Reduced motion keeps only the fade.

## Mobile

At or below 688px, `left` and `right` positions open below the trigger, because a phone rarely has a popover's width beside it. The popover shifts to stay 8px inside the screen, and `large` falls back to 310px below 480px. Text triggers keep a 44px touch target where the platform asks for it.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `child` (the trigger) |
| `content`, `header`, `dismissButton`, `dismissAriaLabel`, `position`, `size`, `fixedWidth`, `triggerAriaLabel`, `wrapTriggerText` | same names |
| `triggerType="text-inline"` | `triggerType: CsPopoverTriggerType.textInline` |
| `ref.dismiss()` | `GlobalKey<CsPopoverState>().currentState!.dismiss()` |
| `ref.focus()` | focus the trigger with your own `FocusNode` |
| `renderWithPortal` | not applicable: popovers always render in the root overlay |
