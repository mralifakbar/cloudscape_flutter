# CsLiveRegion

Cloudscape's `LiveRegion`: announces content to screen readers whenever it changes, without moving focus, for results of filtering, saved states and other updates the user cannot see happen.

Cloudscape reference: https://cloudscape.design/components/live-region/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsLiveRegion(child: Text('12 instances match'))
```

## When to use / when not to

Use a live region for a change that happens away from the user's focus: a result count after filtering, "Saved" after an autosave, the progress of a background task. Do not announce what the user just typed or every keystroke. Components such as `CsFlashbar` and `CsProgressBar` already announce their own changes.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget?` | | Content shown on screen and, without `message`, the source of the announcement |
| `message` | `String?` | | Text to announce; wins over the text of `child` |
| `assertive` | `bool` | `false` | Interrupt the screen reader; only for urgent messages |
| `hidden` | `bool` | `false` | Hide `child` visually and from semantics; still announced |
| `delay` | `Duration` | 1 second | Minimum time between announcements; changes inside it merge. `Duration.zero` announces right after each frame |
| `preventInitialAnnouncement` | `bool` | `false` | Announce only later changes |

Statics: `CsLiveRegion.announce(context, message, {assertive})` sends one announcement; `CsLiveRegion.textOf(context)` reads the text rendered under a context. `CsLiveRegionState.reannounce()` (through a `GlobalKey<CsLiveRegionState>`) repeats the current text.

## Examples

### Result count

```dart
CsLiveRegion(
  child: CsBox(variant: CsBoxVariant.small, text: '3 matches for "prod"'),
)
```

### Announce without showing

```dart
const CsLiveRegion(hidden: true, message: 'Settings saved')
```

### One-off announcement

```dart
CsButton(text: 'Copy ARN', onPress: () => CsLiveRegion.announce(context, 'ARN copied'))
```

## Accessibility

Announcements go through `SemanticsService.sendAnnouncement` for the current view, so they reach VoiceOver and TalkBack. The text of `child` is read the way Cloudscape reads `textContent`: every `Text` and `RichText` below it, in order, with whitespace collapsed. Equal consecutive messages are announced once; call `reannounce` when repeating the same text is meaningful.

## Motion

None.

## Mobile

No layout of its own: `child` lays out as it would without the region.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `child` (or `message`) |
| `assertive`, `hidden` | same names |
| `tagName` | not applicable |
| internal `delay`, `preventInitialAnnouncement`, `reannounce()` | `delay`, `preventInitialAnnouncement`, `CsLiveRegionState.reannounce()` |
