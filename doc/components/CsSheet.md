# CsSheet

A sheet attached to a screen edge that follows the finger, snaps by release velocity and dismisses with a flick, usually opened with `showCsSheet`. Cloudscape components use it on phones in place of anchored menus and panels.

Cloudscape reference: https://cloudscape.design/components/drawer/ (a foundation primitive; Cloudscape's web components have no sheet)

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
Future<void> chooseRegion(BuildContext context) async {
  final region = await showCsSheet<String>(
    context: context,
    semanticLabel: 'Choose a Region',
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in const ['us-east-1', 'eu-west-1', 'ap-southeast-1'])
          CsButton(text: r, variant: CsButtonVariant.link, onPress: () => CsSheetScope.closeFrom(context, r)),
      ],
    ),
  );
}
```

## When to use / when not to

Use a sheet on phones for choices and short tasks that would be a dropdown, popover or side panel on a wide screen. On desktop prefer `CsAnchoredOverlay`-based components, `CsModal` or `CsDrawer`. Components that switch automatically (`CsDropdown` with `CsPresentation.auto`) already use it.

## Parameters

### showCsSheet

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `context` | `BuildContext` | required | |
| `builder` | `WidgetBuilder` | required | Sheet content |
| `edge` | `CsSheetEdge` | `bottom` | `bottom`, `top`, `start`, `end` |
| `snapPoints` | `List<double>?` | | Visible heights as fractions of the screen (bottom and top sheets); null sizes to content |
| `initialSnapPointIndex` | `int?` | smallest | Index into the sorted snap points |
| `dismissible` | `bool` | `true` | Scrim tap, flick, Escape and back close it |
| `showHandle` | `bool` | `true` | Grab handle on bottom sheets |
| `maxExtentFraction` | `double` | `0.85` | Largest share of the screen |
| `semanticLabel` | `String?` | | Name of the sheet's route |
| `useRootNavigator` | `bool` | `true` | |

Returns `Future<T?>` with the value the sheet closed with. Close it from inside with `CsSheetScope.closeFrom(context, result)` or `Navigator.pop`.

### CsSheet

`CsSheet({required CsSheetEdge edge, required Widget child, Widget? header, double maxExtentFraction = 0.75, List<double>? snapPoints, int? initialSnapPointIndex, bool preventDismissGestures = false, VoidCallback? onCloseComplete, VoidCallback? onOpenComplete, String? accessibilityLabel, double borderRadius = 16, bool? reduceMotion})` is the widget `showCsSheet` builds, for hosting a sheet in your own route. `CsSheetHandle` is the grab handle.

## Examples

### Snap points

```dart
Future<void> showLogs(BuildContext context) => showCsSheet<void>(
  context: context,
  snapPoints: const [0.4, 0.9],
  semanticLabel: 'Logs for i-0abc123',
  builder: (context) => ListView(
    children: [for (var i = 0; i < 40; i++) Text('2026-11-16T10:00:${i.toString().padLeft(2, '0')}Z GET /index.html 200')],
  ),
);
```

## Accessibility

The sheet is its own route named by `semanticLabel`; focus is trapped inside it and returns when it closes. Escape and the back gesture close it (unless not dismissible). The handle is a "Close" button for screen readers, and the scrim is a "Close" button too.

## Motion

The sheet springs in from its edge and follows the finger 1:1 while dragged. On release the velocity is projected to pick the nearest snap point or dismiss; past its open position it rubberbands. It can be grabbed mid-animation, and a scroll view inside a bottom sheet hands its overscroll to the sheet. Dismissing runs the entry path backwards. Reduced motion replaces the slide with a fade.

## Mobile

Built for phones: bottom sheets respect the safe area and the keyboard, and `snapPoints` let long content open half-way first.

## Cloudscape React mapping

| Cloudscape concept | Flutter parameter |
| --- | --- |
| mobile dropdowns and panels | `showCsSheet` |
| `onDismiss` | the returned `Future` |
