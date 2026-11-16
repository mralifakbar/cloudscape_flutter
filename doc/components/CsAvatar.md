# CsAvatar

A round picture of a person or a generative AI assistant in a chat, with initials, an icon, an image or a loading state.

Cloudscape reference: https://cloudscape.design/components/avatar/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsAvatar(
  color: CsAvatarColor.genAi,
  icon: CsIcons.genAi,
  ariaLabel: 'Generative AI assistant',
  tooltipText: 'Generative AI assistant',
)
```

## When to use / when not to

- Use next to a `CsChatBubble` to show who wrote a message.
- Use `CsAvatarColor.genAi` (the gen-AI gradient) only for AI assistants, and `defaultColor` for people.
- Set `loading` on the assistant's avatar while it generates a response, together with the bubble's `showLoadingBar`.
- Do not use it as a profile menu trigger in the top navigation; that is a button.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `ariaLabel` | `String` | required | Accessible name, such as "Avatar of the sample user". Include `tooltipText` in it when both are set. |
| `color` | `CsAvatarColor` | `defaultColor` | `defaultColor` (`color-background-avatar-default`) or `genAi` (the `colorBackgroundAvatarGenAi` radial gradient). |
| `tooltipText` | `String?` | `null` | Tooltip shown on hover, keyboard focus and touch. |
| `initials` | `String?` | `null` | One or two characters; later characters are ignored. Takes precedence over the icon. |
| `loading` | `bool` | `false` | Shows three bouncing dots. The dots (and, for gen-AI, the rotating gradient) animate only while true. Takes precedence over everything else. |
| `icon` | `CsIconData?` | `CsIcons.userProfile` | Icon when there are no initials. Use `CsIcons.genAi` for assistants. |
| `iconWidget` | `Widget?` | `null` | Custom icon (Cloudscape `iconSvg`). Takes precedence over `icon`. |
| `image` | `ImageProvider?` | `null` | Picture cropped to the circle (Cloudscape `imgUrl`). Takes precedence over initials and icon. |
| `width` | `double` | `28` | Width and height. Values below 28 are raised to 28. |
| `focusNode` | `FocusNode?` | `null` | Focus node of the avatar, which is focusable so keyboard users reach the tooltip. |

## Examples

### Person with initials and a tooltip

```dart
const CsAvatar(ariaLabel: 'Avatar of the sample user', initials: 'SU', tooltipText: 'Account')
```

### Assistant generating a response

```dart
const CsAvatar(
  color: CsAvatarColor.genAi,
  icon: CsIcons.genAi,
  loading: true,
  ariaLabel: 'Generative AI assistant, generating a response',
)
```

### Larger avatar

```dart
const CsAvatar(ariaLabel: 'Avatar of the sample user', initials: 'SU', width: 48)
```

## Accessibility

- Exposed as one image node with `ariaLabel`; its content is hidden from screen readers.
- Focusable with Tab (Cloudscape `tabIndex=0`) and shows the 2px focus ring 4px outside the circle. Focus opens the tooltip.

## Motion

- Loading dots: each dot jumps by its own height at 28% of a 1.2s loop (`motion-duration-avatar-loading-dots`), staggered by 100ms.
- Gen-AI loading: the gradient rotates once per 3.6s and grows to 150% halfway (`motion-duration-avatar-gen-ai-gradient`, `motion-easing-avatar-gen-ai-gradient`); reversed in RTL.
- Nothing animates when `loading` is false. Under reduced motion the dots and gradient are still.

## Mobile

The avatar keeps its size on phones. A touch shows the tooltip while the finger is down.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `color` | `color` (`'gen-ai'` is `CsAvatarColor.genAi`) |
| `tooltipText` | `tooltipText` |
| `initials` | `initials` |
| `loading` | `loading` |
| `ariaLabel` | `ariaLabel` |
| `iconName` | `icon` |
| `iconSvg` | `iconWidget` |
| `iconUrl`, `imgUrl` | `image` (any `ImageProvider`) |
| `width` | `width` |
| `style` | not supported; theme with color overrides |
