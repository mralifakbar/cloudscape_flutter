import 'dart:async';

import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// Modals, dialogs, popovers, flashbars, alerts, progress bars, skeletons and live regions. Every name and figure here is sample data.
final CsDemoCategory feedbackCategory = CsDemoCategory(
  title: 'Feedback and overlays',
  description: 'Modals, dialogs, popovers, flashbars, alerts, progress bars, skeletons and live regions.',
  icon: CsIcons.notification,
  demos: [
    CsDemo(
      title: 'CsModal',
      description: 'Sizes, positions, a required choice, long scrolling content and showCsModal with a result.',
      docPath: 'doc/components/CsModal.md',
      builder: (_) => const _ModalDemo(),
    ),
    CsDemo(
      title: 'CsDialog',
      description: 'An inline dialog with header actions and a footer that opens in place.',
      docPath: 'doc/components/CsDialog.md',
      builder: (_) => const _DialogDemo(),
    ),
    CsDemo(
      title: 'CsPopover',
      description: 'Text, inline and custom triggers, every size and position, with and without a close button.',
      docPath: 'doc/components/CsPopover.md',
      builder: (_) => const _PopoverDemo(),
    ),
    CsDemo(
      title: 'CsFlashbar',
      description: 'Every message type, loading, actions, dismissal with motion, and a stack with a notification bar.',
      docPath: 'doc/components/CsFlashbar.md',
      builder: (_) => const _FlashbarDemo(),
    ),
    CsDemo(
      title: 'CsAlert',
      description: 'Every type, with header, action and dismiss, hidden and shown again.',
      docPath: 'doc/components/CsAlert.md',
      builder: (_) => const _AlertDemo(),
    ),
    CsDemo(
      title: 'CsProgressBar',
      description: 'A running operation, success and error results, and the flash and key-value variants.',
      docPath: 'doc/components/CsProgressBar.md',
      builder: (_) => const _ProgressBarDemo(),
    ),
    CsDemo(
      title: 'CsSkeleton',
      description: 'Text and block placeholders that swap to content when loading ends.',
      docPath: 'doc/components/CsSkeleton.md',
      builder: (_) => const _SkeletonDemo(),
    ),
    CsDemo(
      title: 'CsLiveRegion',
      description: 'Screen reader announcements for a changing result count and a hidden status.',
      docPath: 'doc/components/CsLiveRegion.md',
      builder: (_) => const _LiveRegionDemo(),
    ),
    CsDemo(
      title: 'CsErrorBoundary',
      description: 'A section that fails to build shows an error fallback with a Refresh action.',
      docPath: 'doc/components/CsErrorBoundary.md',
      builder: (_) => const _ErrorBoundaryDemo(),
    ),
  ],
);

Widget _row(List<Widget> children) => Wrap(spacing: CsSpace.xs, runSpacing: CsSpace.xs, children: children);

class _ModalDemo extends StatefulWidget {
  const _ModalDemo();

  @override
  State<_ModalDemo> createState() => _ModalDemoState();
}

class _ModalDemoState extends State<_ModalDemo> {
  bool _delete = false;
  bool _required = false;
  bool _long = false;
  CsModalSize _size = CsModalSize.medium;
  String _last = 'None yet';

  void _closeDelete([CsModalDismissReason? reason]) => setState(() {
    _delete = false;
    _last = reason?.name ?? 'footer action';
  });

  Future<void> _showResult() async {
    final ok = await showCsModal<bool>(
      context: context,
      header: 'Delete bucket',
      size: CsModalSize.small,
      builder: (_) => const Text('Permanently delete example-bucket and its 1,204 objects?'),
      footerBuilder: (context) => Wrap(
        alignment: WrapAlignment.end,
        spacing: CsSpace.xs,
        children: [
          CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () => Navigator.of(context).pop(false)),
          CsButton(text: 'Delete', variant: CsButtonVariant.primary, onPress: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
    if (mounted) setState(() => _last = 'showCsModal returned $ok');
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Delete confirmation',
          caption: 'Last dismissal: $_last',
          child: _row([
            for (final s in CsModalSize.values)
              CsButton(
                text: 'Open ${s.name}',
                variant: s == CsModalSize.medium ? CsButtonVariant.primary : CsButtonVariant.normal,
                onPress: () => setState(() {
                  _size = s;
                  _delete = true;
                }),
              ),
          ]),
        ),
        DemoSection(
          title: 'Required choice and long content',
          caption: 'Without a close button, positioned at the top; the body scrolls and the footer stays.',
          child: _row([
            CsButton(text: 'Choose a Region', onPress: () => setState(() => _required = true)),
            CsButton(text: 'View event log', onPress: () => setState(() => _long = true)),
          ]),
        ),
        DemoSection(
          title: 'showCsModal',
          caption: 'Awaits the value the modal closes with.',
          child: _row([CsButton(text: 'Delete bucket', onPress: _showResult)]),
        ),
        CsModal(
          visible: _delete,
          size: _size,
          header: 'Delete instance',
          onDismiss: _closeDelete,
          footerActions: [
            CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: _closeDelete),
            CsButton(text: 'Delete', variant: CsButtonVariant.primary, onPress: _closeDelete),
          ],
          child: const Text('Permanently delete i-0abc123? You cannot undo this action.'),
        ),
        CsModal(
          visible: _required,
          hideDismissButton: true,
          position: CsModalPosition.top,
          header: 'Choose a Region',
          onDismiss: (_) => setState(() => _required = false),
          footerActions: [
            CsButton(
              text: 'Use us-east-1',
              variant: CsButtonVariant.primary,
              onPress: () => setState(() => _required = false),
            ),
          ],
          child: const Text('Resources you create next are placed in this Region.'),
        ),
        CsModal(
          visible: _long,
          size: CsModalSize.large,
          header: 'Event log for i-0abc123',
          onDismiss: (_) => setState(() => _long = false),
          footerActions: [CsButton(text: 'Close', onPress: () => setState(() => _long = false))],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 40; i++)
                CsBox(
                  variant: CsBoxVariant.code,
                  text: '2026-11-16T10:${i.toString().padLeft(2, '0')}:00Z  state change  pending -> running',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogDemo extends StatefulWidget {
  const _DialogDemo();

  @override
  State<_DialogDemo> createState() => _DialogDemoState();
}

class _DialogDemoState extends State<_DialogDemo> {
  bool _open = false;
  String _name = 'storefront-cdn';

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Inline rename',
          caption: 'Opens in place without a backdrop. Escape or the close button dismisses it.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CsSpace.s,
            children: [
              Wrap(
                spacing: CsSpace.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CsBox(text: 'Distribution d111111abcdef8: $_name'),
                  CsButton(text: 'Rename', onPress: () => setState(() => _open = true)),
                ],
              ),
              if (_open)
                CsDialog(
                  header: 'Rename distribution',
                  headerActions: CsButton(
                    variant: CsButtonVariant.icon,
                    icon: CsIcons.statusInfo,
                    semanticLabel: 'About names',
                    onPress: () {},
                  ),
                  onDismiss: () => setState(() => _open = false),
                  footer: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: CsSpace.xs,
                    children: [
                      CsButton(
                        text: 'Cancel',
                        variant: CsButtonVariant.link,
                        onPress: () => setState(() => _open = false),
                      ),
                      CsButton(
                        text: 'Save',
                        variant: CsButtonVariant.primary,
                        onPress: () => setState(() => _open = false),
                      ),
                    ],
                  ),
                  child: CsInput(value: _name, onChange: (v) => setState(() => _name = v)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PopoverDemo extends StatefulWidget {
  const _PopoverDemo();

  @override
  State<_PopoverDemo> createState() => _PopoverDemoState();
}

class _PopoverDemoState extends State<_PopoverDemo> {
  bool _controlled = false;

  @override
  Widget build(BuildContext context) {
    const detail = Text('This instance contains insufficient memory. Stop the instance and choose a larger type.');
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Text trigger with a status',
          child: _row([
            const CsPopover(
              header: 'Memory error',
              content: detail,
              child: CsStatusIndicator(type: CsStatusType.error, text: 'Error'),
            ),
          ]),
        ),
        const DemoSection(
          title: 'Inline text trigger',
          child: Wrap(
            children: [
              Text('Requests are fetched from the '),
              CsPopover(
                triggerType: CsPopoverTriggerType.textInline,
                size: CsPopoverSize.small,
                header: 'Origin',
                content: Text('The server content is fetched from, such as example-bucket.'),
                child: Text('origin'),
              ),
              Text(' of the distribution.'),
            ],
          ),
        ),
        DemoSection(
          title: 'Custom trigger without a close button',
          caption: 'The content is announced; Tab closes it.',
          child: _row([
            CsPopover(
              triggerType: CsPopoverTriggerType.custom,
              dismissButton: false,
              size: CsPopoverSize.small,
              position: CsPopoverPosition.top,
              content: const CsStatusIndicator(type: CsStatusType.success, text: 'ARN copied'),
              child: CsButton(text: 'Copy ARN', icon: CsIcons.copy, onPress: () {}),
            ),
          ]),
        ),
        DemoSection(
          title: 'Positions and sizes',
          caption: 'Left and right open below the trigger on phones.',
          child: _row([
            for (final p in CsPopoverPosition.values)
              for (final s in CsPopoverSize.values)
                CsPopover(
                  position: p,
                  size: s,
                  header: '${p.name}, ${s.name}',
                  content: const Text('m5.large: 2 vCPU, 8 GiB memory, up to 10 Gbps network.'),
                  child: Text('${p.name} ${s.name}'),
                ),
          ]),
        ),
        DemoSection(
          title: 'Controlled, fixed width',
          child: _row([
            CsPopover(
              visible: _controlled,
              onVisibleChange: (v) => setState(() => _controlled = v),
              fixedWidth: true,
              size: CsPopoverSize.large,
              header: 'Instance type',
              content: const Text('m5.large'),
              child: const Text('m5.large'),
            ),
            CsButton(
              text: _controlled ? 'Close from outside' : 'Open from outside',
              onPress: () => setState(() => _controlled = !_controlled),
            ),
          ]),
        ),
      ],
    );
  }
}

class _FlashbarDemo extends StatefulWidget {
  const _FlashbarDemo();

  @override
  State<_FlashbarDemo> createState() => _FlashbarDemoState();
}

class _FlashbarDemoState extends State<_FlashbarDemo> {
  int _next = 0;
  bool _stack = true;
  late List<CsFlashbarItem> _items = [
    _make(CsFlashbarType.error),
    _make(CsFlashbarType.success),
    _make(CsFlashbarType.warning),
    _make(CsFlashbarType.info),
  ];

  static const _samples = {
    CsFlashbarType.success: ('Instance launched', 'i-0abc123 is starting in us-east-1.'),
    CsFlashbarType.error: ('Could not delete bucket', 'example-bucket is not empty.'),
    CsFlashbarType.warning: ('Certificate expires soon', 'The certificate for d111111abcdef8 expires in 7 days.'),
    CsFlashbarType.info: ('Maintenance scheduled', 'Instances in us-east-1a restart on Sunday at 02:00 UTC.'),
    CsFlashbarType.inProgress: ('Creating snapshot', 'Snapshot of vol-0abc123 is in progress.'),
  };

  CsFlashbarItem _make(CsFlashbarType type, {bool loading = false}) {
    final id = 'flash-${_next++}';
    final (header, content) = _samples[type]!;
    return CsFlashbarItem(
      id: id,
      type: type,
      loading: loading,
      header: header,
      content: content,
      dismissible: true,
      onDismiss: () => setState(() => _items = _items.where((i) => i.id != id).toList()),
      buttonText: type == CsFlashbarType.error ? 'Empty bucket' : null,
      onButtonPress: () {},
    );
  }

  void _add(CsFlashbarType type, {bool loading = false}) =>
      setState(() => _items = [_make(type, loading: loading), ..._items]);

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Add messages',
          caption: 'New messages slide in and are announced; dismissed ones slide out.',
          child: _row([
            for (final t in CsFlashbarType.values) CsButton(text: 'Add ${t.name}', onPress: () => _add(t)),
            CsButton(text: 'Add loading', onPress: () => _add(CsFlashbarType.info, loading: true)),
            CsButton(
              text: _stack ? 'Show as list' : 'Stack items',
              variant: CsButtonVariant.link,
              onPress: () => setState(() => _stack = !_stack),
            ),
          ]),
        ),
        DemoSection(
          title: _stack ? 'Stacked' : 'List',
          caption: '${_items.length} messages',
          child: CsFlashbar(items: _items, stackItems: _stack),
        ),
        const DemoSection(
          title: 'Progress inside a flash',
          child: CsFlash(
            item: CsFlashbarItem(
              type: CsFlashbarType.inProgress,
              contentWidget: CsProgressBar(
                variant: CsProgressBarVariant.flash,
                label: 'Creating snapshot of vol-0abc123',
                value: 42,
                additionalInfo: 'About 3 minutes remaining',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertDemo extends StatefulWidget {
  const _AlertDemo();

  @override
  State<_AlertDemo> createState() => _AlertDemoState();
}

class _AlertDemoState extends State<_AlertDemo> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Types',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              for (final t in CsAlertType.values)
                CsAlert(type: t, content: 'Sample ${t.name} message about the bucket example-bucket.'),
            ],
          ),
        ),
        DemoSection(
          title: 'Header, action and dismiss',
          caption: 'The action moves below the message on narrow screens.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsAlert(
                visible: _visible,
                type: CsAlertType.error,
                header: 'Could not delete bucket',
                content: 'example-bucket is not empty. Empty it, then try again.',
                action: CsButton(text: 'Empty bucket', onPress: () {}),
                dismissible: true,
                onDismiss: () => setState(() => _visible = false),
              ),
              if (!_visible) CsButton(text: 'Show alert again', onPress: () => setState(() => _visible = true)),
              const CsAlert(
                type: CsAlertType.warning,
                header: 'Instance is running',
                child: CsSpaceBetween(
                  size: CsSpacingSize.xxs,
                  children: [
                    Text('Stop i-0abc123 before you change its instance type.'),
                    CsLink(text: 'Learn about instance types', external: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressBarDemo extends StatefulWidget {
  const _ProgressBarDemo();

  @override
  State<_ProgressBarDemo> createState() => _ProgressBarDemoState();
}

class _ProgressBarDemoState extends State<_ProgressBarDemo> {
  double _value = 0;
  CsProgressBarStatus _status = CsProgressBarStatus.inProgress;
  Timer? _timer;

  void _start({bool fail = false}) {
    _timer?.cancel();
    setState(() {
      _value = 0;
      _status = CsProgressBarStatus.inProgress;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        _value += 7;
        if (fail && _value >= 60) {
          _status = CsProgressBarStatus.error;
          t.cancel();
        } else if (_value >= 100) {
          _value = 100;
          _status = CsProgressBarStatus.success;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Running operation',
          caption: 'The bar animates to each value; the result fades in.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsProgressBar(
                label: 'Creating snapshot',
                description: 'vol-0abc123',
                value: _value,
                status: _status,
                additionalInfo: 'Sample data, updated every 300 ms',
                resultText: _status == CsProgressBarStatus.success ? 'Snapshot created' : 'Snapshot failed',
                resultButtonText: _status == CsProgressBarStatus.error ? 'Retry' : null,
                onResultButtonPress: _start,
              ),
              _row([
                CsButton(text: 'Start', onPress: _start),
                CsButton(text: 'Start and fail', onPress: () => _start(fail: true)),
              ]),
            ],
          ),
        ),
        const DemoSection(
          title: 'Key-value',
          child: CsProgressBar(
            variant: CsProgressBarVariant.keyValue,
            label: 'Storage used',
            value: 73,
            additionalInfo: '73 of 100 GiB',
          ),
        ),
      ],
    );
  }
}

class _SkeletonDemo extends StatefulWidget {
  const _SkeletonDemo();

  @override
  State<_SkeletonDemo> createState() => _SkeletonDemoState();
}

class _SkeletonDemoState extends State<_SkeletonDemo> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Instance summary',
          caption: 'The wave runs only while loading and is off with reduced motion.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsSkeleton(
                loading: _loading,
                variant: CsSkeletonVariant.textHeadingL,
                width: 220,
                child: const CsBox(variant: CsBoxVariant.h2, text: 'i-0abc123'),
              ),
              CsSkeleton(
                loading: _loading,
                child: const Text('m5.large in us-east-1a, running for 12 days. Sample data.'),
              ),
              _row([
                CsButton(
                  text: _loading ? 'Finish loading' : 'Load again',
                  onPress: () => setState(() => _loading = !_loading),
                ),
              ]),
            ],
          ),
        ),
        DemoSection(
          title: 'Variants',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [for (final v in CsSkeletonVariant.values) CsSkeleton(variant: v, width: 240)],
          ),
        ),
        const DemoSection(
          title: 'Lines and blocks',
          child: CsSpaceBetween(size: CsSpacingSize.s, children: [CsSkeletonLines(lines: 3), CsSkeleton(height: 120)]),
        ),
      ],
    );
  }
}

class _LiveRegionDemo extends StatefulWidget {
  const _LiveRegionDemo();

  @override
  State<_LiveRegionDemo> createState() => _LiveRegionDemoState();
}

class _LiveRegionDemoState extends State<_LiveRegionDemo> {
  int _matches = 12;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Visible result count',
          caption: 'Turn on a screen reader: the count is announced when it changes.',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              CsLiveRegion(child: CsBox(text: '$_matches instances match')),
              _row([
                CsButton(text: 'Narrow filter', onPress: () => setState(() => _matches = (_matches / 2).floor())),
                CsButton(text: 'Clear filter', onPress: () => setState(() => _matches = 12)),
              ]),
            ],
          ),
        ),
        DemoSection(
          title: 'Hidden, assertive',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              CsLiveRegion(hidden: true, assertive: true, message: _saved ? 'Settings saved' : null),
              _row([
                CsButton(text: 'Save settings', onPress: () => setState(() => _saved = true)),
                CsButton(
                  text: 'Announce once',
                  variant: CsButtonVariant.link,
                  onPress: () => CsLiveRegion.announce(context, 'ARN copied'),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBoundaryDemo extends StatefulWidget {
  const _ErrorBoundaryDemo();

  @override
  State<_ErrorBoundaryDemo> createState() => _ErrorBoundaryDemoState();
}

class _ErrorBoundaryDemoState extends State<_ErrorBoundaryDemo> {
  final GlobalKey<CsErrorBoundaryState> _custom = GlobalKey();
  bool _broken = false;
  final List<String> _log = [];

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'A widget that throws while building',
          caption: 'Break the section to replace it with the default fallback. Refresh builds it again.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsButton(text: 'Break instance details', onPress: _broken ? null : () => setState(() => _broken = true)),
              CsErrorBoundary(
                errorBoundaryId: 'instance-details',
                onError: (d) => setState(() => _log.insert(0, '${d.errorBoundaryId}: ${d.error}')),
                onRefresh: () => setState(() => _broken = false),
                child: _InstanceDetails(broken: _broken),
              ),
              if (_log.isNotEmpty)
                CsBox(color: CsBoxColor.textBodySecondary, variant: CsBoxVariant.small, text: 'onError: ${_log.first}'),
            ],
          ),
        ),
        DemoSection(
          title: 'Custom fallback',
          caption: 'renderFallback rearranges the default slots.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsButton(text: 'Show fallback', onPress: () => _custom.currentState?.forceError()),
              CsErrorBoundary(
                key: _custom,
                onError: (_) {},
                i18nStrings: const CsErrorBoundaryI18nStrings(
                  headerText: 'Metrics could not be shown',
                  descriptionText: 'The chart failed to render.',
                  refreshActionText: 'Try again',
                ),
                renderFallback: (context, slots) => CsContainer(
                  header: DefaultTextStyle.merge(
                    style: context.cs.text(CsTypeScale.headingS, weight: CsTypography.bold),
                    child: slots.header,
                  ),
                  footer: slots.action,
                  child: slots.description,
                ),
                child: const CsContainer(child: Text('CPU utilization 42%, network in 1.2 MB/s')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstanceDetails extends StatelessWidget {
  const _InstanceDetails({required this.broken});

  final bool broken;

  @override
  Widget build(BuildContext context) {
    if (broken) throw StateError('Sample failure: instance details could not be built');
    return const CsContainer(
      child: CsKeyValuePairs(
        items: [
          CsKeyValuePair(label: 'Instance ID', value: 'i-0abc123'),
          CsKeyValuePair(
            label: 'State',
            valueWidget: CsStatusIndicator(type: CsStatusType.success, text: 'Running'),
          ),
        ],
      ),
    );
  }
}
