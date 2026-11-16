# Accessibility

- **Semantics.** Every control exposes its role, label and state (button, link, checked, toggled, selected, expanded, slider value, text field). Icon-only buttons require a `semanticLabel` (an assert enforces it for `CsButton`).
- **Keyboard.** Tab order follows visual order. Enter and Space activate. Arrow keys move within groups (radio groups, tabs, segmented controls, menus, option lists, calendars, tree views). Escape closes popovers, dropdowns, sheets and modals. Modals trap focus and return it to the trigger on close.
- **Focus ring.** Keyboard focus shows Cloudscape's 2px `color-border-item-focused` ring, drawn outside the control so layout never shifts. Fields show their focused border and a 1px ring.
- **Disabled with a reason.** Buttons and menu items with `disabledReason` stay focusable and explain themselves in a tooltip.
- **Contrast.** Cloudscape's text tokens pass WCAG AA on the surfaces Cloudscape puts them on. Check custom pairs with `CsColorUtils.contrastRatio`.
- **Status is never color alone.** Status indicators, flash messages, alerts and form errors carry an icon and text.
- **Announcements.** Flash messages, form errors, table selection and "Copied" confirmations are live regions; `CsLiveRegion` announces anything else.
- **Text scale** up to 2x, RTL layouts (directional icons mirror), and disabled or reduced motion are supported and tested.
- **Headings.** `CsHeader` and heading `CsBox` variants are marked as headings for screen reader navigation.
