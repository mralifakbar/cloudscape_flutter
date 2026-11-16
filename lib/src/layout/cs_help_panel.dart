import 'package:flutter/widgets.dart';

import '../feedback/cs_spinner.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// Cloudscape's `HelpPanel`: the help content shown in the app layout's
/// tools panel, with a header, body text and a footer of related links.
///
/// ```dart
/// CsHelpPanel(
///   header: 'Instances',
///   footer: const Text('Related: Launch templates'),
///   child: Column(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     children: [
///       CsHelpPanel.paragraph('View and manage your instances.'),
///       CsHelpPanel.heading('Instance state'),
///       CsHelpPanel.list(const ['Running', 'Stopped']),
///     ],
///   ),
/// )
/// ```
///
/// The header uses the panel header font (heading-m, 18/22) above a 1px
/// `color-border-panel-header` divider; the body is
/// `color-text-body-secondary` padded with `space-panel-side-left/right`.
/// The static helpers ([heading], [paragraph], [list], [divider], [code])
/// reproduce Cloudscape's help panel text styles.
class CsHelpPanel extends StatelessWidget {
  const CsHelpPanel({
    super.key,
    this.header,
    this.headerWidget,
    this.child,
    this.footer,
    this.loading = false,
    this.loadingText,
  });

  /// Panel title, usually the page or feature name.
  final String? header;

  /// Custom header in place of [header].
  final Widget? headerWidget;

  /// The help content (Cloudscape `children`).
  final Widget? child;

  /// Content under a divider, usually a "Learn more" list of links.
  final Widget? footer;

  /// Shows a spinner and [loadingText] instead of the content.
  final bool loading;

  /// Defaults to the shared "Loading" string.
  final String? loadingText;

  /// A section heading inside the content (heading-m, 24px above).
  static Widget heading(String text, {bool first = false}) => Builder(
    builder: (context) => Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.only(top: first ? 0 : CsSpace.xl, bottom: CsSpace.xs),
        child: Text(text, style: context.cs.text(CsTypeScale.headingM)),
      ),
    ),
  );

  /// A paragraph with 12px vertical margins.
  static Widget paragraph(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: CsSpace.s / 2),
    child: Text(text),
  );

  /// A bulleted (or numbered) list, indented 20px.
  static Widget list(List<String> items, {bool ordered = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: CsSpace.s / 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: CsSpace.xxs / 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: CsSpace.l, child: Text(ordered ? '${i + 1}.' : '•')),
                Expanded(child: Text(items[i])),
              ],
            ),
          ),
      ],
    ),
  );

  /// A divider between sections (`hr`), with 24px around it.
  static Widget divider() => Builder(
    builder: (context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: CsSpace.xl),
      child: SizedBox(
        height: 1,
        width: double.infinity,
        child: ColoredBox(color: context.cs.colors.borderDividerDefault),
      ),
    ),
  );

  /// Inline monospace text on the code highlight background.
  static Widget code(String text) => Builder(
    builder: (context) => Container(
      margin: const EdgeInsets.symmetric(vertical: CsSpace.xs),
      padding: const EdgeInsets.all(CsSpace.xxs),
      color: context.cs.colors.backgroundContainerHeader,
      child: Text(text, style: context.cs.code()),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final side = EdgeInsetsDirectional.only(start: CsSpace.panelSideLeft, end: cs.space.panelSideRight);
    final headerContent = headerWidget ?? (header == null ? null : Text(header!, style: cs.text(CsTypeScale.headingM)));

    if (loading) {
      final text = loadingText ?? context.csStrings.loading;
      return Padding(
        padding: EdgeInsets.only(top: cs.space.panelHeaderVertical, bottom: cs.space.panelContentBottom),
        child: Padding(
          padding: side,
          child: Semantics(
            liveRegion: true,
            label: text,
            child: Row(
              spacing: CsSpace.xs,
              children: [
                const CsSpinner(),
                Flexible(
                  child: Text(text, style: cs.text(CsTypeScale.bodyM, color: CsColor.textStatusInactive)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: cs.space.panelHeaderVertical, bottom: cs.space.panelContentBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (headerContent != null)
            Container(
              margin: EdgeInsets.only(bottom: cs.space.panelContentTop),
              padding: EdgeInsetsDirectional.only(
                start: CsSpace.panelSideLeft,
                // Room for the close button the app layout draws over the header.
                end: CsSpace.xl + cs.space.scaledXxl,
                bottom: cs.space.panelHeaderVertical,
              ),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: cs.colors.borderPanelHeader)),
              ),
              child: Semantics(
                header: true,
                headingLevel: 2,
                child: DefaultTextStyle.merge(style: cs.text(CsTypeScale.headingM), child: headerContent),
              ),
            ),
          if (child != null)
            Padding(
              padding: side,
              child: DefaultTextStyle.merge(
                style: cs.text(CsTypeScale.bodyM, color: CsColor.textBodySecondary),
                child: child!,
              ),
            ),
          if (footer != null) ...[
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: CsSpace.panelSideLeft - CsSpace.panelDividerMarginHorizontal,
                end: cs.space.panelSideRight - CsSpace.panelDividerMarginHorizontal,
                top: cs.space.scaledXl,
                bottom: cs.space.scaledXl,
              ),
              child: SizedBox(height: 1, child: ColoredBox(color: cs.colors.borderDividerDefault)),
            ),
            Padding(
              padding: side,
              child: DefaultTextStyle.merge(
                style: cs.text(CsTypeScale.bodyM, color: CsColor.textBodySecondary),
                child: footer!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
