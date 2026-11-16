import 'package:flutter/widgets.dart';

import '../cs_autosuggest.dart';

/// Extra behavior a composite (the property filter) gives the
/// [CsAutosuggest] inside it, without widening the public API.
class AutosuggestHooks extends InheritedWidget {
  const AutosuggestHooks({super.key, required super.child, this.keepOpenAfterSelect, this.highlightText, this.leading});

  /// Return true to keep the list open after a pick (a property or an
  /// operator was chosen and the value comes next).
  final bool Function(CsAutosuggestSelectDetail detail)? keepOpenAfterSelect;

  /// Overrides the text highlighted in suggestions.
  final String? highlightText;

  /// Icon at the start of the input.
  final Widget? leading;

  static AutosuggestHooks? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AutosuggestHooks>();

  @override
  bool updateShouldNotify(AutosuggestHooks old) =>
      old.highlightText != highlightText || old.leading != leading || old.keepOpenAfterSelect != keepOpenAfterSelect;
}
