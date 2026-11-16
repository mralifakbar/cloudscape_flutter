import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phone size used by default; pass [csDesktopSize] for desktop layouts.
const Size csPhoneSize = Size(390, 844);
const Size csDesktopSize = Size(1280, 800);

/// Wraps [child] in everything a Cloudscape widget expects: media query, an
/// app (overlay, navigator, tap regions), directionality and a theme.
Widget csHarness(
  Widget child, {
  Brightness brightness = Brightness.light,
  CsDensity density = CsDensity.comfortable,
  CsTapTargetSize tapTargetSize = CsTapTargetSize.padded,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
  double textScale = 1,
  bool center = true,
  Size size = csPhoneSize,
}) {
  final theme = brightness == Brightness.dark
      ? CsThemeData.dark(density: density, tapTargetSize: tapTargetSize)
      : CsThemeData.light(density: density, tapTargetSize: tapTargetSize);
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations, textScaler: TextScaler.linear(textScale), size: size),
    child: CsTheme(
      data: theme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: csMaterialTheme(theme),
        builder: (context, app) => Directionality(textDirection: textDirection, child: app!),
        home: Builder(
          builder: (context) => ColoredBox(
            color: context.cs.colors.backgroundLayoutMain,
            child: DefaultTextStyle(
              style: context.cs.body,
              child: center ? Center(child: child) : child,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Pumps [child] inside [csHarness] and settles animations.
Future<void> pumpCs(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  CsDensity density = CsDensity.comfortable,
  CsTapTargetSize tapTargetSize = CsTapTargetSize.padded,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
  double textScale = 1,
  bool center = true,
  Size size = csPhoneSize,
  bool settle = true,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    csHarness(
      child,
      brightness: brightness,
      density: density,
      tapTargetSize: tapTargetSize,
      textDirection: textDirection,
      disableAnimations: disableAnimations,
      textScale: textScale,
      center: center,
      size: size,
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// Renders [child] in light and dark side by side for golden comparison.
Widget goldenPair(Widget child, {double width = 360}) {
  Widget pane(Brightness b) => CsTheme(
    data: b == Brightness.dark
        ? CsThemeData.dark(tapTargetSize: CsTapTargetSize.shrinkWrap)
        : CsThemeData.light(tapTargetSize: CsTapTargetSize.shrinkWrap),
    child: Builder(
      builder: (context) => Container(
        width: width,
        color: context.cs.colors.backgroundLayoutMain,
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(style: context.cs.body, child: child),
      ),
    ),
  );
  return MediaQuery(
    data: const MediaQueryData(size: Size(800, 1200)),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [pane(Brightness.light), pane(Brightness.dark)],
        ),
      ),
    ),
  );
}
