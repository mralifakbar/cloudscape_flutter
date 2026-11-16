# CsDialog

Cloudscape's `Dialog`: a small panel that opens in place, next to the content it is about (a quick rename inside a card, a confirmation in a side panel), without a backdrop and without blocking the rest of the page.

Cloudscape reference: https://cloudscape.design/components/dialog/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsDialog(
  header: 'Rename distribution',
  onDismiss: () {},
  child: const Text('d111111abcdef8'),
)
```

## When to use / when not to

Use a dialog for a short, optional task that belongs to one spot on the page, when the user may still want to look at or use the page around it. When the user must answer before going on, use `CsModal`. For read-only detail on a trigger, use `CsPopover`.

Render the dialog while it should show and remove it in `onDismiss`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `header` | `String?` | | Heading (heading-s) and accessible name. `header` or `headerWidget` is required |
| `headerWidget` | `Widget?` | | Rich content in place of `header` |
| `onDismiss` | `VoidCallback` | required | Close button and Escape |
| `headerActions` | `Widget?` | | Controls in the header row before the close button |
| `child` | `Widget?` | | Content |
| `footer` | `Widget?` | | Footer, usually actions. Hidden when null |
| `i18nStrings` | `CsDialogI18nStrings?` | | `dismissAriaLabel` (default `'Close dialog'`) |
| `autofocus` | `bool` | `true` | Move focus into the dialog when it appears |

## Examples

### Inline edit

```dart
class RenameCard extends StatefulWidget {
  const RenameCard({super.key});

  @override
  State<RenameCard> createState() => _RenameCardState();
}

class _RenameCardState extends State<RenameCard> {
  bool _editing = false;
  String _name = 'storefront-cdn';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CsButton(text: 'Rename', onPress: () => setState(() => _editing = true)),
        if (_editing)
          CsDialog(
            header: 'Rename distribution',
            onDismiss: () => setState(() => _editing = false),
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () => setState(() => _editing = false)),
                const SizedBox(width: 8),
                CsButton(text: 'Save', variant: CsButtonVariant.primary, onPress: () => setState(() => _editing = false)),
              ],
            ),
            child: CsInput(value: _name, onChange: (v) => setState(() => _name = v)),
          ),
      ],
    );
  }
}
```

### Header actions

```dart
CsDialog(
  header: 'Cache behavior',
  onDismiss: () {},
  headerActions: CsButton(variant: CsButtonVariant.icon, icon: CsIcons.settings, semanticLabel: 'Settings', onPress: () {}),
  child: const Text('Requests for /images/* are cached for 24 hours.'),
)
```

## Accessibility

The dialog is a semantics container named by its header. Focus moves into it when it appears and returns to the widget that had focus before when it is removed, if that widget still exists. Escape calls `onDismiss`. Tab is not trapped, because the page stays usable. The close button is announced with `dismissAriaLabel`.

## Motion

The dialog has no motion of its own, as in Cloudscape. Wrap it in your own transition if it should animate where it appears.

## Mobile

The dialog takes the width its parent gives it and wraps its header and content, so it fits a 390px screen at 2x text. Keep footers short or let them wrap.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `header` | `header` / `headerWidget` |
| `headerActions`, `footer`, `onDismiss`, `i18nStrings.dismissAriaLabel` | same names |
| `children` | `child` |
| focus restore on unmount | built in; `autofocus` to opt out of moving focus in |
