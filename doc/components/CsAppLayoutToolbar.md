# CsAppLayoutToolbar

Cloudscape's `AppLayoutToolbar`: the app layout with a 42px toolbar row holding the navigation trigger, breadcrumbs and the tools and drawer triggers. Same API as `CsAppLayout`.

Cloudscape reference: https://cloudscape.design/components/app-layout-toolbar/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsAppLayoutToolbar(
  navigation: const Text('Side navigation'),
  breadcrumbs: const Text('Buckets'),
  tools: const CsHelpPanel(header: 'Buckets', child: Text('Help')),
  content: const Text('Bucket list'),
)
```

## When to use / when not to

Use it instead of `CsAppLayout` when the service uses the toolbar layout: all panel triggers live in one row and panels open under it.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `content` | `Widget?` |  | Page content, often a `CsContentLayout` |
| `contentHeader` | `Widget?` |  | Header above the content |
| `navigation` | `Widget?` |  | Side navigation |
| `navigationOpen` | `bool?` |  | Controlled; null lets the layout manage it (from `contentType`, closed on phones) |
| `onNavigationChange` | `ValueChanged<bool>?` |  |  |
| `navigationWidth` | `double` | `280` |  |
| `navigationHide` | `bool` | `false` | Removes navigation and its toggle |
| `tools` | `Widget?` |  | Help content, usually `CsHelpPanel` |
| `toolsOpen` | `bool?` |  | Controlled; null lets the layout manage it |
| `onToolsChange` | `ValueChanged<bool>?` |  |  |
| `toolsWidth` | `double` | `290` |  |
| `toolsHide` | `bool` | `false` |  |
| `breadcrumbs` | `Widget?` |  |  |
| `notifications` | `Widget?` |  | Usually a `CsFlashbar`; announced as a live region |
| `stickyNotifications` | `bool` | `false` | Notifications stay pinned while content scrolls |
| `contentType` | `CsAppLayoutContentType` | `defaultVariant` | `defaultVariant`, `form` (nav closed, 800px), `table`, `cards`, `wizard` (nav closed, 1080px), `dashboard` |
| `maxContentWidth` | `double?` |  | Overrides the content type cap |
| `minContentWidth` | `double` | `280` |  |
| `disableContentPaddings` | `bool` | `false` |  |
| `disableContentHeaderOverlap` | `bool` | `false` |  |
| `headerVariant` | `CsAppLayoutHeaderVariant` | `defaultVariant` | `defaultVariant` or `highContrast` |
| `splitPanel` | `Widget?` |  | Usually a `CsSplitPanel` |
| `splitPanelOpen` | `bool?` |  | Controlled; null lets the layout manage it (starts closed) |
| `onSplitPanelToggle` | `ValueChanged<bool>?` |  |  |
| `splitPanelSize` | `double?` |  | Height (bottom) or width (side) |
| `onSplitPanelResize` | `ValueChanged<double>?` |  |  |
| `splitPanelPosition` | `CsSplitPanelPosition?` |  | `bottom` or `side`; controlled preferences |
| `onSplitPanelPreferencesChange` | `ValueChanged<CsSplitPanelPosition>?` |  |  |
| `drawers` | `List<CsAppLayoutDrawer>` | `[]` | `id`, `content`, `ariaLabels`, `icon`, `iconWidget`, `badge`, `resizable`, `defaultSize`, `onResize` |
| `activeDrawerId` | `String?` |  | Controlled open drawer |
| `onDrawerChange` | `ValueChanged<String?>?` |  | Drawer to open, or null |
| `ariaLabels` | `CsAppLayoutLabels` |  | Region and toggle names |
| `mobile` | `bool?` |  | Forces the phone (true) or wide (false) layout |

## Examples

### Drawers in the toolbar

```dart
CsAppLayoutToolbar(
  drawers: const [
    CsAppLayoutDrawer(
      id: 'notes',
      icon: CsIcons.edit,
      ariaLabels: CsAppLayoutDrawerLabels(drawerName: 'Notes'),
      content: CsDrawer(header: Text('Notes'), child: Text('Rotate keys')),
    ),
  ],
  content: const Text('Bucket list'),
)
```

## Accessibility

Navigation, tools, drawers and notifications are named regions (`ariaLabels`). Toggles are labelled buttons with toggled state. Phone overlays trap focus and close with Escape. Notifications are a live region.

## Motion

Wide-screen navigation opens and closes by animating its width over `motion-duration-complex` (250ms, expressive easing). Phone overlays slide in from their edge over the same duration. Reduced motion makes both instant. Resizing drawers and the split panel follows the pointer 1:1.

## Mobile

The toolbar stays at all widths; at or below 688px panels open as full-screen overlays instead of beside the content.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `content / contentHeader` | same names |
| `navigation / navigationOpen / onNavigationChange / navigationWidth / navigationHide` | same names (`onNavigationChange` gets a bool) |
| `tools / toolsOpen / onToolsChange / toolsWidth / toolsHide` | same names |
| `breadcrumbs / notifications / stickyNotifications` | same names |
| `contentType` | `contentType` (`CsAppLayoutContentType`) |
| `maxContentWidth / minContentWidth` | same names |
| `disableContentPaddings / disableContentHeaderOverlap / headerVariant` | same names |
| `splitPanel / splitPanelOpen / onSplitPanelToggle / splitPanelSize / onSplitPanelResize` | same names |
| `splitPanelPreferences / onSplitPanelPreferencesChange` | `splitPanelPosition` / `onSplitPanelPreferencesChange` |
| `drawers / activeDrawerId / onDrawerChange` | same names (`CsAppLayoutDrawer`) |
| `ariaLabels` | `ariaLabels` (`CsAppLayoutLabels`) |
| `navigationCloseBehavior / navigationCollapsedWidth` | not supported |
| `headerSelector / footerSelector / disableBodyScroll` | not needed (the layout fills its parent) |
| `ref (openTools, focusSplitPanel...)` | drive the controlled props instead |
