import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// App layout, content layout, containers, headers, column layout, grid,
/// tabs, expandable sections, split panel, drawer, panel layout and help
/// panel. Every name and figure here is sample data.
final CsDemoCategory layoutCategory = CsDemoCategory(
  title: 'Layout',
  description:
      'App layout, content layout, containers, headers, column layout, grid, tabs, expandable sections, split panel and help panel.',
  icon: CsIcons.viewFull,
  demos: [
    CsDemo(
      title: 'CsAppLayout',
      description: 'Navigation, tools, drawers, notifications and a split panel; overlays on phones.',
      docPath: 'doc/components/CsAppLayout.md',
      builder: (_) => const _AppLayoutDemo(toolbar: false),
    ),
    CsDemo(
      title: 'CsAppLayoutToolbar',
      description: 'The toolbar variant: triggers and breadcrumbs in a row along the top.',
      docPath: 'doc/components/CsAppLayoutToolbar.md',
      builder: (_) => const _AppLayoutDemo(toolbar: true),
    ),
    CsDemo(
      title: 'CsContentLayout',
      description: 'Page header variants, overlap, secondary header and a custom background.',
      docPath: 'doc/components/CsContentLayout.md',
      builder: (_) => const _ContentLayoutDemo(),
    ),
    CsDemo(
      title: 'CsContainer',
      description: 'Header, footer, media, stacked containers, fit height and paddings.',
      docPath: 'doc/components/CsContainer.md',
      builder: (_) => const _ContainerDemo(),
    ),
    CsDemo(
      title: 'CsHeader',
      description: 'h1, h2, h3 and sticky h1 with counter, info, description, secondary content and actions.',
      docPath: 'doc/components/CsHeader.md',
      builder: (_) => const _HeaderDemo(),
    ),
    CsDemo(
      title: 'CsColumnLayout',
      description: 'One to four columns, text grid, borders and a minimum column width.',
      docPath: 'doc/components/CsColumnLayout.md',
      builder: (_) => const _ColumnLayoutDemo(),
    ),
    CsDemo(
      title: 'CsGrid',
      description: 'Twelve columns with spans, offsets, push and pull per breakpoint.',
      docPath: 'doc/components/CsGrid.md',
      builder: (_) => const _GridDemo(),
    ),
    CsDemo(
      title: 'CsDivider',
      description: 'Horizontal, labelled and vertical dividers.',
      docPath: 'doc/components/CsDivider.md',
      builder: (_) => const _DividerDemo(),
    ),
    CsDemo(
      title: 'CsExpandableSection',
      description: 'Default, footer, container, stacked, navigation and inline variants.',
      docPath: 'doc/components/CsExpandableSection.md',
      builder: (_) => const _ExpandableDemo(),
    ),
    CsDemo(
      title: 'CsTabs',
      description: 'Default, container and stacked tabs with disabled, dismissible and overflowing tabs.',
      docPath: 'doc/components/CsTabs.md',
      builder: (_) => const _TabsDemo(),
    ),
    CsDemo(
      title: 'CsSplitPanel',
      description: 'Bottom and side split panels in an app layout, collapse and hide.',
      docPath: 'doc/components/CsSplitPanel.md',
      builder: (_) => const _SplitPanelDemo(),
    ),
    CsDemo(
      title: 'CsDrawer',
      description: 'A panel with a header, loading state and sticky footer, inline or over the screen.',
      docPath: 'doc/components/CsDrawer.md',
      builder: (_) => const _DrawerDemo(),
    ),
    CsDemo(
      title: 'CsPanelLayout',
      description: 'A resizable side panel next to main content.',
      docPath: 'doc/components/CsPanelLayout.md',
      builder: (_) => const _PanelLayoutDemo(),
    ),
    CsDemo(
      title: 'CsHelpPanel',
      description: 'Help content with headings, lists, a footer of links and a loading state.',
      docPath: 'doc/components/CsHelpPanel.md',
      builder: (_) => const _HelpPanelDemo(),
    ),
  ],
);

Widget _frame(BuildContext context, Widget child, {double height = 560}) => Container(
  height: height,
  decoration: BoxDecoration(
    border: Border.all(color: context.cs.colors.borderDividerDefault),
    borderRadius: BorderRadius.circular(CsBorderRadius.container),
  ),
  clipBehavior: Clip.antiAlias,
  child: child,
);

Widget _sampleNav(BuildContext context) => Padding(
  padding: const EdgeInsets.all(CsSpace.l),
  child: CsSpaceBetween(
    size: CsSpacingSize.s,
    children: [
      const CsBox(variant: CsBoxVariant.h3, text: 'Compute console'),
      for (final item in ['Instances', 'Launch templates', 'Volumes', 'Snapshots', 'Load balancers'])
        CsLink(text: item, onFollow: () {}),
    ],
  ),
);

Widget _helpPanel() => CsHelpPanel(
  header: 'Instances',
  footer: CsSpaceBetween(
    size: CsSpacingSize.xs,
    children: [
      const CsBox(variant: CsBoxVariant.h3, text: 'Related topics'),
      CsLink(text: 'Launch templates', onFollow: () {}),
      CsLink(text: 'Instance types', onFollow: () {}),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CsHelpPanel.paragraph(
        'An instance is a virtual server. Select an instance to see its details in the split panel.',
      ),
      CsHelpPanel.heading('Instance states'),
      CsHelpPanel.list(const ['Pending', 'Running', 'Stopping', 'Stopped']),
    ],
  ),
);

class _AppLayoutDemo extends StatefulWidget {
  const _AppLayoutDemo({required this.toolbar});

  final bool toolbar;

  @override
  State<_AppLayoutDemo> createState() => _AppLayoutDemoState();
}

class _AppLayoutDemoState extends State<_AppLayoutDemo> {
  bool _nav = true;
  String? _drawer;
  bool _split = false;
  bool? _mobile;
  bool _highContrast = false;
  CsAppLayoutContentType _type = CsAppLayoutContentType.table;
  CsSplitPanelPosition _position = CsSplitPanelPosition.bottom;

  @override
  Widget build(BuildContext context) {
    final drawers = [
      CsAppLayoutDrawer(
        id: 'security',
        icon: CsIcons.security,
        badge: true,
        resizable: true,
        ariaLabels: const CsAppLayoutDrawerLabels(drawerName: 'Security findings'),
        content: CsDrawer(
          header: const Text('Security findings'),
          footer: CsButton(text: 'Review findings', onPress: () {}),
          child: const CsBox(text: '2 findings on i-0abc123 (sample data).'),
        ),
      ),
      const CsAppLayoutDrawer(
        id: 'notes',
        icon: CsIcons.edit,
        ariaLabels: CsAppLayoutDrawerLabels(drawerName: 'Notes'),
        content: CsDrawer(
          header: Text('Notes'),
          child: CsBox(text: 'Rotate keys for example-bucket.'),
        ),
      ),
    ];
    final content = CsSpaceBetween(
      size: CsSpacingSize.l,
      children: [
        CsContainer(
          header: CsHeader(
            title: 'Instances',
            counter: '(3)',
            actions: CsButton(
              text: _split ? 'Hide details' : 'Show details',
              onPress: () => setState(() => _split = !_split),
            ),
          ),
          child: const CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              CsStatusIndicator(text: 'i-0abc123  running'),
              CsStatusIndicator(type: CsStatusType.stopped, text: 'i-0def456  stopped'),
              CsStatusIndicator(type: CsStatusType.pending, text: 'i-0ghi789  pending'),
            ],
          ),
        ),
        const CsContainer(
          child: SizedBox(height: 400, child: CsBox(text: 'Scroll to see the content area move.')),
        ),
      ],
    );
    const splitPanel = CsSplitPanel(
      header: 'i-0abc123',
      headerDescription: 'Running in us-example-1a',
      child: CsColumnLayout(
        columns: 3,
        variant: CsColumnLayoutVariant.textGrid,
        children: [
          CsBox(text: 'Type: t3.micro'),
          CsBox(text: 'Private IP: 10.0.0.12'),
          CsBox(text: 'Launched: 3 days ago'),
        ],
      ),
    );
    final notifications = Container(
      padding: const EdgeInsets.all(CsSpace.s),
      decoration: BoxDecoration(
        color: context.cs.colors.backgroundStatusInfo,
        borderRadius: BorderRadius.circular(CsBorderRadius.flashbar),
      ),
      child: const CsStatusIndicator(type: CsStatusType.info, text: 'Sample notification: maintenance on Sunday.'),
    );
    const breadcrumbs = CsBox(color: CsBoxColor.textBodySecondary, text: 'Compute  /  Instances');
    const header = CsHeader(variant: CsHeaderVariant.h1, title: 'Instances', description: 'Sample data');

    final layout = widget.toolbar
        ? CsAppLayoutToolbar(
            mobile: _mobile,
            contentType: _type,
            navigation: _sampleNav(context),
            navigationOpen: _nav,
            onNavigationChange: (v) => setState(() => _nav = v),
            tools: _helpPanel(),
            drawers: drawers,
            activeDrawerId: _drawer,
            onDrawerChange: (v) => setState(() => _drawer = v),
            breadcrumbs: breadcrumbs,
            notifications: notifications,
            stickyNotifications: true,
            headerVariant: _highContrast
                ? CsAppLayoutHeaderVariant.highContrast
                : CsAppLayoutHeaderVariant.defaultVariant,
            contentHeader: header,
            splitPanel: splitPanel,
            splitPanelOpen: _split,
            onSplitPanelToggle: (v) => setState(() => _split = v),
            splitPanelPosition: _position,
            onSplitPanelPreferencesChange: (v) => setState(() => _position = v),
            content: content,
          )
        : CsAppLayout(
            mobile: _mobile,
            contentType: _type,
            navigation: _sampleNav(context),
            navigationOpen: _nav,
            onNavigationChange: (v) => setState(() => _nav = v),
            tools: _helpPanel(),
            drawers: drawers,
            activeDrawerId: _drawer,
            onDrawerChange: (v) => setState(() => _drawer = v),
            breadcrumbs: breadcrumbs,
            notifications: notifications,
            stickyNotifications: true,
            headerVariant: _highContrast
                ? CsAppLayoutHeaderVariant.highContrast
                : CsAppLayoutHeaderVariant.defaultVariant,
            contentHeader: header,
            splitPanel: splitPanel,
            splitPanelOpen: _split,
            onSplitPanelToggle: (v) => setState(() => _split = v),
            splitPanelPosition: _position,
            onSplitPanelPreferencesChange: (v) => setState(() => _position = v),
            content: content,
          );

    return DemoColumn(
      children: [
        DemoSection(
          title: 'Options',
          caption: 'The layout switches to the phone bar at 688px of its own width; force it here.',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              CsButton(
                text: _mobile == true ? 'Automatic layout' : 'Phone layout',
                onPress: () => setState(() => _mobile = _mobile == true ? null : true),
              ),
              CsButton(
                text: _highContrast ? 'Default header' : 'High-contrast header',
                onPress: () => setState(() => _highContrast = !_highContrast),
              ),
              CsButton(
                text: 'Content type: ${_type.name}',
                onPress: () => setState(
                  () => _type = CsAppLayoutContentType.values[(_type.index + 1) % CsAppLayoutContentType.values.length],
                ),
              ),
              CsButton(text: 'Open help panel', onPress: () => setState(() => _drawer = r'$tools')),
            ],
          ),
        ),
        DemoSection(title: 'Layout', child: _frame(context, layout)),
      ],
    );
  }
}

class _ContentLayoutDemo extends StatefulWidget {
  const _ContentLayoutDemo();

  @override
  State<_ContentLayoutDemo> createState() => _ContentLayoutDemoState();
}

class _ContentLayoutDemoState extends State<_ContentLayoutDemo> {
  CsContentLayoutHeaderVariant _variant = CsContentLayoutHeaderVariant.highContrast;
  bool _overlap = true;

  @override
  Widget build(BuildContext context) {
    Widget page({CsHeaderBackgroundBuilder? background}) => CsContentLayout(
      defaultPadding: true,
      headerVariant: _variant,
      headerBackgroundStyle: background,
      disableOverlap: !_overlap,
      breadcrumbs: const CsBox(color: CsBoxColor.textBodySecondary, text: 'Storage  /  Buckets'),
      header: CsHeader(
        variant: CsHeaderVariant.h1,
        title: 'example-bucket',
        description: 'Sample bucket in us-example-1',
        actions: CsButton(text: 'Upload', variant: CsButtonVariant.primary, onPress: () {}),
      ),
      secondaryHeader: const CsContainer(child: CsBox(text: '1,204 objects, 3.2 GB')),
      child: const CsContainer(
        header: CsHeader(title: 'Objects'),
        child: CsBox(text: 'reports/2026-11.csv'),
      ),
    );
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Header variant',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              for (final v in CsContentLayoutHeaderVariant.values)
                CsButton(
                  text: v.name,
                  variant: v == _variant ? CsButtonVariant.primary : CsButtonVariant.normal,
                  onPress: () => setState(() => _variant = v),
                ),
              CsButton(
                text: _overlap ? 'Disable overlap' : 'Enable overlap',
                onPress: () => setState(() => _overlap = !_overlap),
              ),
            ],
          ),
        ),
        DemoSection(title: 'Page', child: page()),
        DemoSection(
          title: 'Custom header background',
          child: page(
            background: (b) => BoxDecoration(
              gradient: LinearGradient(
                colors: b == Brightness.dark
                    ? const [Color(0xFF0F1B2A), Color(0xFF1B2D44)]
                    : const [Color(0xFFE8F1FB), Color(0xFFF7FAFD)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContainerDemo extends StatefulWidget {
  const _ContainerDemo();

  @override
  State<_ContainerDemo> createState() => _ContainerDemoState();
}

class _ContainerDemoState extends State<_ContainerDemo> {
  int _edits = 0;

  @override
  Widget build(BuildContext context) {
    final media = ColoredBox(
      color: context.cs.colors.backgroundContainerHeader,
      child: const Center(child: CsIcon(CsIcons.globe, size: CsIconSize.large)),
    );
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Header, content and footer',
          child: CsContainer(
            header: const CsHeader(title: 'Distribution settings', description: 'd111111abcdef8'),
            footer: CsButton(text: 'Edit settings ($_edits)', onPress: () => setState(() => _edits++)),
            child: const CsBox(text: 'Price class: use all edge locations'),
          ),
        ),
        const DemoSection(
          title: 'Stacked',
          child: Column(
            children: [
              CsContainer(
                variant: CsContainerVariant.stacked,
                stackPosition: CsStackPosition.first,
                header: CsHeader(title: 'Origin'),
                child: CsBox(text: 'example-bucket'),
              ),
              CsContainer(
                variant: CsContainerVariant.stacked,
                stackPosition: CsStackPosition.middle,
                header: CsHeader(title: 'Behaviors'),
                child: CsBox(text: 'Default (*)'),
              ),
              CsContainer(
                variant: CsContainerVariant.stacked,
                stackPosition: CsStackPosition.last,
                header: CsHeader(title: 'Tags'),
                child: CsBox(text: 'environment: test'),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Media',
          caption: 'Side media moves to the top on phones.',
          child: CsSpaceBetween(
            size: CsSpacingSize.l,
            children: [
              CsContainer(
                media: CsContainerMedia(content: media, height: 120),
                header: const CsHeader(title: 'Top media'),
                child: const CsBox(text: 'A sample illustration above the header.'),
              ),
              CsContainer(
                media: CsContainerMedia(content: media, position: CsContainerMediaPosition.side, width: 160),
                header: const CsHeader(title: 'Side media'),
                child: const CsBox(text: 'A sample illustration at the start.'),
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Fit height',
          child: SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CsContainer(
                    fitHeight: true,
                    header: CsHeader(title: 'Requests'),
                    child: CsBox(text: '1,024'),
                  ),
                ),
                SizedBox(width: CsSpace.l),
                Expanded(
                  child: CsContainer(
                    fitHeight: true,
                    header: CsHeader(title: 'Errors'),
                    child: CsBox(text: '3'),
                  ),
                ),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Without content paddings',
          child: CsContainer(
            header: const CsHeader(title: 'Map'),
            disableContentPaddings: true,
            child: SizedBox(height: 80, child: ColoredBox(color: context.cs.colors.backgroundContainerHeader)),
          ),
        ),
      ],
    );
  }
}

class _HeaderDemo extends StatelessWidget {
  const _HeaderDemo();

  @override
  Widget build(BuildContext context) {
    final actions = CsSpaceBetween(
      direction: CsSpaceBetweenDirection.horizontal,
      size: CsSpacingSize.xs,
      children: [
        CsButton(text: 'Delete', onPress: () {}),
        CsButton(text: 'Create distribution', variant: CsButtonVariant.primary, onPress: () {}),
      ],
    );
    final info = CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: () {});
    return DemoColumn(
      children: [
        DemoSection(
          title: 'h1',
          child: CsHeader(
            variant: CsHeaderVariant.h1,
            title: 'Distributions',
            counter: '(24)',
            info: info,
            description: 'Sample distributions in this account.',
            actions: actions,
          ),
        ),
        DemoSection(
          title: 'h2 with secondary content',
          child: CsHeader(
            title: 'Origins',
            counter: '(2)',
            secondaryContent: const CsStatusIndicator(text: 'Healthy'),
            actions: CsButton(text: 'Add origin', onPress: () {}),
          ),
        ),
        DemoSection(
          title: 'h3',
          child: CsHeader(variant: CsHeaderVariant.h3, title: 'Cache key', info: info),
        ),
        const DemoSection(
          title: 'Sticky h1, stuck',
          caption: 'Tables set CsHeaderStickyScope while their header is stuck.',
          child: CsHeaderStickyScope(
            stuck: true,
            child: CsHeader(
              variant: CsHeaderVariant.awsuiH1Sticky,
              title: 'Instances',
              description: 'Hidden while stuck',
            ),
          ),
        ),
      ],
    );
  }
}

class _ColumnLayoutDemo extends StatefulWidget {
  const _ColumnLayoutDemo();

  @override
  State<_ColumnLayoutDemo> createState() => _ColumnLayoutDemoState();
}

class _ColumnLayoutDemoState extends State<_ColumnLayoutDemo> {
  int _columns = 3;
  CsColumnLayoutBorders _borders = CsColumnLayoutBorders.none;

  @override
  Widget build(BuildContext context) {
    const pairs = [
      ('Instance ID', 'i-0abc123'),
      ('Status', 'Running'),
      ('Type', 't3.micro'),
      ('Zone', 'us-example-1a'),
      ('Private IP', '10.0.0.12'),
      ('Launched', '3 days ago'),
    ];
    final items = [
      for (final p in pairs)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CsBox(variant: CsBoxVariant.awsuiKeyLabel, text: p.$1),
            CsBox(text: p.$2),
          ],
        ),
    ];
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Columns and borders',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              for (var i = 1; i <= 4; i++)
                CsButton(
                  text: '$i',
                  variant: i == _columns ? CsButtonVariant.primary : CsButtonVariant.normal,
                  onPress: () => setState(() => _columns = i),
                ),
              for (final b in CsColumnLayoutBorders.values)
                CsButton(
                  text: b.name,
                  variant: b == _borders ? CsButtonVariant.primary : CsButtonVariant.normal,
                  onPress: () => setState(() => _borders = b),
                ),
            ],
          ),
        ),
        DemoSection(
          title: 'Default',
          child: CsColumnLayout(columns: _columns, borders: _borders, children: items),
        ),
        DemoSection(
          title: 'Text grid',
          child: CsColumnLayout(columns: _columns, variant: CsColumnLayoutVariant.textGrid, children: items),
        ),
        DemoSection(
          title: 'Minimum column width 160px',
          caption: 'Fits up to six columns, keeping an even count when it wraps.',
          child: CsColumnLayout(columns: 6, minColumnWidth: 160, borders: _borders, children: items),
        ),
      ],
    );
  }
}

class _GridDemo extends StatelessWidget {
  const _GridDemo();

  @override
  Widget build(BuildContext context) {
    Widget cell(String text) => Container(
      padding: const EdgeInsets.all(CsSpace.s),
      decoration: BoxDecoration(
        color: context.cs.colors.backgroundContainerHeader,
        borderRadius: BorderRadius.circular(CsBorderRadius.item),
      ),
      child: CsBox(text: text),
    );
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Responsive spans',
          caption: 'Full width under 688px, 8 + 4 above.',
          child: CsGrid(
            gridDefinition: const [
              CsGridDefinition(colspan: {CsBreakpoint.base: 12, CsBreakpoint.xs: 8}),
              CsGridDefinition(colspan: {CsBreakpoint.base: 12, CsBreakpoint.xs: 4}),
            ],
            children: [cell('Main (8)'), cell('Aside (4)')],
          ),
        ),
        DemoSection(
          title: 'Thirds',
          child: CsGrid(
            gridDefinition: const [
              CsGridDefinition.all(colspan: 4),
              CsGridDefinition.all(colspan: 4),
              CsGridDefinition.all(colspan: 4),
            ],
            children: [cell('4'), cell('4'), cell('4')],
          ),
        ),
        DemoSection(
          title: 'Offset',
          child: CsGrid(
            gridDefinition: const [CsGridDefinition.all(colspan: 6, offset: 3)],
            children: [cell('6, offset 3')],
          ),
        ),
        DemoSection(
          title: 'Push and pull',
          child: CsGrid(
            gridDefinition: const [
              CsGridDefinition.all(colspan: 6, push: 6),
              CsGridDefinition.all(colspan: 6, pull: 6),
            ],
            children: [cell('First in order'), cell('Second in order')],
          ),
        ),
        DemoSection(
          title: 'No gutters',
          child: CsGrid(
            disableGutters: true,
            gridDefinition: const [CsGridDefinition.all(colspan: 6), CsGridDefinition.all(colspan: 6)],
            children: [cell('6'), cell('6')],
          ),
        ),
      ],
    );
  }
}

class _DividerDemo extends StatelessWidget {
  const _DividerDemo();

  @override
  Widget build(BuildContext context) => const DemoColumn(
    children: [
      DemoSection(title: 'Horizontal', child: CsDivider()),
      DemoSection(
        title: 'With label',
        child: CsDivider(label: 'or'),
      ),
      DemoSection(
        title: 'Vertical',
        child: SizedBox(
          height: 24,
          child: Row(
            spacing: CsSpace.s,
            children: [
              CsBox(text: 'Edit'),
              CsDivider(orientation: CsDividerOrientation.vertical),
              CsBox(text: 'Copy'),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ExpandableDemo extends StatefulWidget {
  const _ExpandableDemo();

  @override
  State<_ExpandableDemo> createState() => _ExpandableDemoState();
}

class _ExpandableDemoState extends State<_ExpandableDemo> {
  bool _controlled = true;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        const DemoSection(
          title: 'Default',
          child: CsExpandableSection(
            headerText: 'Additional settings',
            headerDescription: 'Metadata and monitoring',
            child: CsBox(text: 'Detailed monitoring: off'),
          ),
        ),
        DemoSection(
          title: 'Controlled container',
          caption: 'Expanded: $_controlled',
          child: CsExpandableSection(
            variant: CsExpandableSectionVariant.container,
            headerText: 'Tags',
            headerCounter: '(2)',
            headerDescription: 'Labels for cost allocation',
            headerInfo: CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: () {}),
            headerActions: CsButton(text: 'Manage tags', onPress: () {}),
            expanded: _controlled,
            onChange: (v) => setState(() => _controlled = v),
            child: const CsBox(text: 'environment: test, team: storage'),
          ),
        ),
        const DemoSection(
          title: 'Stacked',
          child: Column(
            children: [
              CsExpandableSection(
                variant: CsExpandableSectionVariant.stacked,
                stackPosition: CsStackPosition.first,
                headerText: 'Network',
                child: CsBox(text: 'vpc-0abc123'),
              ),
              CsExpandableSection(
                variant: CsExpandableSectionVariant.stacked,
                stackPosition: CsStackPosition.last,
                headerText: 'Storage',
                child: CsBox(text: 'vol-0abc123, 8 GiB'),
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Footer',
          child: CsExpandableSection(
            variant: CsExpandableSectionVariant.footer,
            headerText: 'Advanced options',
            child: CsBox(text: 'Termination protection: on'),
          ),
        ),
        const DemoSection(
          title: 'Navigation',
          caption: 'Only the caret toggles.',
          child: CsExpandableSection(
            variant: CsExpandableSectionVariant.navigation,
            headerText: 'Images',
            defaultExpanded: true,
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: CsSpace.l),
              child: CsBox(text: 'AMIs, AMI catalog'),
            ),
          ),
        ),
        const DemoSection(
          title: 'Inline',
          child: CsExpandableSection(
            variant: CsExpandableSectionVariant.inline,
            headerText: 'Show command',
            child: CsBox(variant: CsBoxVariant.code, text: 'describe-instances --instance-ids i-0abc123'),
          ),
        ),
      ],
    );
  }
}

class _TabsDemo extends StatefulWidget {
  const _TabsDemo();

  @override
  State<_TabsDemo> createState() => _TabsDemoState();
}

class _TabsDemoState extends State<_TabsDemo> {
  String _active = 'details';
  final List<String> _logs = ['Access log', 'Error log', 'Audit log'];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const CsTab(
        id: 'details',
        label: 'Details',
        content: CsBox(text: 'Instance i-0abc123, t3.micro'),
      ),
      const CsTab(
        id: 'monitoring',
        label: 'Monitoring',
        content: CsBox(text: 'CPU 12%, network 3 MB/s'),
      ),
      const CsTab(
        id: 'security',
        label: 'Security',
        disabled: true,
        disabledReason: 'You need permission to view security groups.',
      ),
      for (final l in _logs)
        CsTab(
          id: l,
          label: l,
          dismissible: true,
          onDismiss: () => setState(() {
            _logs.remove(l);
            if (_active == l) _active = 'details';
          }),
          content: CsBox(text: '$l: 0 entries (sample)'),
        ),
    ];
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Default',
          caption: 'Active: $_active. Swipe the content on touch screens.',
          child: CsTabs(
            tabs: tabs,
            activeTabId: _active,
            onChange: (id) => setState(() => _active = id),
            swipeable: true,
          ),
        ),
        DemoSection(
          title: 'Container with actions',
          child: CsTabs(
            variant: CsTabsVariant.container,
            actions: CsButton(
              variant: CsButtonVariant.icon,
              icon: CsIcons.refresh,
              semanticLabel: 'Refresh',
              onPress: () {},
            ),
            tabs: const [
              CsTab(
                id: 'a',
                label: 'Origins',
                content: CsBox(text: 'example-bucket'),
              ),
              CsTab(
                id: 'b',
                label: 'Behaviors',
                content: CsBox(text: 'Default (*)'),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Overflowing',
          caption: 'Scroll arrows appear when the tabs do not fit.',
          child: CsTabs(
            tabs: [
              for (var i = 1; i <= 10; i++)
                CsTab(
                  id: '$i',
                  label: 'Distribution $i',
                  content: CsBox(text: 'd11111$i (sample)'),
                ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Stacked',
          child: CsTabs(
            variant: CsTabsVariant.stacked,
            tabs: [
              CsTab(
                id: 'a',
                label: 'Inbound',
                content: CsBox(text: '2 rules'),
              ),
              CsTab(
                id: 'b',
                label: 'Outbound',
                content: CsBox(text: '1 rule'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SplitPanelDemo extends StatefulWidget {
  const _SplitPanelDemo();

  @override
  State<_SplitPanelDemo> createState() => _SplitPanelDemoState();
}

class _SplitPanelDemoState extends State<_SplitPanelDemo> {
  bool _open = true;
  double _size = 220;
  CsSplitPanelPosition _position = CsSplitPanelPosition.bottom;
  CsSplitPanelCloseBehavior _behavior = CsSplitPanelCloseBehavior.collapse;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Options',
          caption: 'Position: ${_position.name}, size: ${_size.round()}px, open: $_open',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              CsButton(text: _open ? 'Close' : 'Open', onPress: () => setState(() => _open = !_open)),
              CsButton(
                text: 'Close behavior: ${_behavior.name}',
                onPress: () => setState(
                  () => _behavior = _behavior == CsSplitPanelCloseBehavior.collapse
                      ? CsSplitPanelCloseBehavior.hide
                      : CsSplitPanelCloseBehavior.collapse,
                ),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'In an app layout',
          child: _frame(
            context,
            CsAppLayout(
              navigationHide: true,
              toolsHide: true,
              splitPanelOpen: _open,
              onSplitPanelToggle: (v) => setState(() => _open = v),
              splitPanelSize: _size,
              onSplitPanelResize: (v) => setState(() => _size = v),
              splitPanelPosition: _position,
              onSplitPanelPreferencesChange: (v) => setState(() => _position = v),
              splitPanel: CsSplitPanel(
                header: 'example-bucket',
                headerDescription: 'Sample bucket details',
                closeBehavior: _behavior,
                headerActions: CsButton(text: 'Edit', onPress: () {}),
                child: const CsColumnLayout(
                  columns: 2,
                  variant: CsColumnLayoutVariant.textGrid,
                  children: [
                    CsBox(text: 'Region: us-example-1'),
                    CsBox(text: 'Versioning: on'),
                  ],
                ),
              ),
              content: const CsContainer(
                header: CsHeader(title: 'Buckets'),
                child: CsBox(text: 'example-bucket'),
              ),
            ),
            height: 480,
          ),
        ),
        const DemoSection(
          title: 'Standalone',
          child: CsSplitPanel(
            header: 'i-0abc123',
            child: CsBox(text: 'Instance details'),
          ),
        ),
      ],
    );
  }
}

class _DrawerDemo extends StatefulWidget {
  const _DrawerDemo();

  @override
  State<_DrawerDemo> createState() => _DrawerDemoState();
}

class _DrawerDemoState extends State<_DrawerDemo> {
  bool _open = false;
  bool _loading = false;
  String _lastClose = 'none';

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Inline with sticky footer',
          child: _frame(
            context,
            CsDrawer(
              header: const Text('Instance details'),
              headerActions: CsButton(
                variant: CsButtonVariant.icon,
                icon: CsIcons.refresh,
                semanticLabel: 'Refresh',
                onPress: () async {
                  setState(() => _loading = true);
                  await Future<void>.delayed(const Duration(seconds: 2));
                  if (mounted) setState(() => _loading = false);
                },
              ),
              loading: _loading,
              footer: CsButton(text: 'Stop instance', onPress: () {}),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (var i = 0; i < 20; i++) CsBox(text: 'Attribute $i: value (sample)')],
              ),
            ),
            height: 320,
          ),
        ),
        DemoSection(
          title: 'Over the screen',
          caption: 'Last close: $_lastClose',
          child: Row(
            children: [
              CsButton(text: 'Open filters', onPress: () => setState(() => _open = true)),
              CsDrawer(
                position: CsDrawerPosition.fixed,
                open: _open,
                backdrop: true,
                header: const Text('Filters'),
                onClose: (m) => setState(() {
                  _open = false;
                  _lastClose = m.name;
                }),
                footer: CsButton(
                  text: 'Apply filters',
                  variant: CsButtonVariant.primary,
                  onPress: () => setState(() => _open = false),
                ),
                child: const CsBox(text: 'State: running, Zone: us-example-1a'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelLayoutDemo extends StatefulWidget {
  const _PanelLayoutDemo();

  @override
  State<_PanelLayoutDemo> createState() => _PanelLayoutDemoState();
}

class _PanelLayoutDemoState extends State<_PanelLayoutDemo> {
  double _size = 220;
  CsPanelPosition _position = CsPanelPosition.sideStart;
  CsPanelLayoutDisplay _display = CsPanelLayoutDisplay.all;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Options',
          caption: 'Panel ${_size.round()}px. Drag the handle or use the arrow keys on it.',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              CsButton(
                text: 'Panel at ${_position == CsPanelPosition.sideStart ? 'end' : 'start'}',
                onPress: () => setState(
                  () => _position = _position == CsPanelPosition.sideStart
                      ? CsPanelPosition.sideEnd
                      : CsPanelPosition.sideStart,
                ),
              ),
              for (final d in CsPanelLayoutDisplay.values)
                CsButton(
                  text: d.name,
                  variant: d == _display ? CsButtonVariant.primary : CsButtonVariant.normal,
                  onPress: () => setState(() => _display = d),
                ),
            ],
          ),
        ),
        DemoSection(
          title: 'Panel layout',
          child: _frame(
            context,
            CsPanelLayout(
              resizable: true,
              scrollable: true,
              panelPosition: _position,
              display: _display,
              panelSize: _size,
              minPanelSize: 150,
              maxPanelSize: 400,
              onPanelResize: (d) => setState(() => _size = d.panelSize),
              panelContent: const Padding(
                padding: EdgeInsets.all(CsSpace.l),
                child: CsSpaceBetween(
                  size: CsSpacingSize.xs,
                  children: [
                    CsBox(variant: CsBoxVariant.h3, text: 'Filters'),
                    CsBox(text: 'State: running'),
                    CsBox(text: 'Type: t3.micro'),
                  ],
                ),
              ),
              mainContent: const Padding(
                padding: EdgeInsets.all(CsSpace.l),
                child: CsBox(text: '3 matching instances (sample data)'),
              ),
            ),
            height: 260,
          ),
        ),
      ],
    );
  }
}

class _HelpPanelDemo extends StatefulWidget {
  const _HelpPanelDemo();

  @override
  State<_HelpPanelDemo> createState() => _HelpPanelDemoState();
}

class _HelpPanelDemoState extends State<_HelpPanelDemo> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Help panel',
          child: CsContainer(disableContentPaddings: true, child: _helpPanel()),
        ),
        DemoSection(
          title: 'Loading',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CsButton(
                text: _loading ? 'Stop loading' : 'Show loading',
                onPress: () => setState(() => _loading = !_loading),
              ),
              if (_loading)
                const CsContainer(
                  disableContentPaddings: true,
                  child: CsHelpPanel(loading: true, loadingText: 'Loading help content'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
