// Flutter 3.47 moved Material into the `material_ui` package and deprecated
// this import. This package still supports Flutter 3.38, where `material_ui`
// does not exist; switch the import when the minimum Flutter version moves.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'cs_theme.dart';
import 'cs_theme_data.dart';
import 'cs_typography.dart';

/// Builds a Material [ThemeData] from a Cloudscape theme, so Material widgets
/// you still use (Scaffold, scrollbars, text selection) match Cloudscape
/// colors and type. Ink splashes are off: Cloudscape controls give feedback
/// with color and scale.
ThemeData csMaterialTheme(CsThemeData cs) {
  final c = cs.colors;
  TextStyle t(CsTypeScale s) => cs.text(s);

  final scheme = ColorScheme(
    brightness: cs.brightness,
    primary: c.backgroundButtonPrimaryDefault,
    onPrimary: c.textInteractiveInvertedDefault,
    secondary: c.textAccent,
    onSecondary: c.textInteractiveInvertedDefault,
    error: c.textStatusError,
    onError: c.textInteractiveInvertedDefault,
    surface: c.backgroundContainerContent,
    onSurface: c.textBodyDefault,
    onSurfaceVariant: c.textBodySecondary,
    surfaceContainerLowest: c.backgroundLayoutMain,
    surfaceContainerLow: c.backgroundContainerContent,
    surfaceContainer: c.backgroundContainerContent,
    surfaceContainerHigh: c.backgroundContainerHeader,
    surfaceContainerHighest: c.backgroundDropdownItemHover,
    outline: c.borderInputDefault,
    outlineVariant: c.borderDividerDefault,
    inverseSurface: c.backgroundNotificationGrey,
    onInverseSurface: c.textNotificationDefault,
    scrim: c.backgroundModalOverlay,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: cs.brightness,
    scaffoldBackgroundColor: c.backgroundLayoutMain,
    canvasColor: c.backgroundContainerContent,
    dividerColor: c.borderDividerDefault,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    fontFamily: cs.typography.sans,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.textBodyDefault,
      selectionColor: c.backgroundItemSelected,
      selectionHandleColor: c.borderItemFocused,
    ),
    textTheme: TextTheme(
      displayLarge: t(CsTypeScale.displayXl),
      displayMedium: t(CsTypeScale.displayL),
      displaySmall: t(CsTypeScale.headingXl),
      headlineLarge: t(CsTypeScale.headingXl),
      headlineMedium: t(CsTypeScale.headingL),
      headlineSmall: t(CsTypeScale.headingM),
      titleLarge: t(CsTypeScale.headingL),
      titleMedium: t(CsTypeScale.headingS),
      titleSmall: t(CsTypeScale.headingXs),
      bodyLarge: t(CsTypeScale.bodyM),
      bodyMedium: t(CsTypeScale.bodyM),
      bodySmall: cs.text(CsTypeScale.bodyS, color: null).copyWith(color: c.textBodySecondary),
      labelLarge: t(CsTypeScale.bodyM).copyWith(fontWeight: CsTypography.bold),
      labelMedium: t(CsTypeScale.bodyS).copyWith(fontWeight: CsTypography.bold),
      labelSmall: t(CsTypeScale.bodyS),
    ),
  );
}

/// Wraps [child] in a Material [Theme] derived from the nearest [CsTheme].
/// Place it under [CsThemeProvider] when mixing Material widgets in.
class CsMaterialTheme extends StatelessWidget {
  const CsMaterialTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(data: csMaterialTheme(context.cs), child: child);
}
