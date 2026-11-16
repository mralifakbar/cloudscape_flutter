import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// Theme, icons, type, buttons, spinner, tooltip and the visual contexts.
/// Every name and figure here is sample data.
final CsDemoCategory foundationCategory = CsDemoCategory(
  title: 'Foundation',
  description: 'Buttons, icons, Box typography, spacing, spinners, tooltips and visual contexts.',
  icon: CsIcons.settings,
  demos: [
    CsDemo(
      title: 'CsButton',
      description: 'Normal, primary, link and icon variants, with icons, loading and disabled states.',
      docPath: 'doc/components/CsButton.md',
      builder: (_) => const _ButtonDemo(),
    ),
    CsDemo(
      title: 'CsBox',
      description: 'Headings, paragraphs, small print, code, key labels and large values.',
      docPath: 'doc/components/CsBox.md',
      builder: (_) => const _BoxDemo(),
    ),
    CsDemo(
      title: 'CsSpaceBetween',
      description: 'Token-sized gaps, vertical and horizontal.',
      docPath: 'doc/components/CsSpaceBetween.md',
      builder: (_) => const _SpaceBetweenDemo(),
    ),
    CsDemo(
      title: 'CsIcon',
      description: 'Sizes from x-small to large, each with its own stroke, and the color variants.',
      docPath: 'doc/components/CsIcon.md',
      builder: (_) => const _IconDemo(),
    ),
    CsDemo(
      title: 'CsSpinner',
      description: 'Normal, big and large, and inverted on a dark surface.',
      docPath: 'doc/components/CsSpinner.md',
      builder: (_) => const _SpinnerDemo(),
    ),
    CsDemo(
      title: 'CsTooltip',
      description: 'A short label on hover, focus and long press.',
      docPath: 'doc/components/CsTooltip.md',
      builder: (_) => const _TooltipDemo(),
    ),
    CsDemo(
      title: 'CsVisualContext',
      description: 'The dark top navigation and high-contrast header contexts recolor their content.',
      docPath: 'doc/components/CsVisualContext.md',
      builder: (_) => const _VisualContextDemo(),
    ),
    CsDemo(
      title: 'CsIconProvider',
      description: 'Replaces built-in icons by name for a subtree, including the icons inside components.',
      docPath: 'doc/components/CsIconProvider.md',
      builder: (_) => const _IconProviderDemo(),
    ),
    CsDemo(
      title: 'CsNavigableGroup',
      description: 'A toolbar that is one Tab stop, with the arrow keys moving between its buttons.',
      docPath: 'doc/components/CsNavigableGroup.md',
      builder: (_) => const _NavigableGroupDemo(),
    ),
  ],
);

class _ButtonDemo extends StatefulWidget {
  const _ButtonDemo();

  @override
  State<_ButtonDemo> createState() => _ButtonDemoState();
}

class _ButtonDemoState extends State<_ButtonDemo> {
  bool _loading = false;
  int _presses = 0;

  Future<void> _launch() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Variants',
          child: CsSpaceBetween(
            direction: CsSpaceBetweenDirection.horizontal,
            size: CsSpacingSize.xs,
            children: [
              CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () {}),
              CsButton(text: 'Edit', onPress: () => setState(() => _presses++)),
              CsButton(text: 'Create distribution', variant: CsButtonVariant.primary, onPress: () {}),
            ],
          ),
        ),
        DemoSection(
          title: 'With icons',
          child: CsSpaceBetween(
            direction: CsSpaceBetweenDirection.horizontal,
            size: CsSpacingSize.xs,
            alignItems: CsSpaceBetweenAlign.center,
            children: [
              CsButton(text: 'Add item', icon: CsIcons.addPlus, onPress: () {}),
              CsButton(
                text: 'Actions',
                icon: CsIcons.caretDownFilled,
                iconAlign: CsButtonIconAlign.right,
                onPress: () {},
              ),
              CsButton(text: 'Documentation', external: true, variant: CsButtonVariant.link, onPress: () {}),
              CsButton(icon: CsIcons.refresh, semanticLabel: 'Refresh instances', onPress: () {}),
              CsButton(
                icon: CsIcons.settings,
                variant: CsButtonVariant.icon,
                semanticLabel: 'Preferences',
                onPress: () {},
              ),
              CsButton(
                icon: CsIcons.copy,
                variant: CsButtonVariant.inlineIcon,
                semanticLabel: 'Copy ARN',
                onPress: () {},
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Loading and disabled',
          caption: 'A disabled button with a reason stays focusable and explains itself in a tooltip.',
          child: CsSpaceBetween(
            direction: CsSpaceBetweenDirection.horizontal,
            size: CsSpacingSize.xs,
            children: [
              CsButton(
                text: _loading ? 'Launching' : 'Launch instance',
                variant: CsButtonVariant.primary,
                loading: _loading,
                loadingText: 'Launching instance',
                onPress: _launch,
              ),
              const CsButton(text: 'Delete'),
              CsButton(
                text: 'Stop',
                disabled: true,
                disabledReason: 'The instance is already stopped.',
                onPress: () {},
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Inline link and full width',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: CsSpace.xxs,
                children: [
                  CsBox(text: 'Edit pressed $_presses ${_presses == 1 ? 'time' : 'times'}.'),
                  CsButton(
                    text: 'Reset',
                    variant: CsButtonVariant.inlineLink,
                    onPress: () => setState(() => _presses = 0),
                  ),
                ],
              ),
              CsButton(text: 'Continue', variant: CsButtonVariant.primary, fullWidth: true, onPress: () {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoxDemo extends StatelessWidget {
  const _BoxDemo();

  @override
  Widget build(BuildContext context) {
    return const DemoColumn(
      children: [
        DemoSection(
          title: 'Text variants',
          child: CsSpaceBetween(
            size: CsSpacingSize.n,
            children: [
              CsBox(variant: CsBoxVariant.h1, text: 'Heading 1'),
              CsBox(variant: CsBoxVariant.h2, text: 'Heading 2'),
              CsBox(variant: CsBoxVariant.h3, text: 'Heading 3'),
              CsBox(variant: CsBoxVariant.h4, text: 'Heading 4'),
              CsBox(variant: CsBoxVariant.h5, text: 'Heading 5'),
              CsBox(
                variant: CsBoxVariant.p,
                text: 'Paragraph text is 14px on a 20px line, the size of all content in Cloudscape.',
              ),
              CsBox(variant: CsBoxVariant.small, text: 'Small text for descriptions and fine print.'),
              CsBox(variant: CsBoxVariant.code, text: 'arn:aws:s3:::example-bucket'),
            ],
          ),
        ),
        DemoSection(
          title: 'Key-value and large values',
          child: Wrap(
            spacing: CsSpace.xxl,
            runSpacing: CsSpace.s,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CsBox(variant: CsBoxVariant.awsuiKeyLabel, text: 'Running instances'),
                  CsBox(variant: CsBoxVariant.awsuiValueLarge, text: '14'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CsBox(variant: CsBoxVariant.awsuiKeyLabel, text: 'Status'),
                  CsBox(color: CsBoxColor.textStatusSuccess, text: 'Healthy'),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Inline code and generative AI label',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: CsSpace.xxs,
                children: [
                  CsBox(text: 'Run'),
                  CsBox(variant: CsBoxVariant.awsuiInlineCode, text: 'aws s3 ls'),
                  CsBox(text: 'to list buckets.'),
                ],
              ),
              CsBox(variant: CsBoxVariant.awsuiGenAiLabel, text: 'Generated by AI. Review before you use it.'),
            ],
          ),
        ),
        DemoSection(
          title: 'Visual accents',
          child: CsSpaceBetween(
            direction: CsSpaceBetweenDirection.horizontal,
            size: CsSpacingSize.xs,
            children: [
              CsVisualAccent(color: CsVisualAccentColor.indigo, equalAspect: true, child: CsIcon(CsIcons.globe)),
              CsVisualAccent(color: CsVisualAccentColor.green, equalAspect: true, child: CsIcon(CsIcons.security)),
              CsVisualAccent(color: CsVisualAccentColor.orange, equalAspect: true, child: CsIcon(CsIcons.key)),
              CsVisualAccent(
                color: CsVisualAccentColor.purple,
                child: CsBox(variant: CsBoxVariant.strong, text: 'New'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpaceBetweenDemo extends StatelessWidget {
  const _SpaceBetweenDemo();

  @override
  Widget build(BuildContext context) {
    Widget chip(String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.xs, vertical: CsSpace.xxs),
      decoration: BoxDecoration(
        color: context.cs.colors.backgroundItemSelected,
        borderRadius: BorderRadius.circular(CsBorderRadius.badge),
      ),
      child: CsBox(text: t),
    );
    return DemoColumn(
      children: [
        for (final size in [CsSpacingSize.xxs, CsSpacingSize.s, CsSpacingSize.xl])
          DemoSection(
            title: 'Horizontal, ${size.name} (${size.value.toInt()}px)',
            child: CsSpaceBetween(
              direction: CsSpaceBetweenDirection.horizontal,
              size: size,
              children: [chip('First'), chip('Second'), chip('Third')],
            ),
          ),
      ],
    );
  }
}

class _IconDemo extends StatelessWidget {
  const _IconDemo();

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Sizes',
          caption: 'Strokes stay 1.5 to 4px at every size.',
          child: CsSpaceBetween(
            direction: CsSpaceBetweenDirection.horizontal,
            size: CsSpacingSize.m,
            alignItems: CsSpaceBetweenAlign.end,
            children: [for (final s in CsIconSize.values) CsIcon(CsIcons.settings, size: s)],
          ),
        ),
        const DemoSection(
          title: 'Variants',
          child: CsSpaceBetween(
            direction: CsSpaceBetweenDirection.horizontal,
            size: CsSpacingSize.m,
            children: [
              CsIcon(CsIcons.statusPositive, variant: CsIconVariant.success),
              CsIcon(CsIcons.statusWarning, variant: CsIconVariant.warning),
              CsIcon(CsIcons.statusNegative, variant: CsIconVariant.error),
              CsIcon(CsIcons.statusInfo, variant: CsIconVariant.info),
              CsIcon(CsIcons.external, variant: CsIconVariant.link),
              CsIcon(CsIcons.lockPrivate, variant: CsIconVariant.subtle),
              CsIcon(CsIcons.close, variant: CsIconVariant.disabled),
              CsIcon(CsIcons.notification, badge: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpinnerDemo extends StatelessWidget {
  const _SpinnerDemo();

  @override
  Widget build(BuildContext context) {
    return const DemoColumn(
      children: [
        DemoSection(
          title: 'Sizes',
          child: CsSpaceBetween(
            direction: CsSpaceBetweenDirection.horizontal,
            size: CsSpacingSize.l,
            alignItems: CsSpaceBetweenAlign.center,
            children: [
              CsSpinner(),
              CsSpinner(size: CsSpinnerSize.big),
              CsSpinner(size: CsSpinnerSize.large),
            ],
          ),
        ),
        DemoSection(
          title: 'Inline with text',
          child: Row(
            spacing: CsSpace.xxs,
            children: [
              CsSpinner(semanticLabel: ''),
              CsBox(text: 'Loading instances'),
            ],
          ),
        ),
      ],
    );
  }
}

class _TooltipDemo extends StatelessWidget {
  const _TooltipDemo();

  @override
  Widget build(BuildContext context) {
    return DemoSection(
      title: 'On an icon button',
      caption: 'Hover, focus with the keyboard, or long press on touch.',
      child: Row(
        children: [
          CsTooltip(
            content: 'Copy the bucket ARN',
            child: CsButton(
              icon: CsIcons.copy,
              variant: CsButtonVariant.icon,
              semanticLabel: 'Copy ARN',
              onPress: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualContextDemo extends StatelessWidget {
  const _VisualContextDemo();

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Header context',
          caption: 'Always dark, for the high-contrast page header.',
          child: CsVisualContext(
            context: CsVisualContextName.header,
            child: Builder(
              builder: (context) => Container(
                padding: const EdgeInsets.all(CsSpace.l),
                decoration: BoxDecoration(
                  color: context.cs.colors.backgroundHomeHeader,
                  borderRadius: BorderRadius.circular(CsBorderRadius.container),
                ),
                child: CsHeader(
                  variant: CsHeaderVariant.h1,
                  title: 'Amazon S3',
                  description: 'Object storage built to retrieve any amount of data.',
                  actions: CsButton(text: 'Create bucket', variant: CsButtonVariant.primary, onPress: () {}),
                ),
              ),
            ),
          ),
        ),
        DemoSection(
          title: 'Top navigation context',
          child: CsVisualContext(
            context: CsVisualContextName.topNavigation,
            child: Builder(
              builder: (context) => Container(
                padding: const EdgeInsets.symmetric(horizontal: CsSpace.l, vertical: CsSpace.xs),
                color: context.cs.colors.backgroundContainerContent,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Service console',
                        style: context.cs.text(CsTypeScale.headingS, color: CsColor.textTopNavigationTitle),
                      ),
                    ),
                    CsButton(
                      icon: CsIcons.notification,
                      variant: CsButtonVariant.icon,
                      semanticLabel: 'Notifications',
                      onPress: () {},
                    ),
                    CsButton(
                      icon: CsIcons.userProfile,
                      variant: CsButtonVariant.icon,
                      semanticLabel: 'Account',
                      onPress: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconProviderDemo extends StatefulWidget {
  const _IconProviderDemo();

  @override
  State<_IconProviderDemo> createState() => _IconProviderDemoState();
}

class _IconProviderDemoState extends State<_IconProviderDemo> {
  bool _override = true;

  static const _icons = {
    'close': CsIcons.arrowLeft,
    'status-positive': CsIcons.check,
    'caret-down-filled': CsIcons.angleDown,
    'settings': CsIcons.sliders,
  };

  Widget _sample() => Wrap(
    spacing: CsSpace.m,
    runSpacing: CsSpace.s,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const CsIcon(CsIcons.close, semanticLabel: 'close'),
      const CsIcon(CsIcons.settings, semanticLabel: 'settings'),
      const CsStatusIndicator(type: CsStatusType.success, text: 'Available'),
      CsButton(icon: CsIcons.settings, variant: CsButtonVariant.icon, semanticLabel: 'Preferences', onPress: () {}),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Overrides by name',
          caption: 'close, status-positive, caret-down-filled and settings are replaced below the provider.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsToggle(
                checked: _override,
                onChange: (v) => setState(() => _override = v),
                child: const Text('Apply the icon overrides'),
              ),
              CsIconProvider(icons: _override ? _icons : const {}, child: _sample()),
            ],
          ),
        ),
        const DemoSection(
          title: 'Nested reset',
          caption: 'An inner provider resets close to the built-in icon; CsIconProvider.reset clears every override.',
          child: CsIconProvider(
            icons: _icons,
            child: Row(
              spacing: CsSpace.l,
              children: [
                CsIcon(CsIcons.close, semanticLabel: 'Overridden'),
                CsIconProvider(
                  icons: {'close': null},
                  child: CsIcon(CsIcons.close, semanticLabel: 'Reset by name'),
                ),
                CsIconProvider.reset(child: CsIcon(CsIcons.settings, semanticLabel: 'Reset all')),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Widget override',
          caption: 'Any widget, sized like the icon it replaces.',
          child: CsIconProvider(
            iconWidgets: {
              'user-profile': DecoratedBox(
                decoration: BoxDecoration(color: context.cs.colors.backgroundBadgeIcon, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: 16),
              ),
            },
            child: const Row(
              spacing: CsSpace.s,
              children: [
                CsIcon(CsIcons.userProfile, size: CsIconSize.medium),
                Flexible(child: Text('Signed in as sample-user')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NavigableGroupDemo extends StatefulWidget {
  const _NavigableGroupDemo();

  @override
  State<_NavigableGroupDemo> createState() => _NavigableGroupDemoState();
}

class _NavigableGroupDemoState extends State<_NavigableGroupDemo> {
  final GlobalKey<CsNavigableGroupState> _toolbar = GlobalKey();
  String _last = 'none';
  bool _loop = false;
  bool _bold = false;
  bool _italic = false;

  void _act(String name) => setState(() => _last = name);

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Instance actions toolbar',
          caption:
              'Tab once into the group, then use the left and right arrows, Home and End. '
              'Terminate is disabled and skipped. Last action: $_last.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsToggle(
                checked: _loop,
                onChange: (v) => setState(() => _loop = v),
                child: const Text('Wrap around at the ends'),
              ),
              CsNavigableGroup(
                key: _toolbar,
                loop: _loop,
                semanticLabel: 'Instance actions',
                child: Wrap(
                  spacing: CsSpace.xs,
                  runSpacing: CsSpace.xs,
                  children: [
                    CsButton(text: 'Start', onPress: () => _act('Start')),
                    CsButton(text: 'Stop', onPress: () => _act('Stop')),
                    CsButton(text: 'Reboot', onPress: () => _act('Reboot')),
                    const CsButton(text: 'Terminate', disabled: true),
                    CsButton(
                      icon: CsIcons.refresh,
                      variant: CsButtonVariant.icon,
                      semanticLabel: 'Refresh',
                      onPress: () => _act('Refresh'),
                    ),
                  ],
                ),
              ),
              CsButton(
                text: 'Focus the toolbar',
                variant: CsButtonVariant.link,
                onPress: () => _toolbar.currentState?.focus(),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Vertical toggle buttons',
          caption: 'navigationDirection vertical: up and down move between the toggles.',
          child: CsNavigableGroup(
            navigationDirection: CsNavigationDirection.vertical,
            semanticLabel: 'Text style',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CsSpace.xs,
              children: [
                CsToggleButton(text: 'Bold', pressed: _bold, onChange: (v) => setState(() => _bold = v)),
                CsToggleButton(text: 'Italic', pressed: _italic, onChange: (v) => setState(() => _italic = v)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
