# Motion

Motion answers touch. Feedback on press, springs that start from where things are, sheets that follow the finger. Nothing loops forever.

## Cloudscape's motion tokens

Fixed transitions use the motion tokens of Cloudscape's visual refresh theme:

| Token | Value | Use |
| --- | --- | --- |
| `CsDurations.responsive` + `CsCurves.responsive` | 115ms, `cubic-bezier(0, 0, 0, 1)` | Tooltips, popovers, small state changes |
| `CsDurations.expressive` + `CsCurves.expressive` | 165ms, `cubic-bezier(0.84, 0, 0.16, 1)` | Check marks, toggles, indicators |
| `CsDurations.complex` | 250ms | Panels, theme cross-fade |
| `CsDurations.showPaced` + `CsCurves.showPaced` | 180ms, ease-out | Expandable sections |
| `CsDurations.moderate` + `CsCurves.easeOutQuart` | 135ms | Caret rotation |

Wrap durations in `CsMotion.duration(context, d)` so disabled motion collapses them.

## Press feedback

Every tappable surface is a `CsPressable`. Its state changes on pointer-down: the surface scales to 0.98 with a spring, and hover and active colors switch instantly (hover colors are never animated).

## Springs

Anything a finger touches moves on a spring that starts from the current value and carries velocity, so it can be grabbed and reversed mid-flight.

| Spring | Damping | Response | Use |
| --- | --- | --- | --- |
| `CsSprings.standard` | 1.0 | 0.35s | Things that move on their own |
| `CsSprings.press` | 1.0 | 0.2s | Press down and release |
| `CsSprings.popup` | 1.0 | 0.2s | Popovers and dropdowns scaling from their trigger |
| `CsSprings.sheet` | 0.86 | 0.32s | Sheets, drawers and panels settling after a drag |
| `CsSprings.momentum` | 0.8 | 0.35s | Only after a flick that carried momentum |

## Gestures

Drags follow the finger 1:1. On release the velocity goes into the spring, `CsMotion.project(velocity)` predicts where the gesture was heading, and `CsMotion.rubberband` resists past the bounds. Sheets, split panels, sliders and toggles work this way.

## Loops

A repeating animation runs only while a real state is true (a spinner or loading bar while loading, hotspots while a tutorial runs) and stops when hidden.

## Disabled and reduced motion

`CsMotion.reduceMotion(context)` is true when the platform asks for reduced motion or the theme has `disableMotion` (Cloudscape's `disableMotion`). Slides, scales and springs become instant changes. The spinner keeps turning, as in Cloudscape, so loading never looks stuck.
