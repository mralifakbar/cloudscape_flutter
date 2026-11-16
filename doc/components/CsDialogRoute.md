# CsDialogRoute

A navigator route that draws the Cloudscape backdrop (`CsScrim`) and runs dialog motion around a custom widget; Escape, a backdrop tap and the back gesture pop it.

Cloudscape reference: https://cloudscape.design/components/modal/ (a foundation primitive; use `CsModal` for Cloudscape's modal)

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
Future<void> openPanel(BuildContext context) => Navigator.of(context).push(
  CsDialogRoute<void>(
    semanticLabel: 'Keyboard shortcuts',
    builder: (context) => const Center(child: CsContainer(child: Text('Press / to search'))),
  ),
);
```

## When to use / when not to

Use it for a custom blocking overlay that `CsModal` does not cover (a command palette, a full-screen image). For Cloudscape's modal use `CsModal` or `showCsModal`, which add the header, footer, sizes and dismiss reasons.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `builder` | `WidgetBuilder` | required | Route content, laid out over the whole screen |
| `transition` | `CsDialogTransition` | `scale` | `scale` (fade plus scale from 0.9) or `slideUp` (fade plus a 40px rise, for full-screen pages on phones) |
| `dismissible` | `bool` | `true` | A backdrop tap pops the route |
| `closeOnEscape` | `bool` | `true` | |
| `restoreFocusOnUnmount` | `bool` | `true` | Return focus to the widget focused before |
| `showScrim` | `bool` | `true` | Draw the backdrop |
| `semanticLabel` | `String?` | | Name of the route for screen readers |
| `settings` | `RouteSettings?` | | |

## Examples

### Full-screen page on phones

```dart
Future<void> openImage(BuildContext context) => Navigator.of(context).push(
  CsDialogRoute<void>(
    transition: CsDialogTransition.slideUp,
    semanticLabel: 'Architecture diagram',
    builder: (context) => const SafeArea(child: Placeholder()),
  ),
);
```

## Accessibility

The content is wrapped in a `CsFocusTrap` and a semantics scope that names the route; the scrim is a "Close" button when `dismissible`.

## Motion

Fade plus scale from 0.9 (or a 40px rise) over 115ms with Cloudscape's responsive easing; the backdrop fades with it. Reduced motion shortens the transition and drops the scale and slide.

## Mobile

The builder gets the whole screen; add `SafeArea` and your own padding.

## Cloudscape React mapping

| Cloudscape concept | Flutter parameter |
| --- | --- |
| modal overlay | `showScrim` |
| `onDismiss` reason `overlay` / `keyboard` | `dismissible`, `closeOnEscape` |
