# CsSupportPromptGroup

Suggested prompts a user can send to a generative AI assistant with one tap.

Cloudscape reference: https://cloudscape.design/components/support-prompt-group/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsSupportPromptGroup(
  ariaLabel: 'Suggested prompts',
  items: const [
    CsSupportPrompt(id: 'cost', text: 'Why did my bill go up this month?'),
    CsSupportPrompt(id: 'scale', text: 'How do I scale instance i-0abc123?'),
  ],
  onItemClick: (id) {},
)
```

## When to use / when not to

- Use at the start of a conversation or after a response, to suggest next questions.
- Keep prompts short and specific. Use 2 to 4 at a time.
- Do not use them for actions that change resources; use buttons.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<CsSupportPrompt>` | required | The prompts. An empty list renders nothing. |
| `onItemClick` | `ValueChanged<String>` | required | Called with the chosen prompt's `id`. |
| `ariaLabel` | `String` | required | Accessible name of the group. |
| `alignment` | `CsSupportPromptAlignment` | `vertical` | `vertical` stacks the prompts; `horizontal` flows them in wrapping rows. |

`CsSupportPrompt` fields: `id` (`String`, required), `text` (`String`, required), `textWidget` (`Widget?`, rich content instead of `text`), `icon` (`CsIconData?`), `iconWidget` (`Widget?`), `iconPosition` (`CsSupportPromptIconPosition.left` or `right`, default `left`), `iconVerticalAlignment` (`start`, `center` or `end`, default `start`), `ariaLabel` (`String?`).

Reach the state with a `GlobalKey<CsSupportPromptGroupState>` and call `focus(id)` to move focus to a prompt (Cloudscape `ref.focus`).

## Examples

### Horizontal with icons

```dart
CsSupportPromptGroup(
  ariaLabel: 'Suggested prompts',
  alignment: CsSupportPromptAlignment.horizontal,
  items: const [
    CsSupportPrompt(id: 'logs', text: 'Summarize error logs', icon: CsIcons.genAi),
    CsSupportPrompt(
      id: 'alarms',
      text: 'Explain this alarm',
      icon: CsIcons.external,
      iconPosition: CsSupportPromptIconPosition.right,
    ),
  ],
  onItemClick: (id) {},
)
```

## Accessibility

- The group is a single Tab stop. Arrow keys move between prompts and wrap around (left and right swap in RTL); Home and End (and Page Up and Page Down) jump to the first and last; Enter or Space sends the focused prompt. Tab leaves the group and Shift+Tab returns to the last focused prompt.
- Each prompt is a button; the group carries `ariaLabel`.

## Motion

Prompts get the standard press feedback; hover colors switch instantly.

## Mobile

Prompts wrap their text and, in `horizontal`, flow to new rows, so nothing overflows at 390px. The hit area of each prompt is at least 44px tall on touch screens.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items` | `items` (`CsSupportPrompt`) |
| `items[].iconName` | `icon` |
| `items[].iconSvg` | `iconWidget` |
| `onItemClick` | `onItemClick` (the `id`; modifier keys are not passed) |
| `ariaLabel` | `ariaLabel` |
| `alignment` | `alignment` |
| `ref.focus(id)` | `GlobalKey<CsSupportPromptGroupState>().currentState!.focus(id)` |
