# CsAreaChart

An area chart that stacks series to show how parts add up to a total over time; the popover ends with the total.

Cloudscape reference: https://cloudscape.design/components/area-chart/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
final days = [for (var i = 1; i <= 7; i++) DateTime(2026, 11, i)];
final inbound = CsChartSeries<DateTime>.area(
  title: 'Inbound',
  data: [for (final d in days) CsChartDatum(d, 120 + d.day * 4)],
  valueFormatter: (y, x) => '$y GB',
);
final outbound = CsChartSeries<DateTime>.area(
  title: 'Outbound',
  data: [for (final d in days) CsChartDatum(d, 60 + d.day * 2)],
  valueFormatter: (y, x) => '$y GB',
);

CsAreaChart<DateTime>(
  series: [inbound, outbound, const CsChartSeries<DateTime>.threshold(title: 'Capacity', y: 300)],
  xScaleType: CsChartScaleType.time,
  detailTotalFormatter: (v) => '$v GB',
  height: 300,
  ariaLabel: 'Network traffic',
)
```

## When to use / when not to

- Use it to show the composition of a total over time (traffic by Region, cost by service).
- Every area series must use the same x values. Areas stack in series order, so the top edge is the total.
- Use `CsLineChart` when the series should be compared, not added.

## Parameters

`T` is the x value type: `num` (`int`, `double`) for linear and log axes, `DateTime` for time axes, `String` for categories. Series, data and helper types are documented in [CsChartSeries](CsChartSeries.md).

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `series` | `List<CsChartSeries<T>>` | required | The series, in legend order. Keep the same instances between builds: the chart compares series by identity. |
| `visibleSeries` | `List<CsChartSeries<T>>?` | `null` | Series shown. Null lets the built-in filter manage it; pass a list and update it in `onFilterChange` to control it. |
| `onFilterChange` | `ValueChanged<List<CsChartSeries<T>>>?` | `null` | The built-in filter changed the visible series. |
| `highlightedSeries` | `CsChartSeries<T>?` | `null` | Series to highlight. The chart also highlights on hover and focus; a new value passed here replaces the current highlight. |
| `onHighlightChange` | `ValueChanged<CsChartSeries<T>?>?` | `null` | The user highlighted a series (legend, point, keyboard) or cleared it. |
| `xScaleType` | `CsChartScaleType` | `CsChartScaleType.linear` | `linear`, `log`, `time` (`DateTime` x) or `categorical` (needed for bars). |
| `yScaleType` | `CsChartYScaleType` | `linear` | `linear` or `log`. |
| `xDomain` | `List<T>?` | `null` | `[min, max]` for numbers and dates, the ordered categories for `categorical`. Null fits all series (hidden ones too, so filtering never rescales). |
| `yDomain` | `List<num>?` | `null` | `[min, max]`. Null fits all data plus zero and rounds out to tick steps. |
| `xTitle / yTitle` | `String?` | `null` | Bold axis titles: x below the axis, y above the plot. |
| `legendTitle` | `String?` | `null` | Bold title above the legend. |
| `xTickFormatter` | `CsChartTickFormatter<T>?` | `null` | Formats x ticks and the popover title. `\n` makes two lines. Default: numbers as written, dates by span (`Nov 3`, `14:00`, `Mar 2026`). |
| `yTickFormatter` | `CsChartTickFormatter<num>?` | `null` | Formats value ticks. |
| `height` | `double` | `500` | Plot height in logical pixels; axis labels and titles add to it. |
| `fitHeight` | `bool` | `false` | Fill a parent with bounded height. Without a bounded parent it falls back to `height`. |
| `hideFilter` | `bool` | `false` | Hides the built-in series filter. |
| `hideLegend` | `bool` | `false` | Hides the legend. |
| `additionalFilters` | `Widget?` | `null` | Extra filters placed next to the built-in one. |
| `statusType` | `CsChartStatusType` | `finished` | `loading`, `finished` or `error`. |
| `empty / noMatch` | `Widget?` | `null` | Shown when `series` is empty / when the filter hides every series. |
| `loadingText / errorText / recoveryText` | `String?` | `null` | Status copy. Defaults: "Loading chart", "The data couldn't be fetched. Try again later.", "Retry". |
| `onRecoveryClick` | `VoidCallback?` | `null` | Called from the recovery link next to `errorText`. Without it there is no link. |
| `detailPopoverSize` | `CsChartPopoverSize` | `medium` | Popover max width: `small` 210, `medium` 310, `large` 482. |
| `detailPopoverFooter` | `Widget Function(T x)?` | `null` | Content under a divider at the bottom of the popover. |
| `detailTotalFormatter` | `CsChartTickFormatter<num>?` | `null` | Formats the popover's total row. Defaults to `yTickFormatter`. |
| `i18nStrings` | `CsChartI18nStrings` | `const CsChartI18nStrings()` | Filter, legend, popover and screen reader labels (see CsChartSeries.md). |
| `ariaLabel` | `String?` | `null` | Accessible name; match the visible heading. |
| `ariaDescription` | `String?` | `null` | Short summary read before the generated series and axis summary. |

## Examples

### Custom total label

```dart
CsAreaChart<int>(
  series: series,
  i18nStrings: const CsChartI18nStrings(detailTotalLabel: 'All Regions'),
  ariaLabel: 'Traffic',
)
```

## Accessibility

- The plot is one focusable element announced as `ariaLabel` plus the chart kind ("Line chart"), with a hint that reads `ariaDescription` and a generated summary (series titles, x range or categories, y range).
- Keyboard, as in Cloudscape: Tab focuses the plot and highlights the first position. Left and Right move between x positions (bar groups; Up and Down for horizontal bars), Up and Down cycle between all series and one series at a time, Home and End jump to the ends, Enter or Space pins the popover, Escape dismisses it.
- The semantics value is the highlighted position and every value ("h2, i-0abc123 20%, Alarm 45"); screen reader increase and decrease gestures move between positions.
- A 2px `color-border-item-focused` outline marks the focused point, x line or group.
- The legend is one tab stop with Left and Right between entries; each entry is a toggle button. The filter is a labelled button that opens a list of checkable rows.
- Loading, error and empty states sit in a live region. Series are never told apart by color alone: the legend, filter and popover pair each color with its title and marker shape (line, bar, dashed threshold).

## Motion

- Data animates in once when it first appears (250ms `motion-duration-complex`, `showPaced` easing): lines and areas reveal from the start of the x axis, bars grow out of the baseline, pie segments sweep clockwise.
- Dimming non-highlighted series and legend entries fades over 90ms (`motion-duration-transition-quick`), like Cloudscape's opacity transitions.
- The popover scales and fades in from its anchor (`CsAnchoredOverlay`).
- Reduced motion (`MediaQuery.disableAnimations` or the theme's `disableMotion`) shows everything at once.

## Mobile

- Touch: tap or drag a finger across the plot to scrub the crosshair (or bar groups) with a selection haptic per step; lifting the finger keeps the popover, pinned, with its close button. Tap outside to dismiss. Vertical drags still scroll the page.
- At or below 688px the popover opens above the highlighted point instead of beside it, so it gets the full width.
- The filter opens as a bottom sheet on phones (`CsDropdown`, `CsPresentation.auto`).
- Axis labels drop until they no longer overlap, and the legend wraps. Labels and popover text scale with the platform text size.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `series` (`title`, `type`, `data`, `color`, `valueFormatter`) | `series` with `CsChartSeries.line/.bar/.area/.threshold`; `color` is a `Color`, plus `colorToken` |
| threshold `y` / `x` | `CsChartSeries.threshold(y:)` / `CsChartSeries.threshold(x:)` |
| `xScaleType`, `yScaleType` | `xScaleType` (`CsChartScaleType`), `yScaleType` (`CsChartYScaleType`) |
| `xDomain`, `yDomain`, `xTitle`, `yTitle`, `legendTitle` | same names |
| `xTickFormatter`, `yTickFormatter` (also the deprecated `i18nStrings` versions) | `xTickFormatter`, `yTickFormatter` |
| `detailTotalFormatter`, `i18nStrings.detailTotalLabel` | `detailTotalFormatter`, `CsChartI18nStrings.detailTotalLabel` |
| `height`, `fitHeight`, `hideFilter`, `hideLegend`, `additionalFilters` | same names |
| `statusType`, `empty`, `noMatch`, `loadingText`, `errorText`, `recoveryText`, `onRecoveryClick` | same names |
| `detailPopoverSize`, `detailPopoverFooter` | `detailPopoverSize` (`CsChartPopoverSize`), `detailPopoverFooter` (builder) |
| `visibleSeries` + `onFilterChange` (`detail.visibleSeries`) | `visibleSeries` + `onFilterChange(List)` |
| `highlightedSeries` + `onHighlightChange` (`detail.highlightedSeries`) | `highlightedSeries` + `onHighlightChange(series)` |
| `ariaLabel`, `ariaDescription` | same names |
| `ariaLabelledby` | not supported (web only); use `ariaLabel` |
| `i18nStrings` | `CsChartI18nStrings` |
