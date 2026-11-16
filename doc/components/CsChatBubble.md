# CsChatBubble

One message in a conversation with a person or a generative AI assistant, paired with an avatar and optional actions.

Cloudscape reference: https://cloudscape.design/components/chat-bubble/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsChatBubble(
  type: CsChatBubbleType.incoming,
  ariaLabel: 'Generative AI assistant at 3:42pm',
  avatar: const CsAvatar(
    color: CsAvatarColor.genAi,
    icon: CsIcons.genAi,
    ariaLabel: 'Generative AI assistant',
  ),
  child: const Text('Bucket example-bucket has versioning enabled.'),
)
```

## When to use / when not to

- Use `incoming` for messages from the assistant or other people (filled) and `outgoing` for the current user's messages (no fill).
- Use `hideAvatar` on consecutive messages from the same author.
- Use `actions` for message actions (copy, thumbs up and down), not for navigation.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `type` | `CsChatBubbleType` | required | `incoming` or `outgoing`. |
| `ariaLabel` | `String` | required | Unique accessible name of the message group, such as "Sample user at 3:42pm". |
| `child` | `Widget` | required | Message content. Text uses body-m on a 22px line. |
| `avatar` | `Widget?` | `null` | Usually a `CsAvatar`. |
| `actions` | `Widget?` | `null` | Footer below the content. |
| `showLoadingBar` | `bool` | `false` | Shows `CsLoadingBar(variant: genAiMasked)` along the bottom edge. |
| `hideAvatar` | `bool` | `false` | Hides the avatar but keeps its space; also removes it from focus and semantics (Cloudscape `inert`). |
| `stretch` | `bool` | `false` | Fills the available width instead of fitting the content. |
| `align` | `CsChatBubbleAlign` | `start` | `end` places the bubble first and the avatar after it, aligned to the end. |

## Examples

### Outgoing message aligned to the end

```dart
const CsChatBubble(
  type: CsChatBubbleType.outgoing,
  align: CsChatBubbleAlign.end,
  ariaLabel: 'Sample user at 3:41pm',
  avatar: CsAvatar(ariaLabel: 'Account', initials: 'SU'),
  child: Text('Is versioning enabled on example-bucket?'),
)
```

### Streaming response with actions

```dart
CsChatBubble(
  type: CsChatBubbleType.incoming,
  ariaLabel: 'Generative AI assistant at 3:42pm',
  showLoadingBar: true,
  avatar: const CsAvatar(
    color: CsAvatarColor.genAi,
    icon: CsIcons.genAi,
    loading: true,
    ariaLabel: 'Generative AI assistant, generating',
  ),
  actions: CsButton(variant: CsButtonVariant.icon, icon: CsIcons.copy, semanticLabel: 'Copy', onPress: () {}),
  child: const Text('Checking the bucket configuration'),
)
```

## Accessibility

The row is a labelled semantics group (`role="group"` with `aria-label`), so each message is announced with its author and time. Children keep their own semantics.

## Motion

Only the optional loading bar and the avatar's loading state animate.

## Mobile

The bubble wraps its text inside the available width, so long messages never overflow at 390px. Use `stretch` when messages contain footers that should line up.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `type` | `type` |
| `children` | `child` |
| `avatar` | `avatar` |
| `actions` | `actions` |
| `showLoadingBar` | `showLoadingBar` |
| `ariaLabel` | `ariaLabel` |
| `hideAvatar` | `hideAvatar` |
| `stretch` | `stretch` |
| `align` | `align` |
| `style` | not supported; theme with color overrides |
