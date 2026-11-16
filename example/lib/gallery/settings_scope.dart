import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

/// Shares the gallery's theme mode and density with every page.
class GallerySettings extends InheritedWidget {
  const GallerySettings({
    super.key,
    required this.mode,
    required this.density,
    required this.onModeChange,
    required this.onDensityChange,
    required super.child,
  });

  final CsThemeMode mode;
  final CsDensity density;
  final ValueChanged<CsThemeMode> onModeChange;
  final ValueChanged<CsDensity> onDensityChange;

  static GallerySettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GallerySettings>();

  @override
  bool updateShouldNotify(GallerySettings oldWidget) =>
      mode != oldWidget.mode || density != oldWidget.density;
}

/// Icon buttons that cycle the color mode (System, Light, Dark) and switch
/// between comfortable and compact density.
class GalleryToggles extends StatelessWidget {
  const GalleryToggles({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = GallerySettings.maybeOf(context);
    if (settings == null) return const SizedBox.shrink();
    final modeName = switch (settings.mode) {
      CsThemeMode.system => 'System',
      CsThemeMode.light => 'Light',
      CsThemeMode.dark => 'Dark',
    };
    final next = CsThemeMode.values[(settings.mode.index + 1) % CsThemeMode.values.length];
    final compact = settings.density == CsDensity.compact;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CsButton(
          icon: compact ? CsIcons.viewFull : CsIcons.listView,
          variant: CsButtonVariant.icon,
          semanticLabel: compact ? 'Density: compact. Switch to comfortable' : 'Density: comfortable. Switch to compact',
          onPress: () => settings.onDensityChange(compact ? CsDensity.comfortable : CsDensity.compact),
        ),
        CsButton(
          icon: CsIcons.lightDark,
          variant: CsButtonVariant.icon,
          semanticLabel: 'Theme: $modeName. Switch to ${next.name}',
          onPress: () => settings.onModeChange(next),
        ),
      ],
    );
  }
}
