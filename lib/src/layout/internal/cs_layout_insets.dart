import 'package:flutter/widgets.dart';

/// Horizontal content padding the app layout leaves to a `CsContentLayout`
/// placed directly in its content slot, so the content layout's header
/// background can reach the edges of the content area while its header and
/// content keep the padding. Internal plumbing.
class CsLayoutContentInsets extends InheritedWidget {
  const CsLayoutContentInsets({super.key, required this.horizontal, required this.top, required super.child});

  final double horizontal;
  final double top;

  static CsLayoutContentInsets? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CsLayoutContentInsets>();

  @override
  bool updateShouldNotify(CsLayoutContentInsets old) => old.horizontal != horizontal || old.top != top;
}
