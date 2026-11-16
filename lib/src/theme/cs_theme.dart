import 'package:flutter/widgets.dart';

import 'cs_licenses.dart';
import 'cs_motion.dart';
import 'cs_theme_data.dart';
import 'cs_typography.dart';
import 'generated/cs_colors.g.dart';
import 'generated/cs_tokens.g.dart';

/// Which color mode a [CsThemeProvider] shows.
enum CsThemeMode {
  /// Follow the platform's light/dark setting.
  system,
  light,
  dark,
}

/// Makes a resolved [CsThemeData] available to descendants.
///
/// Most apps use [CsThemeProvider] at the root. Use [CsTheme] directly to
/// force a mode or density for a subtree:
///
/// ```dart
/// CsTheme(data: CsThemeData.dark(), child: const LogsPanel())
/// ```
class CsTheme extends InheritedWidget {
  const CsTheme({super.key, required this.data, required super.child});

  final CsThemeData data;

  /// The nearest theme, or [CsThemeData.fallback] (light) when there is none.
  static CsThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CsTheme>()?.data ?? CsThemeData.fallback;

  static CsThemeData? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<CsTheme>()?.data;

  @override
  bool updateShouldNotify(CsTheme oldWidget) => data != oldWidget.data;
}

/// `context.cs` shorthand for [CsTheme.of].
extension CsThemeContext on BuildContext {
  CsThemeData get cs => CsTheme.of(this);
}

/// The root of a Cloudscape app. Resolves light or dark mode and density,
/// sets the default text style and cross-fades colors when the mode changes
/// (instantly when motion is disabled).
///
/// ```dart
/// CsThemeProvider(
///   mode: CsThemeMode.system,
///   density: CsDensity.comfortable,
///   child: MyApp(),
/// )
/// ```
class CsThemeProvider extends StatefulWidget {
  const CsThemeProvider({
    super.key,
    this.mode = CsThemeMode.system,
    this.density = CsDensity.comfortable,
    this.typography = const CsTypography(),
    this.tapTargetSize,
    this.disableMotion = false,
    this.lightColorOverrides = const {},
    this.darkColorOverrides = const {},
    this.light,
    this.dark,
    this.animationDuration = CsDurations.complex,
    required this.child,
  });

  final CsThemeMode mode;

  /// Comfortable (default) or compact content density.
  final CsDensity density;
  final CsTypography typography;

  /// Defaults to [CsTapTargetSize.platformDefault].
  final CsTapTargetSize? tapTargetSize;

  /// Cloudscape's `disableMotion`. The platform reduce-motion setting turns
  /// motion off as well.
  final bool disableMotion;

  /// Token overrides for light mode, Cloudscape's `applyTheme` equivalent:
  /// `{CsColor.backgroundButtonPrimaryDefault: Color(0xFF7B2FBE)}`.
  final Map<CsColor, Color> lightColorOverrides;

  /// Token overrides for dark mode.
  final Map<CsColor, Color> darkColorOverrides;

  /// Replaces the generated light theme entirely.
  final CsThemeData? light;

  /// Replaces the generated dark theme entirely.
  final CsThemeData? dark;

  /// How long a mode change takes to cross-fade.
  final Duration animationDuration;
  final Widget child;

  @override
  State<CsThemeProvider> createState() => _CsThemeProviderState();
}

class _CsThemeProviderState extends State<CsThemeProvider> {
  @override
  void initState() {
    super.initState();
    registerCsLicenses();
  }

  CsThemeData _resolve(BuildContext context) {
    final brightness = switch (widget.mode) {
      CsThemeMode.light => Brightness.light,
      CsThemeMode.dark => Brightness.dark,
      CsThemeMode.system => MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light,
    };
    final motionDisabled = widget.disableMotion;
    if (brightness == Brightness.dark) {
      return widget.dark?.copyWith(density: widget.density) ??
          CsThemeData.dark(
            density: widget.density,
            typography: widget.typography,
            tapTargetSize: widget.tapTargetSize,
            colorOverrides: widget.darkColorOverrides,
            motionDisabled: motionDisabled,
          );
    }
    return widget.light?.copyWith(density: widget.density) ??
        CsThemeData.light(
          density: widget.density,
          typography: widget.typography,
          tapTargetSize: widget.tapTargetSize,
          colorOverrides: widget.lightColorOverrides,
          motionDisabled: motionDisabled,
        );
  }

  @override
  Widget build(BuildContext context) {
    final target = _resolve(context);
    final duration = widget.disableMotion ? Duration.zero : CsMotion.duration(context, widget.animationDuration);
    return TweenAnimationBuilder<CsThemeData>(
      tween: _CsThemeTween(end: target),
      duration: duration,
      curve: CsCurves.responsive,
      builder: (context, data, child) => CsTheme(
        data: data,
        child: DefaultTextStyle(style: data.body, child: child!),
      ),
      child: widget.child,
    );
  }
}

class _CsThemeTween extends Tween<CsThemeData> {
  _CsThemeTween({required CsThemeData end}) : super(begin: end, end: end);

  @override
  CsThemeData lerp(double t) => CsThemeData.lerp(begin!, end!, t);
}

/// Recolors a subtree for one of Cloudscape's visual contexts, the way
/// Cloudscape applies `awsui-context-*` classes: the dark top navigation,
/// the high-contrast header, the inside of flash messages and alerts.
///
/// ```dart
/// CsVisualContext(
///   context: CsVisualContextName.header,
///   child: CsHeader(variant: CsHeaderVariant.h1, title: 'Instances'),
/// )
/// ```
class CsVisualContext extends StatelessWidget {
  const CsVisualContext({super.key, required this.context, required this.child});

  /// Which context to apply. Named after Cloudscape's `awsui-context-*`.
  final CsVisualContextName context;
  final Widget child;

  @override
  Widget build(BuildContext buildContext) {
    final data = CsTheme.of(buildContext).withVisualContext(context);
    return CsTheme(
      data: data,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: data.colors.textBodyDefault),
        child: child,
      ),
    );
  }
}

/// Switches a subtree to compact or comfortable density.
///
/// ```dart
/// CsDensityScope(density: CsDensity.compact, child: CsTable(...))
/// ```
class CsDensityScope extends StatelessWidget {
  const CsDensityScope({super.key, required this.density, required this.child});

  final CsDensity density;
  final Widget child;

  @override
  Widget build(BuildContext context) => CsTheme(
    data: CsTheme.of(context).copyWith(density: density),
    child: child,
  );
}
