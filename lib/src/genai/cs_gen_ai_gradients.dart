import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// The generative AI gradients, the two Cloudscape color tokens that are not
/// solid colors and therefore are not in the generated color scheme.
///
/// This is the one place they are written out; every gen-AI surface (the
/// avatar, the loading bar) reads them from here. Both tokens have the same
/// value in light and dark mode.
abstract final class CsGenAiGradients {
  // colorBackgroundAvatarGenAi:
  // radial-gradient(circle farthest-corner at top right, #b8e7ff 0%,
  // #0099ff 25%, #5c7fff 40%, #8575ff 60%, #962eff 80%)
  //
  // colorBackgroundLoadingBarGenAi:
  // linear-gradient(90deg, #b8e7ff 0%, #0099ff 10%, #5c7fff 24%,
  // #8575ff 50%, #962eff 76%, #0099ff 90%, #b8e7ff 100%)
  static const Color _sky = Color(0xFFB8E7FF);
  static const Color _blue = Color(0xFF0099FF);
  static const Color _indigo = Color(0xFF5C7FFF);
  static const Color _violet = Color(0xFF8575FF);
  static const Color _purple = Color(0xFF962EFF);

  /// Cloudscape `colorBackgroundAvatarGenAi`, for a square box.
  ///
  /// CSS `circle farthest-corner at top right` centers the circle on the top
  /// right corner with a radius reaching the bottom left corner: the
  /// diagonal, which is sqrt(2) times the side of a square. Flutter measures
  /// [RadialGradient.radius] in fractions of the shortest side.
  static const RadialGradient avatar = RadialGradient(
    center: Alignment.topRight,
    radius: math.sqrt2,
    colors: [_sky, _blue, _indigo, _violet, _purple],
    stops: [0, 0.25, 0.4, 0.6, 0.8],
  );

  /// Cloudscape `colorBackgroundLoadingBarGenAi` (left to right).
  static const LinearGradient loadingBar = LinearGradient(
    colors: [_sky, _blue, _indigo, _violet, _purple, _blue, _sky],
    stops: [0, 0.1, 0.24, 0.5, 0.76, 0.9, 1],
  );

  /// Alpha mask of the `gen-ai-masked` loading bar: `mask-image:
  /// linear-gradient(to right, transparent 0%, transparent 3%, black 30%,
  /// black 70%, transparent 97%, transparent 100%)`. Only its alpha is used.
  static const LinearGradient loadingBarMask = LinearGradient(
    colors: [
      Color(0x00000000),
      Color(0x00000000),
      Color(0xFF000000),
      Color(0xFF000000),
      Color(0x00000000),
      Color(0x00000000),
    ],
    stops: [0, 0.03, 0.3, 0.7, 0.97, 1],
  );
}

/// Sends a polite screen reader announcement from [context]'s view.
void csGenAiAnnounce(BuildContext context, String message) {
  if (message.isEmpty) return;
  final view = View.maybeOf(context);
  if (view == null) return;
  SemanticsService.sendAnnouncement(view, message, Directionality.maybeOf(context) ?? TextDirection.ltr);
}
