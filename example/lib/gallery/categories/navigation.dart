import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// Top and side navigation, breadcrumbs, anchor navigation, pagination,
/// links, wizard, steps and tree view. Every name and figure here is sample
/// data.
final CsDemoCategory navigationCategory = CsDemoCategory(
  title: 'Navigation',
  description:
      'Top and side navigation, breadcrumbs, anchor navigation, pagination, links, wizard, steps and tree view.',
  icon: CsIcons.menu,
  demos: [
    CsDemo(
      title: 'CsTopNavigation',
      description: 'Identity, search and utilities with badges and menus; collapses into a More menu on narrow widths.',
      docPath: 'doc/components/CsTopNavigation.md',
      builder: (_) => const _TopNavigationDemo(),
    ),
    CsDemo(
      title: 'CsSideNavigation',
      description: 'Links, sections, section groups, link groups, expandable groups, dividers, info and an icon rail.',
      docPath: 'doc/components/CsSideNavigation.md',
      builder: (_) => const _SideNavigationDemo(),
    ),
    CsDemo(
      title: 'CsBreadcrumbGroup',
      description: 'The path to the current page, collapsing into an ellipsis menu when space runs out.',
      docPath: 'doc/components/CsBreadcrumbGroup.md',
      builder: (_) => const _BreadcrumbDemo(),
    ),
    CsDemo(
      title: 'CsAnchorNavigation',
      description: 'A table of contents that follows the scroll position of a page.',
      docPath: 'doc/components/CsAnchorNavigation.md',
      builder: (_) => const _AnchorNavigationDemo(),
    ),
    CsDemo(
      title: 'CsPagination',
      description: 'Page numbers with ellipses, open-ended loading, compact form and jump to page.',
      docPath: 'doc/components/CsPagination.md',
      builder: (_) => const _PaginationDemo(),
    ),
    CsDemo(
      title: 'CsLink',
      description: 'Secondary, primary, info and large value links, external and inverted.',
      docPath: 'doc/components/CsLink.md',
      builder: (_) => const _LinkDemo(),
    ),
    CsDemo(
      title: 'CsWizard',
      description: 'A launch flow with optional steps, skip-to, validation and a collapsed step list on phones.',
      docPath: 'doc/components/CsWizard.md',
      builder: (_) => const _WizardDemo(),
    ),
    CsDemo(
      title: 'CsSteps',
      description: 'Statuses of a deployment, vertical and horizontal, with annotations.',
      docPath: 'doc/components/CsSteps.md',
      builder: (_) => const _StepsDemo(),
    ),
    CsDemo(
      title: 'CsTreeView',
      description: 'Bucket prefixes and objects with connector lines, actions and keyboard navigation.',
      docPath: 'doc/components/CsTreeView.md',
      builder: (_) => const _TreeViewDemo(),
    ),
  ],
);

/// A line of small print under a demo: what the last interaction did.
class _Result extends StatelessWidget {
  const _Result(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      CsBox(variant: CsBoxVariant.small, color: CsBoxColor.textBodySecondary, text: text);
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.cs.colors.backgroundControlChecked,
      borderRadius: BorderRadius.circular(CsBorderRadius.item),
    ),
    child: CsIcon(CsIcons.globe, dangerouslySetColor: context.cs.colors.textInverted),
  );
}

class _TopNavigationDemo extends StatefulWidget {
  const _TopNavigationDemo();

  @override
  State<_TopNavigationDemo> createState() => _TopNavigationDemoState();
}

class _TopNavigationDemoState extends State<_TopNavigationDemo> {
  String _query = '';
  String _last = 'Nothing chosen yet';
  double _width = 1;

  List<CsTopNavigationUtility> get _utilities => [
    CsTopNavigationButton(
      text: 'Create resource',
      variant: CsTopNavigationButtonVariant.primaryButton,
      onClick: () => setState(() => _last = 'Create resource'),
    ),
    CsTopNavigationButton(
      text: 'Docs',
      href: '/docs',
      external: true,
      externalIconAriaLabel: 'Opens in a new tab',
      onFollow: () => setState(() => _last = 'Docs'),
    ),
    CsTopNavigationButton(
      icon: CsIcons.notification,
      ariaLabel: 'Notifications (3 unread)',
      badge: true,
      disableUtilityCollapse: true,
      onClick: () => setState(() => _last = 'Notifications'),
    ),
    CsTopNavigationMenuDropdown(
      icon: CsIcons.settings,
      ariaLabel: 'Settings',
      title: 'Settings',
      items: const [
        CsTopNavigationMenuItem(id: 'preferences', text: 'Preferences'),
        CsTopNavigationMenuItem(id: 'region', text: 'Region', description: 'us-east-1'),
      ],
      onItemClick: (item) => setState(() => _last = 'Settings: ${item.text}'),
    ),
    CsTopNavigationMenuDropdown(
      icon: CsIcons.userProfile,
      text: 'Account',
      description: 'jane.doe@example.com',
      items: const [
        CsTopNavigationMenuItem(id: 'profile', text: 'Profile'),
        CsTopNavigationMenuItem(id: 'security', text: 'Security credentials'),
        CsTopNavigationMenuItem(
          id: 'support',
          text: 'Support',
          items: [
            CsTopNavigationMenuItem(id: 'docs', text: 'Documentation', href: '/docs', external: true),
            CsTopNavigationMenuItem(id: 'feedback', text: 'Feedback', href: '/feedback'),
          ],
        ),
        CsTopNavigationMenuItem(id: 'signout', text: 'Sign out'),
      ],
      onItemClick: (item) => setState(() => _last = 'User menu: ${item.text}'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Full bar',
          caption: 'Drag the width to watch texts hide, search turn into a button and utilities move into More.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.s,
            children: [
              CsSpaceBetween(
                direction: CsSpaceBetweenDirection.horizontal,
                size: CsSpacingSize.xs,
                children: [
                  for (final w in const [(0.4, '40%'), (0.7, '70%'), (1.0, '100%')])
                    CsButton(
                      text: 'Width ${w.$2}',
                      variant: _width == w.$1 ? CsButtonVariant.primary : CsButtonVariant.normal,
                      onPress: () => setState(() => _width = w.$1),
                    ),
                ],
              ),
              LayoutBuilder(
                builder: (context, constraints) => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    width: constraints.maxWidth * _width,
                    child: CsTopNavigation(
                      identity: CsTopNavigationIdentity(
                        href: '/',
                        title: 'Cloud console',
                        logo: const _LogoMark(),
                        onFollow: () => setState(() => _last = 'Home'),
                      ),
                      search: CsInput(
                        value: _query,
                        type: CsInputType.search,
                        placeholder: 'Search resources',
                        ariaLabel: 'Search resources',
                        onChange: (v) => setState(() => _query = v),
                      ),
                      utilities: _utilities,
                    ),
                  ),
                ),
              ),
              _Result('Last action: $_last'),
            ],
          ),
        ),
        const DemoSection(
          title: 'Identity only, page colors',
          caption: 'visualContext: none follows light and dark mode.',
          child: CsTopNavigation(
            visualContext: CsTopNavigationVisualContext.none,
            identity: CsTopNavigationIdentity(href: '/', title: 'Service console'),
          ),
        ),
      ],
    );
  }
}

class _SideNavigationDemo extends StatefulWidget {
  const _SideNavigationDemo();

  @override
  State<_SideNavigationDemo> createState() => _SideNavigationDemoState();
}

class _SideNavigationDemoState extends State<_SideNavigationDemo> {
  String _active = '/buckets';
  String _change = 'No section toggled yet';
  bool _collapsed = false;

  static const _items = <CsSideNavigationItem>[
    CsSideNavigationLink(text: 'Dashboard', href: '/dashboard'),
    CsSideNavigationSection(
      text: 'Storage',
      items: [
        CsSideNavigationLink(text: 'Buckets', href: '/buckets'),
        CsSideNavigationLink(
          text: 'Access points',
          href: '/access-points',
          info: CsBadge(text: 'New', color: CsBadgeColor.blue),
        ),
        CsSideNavigationLink(text: 'Batch operations', href: '/batch'),
      ],
    ),
    CsSideNavigationExpandableLinkGroup(
      text: 'Instances',
      href: '/instances',
      items: [
        CsSideNavigationLink(text: 'Launch templates', href: '/launch-templates'),
        CsSideNavigationLink(text: 'Spot requests', href: '/spot-requests'),
      ],
    ),
    CsSideNavigationLinkGroup(
      text: 'Distributions',
      href: '/distributions',
      items: [
        CsSideNavigationLink(text: 'Origins', href: '/origins'),
        CsSideNavigationLink(text: 'Behaviors', href: '/behaviors'),
      ],
    ),
    CsSideNavigationSectionGroup(
      title: 'Account',
      items: [
        CsSideNavigationLink(text: 'Settings', href: '/settings'),
        CsSideNavigationSection(
          text: 'Billing',
          defaultExpanded: false,
          items: [CsSideNavigationLink(text: 'Invoices', href: '/invoices')],
        ),
      ],
    ),
    CsSideNavigationDivider(),
    CsSideNavigationLink(text: 'Documentation', href: 'https://example.com/docs', external: true),
  ];

  static const _iconItems = <CsSideNavigationItem>[
    CsSideNavigationLink(text: 'Dashboard', href: '/dashboard', icon: CsIcons.gridView),
    CsSideNavigationLink(text: 'Buckets', href: '/buckets', icon: CsIcons.folder),
    CsSideNavigationLink(text: 'Notifications', href: '/notifications', icon: CsIcons.notification),
    CsSideNavigationExpandableLinkGroup(
      text: 'Security',
      href: '/security',
      icon: CsIcons.security,
      items: [CsSideNavigationLink(text: 'Keys', href: '/keys')],
    ),
    CsSideNavigationDivider(),
    CsSideNavigationLink(text: 'Settings', href: '/settings', icon: CsIcons.settings),
  ];

  void _follow(CsSideNavigationFollowDetail d) {
    if (!d.external) setState(() => _active = d.href);
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Every item type',
          caption: 'Active page: $_active. $_change.',
          child: CsContainer(
            disableContentPaddings: true,
            child: CsSideNavigation(
              header: const CsSideNavigationHeader(text: 'Storage service', href: '/'),
              activeHref: _active,
              items: _items,
              onFollow: _follow,
              onChange: (d) => setState(
                () => _change =
                    '${d.expanded ? 'Expanded' : 'Collapsed'} ${switch (d.item) {
                      CsSideNavigationSection(:final text) => text,
                      CsSideNavigationExpandableLinkGroup(:final text) => text,
                      _ => 'item',
                    }}',
              ),
            ),
          ),
        ),
        DemoSection(
          title: 'With icons, and the icon rail',
          caption: 'Collapsed shows only items with icons; their names show in tooltips.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CsSpace.s,
            children: [
              CsButton(
                text: _collapsed ? 'Expand navigation' : 'Collapse navigation',
                icon: _collapsed ? CsIcons.angleRight : CsIcons.angleLeft,
                onPress: () => setState(() => _collapsed = !_collapsed),
              ),
              CsContainer(
                disableContentPaddings: true,
                child: SizedBox(
                  width: _collapsed ? CsSize.sideNavigationCollapsedWidth : null,
                  child: CsSideNavigation(
                    header: const CsSideNavigationHeader(text: 'Console', href: '/', logo: _LogoMark()),
                    collapsed: _collapsed,
                    activeHref: _active,
                    items: _iconItems,
                    onFollow: _follow,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreadcrumbDemo extends StatefulWidget {
  const _BreadcrumbDemo();

  @override
  State<_BreadcrumbDemo> createState() => _BreadcrumbDemoState();
}

class _BreadcrumbDemoState extends State<_BreadcrumbDemo> {
  String _followed = 'None';

  static const _path = [
    CsBreadcrumbGroupItem(text: 'Storage service', href: '/'),
    CsBreadcrumbGroupItem(text: 'Buckets', href: '/buckets'),
    CsBreadcrumbGroupItem(text: 'example-bucket', href: '/buckets/example-bucket'),
    CsBreadcrumbGroupItem(text: 'logs/', href: '/buckets/example-bucket/logs'),
    CsBreadcrumbGroupItem(text: 'Object properties', href: '/buckets/example-bucket/logs/properties'),
  ];

  @override
  Widget build(BuildContext context) {
    void follow(CsBreadcrumbGroupItem item) => setState(() => _followed = item.href);
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Full width',
          child: CsBreadcrumbGroup(items: _path, onFollow: follow),
        ),
        DemoSection(
          title: 'Collapsed into an ellipsis',
          caption: 'Middle items move into the menu behind the ellipsis.',
          child: SizedBox(
            width: 360,
            child: CsBreadcrumbGroup(items: _path, onFollow: follow),
          ),
        ),
        DemoSection(
          title: 'Narrowest form',
          caption: 'Only the current page title, which opens the whole path.',
          child: SizedBox(
            width: 180,
            child: CsBreadcrumbGroup(items: _path, onFollow: follow),
          ),
        ),
        _Result('Last followed: $_followed'),
      ],
    );
  }
}

class _AnchorNavigationDemo extends StatefulWidget {
  const _AnchorNavigationDemo();

  @override
  State<_AnchorNavigationDemo> createState() => _AnchorNavigationDemoState();
}

class _AnchorNavigationDemoState extends State<_AnchorNavigationDemo> {
  static const _anchors = [
    CsAnchorNavigationAnchor(text: 'Overview', href: '#overview'),
    CsAnchorNavigationAnchor(text: 'Pricing', href: '#pricing'),
    CsAnchorNavigationAnchor(text: 'On-demand', href: '#on-demand', level: 2),
    CsAnchorNavigationAnchor(text: 'Reserved capacity', href: '#reserved', level: 2, info: 'Updated'),
    CsAnchorNavigationAnchor(text: 'Limits', href: '#limits'),
    CsAnchorNavigationAnchor(text: 'Related resources', href: '#related'),
  ];

  final ScrollController _controller = ScrollController();
  final Map<String, GlobalKey> _keys = {for (final a in _anchors) a.href: GlobalKey()};
  late final CsAnchorScrollSpy _spy = CsAnchorScrollSpy(controller: _controller, sections: _keys);
  String _active = '#overview';

  @override
  void dispose() {
    _spy.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = CsAnchorNavigation(
      anchors: _anchors,
      scrollSpy: _spy,
      onActiveHrefChange: (a) => setState(() => _active = a.href),
    );
    final page = SizedBox(
      height: 360,
      child: SingleChildScrollView(
        controller: _controller,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CsSpace.m,
          children: [
            for (final a in _anchors)
              CsContainer(
                key: _keys[a.href],
                header: CsHeader(variant: a.level == 1 ? CsHeaderVariant.h2 : CsHeaderVariant.h3, title: a.text),
                child: const SizedBox(
                  height: 140,
                  child: CsBox(
                    color: CsBoxColor.textBodySecondary,
                    text: 'Sample section content for the instance type documentation.',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Following the scroll position',
          caption: 'Scroll the page or follow an anchor. Active: $_active',
          child: LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth < 560
                ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: CsSpace.m, children: [nav, page])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: CsSpace.l,
                    children: [
                      Expanded(child: page),
                      SizedBox(width: 220, child: nav),
                    ],
                  ),
          ),
        ),
        const DemoSection(
          title: 'Controlled',
          caption: 'activeHref set by the page.',
          child: CsAnchorNavigation(anchors: _anchors, activeHref: '#reserved'),
        ),
      ],
    );
  }
}

class _PaginationDemo extends StatefulWidget {
  const _PaginationDemo();

  @override
  State<_PaginationDemo> createState() => _PaginationDemoState();
}

class _PaginationDemoState extends State<_PaginationDemo> {
  int _page = 5;
  int _openPage = 1;
  int _openCount = 3;
  bool _loadingMore = false;
  int _compact = 2;
  int _jumpPage = 1;
  bool _jumpLoading = false;
  final GlobalKey<CsPaginationState> _jumpKey = GlobalKey();

  Future<void> _loadMore(CsPaginationPageClickDetail d) async {
    if (d.requestedPageAvailable) return;
    setState(() => _loadingMore = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      _openCount += 1;
    });
  }

  Future<void> _jump(int page) async {
    setState(() => _jumpLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _jumpLoading = false;
      _jumpPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Default',
          caption: '20 pages of instances. Current page: $_page.',
          child: CsPagination(
            currentPageIndex: _page,
            pagesCount: 20,
            onChange: (p) => setState(() => _page = p),
            ariaLabels: CsPaginationAriaLabels(
              paginationLabel: 'Instances pages',
              pageLabel: (n) => 'Page $n of all pages',
            ),
          ),
        ),
        DemoSection(
          title: 'Open ended',
          caption: _loadingMore
              ? 'Loading more buckets...'
              : 'The next arrow loads more pages when the last is reached.',
          child: CsPagination(
            currentPageIndex: _openPage,
            pagesCount: _openCount,
            openEnd: true,
            disabled: _loadingMore,
            onChange: (p) => setState(() => _openPage = p),
            onNextPageClick: _loadMore,
          ),
        ),
        DemoSection(
          title: 'Compact',
          child: CsPagination(
            currentPageIndex: _compact,
            pagesCount: 12,
            pagesVariant: CsPaginationPagesVariant.compact,
            onChange: (p) => setState(() => _compact = p),
          ),
        ),
        DemoSection(
          title: 'Jump to page',
          caption: 'Pages past 40 show the out-of-range error.',
          child: CsPagination(
            key: _jumpKey,
            currentPageIndex: _jumpPage,
            pagesCount: 40,
            jumpToPage: CsPaginationJumpToPage(loading: _jumpLoading),
            onChange: _jump,
          ),
        ),
        const DemoSection(title: 'Disabled', child: CsPagination(currentPageIndex: 3, pagesCount: 8, disabled: true)),
      ],
    );
  }
}

class _LinkDemo extends StatefulWidget {
  const _LinkDemo();

  @override
  State<_LinkDemo> createState() => _LinkDemoState();
}

class _LinkDemoState extends State<_LinkDemo> {
  String _last = 'None';

  @override
  Widget build(BuildContext context) {
    VoidCallback follow(String what) =>
        () => setState(() => _last = what);
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Variants',
          child: Wrap(
            spacing: CsSpace.l,
            runSpacing: CsSpace.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CsLink(text: 'Secondary (default)', onFollow: follow('Secondary')),
              CsLink(text: 'Primary', variant: CsLinkVariant.primary, onFollow: follow('Primary')),
              CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: follow('Info')),
              CsLink(text: '128', variant: CsLinkVariant.awsuiValueLarge, onFollow: follow('Value large')),
            ],
          ),
        ),
        DemoSection(
          title: 'Font sizes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CsSpace.xs,
            children: [
              for (final size in CsLinkFontSize.values)
                if (size != CsLinkFontSize.inherit)
                  CsLink(
                    text: 'Distribution d111111abcdef8 (${size.name})',
                    fontSize: size,
                    onFollow: follow(size.name),
                  ),
            ],
          ),
        ),
        DemoSection(
          title: 'In running text',
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Objects in '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: CsLink(text: 'example-bucket', variant: CsLinkVariant.primary, onFollow: follow('Bucket')),
                ),
                const TextSpan(text: ' are encrypted at rest. See '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: CsLink(
                    text: 'encryption settings',
                    variant: CsLinkVariant.primary,
                    external: true,
                    onFollow: follow('External'),
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Inverted',
          caption: 'On a colored background, such as a flash message.',
          child: Container(
            padding: const EdgeInsets.all(CsSpace.m),
            decoration: BoxDecoration(
              color: context.cs.colors.backgroundNotificationBlue,
              borderRadius: BorderRadius.circular(CsBorderRadius.flashbar),
            ),
            child: CsVisualContext(
              context: CsVisualContextName.flashbar,
              child: Wrap(
                spacing: CsSpace.l,
                children: [
                  CsLink(text: 'View instance', color: CsLinkColor.inverted, onFollow: follow('Inverted')),
                  CsLink(
                    text: 'Open console',
                    color: CsLinkColor.inverted,
                    external: true,
                    onFollow: follow('Inverted external'),
                  ),
                ],
              ),
            ),
          ),
        ),
        _Result('Last followed: $_last'),
      ],
    );
  }
}

class _WizardDemo extends StatefulWidget {
  const _WizardDemo();

  @override
  State<_WizardDemo> createState() => _WizardDemoState();
}

class _WizardDemoState extends State<_WizardDemo> {
  int _step = 0;
  bool _loading = false;
  String _name = '';
  String? _nameError;
  String _status = 'In progress';

  Future<void> _navigate(CsWizardNavigateDetail d) async {
    if (d.reason == CsWizardNavigationReason.next && _step == 0) {
      if (_name.trim().isEmpty) {
        setState(() => _nameError = 'Enter an instance name.');
        return;
      }
      setState(() => _loading = true);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _loading = false);
    }
    setState(() {
      _nameError = null;
      _step = d.requestedStepIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Launch an instance',
          caption: 'Name is required on step 1. Storage and tags are optional and can be skipped. $_status.',
          child: CsWizard(
            activeStepIndex: _step,
            isLoadingNextStep: _loading,
            allowSkipTo: true,
            submitButtonText: 'Launch instance',
            onNavigate: _navigate,
            onCancel: () => setState(() {
              _step = 0;
              _status = 'Cancelled';
            }),
            onSubmit: () => setState(() => _status = 'Launched i-0abc123'),
            secondaryActions: CsButton(text: 'Save draft', onPress: () => setState(() => _status = 'Draft saved')),
            steps: [
              CsWizardStep(
                title: 'Choose a name and image',
                info: CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: () {}),
                description: 'Name the instance and pick the image it starts from.',
                content: CsContainer(
                  header: const CsHeader(variant: CsHeaderVariant.h2, title: 'Instance details'),
                  child: CsFormField(
                    label: 'Name',
                    constraintText: 'Up to 64 characters.',
                    errorText: _nameError,
                    child: CsInput(
                      value: _name,
                      placeholder: 'web-server-1',
                      invalid: _nameError != null,
                      onChange: (v) => setState(() => _name = v),
                    ),
                  ),
                ),
              ),
              const CsWizardStep(
                title: 'Configure storage',
                isOptional: true,
                content: CsContainer(
                  header: CsHeader(variant: CsHeaderVariant.h2, title: 'Volumes'),
                  child: CsBox(text: 'Root volume: 8 GiB, general purpose SSD.'),
                ),
              ),
              const CsWizardStep(
                title: 'Add tags',
                isOptional: true,
                content: CsContainer(
                  header: CsHeader(variant: CsHeaderVariant.h2, title: 'Tags'),
                  child: CsBox(text: 'No tags added.'),
                ),
              ),
              CsWizardStep(
                title: 'Review and launch',
                content: CsContainer(
                  header: const CsHeader(variant: CsHeaderVariant.h2, title: 'Summary'),
                  child: CsBox(text: 'Name: ${_name.isEmpty ? '-' : _name}. Image: Linux 2026.1. Storage: 8 GiB.'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepsDemo extends StatefulWidget {
  const _StepsDemo();

  @override
  State<_StepsDemo> createState() => _StepsDemoState();
}

class _StepsDemoState extends State<_StepsDemo> {
  int _progress = 1;
  bool _lines = true;

  List<CsStepsStep> get _deploy {
    CsStatusType status(int i) => i < _progress
        ? CsStatusType.success
        : i == _progress
        ? CsStatusType.loading
        : CsStatusType.pending;
    const titles = ['Build image', 'Run tests', 'Deploy to staging', 'Deploy to production'];
    return [
      for (var i = 0; i < titles.length; i++)
        CsStepsStep(
          status: _progress >= titles.length ? CsStatusType.success : status(i),
          header: titles[i],
          details: i == _progress && _progress < titles.length ? 'In progress' : null,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final connector = _lines ? CsStepsConnectorLines.visible : CsStepsConnectorLines.none;
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Pipeline',
          caption: 'Advance the pipeline to update the statuses.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.m,
            children: [
              CsSpaceBetween(
                direction: CsSpaceBetweenDirection.horizontal,
                size: CsSpacingSize.xs,
                children: [
                  CsButton(text: 'Advance', disabled: _progress >= 4, onPress: () => setState(() => _progress++)),
                  CsButton(text: 'Restart', onPress: () => setState(() => _progress = 0)),
                  CsButton(
                    text: _lines ? 'Hide connector lines' : 'Show connector lines',
                    variant: CsButtonVariant.link,
                    onPress: () => setState(() => _lines = !_lines),
                  ),
                ],
              ),
              CsSteps(steps: _deploy, connectorLines: connector, ariaLabel: 'Pipeline progress'),
            ],
          ),
        ),
        DemoSection(
          title: 'Horizontal',
          caption: 'Switches to vertical when each column would be narrower than 120px.',
          child: CsSteps(steps: _deploy, orientation: CsStepsOrientation.horizontal, connectorLines: connector),
        ),
        const DemoSection(
          title: 'Timeline with annotations',
          child: CsSteps(
            steps: [
              CsStepsStep(status: CsStatusType.info, annotation: '09:58', header: 'Change set created'),
              CsStepsStep(
                status: CsStatusType.warning,
                annotation: '10:01',
                header: 'Drift detected',
                details: '1 resource differs from the template',
              ),
              CsStepsStep(
                status: CsStatusType.error,
                annotation: '10:03',
                header: 'Update failed',
                details: 'Rolled back',
              ),
              CsStepsStep(status: CsStatusType.stopped, annotation: '10:05', header: 'Stack stopped'),
            ],
          ),
        ),
        DemoSection(
          title: 'Custom steps',
          child: CsSteps(
            steps: const [
              CsStepsStep(status: CsStatusType.success, header: 'example-bucket', data: 'Versioning enabled'),
              CsStepsStep(status: CsStatusType.inProgress, header: 'example-logs', data: 'Replicating objects'),
              CsStepsStep(status: CsStatusType.notStarted, header: 'example-archive', data: 'Waiting'),
            ],
            renderStep: (s) => CsStepsRenderedStep(
              icon: CsIcon(
                CsIcons.folder,
                variant: s.status == CsStatusType.success ? CsIconVariant.success : CsIconVariant.subtle,
              ),
              header: CsBox(variant: CsBoxVariant.strong, text: s.header),
              details: CsBox(variant: CsBoxVariant.small, color: CsBoxColor.textBodySecondary, text: '${s.data}'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Obj {
  const _Obj(this.id, this.name, {this.size, this.children});

  final String id;
  final String name;
  final String? size;
  final List<_Obj>? children;
}

class _TreeViewDemo extends StatefulWidget {
  const _TreeViewDemo();

  @override
  State<_TreeViewDemo> createState() => _TreeViewDemoState();
}

class _TreeViewDemoState extends State<_TreeViewDemo> {
  final Set<String> _expanded = {'logs/'};
  bool _lines = true;
  String _last = 'None';

  static const _objects = [
    _Obj(
      'logs/',
      'logs/',
      children: [
        _Obj(
          'logs/2026/',
          '2026/',
          children: [
            _Obj('logs/2026/january.log', 'january.log', size: '1.2 MB'),
            _Obj('logs/2026/february.log', 'february.log', size: '980 KB'),
          ],
        ),
        _Obj('logs/README.md', 'README.md', size: '2 KB'),
      ],
    ),
    _Obj(
      'assets/',
      'assets/',
      children: [
        _Obj('assets/logo.svg', 'logo.svg', size: '4 KB'),
        _Obj('assets/styles.css', 'styles.css', size: '18 KB'),
      ],
    ),
    _Obj('index.html', 'index.html', size: '6 KB'),
  ];

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Objects in example-bucket',
          caption: 'Tab into the tree, then use the arrow keys, Home and End.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.s,
            children: [
              CsSpaceBetween(
                direction: CsSpaceBetweenDirection.horizontal,
                size: CsSpacingSize.xs,
                children: [
                  CsButton(
                    text: 'Expand all',
                    onPress: () => setState(() => _expanded.addAll(['logs/', 'logs/2026/', 'assets/'])),
                  ),
                  CsButton(text: 'Collapse all', onPress: () => setState(_expanded.clear)),
                  CsButton(
                    text: _lines ? 'Hide connector lines' : 'Show connector lines',
                    variant: CsButtonVariant.link,
                    onPress: () => setState(() => _lines = !_lines),
                  ),
                ],
              ),
              CsContainer(
                child: CsTreeView<_Obj>(
                  items: _objects,
                  ariaLabel: 'Objects in example-bucket',
                  expandedItems: _expanded,
                  connectorLines: _lines ? CsTreeViewConnectorLines.vertical : CsTreeViewConnectorLines.none,
                  getItemId: (o, _) => o.id,
                  getItemChildren: (o, _) => o.children,
                  i18nStrings: CsTreeViewI18nStrings(
                    expandButtonLabel: (o) => 'Expand ${o.name}',
                    collapseButtonLabel: (o) => 'Collapse ${o.name}',
                  ),
                  onItemToggle: (d) => setState(() => d.expanded ? _expanded.add(d.id) : _expanded.remove(d.id)),
                  renderItem: (o, _) => CsTreeViewItem(
                    icon: CsIcon(o.children == null ? CsIcons.file : CsIcons.folder),
                    content: Text(o.name),
                    secondaryContent: o.size == null ? null : Text(o.size!),
                    actions: o.children != null
                        ? null
                        : CsButton(
                            variant: CsButtonVariant.inlineIcon,
                            icon: CsIcons.download,
                            semanticLabel: 'Download ${o.name}',
                            onPress: () => setState(() => _last = o.id),
                          ),
                  ),
                ),
              ),
              _Result('Last download: $_last'),
            ],
          ),
        ),
      ],
    );
  }
}
