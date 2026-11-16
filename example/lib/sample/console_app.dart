import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/material.dart';

import 'sample_data.dart';

/// Pages of the sample console.
enum ConsoleSection { dashboard, instances, launch }

/// A small cloud console built only from cloudscape_flutter: a top
/// navigation, an app layout with side navigation and help panel, a
/// dashboard, an instances table with filtering, sorting, pagination and
/// preferences, and a launch wizard. Every name and number is sample data.
class ConsoleApp extends StatefulWidget {
  const ConsoleApp({super.key, this.initialSection = ConsoleSection.instances});

  final ConsoleSection initialSection;

  @override
  State<ConsoleApp> createState() => _ConsoleAppState();
}

class _ConsoleAppState extends State<ConsoleApp> {
  late ConsoleSection _section = widget.initialSection;
  final List<CsFlashbarItem> _flashes = [];
  late List<SampleInstance> _instances = sampleInstances();
  int _launched = 0;

  static const _hrefs = {
    ConsoleSection.dashboard: '/dashboard',
    ConsoleSection.instances: '/instances',
    ConsoleSection.launch: '/launch',
  };

  void _go(ConsoleSection s) => setState(() => _section = s);

  int _flashCount = 0;

  void _flash(CsFlashbarItem Function(String id, VoidCallback dismiss) build) {
    final id = 'flash-${_flashCount++}';
    setState(() => _flashes.insert(0, build(id, () => setState(() => _flashes.removeWhere((f) => f.id == id)))));
  }

  void _onLaunched(String name, String type) {
    _launched++;
    final instance = SampleInstance(
      id: 'i-0new${_launched.toString().padLeft(4, '0')}',
      name: name,
      state: 'pending',
      type: type,
      zone: 'us-east-1a',
      cpu: 0,
      launched: DateTime(2026, 11, 16, 9),
    );
    setState(() {
      _instances = [instance, ..._instances];
      _section = ConsoleSection.instances;
    });
    _flash(
      (id, dismiss) => CsFlashbarItem(
        id: id,
        type: CsFlashbarType.success,
        header: 'Instance launched',
        content: '$name (${instance.id}) is starting. It is sample data, nothing was created.',
        dismissible: true,
        onDismiss: dismiss,
      ),
    );
  }

  void _setState(Set<String> ids, String state) {
    setState(() {
      _instances = [for (final i in _instances) ids.contains(i.id) ? i.copyWith(state: state) : i];
    });
    _flash(
      (id, dismiss) => CsFlashbarItem(
        id: id,
        type: CsFlashbarType.info,
        content: '${ids.length} ${ids.length == 1 ? 'instance' : 'instances'} set to $state (sample data).',
        dismissible: true,
        onDismiss: dismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_section) {
      ConsoleSection.dashboard => 'Dashboard',
      ConsoleSection.instances => 'Instances',
      ConsoleSection.launch => 'Launch an instance',
    };
    return Scaffold(
      backgroundColor: context.cs.colors.backgroundLayoutMain,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CsTopNavigation(
            identity: CsTopNavigationIdentity(
              href: '/',
              title: 'Sample console',
              onFollow: () => _go(ConsoleSection.dashboard),
            ),
            utilities: [
              CsTopNavigationButton(
                icon: CsIcons.notification,
                ariaLabel: 'Notifications',
                badge: _flashes.isNotEmpty,
                disableUtilityCollapse: true,
                onClick: () {},
              ),
              CsTopNavigationButton(
                icon: CsIcons.arrowLeft,
                text: 'Gallery',
                ariaLabel: 'Back to the gallery',
                onClick: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: CsAppLayout(
                contentType: _section == ConsoleSection.launch
                    ? CsAppLayoutContentType.wizard
                    : (_section == ConsoleSection.instances
                          ? CsAppLayoutContentType.table
                          : CsAppLayoutContentType.dashboard),
                navigation: CsSideNavigation(
                  header: const CsSideNavigationHeader(text: 'Compute', href: '/'),
                  activeHref: _hrefs[_section]!,
                  onFollow: (detail) {
                    final match = _hrefs.entries.where((e) => e.value == detail.href);
                    if (match.isNotEmpty) _go(match.first.key);
                  },
                  items: const [
                    CsSideNavigationLink(text: 'Dashboard', href: '/dashboard'),
                    CsSideNavigationSection(
                      text: 'Instances',
                      items: [
                        CsSideNavigationLink(text: 'Instances', href: '/instances'),
                        CsSideNavigationLink(text: 'Launch an instance', href: '/launch'),
                      ],
                    ),
                  ],
                ),
                tools: CsHelpPanel(
                  header: title,
                  child: const CsTextContent(
                    blocks: [
                      CsTextParagraph(
                        text:
                            'This console is a sample built from cloudscape_flutter. Every instance, number and chart is sample data.',
                      ),
                      CsTextHeading('Instances', level: CsTextHeadingLevel.h3),
                      CsTextParagraph(
                        text: 'Filter, sort and select instances, then start or stop them from the Actions menu.',
                      ),
                    ],
                  ),
                ),
                breadcrumbs: CsBreadcrumbGroup(
                  items: [
                    const CsBreadcrumbGroupItem(text: 'Compute', href: '/'),
                    CsBreadcrumbGroupItem(text: title, href: _hrefs[_section]!),
                  ],
                  onFollow: (item) => item.href == '/' ? _go(ConsoleSection.dashboard) : null,
                ),
                notifications: _flashes.isEmpty ? null : CsFlashbar(items: _flashes, stackItems: true),
                content: switch (_section) {
                  ConsoleSection.dashboard => _Dashboard(
                    instances: _instances,
                    onViewInstances: () => _go(ConsoleSection.instances),
                  ),
                  ConsoleSection.instances => _InstancesPage(
                    instances: _instances,
                    onLaunch: () => _go(ConsoleSection.launch),
                    onSetState: _setState,
                  ),
                  ConsoleSection.launch => _LaunchWizard(
                    onCancel: () => _go(ConsoleSection.instances),
                    onLaunched: _onLaunched,
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.instances, required this.onViewInstances});

  final List<SampleInstance> instances;
  final VoidCallback onViewInstances;

  @override
  Widget build(BuildContext context) {
    int count(String s) => instances.where((i) => i.state == s).length;
    final running = count('running');
    return CsContentLayout(
      header: const CsHeader(
        variant: CsHeaderVariant.h1,
        title: 'Dashboard',
        description: 'Compute overview for the sample account. All figures are sample data.',
      ),
      child: CsSpaceBetween(
        size: CsSpacingSize.l,
        children: [
          CsContainer(
            header: const CsHeader(title: 'Overview'),
            child: CsKeyValuePairs(
              columns: 4,
              items: [
                CsKeyValuePair(label: 'Running', value: '$running'),
                CsKeyValuePair(label: 'Stopped', value: '${count('stopped')}'),
                CsKeyValuePair(label: 'Pending', value: '${count('pending')}'),
                CsKeyValuePair(label: 'Terminated', value: '${count('terminated')}'),
              ],
            ),
          ),
          CsContainer(
            header: const CsHeader(title: 'CPU utilization', description: 'Average across instances, last 24 hours'),
            child: CsLineChart<DateTime>(
              series: [
                for (final (name, seed) in [('web-server-1', 1), ('api-gateway-1', 2)])
                  CsChartSeries<DateTime>.line(
                    title: name,
                    data: [for (final (x, y) in sampleCpu(seed)) CsChartDatum(x, y)],
                    valueFormatter: (y, x) => '${y.round()}%',
                  ),
                const CsChartSeries<DateTime>.threshold(title: 'Alarm threshold', y: 85),
              ],
              xScaleType: CsChartScaleType.time,
              yDomain: const [0, 100],
              yTitle: 'CPU (%)',
              height: 240,
              ariaLabel: 'CPU utilization over the last 24 hours',
            ),
          ),
          CsContainer(
            header: CsHeader(
              title: 'Instance states',
              actions: CsButton(text: 'View instances', onPress: onViewInstances),
            ),
            child: CsPieChart<CsPieChartDatum>(
              data: [
                CsPieChartDatum(title: 'Running', value: running.toDouble()),
                CsPieChartDatum(title: 'Stopped', value: count('stopped').toDouble()),
                CsPieChartDatum(title: 'Pending', value: count('pending').toDouble()),
                CsPieChartDatum(title: 'Terminated', value: count('terminated').toDouble()),
              ],
              variant: CsPieChartVariant.donut,
              innerMetricValue: '${instances.length}',
              innerMetricDescription: 'instances',
              hideFilter: true,
              ariaLabel: 'Instances by state',
            ),
          ),
        ],
      ),
    );
  }
}

class _InstancesPage extends StatefulWidget {
  const _InstancesPage({required this.instances, required this.onLaunch, required this.onSetState});

  final List<SampleInstance> instances;
  final VoidCallback onLaunch;
  final void Function(Set<String> ids, String state) onSetState;

  @override
  State<_InstancesPage> createState() => _InstancesPageState();
}

class _InstancesPageState extends State<_InstancesPage> {
  late CsCollection<SampleInstance> _collection;
  var _prefs = const CsCollectionPreferencesValue<void>(pageSize: 10, wrapLines: false, stripedRows: false);

  @override
  void initState() {
    super.initState();
    _collection = _build(widget.instances, pageSize: 10);
  }

  CsCollection<SampleInstance> _build(List<SampleInstance> items, {required int pageSize}) => CsCollection(
    items,
    filtering: CsCollectionFiltering(
      filteringFunction: (i, text) {
        final t = text.toLowerCase();
        return i.name.contains(t) || i.id.contains(t) || i.type.contains(t) || i.zone.contains(t);
      },
      empty: CsBox(
        textAlign: TextAlign.center,
        child: CsSpaceBetween(
          size: CsSpacingSize.xs,
          alignItems: CsSpaceBetweenAlign.center,
          children: [
            const CsBox(variant: CsBoxVariant.strong, text: 'No instances'),
            CsButton(text: 'Launch instance', onPress: widget.onLaunch),
          ],
        ),
      ),
      noMatch: CsSpaceBetween(
        size: CsSpacingSize.xs,
        alignItems: CsSpaceBetweenAlign.center,
        children: [
          const CsBox(variant: CsBoxVariant.strong, text: 'No matches'),
          CsButton(text: 'Clear filter', onPress: () => _collection.setFiltering('')),
        ],
      ),
    ),
    sorting: const CsCollectionSorting(),
    pagination: CsCollectionPagination(pageSize: pageSize),
    selection: CsCollectionSelection(trackBy: (i) => i.id),
  );

  @override
  void didUpdateWidget(_InstancesPage old) {
    super.didUpdateWidget(old);
    if (old.instances != widget.instances) _collection.allItems = widget.instances;
  }

  @override
  void dispose() {
    _collection.dispose();
    super.dispose();
  }

  CsStatusType _status(String state) => switch (state) {
    'running' => CsStatusType.success,
    'stopped' => CsStatusType.stopped,
    'pending' => CsStatusType.pending,
    _ => CsStatusType.error,
  };

  @override
  Widget build(BuildContext context) {
    final columns = <CsTableColumn<SampleInstance>>[
      CsTableColumn(
        id: 'name',
        header: 'Name',
        isRowHeader: true,
        sortingComparator: (a, b) => a.name.compareTo(b.name),
        cell: (context, i) => CsLink(text: i.name, onFollow: () {}),
      ),
      CsTableColumn(
        id: 'id',
        header: 'Instance ID',
        sortingComparator: (a, b) => a.id.compareTo(b.id),
        cell: (context, i) => CsBox(variant: CsBoxVariant.code, text: i.id),
      ),
      CsTableColumn(
        id: 'state',
        header: 'State',
        sortingComparator: (a, b) => a.state.compareTo(b.state),
        cell: (context, i) =>
            CsStatusIndicator(type: _status(i.state), text: i.state[0].toUpperCase() + i.state.substring(1)),
      ),
      CsTableColumn(
        id: 'type',
        header: 'Type',
        sortingComparator: (a, b) => a.type.compareTo(b.type),
        cell: (context, i) => Text(i.type),
      ),
      CsTableColumn(
        id: 'zone',
        header: 'Availability zone',
        sortingComparator: (a, b) => a.zone.compareTo(b.zone),
        cell: (context, i) => Text(i.zone),
      ),
      CsTableColumn(
        id: 'cpu',
        header: 'CPU',
        sortingComparator: (a, b) => a.cpu.compareTo(b.cpu),
        cell: (context, i) => Text('${i.cpu}%'),
      ),
    ];

    return ListenableBuilder(
      listenable: _collection,
      builder: (context, _) {
        final selected = _collection.selectedItems;
        final ids = {for (final i in selected) i.id};
        return CsTable<SampleInstance>(
          variant: CsTableVariant.fullPage,
          stickyHeader: true,
          wrapLines: _prefs.wrapLines ?? false,
          stripedRows: _prefs.stripedRows ?? false,
          mobileLayout: CsTableMobileLayout.cards,
          header: CsHeader(
            variant: CsHeaderVariant.awsuiH1Sticky,
            title: 'Instances',
            counter: selected.isEmpty
                ? '(${_collection.filteredItemsCount})'
                : '(${selected.length}/${_collection.filteredItemsCount})',
            description: 'Sample instances. Actions change only this demo.',
            actions: CsSpaceBetween(
              direction: CsSpaceBetweenDirection.horizontal,
              size: CsSpacingSize.xs,
              children: [
                CsButtonDropdown(
                  text: 'Actions',
                  disabled: selected.isEmpty,
                  items: const [
                    CsButtonDropdownItem(id: 'start', text: 'Start'),
                    CsButtonDropdownItem(id: 'stop', text: 'Stop'),
                    CsButtonDropdownItem(id: 'terminate', text: 'Terminate'),
                  ],
                  onItemClick: (item) {
                    final state = switch (item.id) {
                      'start' => 'running',
                      'stop' => 'stopped',
                      _ => 'terminated',
                    };
                    widget.onSetState(ids, state);
                    _collection.setSelectedItems(const []);
                  },
                ),
                CsButton(text: 'Launch instance', variant: CsButtonVariant.primary, onPress: widget.onLaunch),
              ],
            ),
          ),
          filter: CsTextFilter(
            filteringText: _collection.filteringText,
            filteringPlaceholder: 'Find instances',
            countText: _collection.isFiltered ? '${_collection.filteredItemsCount} matches' : null,
            onChange: _collection.setFiltering,
          ),
          pagination: CsPagination(
            currentPageIndex: _collection.currentPageIndex,
            pagesCount: _collection.pagesCount,
            onChange: _collection.setCurrentPage,
          ),
          preferences: CsCollectionPreferences<void>(
            preferences: _prefs,
            onConfirm: (next) {
              final size = next.pageSize ?? 10;
              setState(() {
                if (size != (_prefs.pageSize ?? 10)) {
                  final old = _collection;
                  _collection = _build(widget.instances, pageSize: size);
                  WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
                }
                _prefs = next;
              });
            },
            pageSizePreference: const CsPageSizePreference(
              options: [
                CsPageSizeOption(value: 10, label: '10 instances'),
                CsPageSizeOption(value: 20, label: '20 instances'),
              ],
            ),
            wrapLinesPreference: const CsCheckboxPreference(),
            stripedRowsPreference: const CsCheckboxPreference(),
          ),
          items: _collection.items,
          columnDefinitions: columns,
          trackBy: (i) => i.id,
          sortingColumn: _collection.sortingColumn,
          sortingDescending: _collection.sortingDescending,
          onSortingChange: _collection.setSorting,
          selectionType: CsSelectionType.multi,
          selectedItems: selected,
          onSelectionChange: _collection.setSelectedItems,
          empty: _collection.emptyState,
          firstIndex: _collection.firstIndex,
          totalItemsCount: _collection.filteredItemsCount,
        );
      },
    );
  }
}

class _LaunchWizard extends StatefulWidget {
  const _LaunchWizard({required this.onCancel, required this.onLaunched});

  final VoidCallback onCancel;
  final void Function(String name, String type) onLaunched;

  @override
  State<_LaunchWizard> createState() => _LaunchWizardState();
}

class _LaunchWizardState extends State<_LaunchWizard> {
  int _step = 0;
  String _name = '';
  String? _nameError;
  CsOption _type = const CsOption(value: 't3.micro', label: 't3.micro', description: '2 vCPU, 1 GiB memory');
  String _image = 'linux';
  bool _monitoring = true;
  bool _submitting = false;

  static const _types = [
    CsOption(value: 't3.micro', label: 't3.micro', description: '2 vCPU, 1 GiB memory'),
    CsOption(value: 't3.medium', label: 't3.medium', description: '2 vCPU, 4 GiB memory'),
    CsOption(value: 'm6g.large', label: 'm6g.large', description: '2 vCPU, 8 GiB memory'),
  ];

  bool _validName() {
    final ok = RegExp(r'^[a-z0-9-]{3,40}$').hasMatch(_name);
    setState(() => _nameError = ok ? null : 'Use 3 to 40 lowercase letters, numbers and hyphens.');
    return ok;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    widget.onLaunched(_name, _type.value);
  }

  @override
  Widget build(BuildContext context) {
    return CsWizard(
      activeStepIndex: _step,
      isLoadingNextStep: _submitting,
      submitButtonText: 'Launch instance',
      onNavigate: (detail) {
        if (_step == 0 && detail.requestedStepIndex > 0 && !_validName()) return;
        setState(() => _step = detail.requestedStepIndex);
      },
      onCancel: widget.onCancel,
      onSubmit: _submit,
      steps: [
        CsWizardStep(
          title: 'Name and image',
          description: 'Instances are sample data; nothing is created.',
          content: CsContainer(
            header: const CsHeader(title: 'Instance details'),
            child: CsSpaceBetween(
              size: CsSpacingSize.l,
              children: [
                CsFormField(
                  label: 'Name',
                  constraintText: 'Use 3 to 40 lowercase letters, numbers and hyphens.',
                  errorText: _nameError,
                  child: CsInput(
                    value: _name,
                    placeholder: 'web-server-2',
                    invalid: _nameError != null,
                    onChange: (v) => setState(() {
                      _name = v;
                      _nameError = null;
                    }),
                  ),
                ),
                CsFormField(
                  label: 'Image',
                  stretch: true,
                  child: CsTiles(
                    value: _image,
                    onChange: (v) => setState(() => _image = v),
                    items: const [
                      CsTilesItem(value: 'linux', label: 'Linux', description: 'A general purpose Linux image.'),
                      CsTilesItem(value: 'windows', label: 'Windows Server', description: 'For .NET workloads.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        CsWizardStep(
          title: 'Instance type',
          content: CsContainer(
            header: const CsHeader(title: 'Size'),
            child: CsSpaceBetween(
              size: CsSpacingSize.l,
              children: [
                CsFormField(
                  label: 'Instance type',
                  child: CsSelect(selectedOption: _type, options: _types, onChange: (o) => setState(() => _type = o)),
                ),
                CsToggle(
                  checked: _monitoring,
                  onChange: (v) => setState(() => _monitoring = v),
                  label: 'Detailed monitoring',
                  description: 'Collect metrics every minute.',
                ),
              ],
            ),
          ),
        ),
        CsWizardStep(
          title: 'Review and launch',
          content: CsContainer(
            header: const CsHeader(title: 'Review'),
            child: CsKeyValuePairs(
              columns: 2,
              items: [
                CsKeyValuePair(label: 'Name', value: _name.isEmpty ? '-' : _name),
                CsKeyValuePair(label: 'Image', value: _image == 'linux' ? 'Linux' : 'Windows Server'),
                CsKeyValuePair(label: 'Instance type', value: _type.value),
                CsKeyValuePair(label: 'Detailed monitoring', value: _monitoring ? 'On' : 'Off'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
