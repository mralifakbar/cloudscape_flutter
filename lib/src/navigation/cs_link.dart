import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// Link styles (Cloudscape `variant`).
enum CsLinkVariant {
  /// Underlined, so it stands out next to other text: links inside a
  /// paragraph, item IDs in a table, key-value pairs, alerts.
  primary,

  /// No underline until hovered. Use where the context already says the text
  /// is interactive, such as a list of links inside a container. Cloudscape's
  /// default outside tables, cards, alerts and popovers.
  secondary,

  /// The bold body-s "Info" link next to headers and form labels that opens
  /// the help panel. Overrides [CsLink.fontSize] and [CsLink.color].
  info,

  /// A large bold number that links somewhere (`awsui-value-large`), as in a
  /// key-value dashboard. Display-l size unless [CsLink.fontSize] is set.
  awsuiValueLarge,
}

/// Link colors (Cloudscape `color`).
enum CsLinkColor {
  /// `color-text-link-default`: links on regular backgrounds.
  normal,

  /// `color-text-link-inverted-*`, always underlined: links inside flash
  /// messages and other colored backgrounds.
  inverted,
}

/// Font size and line height of a link (Cloudscape `fontSize`).
enum CsLinkFontSize {
  bodyS(CsTypeScale.bodyS),
  bodyM(CsTypeScale.bodyM),
  headingXs(CsTypeScale.headingXs),
  headingS(CsTypeScale.headingS),
  headingM(CsTypeScale.headingM),
  headingL(CsTypeScale.headingL),
  headingXl(CsTypeScale.headingXl),
  displayL(CsTypeScale.displayL),

  /// Take the size of the surrounding text. The default.
  inherit(null);

  const CsLinkFontSize(this.scale);

  /// The type step, or null for [inherit].
  final CsTypeScale? scale;
}

/// Sets the default [CsLinkVariant] for the links below it.
///
/// Cloudscape links default to [CsLinkVariant.secondary], except inside
/// tables, cards, alerts, popovers and the help panel, where they default to
/// [CsLinkVariant.primary] so they stand out from running text. Components
/// that host text-heavy content wrap it in this scope.
///
/// ```dart
/// CsLinkDefaults(variant: CsLinkVariant.primary, child: alertContent)
/// ```
class CsLinkDefaults extends InheritedWidget {
  const CsLinkDefaults({super.key, required this.variant, required super.child});

  /// The variant a [CsLink] without an explicit variant uses.
  final CsLinkVariant variant;

  /// The default variant at [context]: the nearest scope's, else secondary.
  static CsLinkVariant of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CsLinkDefaults>()?.variant ?? CsLinkVariant.secondary;

  @override
  bool updateShouldNotify(CsLinkDefaults oldWidget) => oldWidget.variant != variant;
}

/// Cloudscape's `Link`.
///
/// ```dart
/// CsLink(text: 'View bucket policy', onFollow: openPolicy)
/// CsLink(text: 'Pricing details', external: true, onFollow: openPricing)
/// CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: openHelp)
/// ```
///
/// Flutter has no browser navigation, so following a link always calls
/// [onFollow]; route there. [href] is optional: with one (or with
/// [external]) the link is announced as a link, without one it is announced
/// as a button, as Cloudscape does for an `href`-less link. [onClick] fires
/// on every activation as well, for analytics.
///
/// The link is a single widget. To place one inside a paragraph, put it in a
/// `WidgetSpan` with `alignment: PlaceholderAlignment.baseline`.
///
/// Hover switches to the hover color instantly; [CsLinkVariant.secondary]
/// gains its underline on hover. Keyboard focus draws the 2px focus ring;
/// Enter activates. Inline links keep their text size as the hit area so
/// they do not push lines apart.
class CsLink extends StatelessWidget {
  const CsLink({
    super.key,
    required this.text,
    this.onFollow,
    this.onClick,
    this.href,
    this.variant,
    this.color = CsLinkColor.normal,
    this.fontSize,
    this.external = false,
    this.externalIconAriaLabel,
    this.ariaLabel,
    this.focusNode,
    this.autofocus = false,
    this.maxLines,
  });

  /// The link text (Cloudscape `children`).
  final String text;

  /// Called when the link is followed (Cloudscape `onFollow`). Navigate
  /// here. Without it (and without [onClick]) the link is inert text.
  final VoidCallback? onFollow;

  /// Called on every activation, before [onFollow]. Do not navigate here;
  /// Cloudscape keeps it for side effects such as metrics.
  final VoidCallback? onClick;

  /// Where the link points, for semantics and for routers that key on a
  /// path. Never opened by the widget itself.
  final String? href;

  /// Visual style. Null takes the nearest [CsLinkDefaults], which falls back
  /// to [CsLinkVariant.secondary] like Cloudscape.
  final CsLinkVariant? variant;

  /// Normal or inverted text color. Ignored for [CsLinkVariant.info].
  final CsLinkColor color;

  /// Font size and line height. Null (or [CsLinkFontSize.inherit]) uses the
  /// surrounding text style. Ignored for [CsLinkVariant.info].
  final CsLinkFontSize? fontSize;

  /// Adds the external icon after the text and announces that the link
  /// opens in a new window.
  final bool external;

  /// Accessible name of the external icon. Defaults to
  /// `CsStrings.opensInNewWindow`.
  final String? externalIconAriaLabel;

  /// Accessible name that replaces [text] for screen readers.
  final String? ariaLabel;

  /// Focus node, for moving focus to the link (Cloudscape `ref.focus()`).
  final FocusNode? focusNode;
  final bool autofocus;

  /// Clamp the text to this many lines with an ellipsis. Null wraps freely.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final resolved = variant ?? CsLinkDefaults.of(context);
    final info = resolved == CsLinkVariant.info;
    final inverted = !info && color == CsLinkColor.inverted;
    final interactive = onFollow != null || onClick != null;

    final base = DefaultTextStyle.of(context).style;
    final scale = info
        ? CsTypeScale.bodyS
        : (fontSize?.scale ?? (resolved == CsLinkVariant.awsuiValueLarge ? CsTypeScale.displayL : null));
    var style = scale == null ? base : base.merge(cs.typography.style(scale));
    style = switch (resolved) {
      CsLinkVariant.info => style.copyWith(fontWeight: CsTypography.bold),
      CsLinkVariant.awsuiValueLarge => style.copyWith(fontWeight: CsFontTokens.fontWeightDisplayL),
      _ => style,
    };
    final thickness = scale == CsTypeScale.displayL ? 2.0 : 1.0;

    Widget content(CsPressState state) {
      final lit = state.hovered || state.pressed;
      final Color fg = inverted
          ? (lit ? c.textLinkInvertedHover : c.textLinkInvertedDefault)
          : switch (resolved) {
              CsLinkVariant.info => lit ? c.textLinkInfoHover : c.textLinkInfoDefault,
              CsLinkVariant.secondary => lit ? c.textLinkSecondaryHover : c.textLinkSecondaryDefault,
              _ => lit ? c.textLinkHover : c.textLinkDefault,
            };
      final underline = switch (resolved) {
        CsLinkVariant.info => false,
        CsLinkVariant.secondary => inverted || lit,
        _ => true,
      };
      final textStyle = style.copyWith(
        color: fg,
        decoration: underline ? TextDecoration.underline : TextDecoration.none,
        decorationColor: fg,
        decorationThickness: thickness,
      );
      final fontSizePx = textStyle.fontSize ?? CsTypeScale.bodyM.fontSize;
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text),
            if (external)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: CsSpace.xxs),
                  child: CsIcon(
                    CsIcons.external,
                    size: fontSizePx >= CsTypeScale.headingL.fontSize ? CsIconSize.medium : CsIconSize.small,
                    dangerouslySetColor: fg,
                  ),
                ),
              ),
          ],
        ),
        style: textStyle,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      );
    }

    if (!interactive) {
      return Semantics(
        link: href != null || external,
        label: ariaLabel,
        excludeSemantics: ariaLabel != null,
        child: content(const CsPressState()),
      );
    }

    final isLink = href != null || external;
    return CsPressable(
      onPress: () {
        onClick?.call();
        onFollow?.call();
      },
      focusNode: focusNode,
      autofocus: autofocus,
      scaleOnPress: false,
      minTapTargetSize: 0,
      isLink: isLink,
      isButton: !isLink,
      semanticLabel: ariaLabel,
      semanticHint: external ? (externalIconAriaLabel ?? context.csStrings.opensInNewWindow) : null,
      excludeChildSemantics: ariaLabel != null,
      focusRingWidth: 2,
      focusRingOffset: 1,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
      focusRingColor: inverted ? CsColor.textLinkInvertedDefault : CsColor.borderItemFocused,
      builder: (context, state) => content(state),
    );
  }
}
