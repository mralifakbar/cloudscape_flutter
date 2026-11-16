# CsTabs

Cloudscape's `Tabs`: switches between panels of related content.

Cloudscape reference: https://cloudscape.design/components/tabs/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsTabs(
  tabs: const [
    CsTab(id: 'details', label: 'Details', content: Text('Instance details')),
    CsTab(id: 'monitoring', label: 'Monitoring', content: Text('Metrics')),
  ],
)
```

## When to use / when not to

Use tabs for peer views of the same resource. Do not use them for steps (use `CsWizard`) or for navigation between pages (use `CsSideNavigation`).

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `tabs` | `List<CsTab>` |  | `id`, `label`, `labelWidget`, `content`, `disabled`, `disabledReason`, `dismissible`, `dismissLabel`, `dismissDisabled`, `onDismiss`, `action` |
| `activeTabId` | `String?` |  | Controlled active tab; null lets the tabs manage it |
| `onChange` | `ValueChanged<String>?` |  | Id of the selected tab |
| `variant` | `CsTabsVariant` | `defaultVariant` | `defaultVariant`, `container`, `stacked` |
| `actions` | `Widget?` |  | Controls at the end of the tab row |
| `disableContentPaddings` | `bool` | `false` |  |
| `fitHeight` | `bool` | `false` | Fill the parent height; the panel scrolls |
| `keyboardActivationMode` | `CsTabsKeyboardActivation` | `automatic` | `automatic` or `manual` |
| `i18nStrings` | `CsTabsI18nStrings` |  | Scroll button labels |
| `semanticLabel` | `String?` |  | Name of the tab list |
| `swipeable` | `bool` | `false` | Swipe the content to change tabs |
| `stackPosition` | `CsStackPosition` | `only` | For the `stacked` variant |

## Examples

### Controlled with a disabled and a dismissible tab

```dart
CsTabs(
  activeTabId: 'details',
  onChange: (id) {},
  tabs: [
    const CsTab(id: 'details', label: 'Details', content: Text('i-0abc123')),
    const CsTab(id: 'security', label: 'Security', disabled: true, disabledReason: 'No permission.'),
    CsTab(id: 'logs', label: 'Logs', dismissible: true, onDismiss: () {}, content: const Text('Log')),
  ],
)
```

### Container

```dart
const CsTabs(
  variant: CsTabsVariant.container,
  tabs: [CsTab(id: 'a', label: 'Origins', content: Text('example-bucket'))],
)
```

## Accessibility

Tabs expose `selected` and mutually exclusive semantics and use roving focus: Tab enters the active tab, Left/Right (mirrored in RTL), Home and End move between tabs, and in automatic mode select them. Disabled tabs with a reason stay focusable and show the reason in a tooltip.

## Motion

The 4px active indicator slides between tabs over `motion-duration-expressive`; the tab row scrolls a tab into view with the same timing. Reduced motion jumps.

## Mobile

The tab row scrolls horizontally and shows start and end arrow buttons when it overflows. Labels stay on one line. `swipeable` adds horizontal swipes on the content.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `tabs` | `tabs: [CsTab(...)]` |
| `activeTabId / onChange` | `activeTabId` / `onChange` (String) |
| `variant` | `variant` |
| `actions` | `actions` |
| `disableContentPaddings` | `disableContentPaddings` |
| `fitHeight` | `fitHeight` |
| `keyboardActivationMode` | `keyboardActivationMode` |
| `i18nStrings` | `i18nStrings` |
| `ariaLabel` | `semanticLabel` |
| `tab.href` | not supported (use `onChange`) |
| `contentRenderStrategy` | active only |
| `style` | not supported |
