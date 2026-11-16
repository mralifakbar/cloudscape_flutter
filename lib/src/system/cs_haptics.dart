import 'package:flutter/services.dart';

/// Haptic feedback a control fires on its causal event (commit, snap,
/// selection change). Cs is a pointer-first system, so controls default
/// to [none]; touch-first components opt in.
enum CsHaptic { none, light, medium, heavy, selection }

/// Fires [haptic] through the platform haptics engine.
void csHaptic(CsHaptic haptic) {
  switch (haptic) {
    case CsHaptic.none:
      return;
    case CsHaptic.light:
      HapticFeedback.lightImpact();
    case CsHaptic.medium:
      HapticFeedback.mediumImpact();
    case CsHaptic.heavy:
      HapticFeedback.heavyImpact();
    case CsHaptic.selection:
      HapticFeedback.selectionClick();
  }
}
