# CsAppLayout

Cloudscape's `AppLayout`: the frame of a console page with navigation, breadcrumbs, notifications, content, a split panel and the tools panel or drawers.

Cloudscape reference: https://cloudscape.design/components/app-layout/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsAppLayout(
  navigation: const Text('Side navigation'),
  breadcrumbs: const Text('Instances'),
  tools: const CsHelpPanel(header: 'Instances', child: Text('Help')),
  content: const CsContentLayout(
    header: CsHeader(variant: CsHeaderVariant.h1, title: 'Instances'),
    child: Text('Instances table'),
  ),
)
```

## When to use / when not to

Use it once, as the root of every console page. Give it a bounded size (it fills its parent). Use `CsAppLayoutToolbar` for the toolbar variant with triggers in a top row.

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

### Controlled panels and drawers

```dart
CsAppLayout(
  navigation: const Text('Side navigation'),
  navigationOpen: true,
  onNavigationChange: (open) {},
  drawers: const [
    CsAppLayoutDrawer(
      id: 'security',
      icon: CsIcons.security,
      badge: true,
      resizable: true,
      ariaLabels: CsAppLayoutDrawerLabels(drawerName: 'Security findings'),
      content: CsDrawer(header: Text('Security findings'), child: Text('2 findings')),
    ),
  ],
  activeDrawerId: 'security',
  onDrawerChange: (id) {},
  content: const Text('Instances table'),
)
```

### Split panel

```dart
CsAppLayout(
  splitPanel: const CsSplitPanel(header: 'i-0abc123', child: Text('Details')),
  splitPanelOpen: true,
  onSplitPanelToggle: (open) {},
  splitPanelPosition: CsSplitPanelPosition.side,
  onSplitPanelPreferencesChange: (position) {},
  content: const Text('Instances table'),
)
```

## Accessibility

Navigation, tools, drawers and notifications are named regions (`ariaLabels`). Toggles are labelled buttons with toggled state. Phone overlays trap focus and close with Escape. Notifications are a live region.

## Motion

Wide-screen navigation opens and closes by animating its width over `motion-duration-complex` (250ms, expressive easing). Phone overlays slide in from their edge over the same duration. Reduced motion makes both instant. Resizing drawers and the split panel follows the pointer 1:1.

## Mobile

At or below 688px of the layout's own width (so it also works inside a narrower frame), or with `mobile: true`, a 40px bar along the top holds the navigation toggle, breadcrumbs and the tools and drawer triggers. Navigation, tools, drawers and an open split panel open as full-screen overlays. Moving to the phone layout closes an uncontrolled navigation.

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
