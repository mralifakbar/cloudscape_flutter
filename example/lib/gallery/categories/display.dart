import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// Badges, status indicators, key-value pairs, lists, text content, truncated
/// text and the onboarding components (hotspots, annotation context, tutorial
/// panel). Every name and figure here is sample data.
final CsDemoCategory displayCategory = CsDemoCategory(
  title: 'Display',
  description:
      'Badges, status indicators, key-value pairs, lists, text content, truncated text and onboarding hotspots.',
  icon: CsIcons.statusInfo,
  demos: [
    CsDemo(
      title: 'CsBadge',
      description: 'Blue, grey, green and red badges, the severity scale and custom styles.',
      docPath: 'doc/components/CsBadge.md',
      builder: (_) => const _BadgeDemo(),
    ),
    CsDemo(
      title: 'CsStatusIndicator',
      description: 'Every status type, color overrides, truncation, inline flow and the error entrance.',
      docPath: 'doc/components/CsStatusIndicator.md',
      builder: (_) => const _StatusIndicatorDemo(),
    ),
    CsDemo(
      title: 'CsKeyValuePairs',
      description: 'Details of a distribution in one to four responsive columns, with groups and info links.',
      docPath: 'doc/components/CsKeyValuePairs.md',
      builder: (_) => const _KeyValuePairsDemo(),
    ),
    CsDemo(
      title: 'CsList',
      description: 'Structured items with icons, descriptions and actions, and a sortable list.',
      docPath: 'doc/components/CsList.md',
      builder: (_) => const _ListDemo(),
    ),
    CsDemo(
      title: 'CsTextContent',
      description: 'Headings, paragraphs, lists, code and links with Cloudscape spacing, from blocks or Markdown.',
      docPath: 'doc/components/CsTextContent.md',
      builder: (_) => const _TextContentDemo(),
    ),
    CsDemo(
      title: 'CsTruncatedText',
      description: 'Long identifiers that truncate and show the full text on hover, focus or tap.',
      docPath: 'doc/components/CsTruncatedText.md',
      builder: (_) => const _TruncatedTextDemo(),
    ),
    CsDemo(
      title: 'CsAnnotationContext',
      description: 'A hands-on tutorial: hotspots on a form and the tutorial panel tracking progress.',
      docPath: 'doc/components/CsAnnotationContext.md',
      builder: (_) => const _OnboardingDemo(),
    ),
    CsDemo(
      title: 'CsHotspot',
      description: 'Markers beside fields, inline in labels and on either side, with popovers in four directions.',
      docPath: 'doc/components/CsHotspot.md',
      builder: (_) => const _HotspotDemo(),
    ),
    CsDemo(
      title: 'CsTutorialPanel',
      description: 'The tutorial list with completed, locked and loading states.',
      docPath: 'doc/components/CsTutorialPanel.md',
      builder: (_) => const _TutorialPanelDemo(),
    ),
  ],
);

class _BadgeDemo extends StatefulWidget {
  const _BadgeDemo();

  @override
  State<_BadgeDemo> createState() => _BadgeDemoState();
}

class _BadgeDemoState extends State<_BadgeDemo> {
  int _unread = 3;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        const DemoSection(
          title: 'Colors',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              CsBadge(text: 'Grey'),
              CsBadge(text: 'Blue', color: CsBadgeColor.blue),
              CsBadge(text: 'Green', color: CsBadgeColor.green),
              CsBadge(text: 'Red', color: CsBadgeColor.red),
            ],
          ),
        ),
        const DemoSection(
          title: 'Severity',
          caption: 'For finding and incident severity, always with the severity name.',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              CsBadge(text: 'Critical', color: CsBadgeColor.severityCritical),
              CsBadge(text: 'High', color: CsBadgeColor.severityHigh),
              CsBadge(text: 'Medium', color: CsBadgeColor.severityMedium),
              CsBadge(text: 'Low', color: CsBadgeColor.severityLow),
              CsBadge(text: 'Informational', color: CsBadgeColor.severityNeutral),
            ],
          ),
        ),
        DemoSection(
          title: 'Counter',
          caption: 'Sample data. The badge reads "$_unread unread notifications" to screen readers.',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Notifications'),
              CsBadge(
                text: '$_unread',
                color: _unread == 0 ? CsBadgeColor.grey : CsBadgeColor.red,
                semanticLabel: '$_unread unread notifications',
              ),
              CsButton(text: 'Add', onPress: () => setState(() => _unread++)),
              CsButton(
                text: 'Mark all read',
                variant: CsButtonVariant.link,
                disabled: _unread == 0,
                onPress: () => setState(() => _unread = 0),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Custom style',
          child: Wrap(
            spacing: CsSpace.xs,
            children: [
              CsBadge(
                text: 'Beta',
                style: CsBadgeStyle(
                  borderRadius: 16,
                  paddingInline: CsSpace.s,
                  borderWidth: 1,
                  background: context.cs.colors.backgroundContainerContent,
                  borderColor: context.cs.colors.borderStatusInfo,
                  color: context.cs.colors.textStatusInfo,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusIndicatorDemo extends StatefulWidget {
  const _StatusIndicatorDemo();

  @override
  State<_StatusIndicatorDemo> createState() => _StatusIndicatorDemoState();
}

class _StatusIndicatorDemoState extends State<_StatusIndicatorDemo> {
  int _errorKey = 0;
  CsStatusColor? _override;

  static const _labels = {
    CsStatusType.error: 'Failed',
    CsStatusType.warning: 'Impaired',
    CsStatusType.success: 'Running',
    CsStatusType.info: 'Updated',
    CsStatusType.stopped: 'Stopped',
    CsStatusType.pending: 'Pending',
    CsStatusType.inProgress: 'Stopping',
    CsStatusType.loading: 'Deploying',
    CsStatusType.notStarted: 'Not started',
    CsStatusType.log: 'Log entry',
  };

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Types',
          caption: 'Sample instance states.',
          child: Wrap(
            spacing: CsSpace.l,
            runSpacing: CsSpace.xs,
            children: [
              for (final e in _labels.entries) CsStatusIndicator(type: e.key, text: e.value, colorOverride: _override),
            ],
          ),
        ),
        DemoSection(
          title: 'Color override',
          caption: 'Keeps each icon and recolors it.',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              CsButton(
                text: 'None',
                variant: _override == null ? CsButtonVariant.primary : CsButtonVariant.normal,
                onPress: () => setState(() => _override = null),
              ),
              for (final c in CsStatusColor.values)
                CsButton(
                  text: c.name,
                  variant: _override == c ? CsButtonVariant.primary : CsButtonVariant.normal,
                  onPress: () => setState(() => _override = c),
                ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Wrapping and truncation',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CsSpace.s,
            children: [
              SizedBox(
                width: 220,
                child: CsStatusIndicator(
                  type: CsStatusType.warning,
                  text: 'Certificate for d111111abcdef8.cloudfront.example expires in 3 days',
                ),
              ),
              SizedBox(
                width: 220,
                child: CsStatusIndicator(
                  type: CsStatusType.warning,
                  display: CsStatusDisplay.inline,
                  text: 'Inline: certificate for d111111abcdef8.cloudfront.example expires in 3 days',
                ),
              ),
              SizedBox(
                width: 220,
                child: CsStatusIndicator(
                  type: CsStatusType.warning,
                  wrapText: false,
                  text: 'Truncated: certificate for d111111abcdef8.cloudfront.example expires in 3 days',
                ),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Error entrance',
          caption: 'Fades in and shakes once, as under an invalid form field. Off with reduced motion.',
          child: Wrap(
            spacing: CsSpace.m,
            runSpacing: CsSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CsButton(text: 'Validate', onPress: () => setState(() => _errorKey++)),
              if (_errorKey > 0)
                CsStatusIndicator(
                  key: ValueKey(_errorKey),
                  type: CsStatusType.error,
                  text: 'Bucket name is required.',
                  animate: true,
                ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Sizes',
          child: Wrap(
            spacing: CsSpace.l,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CsStatusIndicator(type: CsStatusType.success, text: 'x-small', iconSize: CsIconSize.xSmall),
              CsStatusIndicator(type: CsStatusType.success, text: 'normal'),
              CsStatusIndicator(type: CsStatusType.loading, text: 'medium', iconSize: CsIconSize.medium),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyValuePairsDemo extends StatefulWidget {
  const _KeyValuePairsDemo();

  @override
  State<_KeyValuePairsDemo> createState() => _KeyValuePairsDemoState();
}

class _KeyValuePairsDemoState extends State<_KeyValuePairsDemo> {
  int _columns = 3;
  String? _help;

  @override
  Widget build(BuildContext context) {
    final items = <CsKeyValueItem>[
      const CsKeyValuePair(label: 'Distribution ID', value: 'd111111abcdef8'),
      CsKeyValuePair(
        label: 'Status',
        info: CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: () => setState(() => _help = 'Status')),
        valueWidget: const CsStatusIndicator(type: CsStatusType.success, text: 'Deployed'),
      ),
      const CsKeyValuePair(label: 'Price class', value: 'Use all edge locations'),
      const CsKeyValuePair(label: 'Domain name', valueWidget: CsTruncatedText('d111111abcdef8.cloudfront.example')),
      CsKeyValuePair(
        label: 'Origin',
        valueWidget: CsLink(text: 'example-bucket', onFollow: () => setState(() => _help = 'example-bucket')),
      ),
      const CsKeyValuePair(label: 'Last modified', value: 'November 16, 2026, 09:41 UTC'),
    ];
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Columns',
          caption: 'Sample data. Columns drop to an even count as the width shrinks.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.m,
            children: [
              Wrap(
                spacing: CsSpace.xs,
                children: [
                  for (var n = 1; n <= 4; n++)
                    CsButton(
                      text: '$n',
                      semanticLabel: '$n columns',
                      variant: _columns == n ? CsButtonVariant.primary : CsButtonVariant.normal,
                      onPress: () => setState(() => _columns = n),
                    ),
                ],
              ),
              CsContainer(
                header: const CsHeader(title: 'Distribution settings'),
                child: CsKeyValuePairs(columns: _columns, items: items, ariaLabel: 'Distribution settings'),
              ),
              if (_help != null) CsBox(variant: CsBoxVariant.small, text: 'Followed: $_help'),
            ],
          ),
        ),
        const DemoSection(
          title: 'Groups',
          child: CsContainer(
            child: CsKeyValuePairs(
              columns: 2,
              items: [
                CsKeyValueGroup(
                  title: 'Origin',
                  items: [
                    CsKeyValuePair(label: 'Bucket', value: 'example-bucket'),
                    CsKeyValuePair(label: 'Origin path', value: '/static'),
                  ],
                ),
                CsKeyValueGroup(
                  title: 'Behavior',
                  items: [
                    CsKeyValuePair(label: 'Viewer protocol', value: 'Redirect HTTP to HTTPS'),
                    CsKeyValuePair(label: 'Cache policy', value: 'CachingOptimized'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bucket {
  const _Bucket(this.name, this.region, this.objects);

  final String name;
  final String region;
  final int objects;
}

class _ListDemo extends StatefulWidget {
  const _ListDemo();

  @override
  State<_ListDemo> createState() => _ListDemoState();
}

class _ListDemoState extends State<_ListDemo> {
  List<_Bucket> _buckets = const [
    _Bucket('example-bucket', 'us-east-1', 1204),
    _Bucket('logs-bucket', 'eu-west-1', 88412),
    _Bucket('backup-bucket', 'ap-southeast-2', 37),
  ];
  List<String> _rules = ['Block known bad bots', 'Rate limit sign-in', 'Allow office addresses', 'Default allow'];
  bool _locked = false;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Structured items',
          caption: 'Sample buckets. Remove one with its action.',
          child: CsContainer(
            child: CsList<_Bucket>(
              items: _buckets,
              ariaLabel: 'Buckets',
              renderItem: (b) => CsListItem(
                id: b.name,
                icon: const CsIcon(CsIcons.folder),
                content: Text(b.name),
                secondaryContent: Text('${b.region}, ${b.objects} objects'),
                actions: CsButton(
                  icon: CsIcons.remove,
                  variant: CsButtonVariant.icon,
                  semanticLabel: 'Remove ${b.name}',
                  onPress: () => setState(() => _buckets = _buckets.where((x) => x != b).toList()),
                ),
              ),
            ),
          ),
        ),
        DemoSection(
          title: 'Sortable',
          caption: 'Drag a handle, or focus it and use Space, the arrow keys and Enter. Escape cancels.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.s,
            children: [
              CsCheckbox(checked: _locked, label: 'Pause reordering', onChange: (v) => setState(() => _locked = v)),
              CsContainer(
                child: CsList<String>(
                  items: _rules,
                  sortable: true,
                  sortDisabled: _locked,
                  ariaLabel: 'Rule priority',
                  renderItem: (r) => CsListItem(id: r, content: Text(r)),
                  onSortingChange: (next) => setState(() => _rules = next),
                ),
              ),
              CsBox(variant: CsBoxVariant.small, text: 'Order: ${_rules.join(', ')}'),
            ],
          ),
        ),
        DemoSection(
          title: 'Without paddings',
          child: CsList<String>(
            items: const ['ReadOnlyAccess', 'ExampleBucketWrite'],
            disablePaddings: true,
            renderItem: (p) => CsListItem(id: p, content: Text(p)),
          ),
        ),
      ],
    );
  }
}

class _TextContentDemo extends StatefulWidget {
  const _TextContentDemo();

  @override
  State<_TextContentDemo> createState() => _TextContentDemoState();
}

class _TextContentDemoState extends State<_TextContentDemo> {
  String? _followed;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Blocks',
          child: CsTextContent(
            blocks: [
              const CsTextHeading('Distributions', level: CsTextHeadingLevel.h1),
              const CsTextParagraph(text: 'A distribution serves your content from edge locations near your viewers.'),
              const CsTextHeading('Price class', level: CsTextHeadingLevel.h3),
              CsTextParagraph(
                spans: [
                  const CsTextRun('Use '),
                  const CsTextCode('PriceClass_All'),
                  const CsTextRun(' to serve from '),
                  const CsTextRun('every', bold: true),
                  const CsTextRun(' edge location, or a '),
                  const CsTextRun('smaller', italic: true),
                  const CsTextRun(' class to lower cost. '),
                  CsTextLink('Pricing', external: true, onFollow: () => setState(() => _followed = 'Pricing')),
                ],
              ),
              const CsTextList(
                items: [
                  CsTextListItem(text: 'All edge locations'),
                  CsTextListItem(
                    text: 'North America and Europe',
                    nested: CsTextList(
                      ordered: true,
                      items: [
                        CsTextListItem(text: 'Lowest cost'),
                        CsTextListItem(text: 'Higher latency elsewhere'),
                      ],
                    ),
                  ),
                ],
              ),
              const CsTextHeading('Example', level: CsTextHeadingLevel.h5),
              const CsTextPre(
                'aws example create-distribution \\\n  --origin example-bucket.s3.example \\\n  --price-class PriceClass_All',
              ),
              const CsTextSmall(text: 'Commands and prices are sample data.'),
            ],
          ),
        ),
        DemoSection(
          title: 'Markdown',
          caption: _followed == null ? 'Links call back with their target.' : 'Followed: $_followed',
          child: CsTextContent.markdown('''
## Create a bucket

Buckets hold **objects**. Names are *global*, so pick something like `example-bucket`.

1. Open [Buckets](buckets)
2. Choose **Create bucket**
  - Enter a name
  - Choose a region
3. Review the settings

<small>Bucket names are sample data.</small>
''', onFollowLink: (target) => setState(() => _followed = target)),
        ),
      ],
    );
  }
}

class _TruncatedTextDemo extends StatefulWidget {
  const _TruncatedTextDemo();

  @override
  State<_TruncatedTextDemo> createState() => _TruncatedTextDemoState();
}

class _TruncatedTextDemoState extends State<_TruncatedTextDemo> {
  double _width = 220;

  static const _arn = 'arn:aws:s3:::example-bucket/logs/2026/11/16/distribution-d111111abcdef8-000123.gz';

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Single line',
          caption: 'Hover, focus with Tab or tap to see the full path. Change the width to see it switch.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CsSpace.s,
            children: [
              Wrap(
                spacing: CsSpace.xs,
                children: [
                  for (final w in const [140.0, 220.0, 680.0])
                    CsButton(
                      text: '${w.round()}px',
                      variant: _width == w ? CsButtonVariant.primary : CsButtonVariant.normal,
                      onPress: () => setState(() => _width = w),
                    ),
                ],
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _width),
                child: const CsTruncatedText(_arn),
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Several lines',
          child: SizedBox(
            width: 260,
            child: CsTruncatedText(
              'Serves static assets for the storefront from example-bucket through every edge location, '
              'with access logs delivered to logs-bucket and a default cache time of one day.',
              maxLines: 2,
            ),
          ),
        ),
        const DemoSection(
          title: 'Custom tooltip',
          child: SizedBox(
            width: 160,
            child: CsTruncatedText(
              'i-0abc123def4567890 (web-server-production-1)',
              tooltipText: 'Instance i-0abc123def4567890',
            ),
          ),
        ),
      ],
    );
  }
}

const CsTutorial _bucketTutorial = CsTutorial(
  title: 'Create a bucket',
  description: Text('Name a bucket, choose where it lives and create it.'),
  completedScreenDescription: Text('You created a bucket. Upload objects to it next.'),
  tasks: [
    CsTutorialTask(
      title: 'Name the bucket',
      steps: [
        CsTutorialStep(
          title: 'Enter a name',
          content: Text('Bucket names are global. Try example-bucket.'),
          hotspotId: 'demo-bucket-name',
        ),
        CsTutorialStep(
          title: 'Choose a region',
          content: Text('Pick the region closest to your users.'),
          warningAlert: Text('The region cannot change after creation.'),
          hotspotId: 'demo-bucket-region',
        ),
      ],
    ),
    CsTutorialTask(
      title: 'Configure and create',
      steps: [
        CsTutorialStep(
          title: 'Turn on versioning',
          content: Text('Versioning keeps every version of an object.'),
          hotspotId: 'demo-bucket-versioning',
        ),
        CsTutorialStep(
          title: 'Create the bucket',
          content: Text('Choose Create bucket to finish.'),
          hotspotId: 'demo-bucket-create',
        ),
      ],
    ),
  ],
);

const CsTutorial _loggingTutorial = CsTutorial(
  title: 'Deliver access logs',
  description: Text('Send access logs of a distribution to logs-bucket.'),
  completedScreenDescription: Text('Access logs now arrive in logs-bucket.'),
  prerequisitesNeeded: true,
  prerequisitesAlert: Text('Create a bucket first to complete this tutorial.'),
  tasks: [
    CsTutorialTask(
      title: 'Logging',
      steps: [CsTutorialStep(title: 'Turn on logging', content: Text('Turn logging on.'), hotspotId: 'demo-logging')],
    ),
  ],
);

class _OnboardingDemo extends StatefulWidget {
  const _OnboardingDemo();

  @override
  State<_OnboardingDemo> createState() => _OnboardingDemoState();
}

class _OnboardingDemoState extends State<_OnboardingDemo> {
  CsTutorial? _current;
  List<CsTutorial> _tutorials = const [_bucketTutorial, _loggingTutorial];
  String _name = '';
  bool _versioning = false;
  String _log = 'No step changes yet.';

  void _complete() {
    final done = _current!.copyWith(completed: true);
    setState(() {
      _current = done;
      _tutorials = [
        for (final t in _tutorials)
          if (t.title == done.title)
            done
          else if (t.title == _loggingTutorial.title)
            t.copyWith(prerequisitesNeeded: false)
          else
            t,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final form = CsContainer(
      header: const CsHeader(title: 'Create bucket', description: 'Sample form for the tutorial.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CsSpace.l,
        children: [
          CsHotspot(
            hotspotId: 'demo-bucket-name',
            child: CsFormField(
              label: 'Bucket name',
              child: CsInput(value: _name, placeholder: 'example-bucket', onChange: (v) => setState(() => _name = v)),
            ),
          ),
          const CsHotspot(
            hotspotId: 'demo-bucket-region',
            direction: CsSide.bottom,
            child: CsFormField(label: 'Region', child: Text('US East (N. Virginia) us-east-1')),
          ),
          Row(
            children: [
              Flexible(
                child: CsCheckbox(
                  checked: _versioning,
                  label: 'Enable versioning',
                  onChange: (v) => setState(() => _versioning = v),
                ),
              ),
              const CsHotspot(hotspotId: 'demo-bucket-versioning'),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: CsHotspot(
              hotspotId: 'demo-bucket-create',
              side: CsHotspotSide.left,
              child: CsButton(text: 'Create bucket', variant: CsButtonVariant.primary, onPress: () {}),
            ),
          ),
        ],
      ),
    );
    final panel = CsContainer(
      child: CsTutorialPanel(tutorials: _tutorials, onFeedbackClick: (_) {}),
    );
    return CsAnnotationContext(
      currentTutorial: _current,
      onStartTutorial: (t) => setState(() => _current = t.copyWith(completed: false)),
      onExitTutorial: (_) => setState(() => _current = null),
      onFinish: _complete,
      onStepChange: (step, reason) => setState(() => _log = 'Step ${step + 1} (${reason.name})'),
      child: DemoColumn(
        children: [
          DemoSection(
            title: 'Tutorial',
            caption:
                'Start "Create a bucket" in the panel. The markers pulse briefly when their step is current. $_log',
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 720) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: CsSpace.l,
                    children: [panel, form],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: CsSpace.l,
                  children: [
                    Expanded(flex: 3, child: form),
                    Expanded(flex: 2, child: panel),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HotspotDemo extends StatefulWidget {
  const _HotspotDemo();

  @override
  State<_HotspotDemo> createState() => _HotspotDemoState();
}

class _HotspotDemoState extends State<_HotspotDemo> {
  static const _tour = CsTutorial(
    title: 'Hotspot directions',
    description: Text('Popovers in each direction.'),
    completedScreenDescription: Text('Done.'),
    tasks: [
      CsTutorialTask(
        title: 'Directions',
        steps: [
          CsTutorialStep(title: 'Top', content: Text('Opens above the marker.'), hotspotId: 'dir-top'),
          CsTutorialStep(title: 'Right', content: Text('Opens to the right.'), hotspotId: 'dir-right'),
          CsTutorialStep(title: 'Bottom', content: Text('Opens below the marker.'), hotspotId: 'dir-bottom'),
          CsTutorialStep(title: 'Left', content: Text('Opens to the left.'), hotspotId: 'dir-left'),
        ],
      ),
    ],
  );

  CsTutorial? _current;

  @override
  Widget build(BuildContext context) {
    return CsAnnotationContext(
      currentTutorial: _current,
      onStartTutorial: (t) => setState(() => _current = t),
      onExitTutorial: (_) => setState(() => _current = null),
      onFinish: () => setState(() => _current = null),
      child: DemoColumn(
        children: [
          DemoSection(
            title: 'Directions and sides',
            caption: 'Outside a tutorial a hotspot renders only its child.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CsSpace.l,
              children: [
                CsButton(
                  text: _current == null ? 'Start walkthrough' : 'End walkthrough',
                  variant: CsButtonVariant.primary,
                  onPress: () => setState(() => _current = _current == null ? _tour : null),
                ),
                const SizedBox(height: CsSpace.xxxl),
                const CsHotspot(hotspotId: 'dir-top', child: Text('Marker on the right, popover on top')),
                const CsHotspot(hotspotId: 'dir-right', direction: CsSide.right, child: Text('Popover to the right')),
                const CsHotspot(
                  hotspotId: 'dir-bottom',
                  direction: CsSide.bottom,
                  side: CsHotspotSide.left,
                  child: Text('Marker on the left, popover below'),
                ),
                const Row(
                  children: [
                    Flexible(child: Text('Inline marker, popover to the left')),
                    CsHotspot(hotspotId: 'dir-left', direction: CsSide.left),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialPanelDemo extends StatefulWidget {
  const _TutorialPanelDemo();

  @override
  State<_TutorialPanelDemo> createState() => _TutorialPanelDemoState();
}

class _TutorialPanelDemoState extends State<_TutorialPanelDemo> {
  bool _loading = false;
  CsTutorial? _current;
  int _downloads = 0;

  @override
  Widget build(BuildContext context) {
    final tutorials = [
      _bucketTutorial.copyWith(completed: true),
      CsTutorial(
        title: 'Invalidate cached files',
        description: const Text('Remove files from edge caches before they expire.'),
        completedScreenDescription: const Text('The invalidation is in progress.'),
        onLearnMore: () {},
        tasks: const [
          CsTutorialTask(
            title: 'Create an invalidation',
            steps: [
              CsTutorialStep(title: 'Enter paths', content: Text('Enter /images/*.'), hotspotId: 'paths'),
              CsTutorialStep(title: 'Create', content: Text('Choose Create invalidation.'), hotspotId: 'inv'),
            ],
          ),
        ],
      ),
      _loggingTutorial,
    ];
    return CsAnnotationContext(
      currentTutorial: _current,
      onStartTutorial: (t) => setState(() => _current = t.copyWith(completed: false)),
      onExitTutorial: (_) => setState(() => _current = null),
      child: DemoColumn(
        children: [
          DemoSection(
            title: 'States',
            caption: 'Sample tutorials: one completed, one ready, one locked. Downloads: $_downloads.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CsSpace.m,
              children: [
                CsCheckbox(checked: _loading, label: 'Loading', onChange: (v) => setState(() => _loading = v)),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: CsContainer(
                    child: CsTutorialPanel(
                      tutorials: tutorials,
                      loading: _loading,
                      onDownload: () => setState(() => _downloads++),
                      i18nStrings: const CsTutorialPanelI18nStrings(
                        tutorialListDescription: 'Walkthroughs of common tasks in this console.',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
