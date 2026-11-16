import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// Button dropdowns, button groups, toggle buttons and copy to clipboard. Every name and figure here is sample data.
final CsDemoCategory actionsCategory = CsDemoCategory(
  title: 'Actions',
  description: 'Button dropdowns, button groups, toggle buttons and copy to clipboard.',
  icon: CsIcons.ellipsis,
  demos: [
    CsDemo(
      title: 'CsButtonDropdown',
      description: 'Menus with groups, checkbox items, expandable groups, disabled reasons, links and a split button.',
      docPath: 'doc/components/CsButtonDropdown.md',
      builder: (_) => const _ButtonDropdownDemo(),
    ),
    CsDemo(
      title: 'CsButtonGroup',
      description: 'Icon buttons, toggles, copy and an overflow menu with click feedback.',
      docPath: 'doc/components/CsButtonGroup.md',
      builder: (_) => const _ButtonGroupDemo(),
    ),
    CsDemo(
      title: 'CsToggleButton',
      description: 'Normal and icon toggles, pressed and not, with disabled and loading states.',
      docPath: 'doc/components/CsToggleButton.md',
      builder: (_) => const _ToggleButtonDemo(),
    ),
    CsDemo(
      title: 'CsCopyToClipboard',
      description: 'Button, icon and inline variants with success feedback.',
      docPath: 'doc/components/CsCopyToClipboard.md',
      builder: (_) => const _CopyDemo(),
    ),
    CsDemo(
      title: 'CsDropdown',
      description: 'The dropdown container: anchored on wide screens, a bottom sheet on phones.',
      docPath: 'doc/components/CsDropdown.md',
      builder: (_) => const _DropdownDemo(),
    ),
    CsDemo(
      title: 'CsMenuPanel',
      description: 'Menu surface, rows, group labels, separators and arrow-key movement.',
      docPath: 'doc/components/CsMenuPanel.md',
      builder: (_) => const _MenuPanelDemo(),
    ),
  ],
);

class _ButtonDropdownDemo extends StatefulWidget {
  const _ButtonDropdownDemo();

  @override
  State<_ButtonDropdownDemo> createState() => _ButtonDropdownDemoState();
}

class _ButtonDropdownDemoState extends State<_ButtonDropdownDemo> {
  String _last = 'No action yet';
  bool _monitoring = true;
  bool _protection = false;

  List<CsButtonDropdownItemOrGroup> get _items => [
    const CsButtonDropdownGroup(
      text: 'Instance state',
      items: [
        CsButtonDropdownItem(id: 'start', text: 'Start instance', icon: CsIcons.play),
        CsButtonDropdownItem(id: 'reboot', text: 'Reboot instance', icon: CsIcons.refresh, labelTag: 'R'),
        CsButtonDropdownItem(
          id: 'stop',
          text: 'Stop instance',
          icon: CsIcons.stopCircle,
          disabled: true,
          disabledReason: 'The instance is already stopped.',
        ),
      ],
    ),
    CsButtonDropdownGroup(
      text: 'Settings',
      items: [
        CsButtonDropdownCheckboxItem(id: 'monitoring', text: 'Detailed monitoring', checked: _monitoring),
        CsButtonDropdownCheckboxItem(id: 'protection', text: 'Termination protection', checked: _protection),
      ],
    ),
    const CsButtonDropdownGroup(
      text: 'Networking',
      expandable: true,
      items: [
        CsButtonDropdownItem(id: 'ip', text: 'Associate IP address', secondaryText: 'Elastic IP'),
        CsButtonDropdownGroup(
          text: 'Security',
          expandable: true,
          items: [CsButtonDropdownItem(id: 'sg', text: 'Change security groups')],
        ),
      ],
    ),
    const CsButtonDropdownItem(id: 'docs', text: 'Instance documentation', external: true),
  ];

  void _click(CsButtonDropdownItemClickDetails d) {
    setState(() {
      if (d.id == 'monitoring') _monitoring = d.checked!;
      if (d.id == 'protection') _protection = d.checked!;
      _last = d.checked == null ? 'Clicked ${d.id}' : '${d.id} turned ${d.checked! ? 'on' : 'off'}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Groups, checkboxes, expandable groups and a link',
          caption: _last,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: CsButtonDropdown(
              text: 'Instance actions',
              items: _items,
              onItemClick: _click,
              onItemFollow: (d) => setState(() => _last = 'Followed ${d.id}'),
            ),
          ),
        ),
        DemoSection(
          title: 'Variants',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CsButtonDropdown(text: 'Normal', items: _items, onItemClick: _click),
              CsButtonDropdown(
                text: 'Primary',
                variant: CsButtonDropdownVariant.primary,
                items: _items,
                onItemClick: _click,
              ),
              CsButtonDropdown(
                variant: CsButtonDropdownVariant.icon,
                ariaLabel: 'More actions',
                items: _items,
                onItemClick: _click,
              ),
              CsButtonDropdown(
                variant: CsButtonDropdownVariant.inlineIcon,
                ariaLabel: 'Row actions',
                items: _items,
                onItemClick: _click,
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Split button',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              CsButtonDropdown(
                variant: CsButtonDropdownVariant.primary,
                ariaLabel: 'More launch options',
                mainAction: CsButtonDropdownMainAction(
                  text: 'Launch instance',
                  onPress: () => setState(() => _last = 'Launched'),
                ),
                items: const [
                  CsButtonDropdownItem(id: 'template', text: 'Launch from template'),
                  CsButtonDropdownItem(id: 'spot', text: 'Request Spot instance'),
                ],
                onItemClick: _click,
              ),
              CsButtonDropdown(
                ariaLabel: 'More export options',
                mainAction: CsButtonDropdownMainAction(
                  text: 'Export',
                  icon: CsIcons.download,
                  onPress: () => setState(() => _last = 'Exported'),
                ),
                items: const [
                  CsButtonDropdownItem(id: 'csv', text: 'Export as CSV'),
                  CsButtonDropdownItem(id: 'json', text: 'Export as JSON'),
                ],
                onItemClick: _click,
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Filtering, loading and disabled',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              CsButtonDropdown(
                text: 'Find action',
                items: _items,
                filteringType: true,
                filteringPlaceholder: 'Find action',
                noMatch: const CsBox(text: 'No actions match', color: CsBoxColor.textBodySecondary),
                onItemClick: _click,
              ),
              CsButtonDropdown(text: 'Loading', items: _items, loading: true, loadingText: 'Loading actions'),
              CsButtonDropdown(
                text: 'Disabled',
                items: _items,
                disabled: true,
                disabledReason: 'Select an instance first.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ButtonGroupDemo extends StatefulWidget {
  const _ButtonGroupDemo();

  @override
  State<_ButtonGroupDemo> createState() => _ButtonGroupDemoState();
}

class _ButtonGroupDemoState extends State<_ButtonGroupDemo> {
  bool _up = false;
  bool _down = false;
  String _last = 'No action yet';

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Message actions',
          caption: _last,
          child: CsButtonGroup(
            ariaLabel: 'Message actions',
            items: [
              CsButtonGroupGroup(
                text: 'Vote',
                items: [
                  CsButtonGroupIconToggleButton(
                    id: 'up',
                    text: 'Helpful',
                    icon: CsIcons.thumbsUp,
                    pressedIcon: CsIcons.thumbsUpFilled,
                    pressed: _up,
                    pressedPopoverFeedback: 'Marked helpful',
                  ),
                  CsButtonGroupIconToggleButton(
                    id: 'down',
                    text: 'Not helpful',
                    icon: CsIcons.thumbsDown,
                    pressedIcon: CsIcons.thumbsDownFilled,
                    pressed: _down,
                    pressedPopoverFeedback: 'Feedback sent',
                  ),
                ],
              ),
              const CsButtonGroupCopyToClipboard(
                id: 'copy',
                text: 'Copy',
                textToCopy: 'Sample response for instance i-0abc123',
                copySuccessText: 'Copied',
                copyErrorText: 'Failed to copy',
              ),
              const CsButtonGroupIconButton(
                id: 'refresh',
                text: 'Regenerate',
                icon: CsIcons.refresh,
                popoverFeedback: 'Regenerating',
              ),
              const CsButtonGroupIconButton(
                id: 'edit',
                text: 'Edit',
                icon: CsIcons.edit,
                disabled: true,
                disabledReason: 'Responses cannot be edited.',
              ),
              const CsButtonGroupMenuDropdown(
                id: 'more',
                text: 'More actions',
                items: [
                  CsButtonDropdownItem(id: 'share', text: 'Share', icon: CsIcons.share),
                  CsButtonDropdownItem(id: 'report', text: 'Report a problem', icon: CsIcons.flag),
                ],
              ),
            ],
            onItemClick: (d) => setState(() {
              if (d.id == 'up') {
                _up = d.pressed!;
                if (_up) _down = false;
              }
              if (d.id == 'down') {
                _down = d.pressed!;
                if (_down) _up = false;
              }
              _last = d.pressed == null ? 'Clicked ${d.id}' : '${d.id} ${d.pressed! ? 'pressed' : 'released'}';
            }),
            onCopySuccess: (id) => setState(() => _last = 'Copied with $id'),
          ),
        ),
      ],
    );
  }
}

class _ToggleButtonDemo extends StatefulWidget {
  const _ToggleButtonDemo();

  @override
  State<_ToggleButtonDemo> createState() => _ToggleButtonDemoState();
}

class _ToggleButtonDemoState extends State<_ToggleButtonDemo> {
  bool _favorite = false;
  bool _grid = true;
  bool _muted = false;

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
              CsToggleButton(
                text: 'Favorite',
                icon: CsIcons.star,
                pressedIcon: CsIcons.starFilled,
                pressed: _favorite,
                onChange: (v) => setState(() => _favorite = v),
              ),
              CsToggleButton(text: 'Show grid', pressed: _grid, onChange: (v) => setState(() => _grid = v)),
            ],
          ),
        ),
        DemoSection(
          title: 'Icon',
          child: Wrap(
            spacing: CsSpace.xs,
            children: [
              CsToggleButton(
                variant: CsToggleButtonVariant.icon,
                icon: CsIcons.audioFull,
                pressedIcon: CsIcons.audioOff,
                ariaLabel: 'Mute',
                pressed: _muted,
                onChange: (v) => setState(() => _muted = v),
              ),
              CsToggleButton(
                variant: CsToggleButtonVariant.icon,
                icon: CsIcons.heart,
                pressedIcon: CsIcons.heartFilled,
                ariaLabel: 'Like',
                pressed: _favorite,
                onChange: (v) => setState(() => _favorite = v),
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Disabled and loading',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              CsToggleButton(
                text: 'Pinned',
                pressed: true,
                disabled: true,
                disabledReason: 'Pinned by an administrator.',
              ),
              CsToggleButton(text: 'Syncing', pressed: false, loading: true, loadingText: 'Syncing'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CopyDemo extends StatelessWidget {
  const _CopyDemo();

  @override
  Widget build(BuildContext context) {
    return const DemoColumn(
      children: [
        DemoSection(
          title: 'Button',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: CsCopyToClipboard(
              textToCopy: 'arn:aws:s3:::example-bucket',
              copyButtonText: 'Copy ARN',
              copySuccessText: 'ARN copied',
              copyErrorText: 'ARN failed to copy',
            ),
          ),
        ),
        DemoSection(
          title: 'Icon',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: CsCopyToClipboard(
              variant: CsCopyToClipboardVariant.icon,
              textToCopy: 'd111111abcdef8',
              copyButtonAriaLabel: 'Copy distribution ID',
              copySuccessText: 'Distribution ID copied',
              copyErrorText: 'Distribution ID failed to copy',
            ),
          ),
        ),
        DemoSection(
          title: 'Inline',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CsSpace.s,
            children: [
              CsCopyToClipboard(
                variant: CsCopyToClipboardVariant.inline,
                textToCopy: 'i-0abc123',
                mono: true,
                copySuccessText: 'Instance ID copied',
                copyErrorText: 'Instance ID failed to copy',
              ),
              CsCopyToClipboard(
                variant: CsCopyToClipboardVariant.inline,
                textToCopy: 'arn:aws:s3:::example-bucket/logs/2026/11/16/access-log.gz',
                wrapText: false,
                copySuccessText: 'Object ARN copied',
                copyErrorText: 'Object ARN failed to copy',
              ),
              CsCopyToClipboard(
                variant: CsCopyToClipboardVariant.inline,
                textToCopy: 'secret',
                textToDisplay: 'Copying is unavailable',
                disabled: true,
                disabledReason: 'You do not have access to this value.',
                copySuccessText: 'Copied',
                copyErrorText: 'Failed to copy',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DropdownDemo extends StatefulWidget {
  const _DropdownDemo();

  @override
  State<_DropdownDemo> createState() => _DropdownDemoState();
}

class _DropdownDemoState extends State<_DropdownDemo> {
  bool _open = false;
  final Set<String> _columns = {'Name', 'State'};

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'A custom picker',
          caption: 'Visible columns: ${_columns.join(', ')}. On phones it opens as a bottom sheet that stays open.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: CsDropdown(
              open: _open,
              matchTriggerWidth: false,
              trapFocus: true,
              sheetLabel: 'Visible columns',
              onDismiss: () => setState(() => _open = false),
              contentBuilder: (context, inSheet) => CsMenuPanel(
                children: [
                  const CsMenuGroupLabel('Visible columns'),
                  for (final c in const ['Name', 'Instance ID', 'State', 'Instance type', 'Region'])
                    CsMenuRow(
                      label: c,
                      checked: _columns.contains(c),
                      leading: SizedBox.square(
                        dimension: 16,
                        child: _columns.contains(c) ? const CsIcon(CsIcons.check) : null,
                      ),
                      onPress: () => setState(() => _columns.contains(c) ? _columns.remove(c) : _columns.add(c)),
                    ),
                ],
              ),
              child: CsButton(
                text: 'Columns',
                icon: CsIcons.caretDownFilled,
                iconAlign: CsButtonIconAlign.right,
                expanded: _open,
                onPress: () => setState(() => _open = !_open),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuPanelDemo extends StatefulWidget {
  const _MenuPanelDemo();

  @override
  State<_MenuPanelDemo> createState() => _MenuPanelDemoState();
}

class _MenuPanelDemoState extends State<_MenuPanelDemo> {
  String _last = 'Use Up and Down to move between rows.';

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Rows, labels and separators',
          caption: _last,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 280,
              child: CsMenuPanel(
                children: [
                  const CsMenuGroupLabel('Instance'),
                  CsMenuRow(
                    label: 'Connect',
                    icon: CsIcons.commandPrompt,
                    description: 'Open a session',
                    onPress: () => setState(() => _last = 'Connect'),
                  ),
                  CsMenuRow(label: 'Edit tags', icon: CsIcons.edit, onPress: () => setState(() => _last = 'Edit tags')),
                  CsMenuRow(label: 'Stop', icon: CsIcons.stopCircle, disabled: true, onPress: () {}),
                  const CsMenuSeparator(),
                  CsMenuRow(label: 'View logs', shortcut: 'L', onPress: () => setState(() => _last = 'View logs')),
                  CsMenuRow(
                    label: 'Terminate',
                    icon: CsIcons.remove,
                    destructive: true,
                    onPress: () => setState(() => _last = 'Terminate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
