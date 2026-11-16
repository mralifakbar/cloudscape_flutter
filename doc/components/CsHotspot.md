# CsHotspot

A marked place in the app that a tutorial step points to; while a tutorial runs it shows a marker that opens the step's annotation popover.

Cloudscape reference: https://cloudscape.design/components/hotspot/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

Widget createButton(VoidCallback create) => CsHotspot(
  hotspotId: 'create-bucket-button',
  child: CsButton(text: 'Create bucket', variant: CsButtonVariant.primary, onPress: create),
);
```

## When to use / when not to

- Wrap each control or field a tutorial step refers to. A hotspot outside a running tutorial (or one the tutorial does not use) renders only its child, so it can stay in the code.
- Without a child, the marker sits inline, for example in a checkbox label.
- Hotspot IDs are unique in the whole app; several tutorials can reuse one.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `hotspotId` | `String` | required | ID that `CsTutorialStep.hotspotId` refers to. |
| `child` | `Widget?` | `null` | The marked element. Without it the marker is inline with `space-xxs` on both sides. |
| `side` | `CsHotspotSide` | `right` | Side of the child the marker sits on (`left`, `right`). |
| `direction` | `CsSide` | `CsSide.top` | Side the annotation popover opens on; it flips when there is no room. |

## Examples

### Inline marker in a label

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

Widget versioning() => const Row(
  children: [
    Text('Enable versioning'),
    CsHotspot(hotspotId: 'versioning', direction: CsSide.bottom),
  ],
);
```

## Accessibility

The marker is a button named by `labelHotspot` ("Annotation for step 1 of 3") with an expanded state, and a 24px hit area (44px on touch screens). The popover takes focus when nothing else has it; Escape and its close button dismiss it, and focus returns to the marker. Previous and Next are disabled when their step's hotspot is not on screen.

## Motion

The popover scales and fades from the marker and follows it while scrolling; opening a step scrolls its hotspot into view. While a tutorial runs, the current step's marker pulses three times (an expanding ring over 2s each) when it becomes current, then rests. Reduced motion turns the pulse and the scroll animation off.

## Mobile

The popover is at most 310px wide, stays inside the screen, and scrolls when its content is taller than the room available. Step buttons wrap under the step counter on narrow screens.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `hotspotId` | `hotspotId` |
| `side` (`'left'`, `'right'`) | `side` (`CsHotspotSide`) |
| `direction` (`'top'`, `'right'`, `'bottom'`, `'left'`) | `direction` (`CsSide`) |
| `children` | `child` |
