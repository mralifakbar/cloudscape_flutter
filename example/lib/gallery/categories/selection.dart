import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// Select, multiselect, autosuggest, tokens, text filter and property filter. Every name and figure here is sample data.
final CsDemoCategory selectionCategory = CsDemoCategory(
  title: 'Selection and filtering',
  description: 'Select, multiselect, autosuggest, tokens, text filter and property filter.',
  icon: CsIcons.filter,
  demos: [
    CsDemo(
      title: 'CsSelect',
      description: 'Single choice with groups, rich options, filtering, async states and an inline label.',
      docPath: 'doc/components/CsSelect.md',
      builder: (_) => const _SelectDemo(),
    ),
    CsDemo(
      title: 'CsMultiselect',
      description: 'Several choices with tokens, a token limit, select all, inline tokens and filtering.',
      docPath: 'doc/components/CsMultiselect.md',
      builder: (_) => const _MultiselectDemo(),
    ),
    CsDemo(
      title: 'CsAutosuggest',
      description: 'Free text with suggestions, the entered-text option and an async loading state.',
      docPath: 'doc/components/CsAutosuggest.md',
      builder: (_) => const _AutosuggestDemo(),
    ),
    CsDemo(
      title: 'CsToken',
      description: 'Normal and inline tokens, dismissible, read-only and disabled.',
      docPath: 'doc/components/CsToken.md',
      builder: (_) => const _TokenDemo(),
    ),
    CsDemo(
      title: 'CsTokenGroup',
      description: 'Dismissible tokens in rows or a column, with a limit.',
      docPath: 'doc/components/CsTokenGroup.md',
      builder: (_) => const _TokenGroupDemo(),
    ),
    CsDemo(
      title: 'CsTextFilter',
      description: 'Free-text filtering of a sample instance list with a match count.',
      docPath: 'doc/components/CsTextFilter.md',
      builder: (_) => const _TextFilterDemo(),
    ),
    CsDemo(
      title: 'CsPropertyFilter',
      description: 'Property, operator and value tokens, free text, and/or, the token editor and Clear filters.',
      docPath: 'doc/components/CsPropertyFilter.md',
      builder: (_) => const _PropertyFilterDemo(),
    ),
  ],
);

const _instanceTypes = <CsOptionItem>[
  CsOptionGroup(
    label: 'General purpose',
    options: [
      CsOption(value: 't3.micro', description: '2 vCPU, 1 GiB memory', labelTag: 'Free tier', tags: ['Burstable']),
      CsOption(value: 't3.small', description: '2 vCPU, 2 GiB memory', tags: ['Burstable']),
      CsOption(value: 'm5.large', description: '2 vCPU, 8 GiB memory'),
      CsOption(
        value: 'm5.24xlarge',
        description: '96 vCPU, 384 GiB memory',
        disabled: true,
        disabledReason: 'Service quota reached',
      ),
    ],
  ),
  CsOptionGroup(
    label: 'Compute optimized',
    options: [
      CsOption(value: 'c6i.large', description: '2 vCPU, 4 GiB memory'),
      CsOption(value: 'c6i.xlarge', description: '4 vCPU, 8 GiB memory'),
    ],
  ),
];

const _regions = <CsOptionItem>[
  CsOption(value: 'us-east-1', label: 'US East (N. Virginia)', icon: CsIcons.globe, filteringTags: ['virginia']),
  CsOption(value: 'us-west-2', label: 'US West (Oregon)', icon: CsIcons.globe),
  CsOption(value: 'eu-west-1', label: 'Europe (Ireland)', icon: CsIcons.globe),
  CsOption(value: 'eu-central-1', label: 'Europe (Frankfurt)', icon: CsIcons.globe),
  CsOption(value: 'ap-southeast-1', label: 'Asia Pacific (Singapore)', icon: CsIcons.globe),
];

class _SelectDemo extends StatefulWidget {
  const _SelectDemo();

  @override
  State<_SelectDemo> createState() => _SelectDemoState();
}

class _SelectDemoState extends State<_SelectDemo> {
  CsOption? _type;
  CsOption? _region = const CsOption(value: 'us-east-1', label: 'US East (N. Virginia)', icon: CsIcons.globe);
  CsOption? _bucket;
  CsDropdownStatusType _status = CsDropdownStatusType.loading;
  List<CsOptionItem> _buckets = const [];

  Future<void> _loadBuckets(CsLoadItemsDetail detail) async {
    if (!detail.firstPage && !detail.samePage) return;
    setState(() => _status = CsDropdownStatusType.loading);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      // The first load fails so the retry link can be tried; the retry succeeds.
      if (!detail.samePage) {
        _status = CsDropdownStatusType.error;
      } else {
        _status = CsDropdownStatusType.finished;
        _buckets = const [
          CsOption(value: 'example-bucket', description: 'us-east-1'),
          CsOption(value: 'logs-bucket', description: 'eu-west-1'),
          CsOption(value: 'archive-bucket', description: 'us-west-2'),
        ];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Groups, label tags and disabled options',
          child: CsFormField(
            label: 'Instance type',
            child: CsSelect(
              options: _instanceTypes,
              selectedOption: _type,
              placeholder: 'Choose an instance type',
              onChange: (o) => setState(() => _type = o),
            ),
          ),
        ),
        DemoSection(
          title: 'Filtering with icons',
          caption: 'Type "virginia" to match a filtering tag.',
          child: CsFormField(
            label: 'Region',
            child: CsSelect(
              options: _regions,
              selectedOption: _region,
              filteringType: CsFilteringType.auto,
              filteringPlaceholder: 'Find region',
              filteringResultsText: (matches, total) => '$matches of $total regions',
              noMatch: const CsBox(text: 'No regions match', color: CsBoxColor.textBodySecondary),
              onChange: (o) => setState(() => _region = o),
            ),
          ),
        ),
        DemoSection(
          title: 'Option trigger and inline label',
          child: CsSelect(
            options: _instanceTypes,
            selectedOption:
                _type ?? const CsOption(value: 't3.micro', description: '2 vCPU, 1 GiB memory', labelTag: 'Free tier'),
            inlineLabelText: 'Instance type',
            triggerVariant: CsSelectTriggerVariant.option,
            onChange: (o) => setState(() => _type = o),
          ),
        ),
        DemoSection(
          title: 'Asynchronous loading',
          caption: 'The first request fails; Retry loads the buckets.',
          child: CsSelect(
            options: _buckets,
            selectedOption: _bucket,
            placeholder: 'Choose a bucket',
            statusType: _status,
            loadingText: 'Loading buckets',
            errorText: 'Could not load buckets',
            recoveryText: 'Retry',
            finishedText: 'End of results',
            onLoadItems: _loadBuckets,
            onChange: (o) => setState(() => _bucket = o),
          ),
        ),
        DemoSection(
          title: 'States',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.s,
            children: [
              CsSelect(options: _regions, selectedOption: _region, invalid: true, onChange: (_) {}),
              CsSelect(options: _regions, selectedOption: _region, warning: true, onChange: (_) {}),
              CsSelect(options: _regions, selectedOption: _region, readOnly: true, onChange: (_) {}),
              CsSelect(
                options: _regions,
                selectedOption: null,
                placeholder: 'Disabled',
                disabled: true,
                onChange: (_) {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _zones = <CsOptionItem>[
  CsOptionGroup(
    label: 'US East (N. Virginia)',
    options: [
      CsOption(value: 'us-east-1a', description: 'use1-az1'),
      CsOption(value: 'us-east-1b', description: 'use1-az2'),
      CsOption(value: 'us-east-1c', description: 'use1-az4', disabled: true),
    ],
  ),
  CsOptionGroup(
    label: 'Europe (Ireland)',
    options: [
      CsOption(value: 'eu-west-1a', description: 'euw1-az1'),
      CsOption(value: 'eu-west-1b', description: 'euw1-az2'),
    ],
  ),
];

class _MultiselectDemo extends StatefulWidget {
  const _MultiselectDemo();

  @override
  State<_MultiselectDemo> createState() => _MultiselectDemoState();
}

class _MultiselectDemoState extends State<_MultiselectDemo> {
  List<CsOption> _zonesSel = const [CsOption(value: 'us-east-1a', description: 'use1-az1')];
  List<CsOption> _states = const [CsOption(value: 'Running'), CsOption(value: 'Pending')];

  static const _stateOptions = <CsOptionItem>[
    CsOption(value: 'Running'),
    CsOption(value: 'Pending'),
    CsOption(value: 'Stopping'),
    CsOption(value: 'Stopped'),
    CsOption(value: 'Terminated'),
  ];

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Groups, select all and a token limit',
          caption: 'Group labels select or clear their group.',
          child: CsFormField(
            label: 'Availability zones',
            child: CsMultiselect(
              options: _zones,
              selectedOptions: _zonesSel,
              placeholder: 'Choose availability zones',
              enableSelectAll: true,
              tokenLimit: 2,
              filteringType: CsFilteringType.auto,
              filteringPlaceholder: 'Find zone',
              onChange: (v) => setState(() => _zonesSel = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Inline tokens',
          child: CsMultiselect(
            options: _stateOptions,
            selectedOptions: _states,
            inlineTokens: true,
            inlineLabelText: 'Instance state',
            placeholder: 'Any state',
            onChange: (v) => setState(() => _states = v),
          ),
        ),
        DemoSection(
          title: 'Closes after each pick, tokens hidden',
          child: CsMultiselect(
            options: _stateOptions,
            selectedOptions: _states,
            keepOpen: false,
            hideTokens: true,
            placeholder: '${_states.length} states selected',
            onChange: (v) => setState(() => _states = v),
          ),
        ),
        DemoSection(
          title: 'Read-only and disabled',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.s,
            children: [
              CsMultiselect(options: _stateOptions, selectedOptions: _states, readOnly: true, placeholder: 'States'),
              CsMultiselect(options: _stateOptions, selectedOptions: _states, disabled: true, placeholder: 'States'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AutosuggestDemo extends StatefulWidget {
  const _AutosuggestDemo();

  @override
  State<_AutosuggestDemo> createState() => _AutosuggestDemoState();
}

class _AutosuggestDemoState extends State<_AutosuggestDemo> {
  String _bucket = '';
  String _instance = '';
  String _picked = 'Nothing picked yet';
  CsDropdownStatusType _status = CsDropdownStatusType.finished;
  List<CsOptionItem> _instances = const [];

  static const _buckets = <CsOptionItem>[
    CsOption(value: 'example-bucket', description: 'us-east-1'),
    CsOption(value: 'logs-bucket', description: 'eu-west-1'),
    CsOption(value: 'archive-bucket', description: 'us-west-2', tags: ['Glacier']),
    CsOption(value: 'static-site-bucket', description: 'us-east-1'),
  ];

  Future<void> _load(CsLoadItemsDetail d) async {
    setState(() => _status = CsDropdownStatusType.loading);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final all = [
      for (var i = 1; i <= 8; i++) CsOption(value: 'i-0abc12$i', label: 'web-server-$i', description: 't3.micro'),
    ];
    setState(() {
      _status = CsDropdownStatusType.finished;
      _instances = [
        for (final o in all)
          if (o.text.contains(d.filteringText) || o.value.contains(d.filteringText)) o,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Suggestions with the entered-text option',
          caption: _picked,
          child: CsFormField(
            label: 'Bucket',
            child: CsAutosuggest(
              value: _bucket,
              options: _buckets,
              placeholder: 'Enter a bucket name',
              enteredTextLabel: (v) => 'Use: "$v"',
              empty: const CsBox(text: 'No buckets', color: CsBoxColor.textBodySecondary),
              onChange: (v) => setState(() => _bucket = v),
              onSelect: (d) =>
                  setState(() => _picked = d.selectedOption == null ? 'Typed value "${d.value}"' : 'Picked ${d.value}'),
            ),
          ),
        ),
        DemoSection(
          title: 'Server filtering',
          caption: 'Suggestions load 700ms after each change.',
          child: CsAutosuggest(
            value: _instance,
            options: _instances,
            filteringType: CsFilteringType.manual,
            placeholder: 'Find an instance',
            statusType: _status,
            loadingText: 'Loading instances',
            finishedText: 'End of results',
            onLoadItems: _load,
            onChange: (v) => setState(() => _instance = v),
          ),
        ),
        DemoSection(
          title: 'States',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.s,
            children: [
              CsAutosuggest(value: 'logs', options: _buckets, invalid: true, onChange: (_) {}),
              CsAutosuggest(value: 'logs', options: _buckets, readOnly: true, onChange: (_) {}),
              CsAutosuggest(value: '', options: _buckets, placeholder: 'Disabled', disabled: true, onChange: (_) {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _TokenDemo extends StatefulWidget {
  const _TokenDemo();

  @override
  State<_TokenDemo> createState() => _TokenDemoState();
}

class _TokenDemoState extends State<_TokenDemo> {
  bool _shown = true;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Normal',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              if (_shown)
                CsToken(
                  label: 'example-bucket',
                  description: 'us-east-1',
                  labelTag: '12 GB',
                  tags: const ['Versioned', 'Encrypted'],
                  icon: CsIcons.folder,
                  onDismiss: () => setState(() => _shown = false),
                )
              else
                CsButton(text: 'Restore token', onPress: () => setState(() => _shown = true)),
              CsToken(label: 'read-only', readOnly: true, onDismiss: () {}),
              CsToken(label: 'disabled', disabled: true, onDismiss: () {}),
            ],
          ),
        ),
        DemoSection(
          title: 'Inline',
          child: Wrap(
            spacing: CsSpace.xxs,
            runSpacing: CsSpace.xxs,
            children: [
              CsToken(label: 'Running', variant: CsTokenVariant.inline, onDismiss: () {}),
              const CsToken(label: 'us-east-1a', variant: CsTokenVariant.inline, icon: CsIcons.locationPin),
              const CsToken(
                label: 'a-long-distribution-name',
                variant: CsTokenVariant.inline,
                tooltipContent: 'a-long-distribution-name (d111111abcdef8)',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TokenGroupDemo extends StatefulWidget {
  const _TokenGroupDemo();

  @override
  State<_TokenGroupDemo> createState() => _TokenGroupDemoState();
}

class _TokenGroupDemoState extends State<_TokenGroupDemo> {
  static const _all = [
    CsTokenGroupItem(label: 'example-bucket', description: 'us-east-1', icon: CsIcons.folder),
    CsTokenGroupItem(label: 'logs-bucket', description: 'eu-west-1', icon: CsIcons.folder),
    CsTokenGroupItem(label: 'archive-bucket', description: 'us-west-2', icon: CsIcons.folder, disabled: true),
    CsTokenGroupItem(label: 'static-site-bucket', description: 'us-east-1', icon: CsIcons.folder),
    CsTokenGroupItem(label: 'backup-bucket', description: 'ap-southeast-1', icon: CsIcons.folder),
  ];
  List<CsTokenGroupItem> _items = List.of(_all);

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Horizontal with a limit',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CsTokenGroup(
                items: _items,
                limit: 3,
                onDismiss: (i) => setState(() => _items = List.of(_items)..removeAt(i)),
              ),
              if (_items.length < _all.length)
                Padding(
                  padding: const EdgeInsets.only(top: CsSpace.s),
                  child: CsButton(text: 'Reset', onPress: () => setState(() => _items = List.of(_all))),
                ),
            ],
          ),
        ),
        DemoSection(
          title: 'Vertical, read-only',
          child: CsTokenGroup(
            items: const [
              CsTokenGroupItem(label: 'report.csv', labelTag: '12 KB', icon: CsIcons.file),
              CsTokenGroupItem(label: 'chart.png', labelTag: '80 KB', icon: CsIcons.file),
            ],
            alignment: CsTokenGroupAlignment.vertical,
            readOnly: true,
            onDismiss: (_) {},
          ),
        ),
      ],
    );
  }
}

const _sampleInstances = [
  ('i-0abc123', 'web-server-1', 't3.micro', 'Running'),
  ('i-0abc124', 'web-server-2', 't3.micro', 'Running'),
  ('i-0abc125', 'api-server-1', 'm5.large', 'Stopped'),
  ('i-0abc126', 'batch-worker', 'c6i.xlarge', 'Pending'),
  ('i-0abc127', 'db-proxy', 'm5.large', 'Running'),
];

class _TextFilterDemo extends StatefulWidget {
  const _TextFilterDemo();

  @override
  State<_TextFilterDemo> createState() => _TextFilterDemoState();
}

class _TextFilterDemoState extends State<_TextFilterDemo> {
  String _text = '';

  @override
  Widget build(BuildContext context) {
    final q = _text.toLowerCase();
    final matches = [
      for (final i in _sampleInstances)
        if ('${i.$1} ${i.$2} ${i.$3} ${i.$4}'.toLowerCase().contains(q)) i,
    ];
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Filter a list',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.s,
            children: [
              CsTextFilter(
                filteringText: _text,
                filteringPlaceholder: 'Find instances',
                countText: matches.length == 1 ? '1 match' : '${matches.length} matches',
                onChange: (v) => setState(() => _text = v),
              ),
              for (final m in matches) CsBox(text: '${m.$2} (${m.$1}), ${m.$3}, ${m.$4}'),
            ],
          ),
        ),
        const DemoSection(
          title: 'Disabled',
          child: CsTextFilter(filteringText: '', filteringPlaceholder: 'Find instances', disabled: true),
        ),
      ],
    );
  }
}

class _PropertyFilterDemo extends StatefulWidget {
  const _PropertyFilterDemo();

  @override
  State<_PropertyFilterDemo> createState() => _PropertyFilterDemoState();
}

class _PropertyFilterDemoState extends State<_PropertyFilterDemo> {
  CsPropertyFilterQuery _query = const CsPropertyFilterQuery(
    tokens: [CsPropertyFilterToken(propertyKey: 'state', operator: CsPropertyFilterOperator.equals, value: 'Running')],
  );

  static const _properties = [
    CsPropertyFilterProperty(key: 'id', propertyLabel: 'Instance ID', groupValuesLabel: 'Instance ID values'),
    CsPropertyFilterProperty(
      key: 'name',
      propertyLabel: 'Name',
      groupValuesLabel: 'Name values',
      operators: [
        CsPropertyFilterOperator.equals,
        CsPropertyFilterOperator.notEquals,
        CsPropertyFilterOperator.contains,
        CsPropertyFilterOperator.startsWith,
      ],
    ),
    CsPropertyFilterProperty(key: 'type', propertyLabel: 'Instance type', groupValuesLabel: 'Instance type values'),
    CsPropertyFilterProperty(key: 'state', propertyLabel: 'State', groupValuesLabel: 'State values'),
  ];

  bool _match(CsPropertyFilterToken t, (String, String, String, String) i) {
    final field = switch (t.propertyKey) {
      'id' => i.$1,
      'name' => i.$2,
      'type' => i.$3,
      'state' => i.$4,
      _ => '${i.$1} ${i.$2} ${i.$3} ${i.$4}',
    }.toLowerCase();
    final v = t.value.toLowerCase();
    return switch (t.operator) {
      CsPropertyFilterOperator.equals => field == v,
      CsPropertyFilterOperator.notEquals => field != v,
      CsPropertyFilterOperator.contains => field.contains(v),
      CsPropertyFilterOperator.notContains => !field.contains(v),
      CsPropertyFilterOperator.startsWith => field.startsWith(v),
      CsPropertyFilterOperator.notStartsWith => !field.startsWith(v),
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      for (final i in _sampleInstances) ...[
        CsPropertyFilterOption(propertyKey: 'id', value: i.$1),
        CsPropertyFilterOption(propertyKey: 'name', value: i.$2),
      ],
      for (final t in {for (final i in _sampleInstances) i.$3}) CsPropertyFilterOption(propertyKey: 'type', value: t),
      for (final s in {for (final i in _sampleInstances) i.$4}) CsPropertyFilterOption(propertyKey: 'state', value: s),
    ];
    final and = _query.operation == CsPropertyFilterOperation.and;
    final matches = [
      for (final i in _sampleInstances)
        if (_query.tokens.isEmpty ||
            (and ? _query.tokens.every((t) => _match(t, i)) : _query.tokens.any((t) => _match(t, i))))
          i,
    ];
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Filter instances',
          caption: 'Pick a property, then an operator, then a value; or type "State = Stopped" and press Enter.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.s,
            children: [
              CsPropertyFilter(
                query: _query,
                onChange: (q) => setState(() => _query = q),
                filteringProperties: _properties,
                filteringOptions: options,
                countText: matches.length == 1 ? '1 match' : '${matches.length} matches',
                tokenLimit: 3,
                filteringConstraintText: 'Sample data: five instances.',
              ),
              for (final m in matches) CsBox(text: '${m.$2} (${m.$1}), ${m.$3}, ${m.$4}'),
            ],
          ),
        ),
        DemoSection(
          title: 'Disabled',
          child: CsPropertyFilter(query: _query, onChange: (_) {}, filteringProperties: _properties, disabled: true),
        ),
      ],
    );
  }
}
