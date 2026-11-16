# CsModal

Cloudscape's `Modal`: a dialog over a dimmed page that collects a decision or a short task (confirm a deletion, edit a setting) before the user goes on, with a header, scrollable content and a footer of actions.

Cloudscape reference: https://cloudscape.design/components/modal/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsModal(
  visible: true,
  onDismiss: (reason) {},
  header: 'Delete instance',
  footerActions: [
    CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () {}),
    CsButton(text: 'Delete', variant: CsButtonVariant.primary, onPress: () {}),
  ],
  child: const Text('Permanently delete i-0abc123? You cannot undo this action.'),
)
```

## When to use / when not to

Use a modal when the user must answer before continuing: a destructive confirmation, a short form that belongs to the current page. Keep it small and focused. For long or multi-step tasks use a full page or `CsWizard`. For extra detail about something on the page use `CsPopover`; for a panel that opens in place without blocking the page use `CsDialog`; for feedback after an action use `CsFlashbar`.

Keep the modal mounted and drive `visible`. Never build it only while open: it could not animate out.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `visible` | `bool` | required | Shows the modal. Changes animate |
| `onDismiss` | `ValueChanged<CsModalDismissReason>?` | | Close button, backdrop tap, Escape or back gesture; set `visible` to false in response |
| `header` | `String?` | | Title (heading-m), also the dialog's accessible name |
| `headerWidget` | `Widget?` | | Rich content in place of `header` |
| `child` | `Widget?` | | Body; scrolls when taller than the window |
| `footer` | `Widget?` | | Footer below a divider; stays visible while the body scrolls |
| `footerActions` | `List<Widget>?` | | Buttons aligned to the end of the footer with an 8px gap; wrap on narrow screens. Ignored when `footer` is set |
| `size` | `CsModalSize` | `medium` | `small` 320, `medium` 600, `large` 820, `xLarge` 1024, `xxLarge` 1280, `max` (window width minus 120) |
| `position` | `CsModalPosition` | `center` | `center`, or `top` for content that changes height |
| `hideDismissButton` | `bool` | `false` | No close button; Escape, backdrop and back still call `onDismiss` |
| `closeAriaLabel` | `String?` | `'Close modal'` | Accessible name of the close button |
| `disableContentPaddings` | `bool` | `false` | Body without padding |
| `width` | `double?` | | Fixed width (at least 320), wins over `size`, capped at the window |
| `height` | `double?` | | Fixed height; the body scrolls inside it |
| `useRootOverlay` | `bool` | `true` | Render above every navigator |

`CsModalDismissReason`: `closeButton`, `overlay`, `keyboard` (Escape and the system back gesture or button).

### showCsModal

`showCsModal<T>({required BuildContext context, required WidgetBuilder builder, String? header, Widget? headerWidget, WidgetBuilder? footerBuilder, CsModalSize size, CsModalPosition position, bool hideDismissButton, bool dismissible = true, String? closeAriaLabel, bool disableContentPaddings, double? width, double? height, bool useRootNavigator = true})` opens the same modal in its own route and completes with the value passed to `Navigator.pop`. The close button always closes it; `dismissible: false` makes the backdrop, Escape and back do nothing.

## Examples

### Delete confirmation with state

```dart
class DeleteInstance extends StatefulWidget {
  const DeleteInstance({super.key});

  @override
  State<DeleteInstance> createState() => _DeleteInstanceState();
}

class _DeleteInstanceState extends State<DeleteInstance> {
  bool _visible = false;

  void _close() => setState(() => _visible = false);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CsButton(text: 'Delete', onPress: () => setState(() => _visible = true)),
        CsModal(
          visible: _visible,
          onDismiss: (_) => _close(),
          header: 'Delete instance',
          footerActions: [
            CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: _close),
            CsButton(text: 'Delete', variant: CsButtonVariant.primary, onPress: _close),
          ],
          child: const Text('Permanently delete i-0abc123? You cannot undo this action.'),
        ),
      ],
    );
  }
}
```

### Awaiting a result

```dart
Future<void> confirm(BuildContext context) async {
  final ok = await showCsModal<bool>(
    context: context,
    header: 'Delete bucket',
    size: CsModalSize.small,
    builder: (context) => const Text('Permanently delete example-bucket?'),
    footerBuilder: (context) => Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      children: [
        CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () => Navigator.of(context).pop(false)),
        CsButton(text: 'Delete', variant: CsButtonVariant.primary, onPress: () => Navigator.of(context).pop(true)),
      ],
    ),
  );
  if (ok == true) {
    // delete the bucket
  }
}
```

### A required choice

```dart
CsModal(
  visible: true,
  hideDismissButton: true,
  position: CsModalPosition.top,
  header: 'Choose a Region',
  onDismiss: (reason) {},
  footerActions: [CsButton(text: 'Continue', variant: CsButtonVariant.primary, onPress: () {})],
  child: const Text('Resources are created in the Region you choose.'),
)
```

## Accessibility

The dialog is its own semantics route named by `header`, and the page behind is hidden from screen readers while it is open. Focus moves to the close button (to the dialog when there is none), Tab and Shift+Tab cycle inside it, and focus returns to the trigger when it closes. Escape and the Android back gesture call `onDismiss` with `keyboard`. The backdrop is announced as a "Close" button.

## Motion

The backdrop fades in and the dialog fades and scales from 0.95 over Cloudscape's 115ms responsive motion (`motion-duration-refresh-only-fast`, `motion-easing-refresh-only-a`). Closing runs the same path backwards, so the modal stays mounted until it has left. Reduced motion keeps only the fade (instant for `CsModal`).

## Mobile

On phones (and any window narrower than the size) the dialog is the full width minus a 12px gutter on each side, Cloudscape's `calc(100vw - 2 * space-s)`. The dialog never grows taller than the window: the body scrolls and the footer stays visible. The on-screen keyboard pushes the dialog up. `size: CsModalSize.max` only adds its 120px margin above 688px.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `visible`, `size`, `position`, `hideDismissButton`, `closeAriaLabel`, `disableContentPaddings`, `width`, `height` | same names |
| `size="x-large"`, `"xx-large"` | `CsModalSize.xLarge`, `CsModalSize.xxLarge` |
| `header` | `header` / `headerWidget` |
| `children` | `child` |
| `footer` | `footer` (or `footerActions`) |
| `onDismiss` (`detail.reason`) | `onDismiss(CsModalDismissReason)` |
| `modalRoot`, `getModalRoot`, `removeModalRoot` | `useRootOverlay` |
| `analyticsMetadata` | not applicable |
