import 'package:flutter/widgets.dart';

import 'cs_icon_data.dart';

/// Overrides built-in icons for a subtree (Cloudscape `IconProvider`).
///
/// Every [CsIcon] below the provider looks its icon up by Cloudscape name
/// (`'close'`, `'status-positive'`) and draws the override instead, so the
/// icons inside components (a modal's close button, a select's caret, a
/// table's sorting icon) change too.
///
/// ```dart
/// CsIconProvider(
///   icons: {'close': CsIcons.arrowLeft, 'status-positive': CsIcons.check},
///   child: page,
/// )
/// ```
///
/// Overrides are inherited by nested providers. A nested provider adds to or
/// replaces the outer overrides; a `null` value resets that name to the
/// built-in icon, and [CsIconProvider.reset] resets every icon for its
/// subtree (Cloudscape `icons={null}`). Use [iconWidgets] for any widget (an
/// image, a brand mark) in place of an icon; it is sized like the icon it
/// replaces.
///
/// Unlike Cloudscape, swapping two icons (`close` to `arrow-left` and
/// `arrow-left` to `close`) or overriding an icon with itself never loops:
/// an override is drawn with its own name reset.
class CsIconProvider extends StatelessWidget {
  const CsIconProvider({super.key, this.icons, this.iconWidgets, required this.child}) : resetAll = false;

  /// Resets every override from outer providers for [child].
  const CsIconProvider.reset({super.key, required this.child}) : icons = null, iconWidgets = null, resetAll = true;

  /// Icon overrides by Cloudscape icon name. A `null` value resets that name
  /// to the built-in icon.
  final Map<String, CsIconData?>? icons;

  /// Widget overrides by Cloudscape icon name, drawn in a box the size of the
  /// icon they replace. A `null` value resets that name. A name in both maps
  /// uses the widget.
  final Map<String, Widget?>? iconWidgets;

  /// Whether this provider resets every outer override.
  final bool resetAll;
  final Widget child;

  /// The override for icon [name] in [context], a [CsIconData] or a
  /// [Widget], or null to draw the built-in icon. Registers a dependency, so
  /// the caller rebuilds when the overrides change.
  static Object? overrideOf(BuildContext context, String name) =>
      context.dependOnInheritedWidgetOfExactType<_CsIconScope>()?.overrides[name];

  @override
  Widget build(BuildContext context) {
    final parent = resetAll ? null : context.dependOnInheritedWidgetOfExactType<_CsIconScope>();
    final merged = <String, Object>{...?parent?.overrides};
    icons?.forEach((name, icon) => icon == null ? merged.remove(name) : merged[name] = icon);
    iconWidgets?.forEach((name, widget) => widget == null ? merged.remove(name) : merged[name] = widget);
    return _CsIconScope(overrides: merged, child: child);
  }
}

/// Draws [child] (an override for [name]) with that name reset, so an
/// override that uses the same icon draws the built-in one.
class CsIconOverrideScope extends StatelessWidget {
  const CsIconOverrideScope({super.key, required this.name, required this.child});

  final String name;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parent = context.dependOnInheritedWidgetOfExactType<_CsIconScope>();
    if (parent == null || !parent.overrides.containsKey(name)) return child;
    return _CsIconScope(overrides: {...parent.overrides}..remove(name), child: child);
  }
}

class _CsIconScope extends InheritedWidget {
  const _CsIconScope({required this.overrides, required super.child});

  final Map<String, Object> overrides;

  @override
  bool updateShouldNotify(_CsIconScope old) {
    if (old.overrides.length != overrides.length) return true;
    for (final e in overrides.entries) {
      if (old.overrides[e.key] != e.value) return true;
    }
    return false;
  }
}
