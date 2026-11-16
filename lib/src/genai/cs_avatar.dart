import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../icons/cs_icon.dart';
import '../overlays/cs_tooltip.dart';
import '../system/cs_focus_ring.dart';
import '../theme/theme.dart';
import 'cs_gen_ai_gradients.dart';

/// Avatar colors (Cloudscape `AvatarProps.Color`).
enum CsAvatarColor {
  /// `color-background-avatar-default`: a neutral gray, for people.
  defaultColor,

  /// The generative AI gradient (`colorBackgroundAvatarGenAi`), for AI
  /// assistants.
  genAi,
}

/// Cloudscape's `Avatar`: a round visual representation of a user or a
/// generative AI assistant in a chat.
///
/// Shows, in order of precedence: three animated dots while [loading], an
/// [image], up to two [initials], or an icon ([iconWidget], else [icon], else
/// `user-profile`). With [tooltipText] a tooltip shows on hover, keyboard
/// focus and touch.
///
/// ```dart
/// const CsAvatar(
///   color: CsAvatarColor.genAi,
///   icon: CsIcons.genAi,
///   ariaLabel: 'Generative AI assistant',
///   tooltipText: 'Generative AI assistant',
/// )
/// ```
class CsAvatar extends StatefulWidget {
  const CsAvatar({
    super.key,
    required this.ariaLabel,
    this.color = CsAvatarColor.defaultColor,
    this.tooltipText,
    this.initials,
    this.loading = false,
    this.icon,
    this.iconWidget,
    this.image,
    this.width = minWidth,
    this.focusNode,
  });

  /// Accessible name, such as "Avatar of the sample user" or "Generative AI
  /// assistant". Include [tooltipText] in it when you use both.
  final String ariaLabel;
  final CsAvatarColor color;

  /// Text shown in a tooltip on hover, focus and touch.
  final String? tooltipText;

  /// One or two characters shown in the avatar. Characters after the
  /// second are ignored. Takes precedence over [icon].
  final String? initials;

  /// Shows three bouncing dots, for an assistant that is generating a
  /// response. The dots and the gen-AI gradient only animate while true.
  final bool loading;

  /// Icon shown when there are no [initials] (Cloudscape `iconName`).
  /// Defaults to [CsIcons.userProfile]; use [CsIcons.genAi] for assistants.
  final CsIconData? icon;

  /// A custom icon widget (Cloudscape `iconSvg`). Takes precedence over
  /// [icon].
  final Widget? iconWidget;

  /// A picture that fills the avatar, cropped to a circle (Cloudscape
  /// `imgUrl`). Takes precedence over [initials] and the icon.
  final ImageProvider? image;

  /// Width and height in logical pixels. Values below [minWidth] are raised
  /// to it.
  final double width;

  /// Focus node for the avatar, which is focusable so keyboard users can
  /// reach its tooltip.
  final FocusNode? focusNode;

  /// The default and minimum size (28px).
  static const double minWidth = 28;

  @override
  State<CsAvatar> createState() => _CsAvatarState();
}

class _CsAvatarState extends State<CsAvatar> with TickerProviderStateMixin {
  late final AnimationController _dots;
  late final AnimationController _gradient;
  bool _focusVisible = false;
  bool _tooltip = false;

  @override
  void initState() {
    super.initState();
    _dots = AnimationController(vsync: this, duration: CsDurations.avatarLoadingDots);
    _gradient = AnimationController(vsync: this, duration: CsDurations.avatarGenAiGradient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimations();
  }

  @override
  void didUpdateWidget(CsAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimations();
  }

  /// The loops only run while loading (and the gradient only for gen-AI);
  /// nothing animates at rest or under reduced motion.
  void _syncAnimations() {
    final motion = !CsMotion.reduceMotion(context);
    final dots = motion && widget.loading;
    final gradient = dots && widget.color == CsAvatarColor.genAi;
    if (dots && !_dots.isAnimating) {
      _dots.repeat();
    } else if (!dots) {
      _dots
        ..stop()
        ..value = 0;
    }
    if (gradient && !_gradient.isAnimating) {
      _gradient.repeat();
    } else if (!gradient) {
      _gradient
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _dots.dispose();
    _gradient.dispose();
    super.dispose();
  }

  void _setTooltip(bool value) {
    if (_tooltip != value && widget.tooltipText != null) setState(() => _tooltip = value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final size = math.max(widget.width, CsAvatar.minWidth);
    final genAi = widget.color == CsAvatarColor.genAi;
    final foreground = cs.colors.textAvatar;

    Widget content;
    if (widget.loading) {
      content = _LoadingDots(animation: _dots, size: size, color: foreground);
    } else if (widget.image != null) {
      content = Image(image: widget.image!, width: size, height: size, fit: BoxFit.cover);
    } else if (widget.initials != null && widget.initials!.isNotEmpty) {
      final letters = widget.initials!.characters.take(2).toString();
      // font-size: clamp(body-s, 0.4 * size, 0.4 * size); bold (heading-l weight).
      content = Text(
        letters,
        maxLines: 1,
        textScaler: TextScaler.noScaling,
        style: cs
            .text(CsTypeScale.bodyS, weight: CsFontTokens.fontWeightHeadingL)
            .copyWith(color: foreground, fontSize: math.max(CsFontTokens.fontSizeBodyS, 0.4 * size), height: 1),
      );
    } else {
      // The icon inherits the avatar's font size: 16px at the default 28px,
      // growing with the avatar.
      final glyph = widget.iconWidget ?? CsIcon(widget.icon ?? CsIcons.userProfile, dangerouslySetColor: foreground);
      content = SizedBox.square(
        dimension: size * CsSize.iconNormal / CsAvatar.minWidth,
        child: FittedBox(
          child: IconTheme(
            data: IconThemeData(color: foreground),
            child: glyph,
          ),
        ),
      );
    }

    Widget surface;
    if (widget.image != null && !widget.loading) {
      surface = SizedBox.square(
        dimension: size,
        child: ClipOval(child: content),
      );
    } else {
      surface = SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: genAi
                    ? (widget.loading
                          ? _MovingGradient(
                              animation: _gradient,
                              size: size,
                              reverse: Directionality.of(context) == TextDirection.rtl,
                            )
                          : const DecoratedBox(decoration: BoxDecoration(gradient: CsGenAiGradients.avatar)))
                    : ColoredBox(color: cs.colors.backgroundAvatarDefault),
              ),
              content,
            ],
          ),
        ),
      );
    }

    surface = CsFocusRing(
      visible: _focusVisible,
      borderRadius: BorderRadius.circular(size),
      // Focus ring gutter: `calc(4px + focus-ring-width)` with a 0 border.
      offset: CsSpace.xxs,
      child: surface,
    );

    Widget result = MouseRegion(
      onEnter: (_) => _setTooltip(true),
      onExit: (_) => _setTooltip(false),
      child: Listener(
        onPointerDown: (e) => _setTooltip(true),
        onPointerUp: (e) {
          // Touch hides on release, as Cloudscape's touchend; a mouse keeps
          // the tooltip until it leaves.
          if (e.kind == PointerDeviceKind.touch) _setTooltip(false);
        },
        child: surface,
      ),
    );

    if (widget.tooltipText != null) {
      result = CsTooltip(content: widget.tooltipText!, open: _tooltip, child: result);
    }

    // The visual is hidden from screen readers; the avatar is one image node
    // that also carries the focus flags (role="img" with tabIndex 0).
    return Semantics(
      container: true,
      image: true,
      label: widget.ariaLabel,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        onShowFocusHighlight: (v) {
          if (_focusVisible != v) setState(() => _focusVisible = v);
        },
        onFocusChange: _setTooltip,
        child: ExcludeSemantics(child: result),
      ),
    );
  }
}

/// The three dots of the loading avatar (`loading-dots` in the chat
/// components): each jumps by its own height at 28% of a 1.2s loop and
/// lands at 44%, offset by 100ms per dot.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.animation, required this.size, required this.color});

  final Animation<double> animation;
  final double size;
  final Color color;

  static double _jump(double t) {
    // dotsDancing keyframes with ease-in-out between them.
    if (t < 0.28) return -Curves.easeInOut.transform(t / 0.28);
    if (t < 0.44) return -1 + Curves.easeInOut.transform((t - 0.28) / 0.16);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final dot = 0.14 * size;
    final period = CsDurations.avatarLoadingDots.inMilliseconds;
    return SizedBox(
      width: size * 0.64,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(
                  0,
                  animation.isAnimating ? _jump((animation.value - (i + 1) * 100 / period) % 1) * dot : 0,
                ),
                child: Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The gen-AI gradient of a loading avatar: rotates once per 3.6s and grows
/// to 150% at the halfway point (`gradientMove`).
class _MovingGradient extends StatelessWidget {
  const _MovingGradient({required this.animation, required this.size, required this.reverse});

  final Animation<double> animation;
  final double size;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = CsCurves.avatarGenAiGradient.transform(animation.value);
        final grow = 1 + 0.5 * (1 - (2 * t - 1).abs());
        final turn = (reverse ? 1 - t : t) * 2 * math.pi;
        return OverflowBox(
          maxWidth: size * grow,
          maxHeight: size * grow,
          child: Transform.rotate(
            angle: turn,
            child: SizedBox.square(
              dimension: size * grow,
              child: const DecoratedBox(decoration: BoxDecoration(gradient: CsGenAiGradients.avatar)),
            ),
          ),
        );
      },
    );
  }
}
