import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// Area, bar, line, mixed and pie charts with legends, filters and detail popovers. Every name and figure here is sample data.
final CsDemoCategory chartsCategory = CsDemoCategory(
  title: 'Charts',
  description: 'Area, bar, line, mixed and pie charts with legends, filters and detail popovers.',
  icon: CsIcons.barChart,
  demos: [
    CsDemo(
      title: 'CsLineChart',
      description: 'Time series with a threshold, controlled filtering, log scale and loading, error and empty states.',
      docPath: 'doc/components/CsLineChart.md',
      builder: (_) => const _LineDemo(),
    ),
    CsDemo(
      title: 'CsBarChart',
      description: 'Grouped, stacked and horizontal bars with a threshold and a popover breakdown.',
      docPath: 'doc/components/CsBarChart.md',
      builder: (_) => const _BarDemo(),
    ),
    CsDemo(
      title: 'CsMixedLineBarChart',
      description: 'Monthly cost bars with an average line, a budget threshold and a deployment marker.',
      docPath: 'doc/components/CsMixedLineBarChart.md',
      builder: (_) => const _MixedDemo(),
    ),
    CsDemo(
      title: 'CsAreaChart',
      description: 'Stacked traffic areas with a total in the popover.',
      docPath: 'doc/components/CsAreaChart.md',
      builder: (_) => const _AreaDemo(),
    ),
    CsDemo(
      title: 'CsPieChart',
      description: 'Pie and donut in three sizes, with labels, descriptions, inner metric and custom popover.',
      docPath: 'doc/components/CsPieChart.md',
      builder: (_) => const _PieDemo(),
    ),
  ],
);

final List<DateTime> _hours = [for (var i = 0; i < 24; i++) DateTime(2026, 11, 16, i)];

double _wave(int i, int seed) => 40 + 25 * ((i * 7 + seed * 13) % 11) / 11 + (i % 5) * 3;

final _cpuA = CsChartSeries<DateTime>.line(
  title: 'i-0abc123',
  data: [for (var i = 0; i < 24; i++) CsChartDatum(_hours[i], _wave(i, 1).round())],
  valueFormatter: (y, x) => '$y%',
);
final _cpuB = CsChartSeries<DateTime>.line(
  title: 'i-0def456',
  data: [for (var i = 0; i < 24; i++) CsChartDatum(_hours[i], (_wave(i, 4) - 18).round())],
  valueFormatter: (y, x) => '$y%',
);
final _cpuC = CsChartSeries<DateTime>.line(
  title: 'i-0fed789',
  data: [for (var i = 0; i < 24; i++) CsChartDatum(_hours[i], (_wave(i, 9) - 30).round())],
  valueFormatter: (y, x) => '$y%',
);
const _alarm = CsChartSeries<DateTime>.threshold(
  title: 'Alarm threshold',
  y: 80,
  colorToken: CsColor.chartsThresholdNegative,
);
final List<CsChartSeries<DateTime>> _cpuSeries = [_cpuA, _cpuB, _cpuC, _alarm];

String _hour(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:00';

class _Toggles extends StatelessWidget {
  const _Toggles({required this.options});

  final List<(String, bool, ValueChanged<bool>)> options;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: CsSpace.l,
    runSpacing: CsSpace.xs,
    children: [
      for (final (label, value, onChange) in options) CsCheckbox(checked: value, label: label, onChange: onChange),
    ],
  );
}

class _StatusPicker extends StatelessWidget {
  const _StatusPicker({required this.value, required this.onChange});

  final CsChartStatusType value;
  final ValueChanged<CsChartStatusType> onChange;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: CsSpace.xs,
    runSpacing: CsSpace.xs,
    children: [
      for (final s in CsChartStatusType.values)
        CsButton(
          text: s.name,
          variant: s == value ? CsButtonVariant.primary : CsButtonVariant.normal,
          onPress: () => onChange(s),
        ),
    ],
  );
}

class _LineDemo extends StatefulWidget {
  const _LineDemo();

  @override
  State<_LineDemo> createState() => _LineDemoState();
}

class _LineDemoState extends State<_LineDemo> {
  List<CsChartSeries<DateTime>> _visible = _cpuSeries;
  CsChartSeries<DateTime>? _highlighted;
  CsChartStatusType _status = CsChartStatusType.finished;
  bool _log = false;
  bool _hideLegend = false;
  bool _empty = false;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'CPU utilization',
          caption:
              'Hover, tap or drag across the plot. Tab in and use the arrow keys; Enter pins the popover. '
              'Highlighted: ${_highlighted?.title ?? 'none'}. Visible: ${_visible.length} of ${_cpuSeries.length}.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.m,
            children: [
              _Toggles(
                options: [
                  ('Log scale', _log, (v) => setState(() => _log = v)),
                  ('Hide legend', _hideLegend, (v) => setState(() => _hideLegend = v)),
                  ('No data', _empty, (v) => setState(() => _empty = v)),
                ],
              ),
              _StatusPicker(value: _status, onChange: (s) => setState(() => _status = s)),
              CsLineChart<DateTime>(
                series: _empty ? const [] : _cpuSeries,
                visibleSeries: _visible,
                onFilterChange: (v) => setState(() => _visible = v),
                onHighlightChange: (s) => setState(() => _highlighted = s),
                xScaleType: CsChartScaleType.time,
                yScaleType: _log ? CsChartYScaleType.log : CsChartYScaleType.linear,
                yDomain: _log ? null : const [0, 100],
                xTickFormatter: _hour,
                yTickFormatter: (v) => '$v%',
                xTitle: 'Time (UTC)',
                yTitle: 'CPU utilization (%)',
                legendTitle: 'Instances',
                hideLegend: _hideLegend,
                height: 300,
                statusType: _status,
                loadingText: 'Loading metrics',
                errorText: 'Metrics could not be loaded.',
                recoveryText: 'Retry',
                onRecoveryClick: () => setState(() => _status = CsChartStatusType.loading),
                empty: const CsBox(text: 'No metrics in this time range', textAlign: TextAlign.center),
                noMatch: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: CsSpace.xs,
                  children: [
                    const CsBox(text: 'No matching data', textAlign: TextAlign.center),
                    CsButton(text: 'Clear filter', onPress: () => setState(() => _visible = _cpuSeries)),
                  ],
                ),
                detailPopoverFooter: (x) => CsLink(text: 'View logs at ${_hour(x)}', onFollow: () {}),
                ariaLabel: 'CPU utilization',
                ariaDescription: 'Hourly CPU utilization of three sample instances.',
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Numeric x axis without filter',
          child: CsLineChart<int>(
            series: [
              CsChartSeries.line(
                title: 'p99 latency',
                data: [for (var i = 0; i <= 10; i++) CsChartDatum(i * 10, 80 + (i * 37 % 41))],
                valueFormatter: (y, x) => '$y ms',
              ),
            ],
            hideFilter: true,
            xTitle: 'Requests per second',
            height: 220,
            detailPopoverSize: CsChartPopoverSize.small,
            ariaLabel: 'Latency by load',
          ),
        ),
      ],
    );
  }
}

const _site1 = CsChartSeries<String>.bar(
  title: 'example-bucket',
  data: [
    CsChartDatum('Jan', 820),
    CsChartDatum('Feb', 940),
    CsChartDatum('Mar', 1100),
    CsChartDatum('Apr', 760),
    CsChartDatum('May', 1240),
  ],
);
const _site2 = CsChartSeries<String>.bar(
  title: 'logs-bucket',
  data: [
    CsChartDatum('Jan', 420),
    CsChartDatum('Feb', 380),
    CsChartDatum('Mar', 510),
    CsChartDatum('Apr', 600),
    CsChartDatum('May', 450),
  ],
);
const _site3 = CsChartSeries<String>.bar(
  title: 'backup-bucket',
  data: [
    CsChartDatum('Jan', 210),
    CsChartDatum('Feb', 260),
    CsChartDatum('Mar', -80),
    CsChartDatum('Apr', 300),
    CsChartDatum('May', 280),
  ],
);
const _target = CsChartSeries<String>.threshold(title: 'Target', y: 1400);

class _BarDemo extends StatefulWidget {
  const _BarDemo();

  @override
  State<_BarDemo> createState() => _BarDemoState();
}

class _BarDemoState extends State<_BarDemo> {
  bool _stacked = false;
  bool _horizontal = false;
  bool _breakdown = false;
  bool _emphasize = true;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Requests per bucket',
          caption: 'Toggle stacking and orientation. With the breakdown on, rows of example-bucket expand.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.m,
            children: [
              _Toggles(
                options: [
                  ('Stacked', _stacked, (v) => setState(() => _stacked = v)),
                  ('Horizontal', _horizontal, (v) => setState(() => _horizontal = v)),
                  ('Popover breakdown', _breakdown, (v) => setState(() => _breakdown = v)),
                  ('Emphasize baseline', _emphasize, (v) => setState(() => _emphasize = v)),
                ],
              ),
              CsBarChart<String>(
                series: const [_site1, _site2, _site3, _target],
                stackedBars: _stacked,
                horizontalBars: _horizontal,
                emphasizeBaselineAxis: _emphasize,
                yTitle: 'Requests (thousands)',
                xTitle: 'Month',
                height: 300,
                detailPopoverSize: _breakdown ? CsChartPopoverSize.large : CsChartPopoverSize.medium,
                detailPopoverSeriesContent: _breakdown
                    ? (series, x, y) => series == _site1
                          ? CsChartSeriesDetail(
                              expandable: true,
                              subItems: [
                                CsChartDetailPair(key: 'GET', value: '${(y * 0.7).round()}'),
                                CsChartDetailPair(key: 'PUT', value: '${(y * 0.3).round()}'),
                              ],
                            )
                          : const CsChartSeriesDetail()
                    : null,
                ariaLabel: 'Requests per bucket',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
final _cost = CsChartSeries<String>.bar(
  title: 'Monthly cost',
  data: [for (var i = 0; i < 6; i++) CsChartDatum(_months[i], 900 + (i * 173 % 500))],
  valueFormatter: (y, x) => '\$$y',
);
final _average = CsChartSeries<String>.line(
  title: 'Running average',
  data: [
    for (var i = 0; i < 6; i++)
      CsChartDatum(
        _months[i],
        ([for (var j = 0; j <= i; j++) 900 + (j * 173 % 500)].reduce((a, b) => a + b) / (i + 1)).round(),
      ),
  ],
  valueFormatter: (y, x) => '\$$y',
);
const _budget = CsChartSeries<String>.threshold(title: 'Budget', y: 1400);
const _deploy = CsChartSeries<String>.threshold(title: 'Migration to d111111abcdef8', x: 'Apr');

class _MixedDemo extends StatefulWidget {
  const _MixedDemo();

  @override
  State<_MixedDemo> createState() => _MixedDemoState();
}

class _MixedDemoState extends State<_MixedDemo> {
  CsChartSeries<String>? _highlighted;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Cost with average and budget',
          caption: 'Highlight from outside the chart: ${_highlighted?.title ?? 'none'}.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.m,
            children: [
              Wrap(
                spacing: CsSpace.xs,
                runSpacing: CsSpace.xs,
                children: [
                  for (final s in [_cost, _average, null])
                    CsButton(text: s?.title ?? 'Clear highlight', onPress: () => setState(() => _highlighted = s)),
                ],
              ),
              CsMixedLineBarChart<String>(
                series: [_cost, _average, _budget, _deploy],
                xScaleType: CsChartScaleType.categorical,
                highlightedSeries: _highlighted,
                onHighlightChange: (s) => setState(() => _highlighted = s),
                yTickFormatter: (v) => '\$$v',
                yTitle: 'Cost (USD)',
                height: 300,
                ariaLabel: 'Monthly cost',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final List<DateTime> _days = [for (var i = 1; i <= 14; i++) DateTime(2026, 11, i)];
final _areaSeries = <CsChartSeries<DateTime>>[
  for (final (i, name) in ['us-east-1', 'eu-west-1', 'ap-southeast-2'].indexed)
    CsChartSeries<DateTime>.area(
      title: name,
      data: [for (final d in _days) CsChartDatum(d, 60 + ((d.day * (i + 3) * 7) % 50) - i * 15)],
      valueFormatter: (y, x) => '$y GB',
    ),
  const CsChartSeries<DateTime>.threshold(title: 'Peak capacity', y: 200),
];

class _AreaDemo extends StatefulWidget {
  const _AreaDemo();

  @override
  State<_AreaDemo> createState() => _AreaDemoState();
}

class _AreaDemoState extends State<_AreaDemo> {
  CsChartStatusType _status = CsChartStatusType.finished;
  bool _fit = false;

  @override
  Widget build(BuildContext context) {
    final chart = CsAreaChart<DateTime>(
      series: _areaSeries,
      xScaleType: CsChartScaleType.time,
      xTickFormatter: (d) => 'Nov ${d.day}',
      detailTotalFormatter: (v) => '$v GB',
      yTitle: 'Network out (GB)',
      height: 280,
      fitHeight: _fit,
      statusType: _status,
      onRecoveryClick: () => setState(() => _status = CsChartStatusType.finished),
      i18nStrings: const CsChartI18nStrings(detailTotalLabel: 'All Regions'),
      ariaLabel: 'Network traffic by Region',
    );
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Network traffic by Region',
          caption: 'The popover ends with the total of the visible areas.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.m,
            children: [
              _Toggles(options: [('Fit a 420px parent', _fit, (v) => setState(() => _fit = v))]),
              _StatusPicker(value: _status, onChange: (s) => setState(() => _status = s)),
              if (_fit) SizedBox(height: 420, child: chart) else chart,
            ],
          ),
        ),
      ],
    );
  }
}

class _InstanceState extends CsPieChartDatum {
  const _InstanceState(String title, num value, this.lastChange) : super(title: title, value: value);

  final String lastChange;
}

const _states = [
  _InstanceState('Running', 62, '2 minutes ago'),
  _InstanceState('Stopped', 21, '1 hour ago'),
  _InstanceState('Pending', 9, '5 minutes ago'),
  _InstanceState('Terminated', 6, '3 days ago'),
  _InstanceState('Stopping', 2, 'just now'),
];

class _PieDemo extends StatefulWidget {
  const _PieDemo();

  @override
  State<_PieDemo> createState() => _PieDemoState();
}

class _PieDemoState extends State<_PieDemo> {
  CsPieChartVariant _variant = CsPieChartVariant.donut;
  CsPieChartSize _size = CsPieChartSize.medium;
  bool _hideTitles = false;
  bool _hideDescriptions = false;
  bool _customPopover = false;
  _InstanceState? _highlighted;

  @override
  Widget build(BuildContext context) {
    final total = _states.fold<num>(0, (a, b) => a + b.value);
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Instance states',
          caption: 'Highlighted: ${_highlighted?.title ?? 'none'}.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.m,
            children: [
              Wrap(
                spacing: CsSpace.xs,
                runSpacing: CsSpace.xs,
                children: [
                  for (final v in CsPieChartVariant.values)
                    CsButton(
                      text: v.name,
                      variant: v == _variant ? CsButtonVariant.primary : CsButtonVariant.normal,
                      onPress: () => setState(() => _variant = v),
                    ),
                  for (final s in CsPieChartSize.values)
                    CsButton(
                      text: s.name,
                      variant: s == _size ? CsButtonVariant.primary : CsButtonVariant.normal,
                      onPress: () => setState(() => _size = s),
                    ),
                ],
              ),
              _Toggles(
                options: [
                  ('Hide titles', _hideTitles, (v) => setState(() => _hideTitles = v)),
                  ('Hide descriptions', _hideDescriptions, (v) => setState(() => _hideDescriptions = v)),
                  ('Custom popover', _customPopover, (v) => setState(() => _customPopover = v)),
                ],
              ),
              CsPieChart<_InstanceState>(
                data: _states,
                variant: _variant,
                size: _size,
                hideTitles: _hideTitles,
                hideDescriptions: _hideDescriptions,
                innerMetricValue: '$total',
                innerMetricDescription: 'instances',
                segmentDescription: (d, sum) => '${d.value} instances, ${(d.value * 100 / sum).round()}%',
                detailPopoverContent: _customPopover
                    ? (d, sum) => [
                        CsChartDetailPair(key: 'Instances', value: '${d.value}'),
                        CsChartDetailPair(key: 'Last change', value: d.lastChange),
                      ]
                    : null,
                detailPopoverFooter: (d) => CsLink(text: 'View ${d.title.toLowerCase()} instances', onFollow: () {}),
                legendTitle: 'State',
                onHighlightChange: (d) => setState(() => _highlighted = d),
                ariaLabel: 'Instance states',
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Loading and empty',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.l,
            children: [
              CsPieChart<CsPieChartDatum>(data: [], statusType: CsChartStatusType.loading, size: CsPieChartSize.small),
              CsPieChart<CsPieChartDatum>(
                data: [],
                size: CsPieChartSize.small,
                empty: CsBox(text: 'No instances in this Region', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
