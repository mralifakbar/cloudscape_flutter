# Mobile

Cloudscape is designed for wide consoles. cloudscape_flutter keeps Cloudscape's look and switches to Cloudscape's own mobile behavior at its mobile breakpoint, 688px (`context.csIsNarrow`).

- **Hit areas.** On touch platforms every control's hit area is at least 44x44 (`CsTapTargetSize.padded`) while the visual keeps Cloudscape's 32px height.
- **App layout.** Navigation, tools and drawers open as full-screen overlays from the app layout's toolbar; the split panel docks at the bottom.
- **Dropdowns become sheets.** Selects, multiselects, autosuggest, button dropdowns and date pickers open in a bottom sheet that follows the finger. Components take `presentation: CsPresentation.auto | popover | sheet`.
- **Modals** take the full width minus gutters; long content scrolls between a sticky header and footer.
- **Tables** scroll horizontally with a sticky first column, or render rows as cards.
- **Breadcrumbs, top navigation and tabs** collapse their overflow into menus and scrollable rows.
- **Forms.** Form fields stretch to the full width; secondary controls move under the control.
- **Text scale.** Components use minimum heights, never fixed heights around text, and are tested at 2x.
- **Safe areas.** Sheets and overlays respect the system insets.
