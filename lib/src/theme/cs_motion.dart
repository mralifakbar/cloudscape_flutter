import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'cs_theme.dart';

/// Springs for anything a finger can touch. Springs start from the current
/// value and carry velocity, so they can be interrupted and reversed
/// mid-flight without a jump. Parameters are a damping ratio and a response
/// time in seconds.
abstract final class CsSprings {
  /// Builds a spring from a damping ratio and a response time in seconds.
  static SpringDescription of({required double dampingRatio, required double response}) {
    final stiffness = math.pow(2 * math.pi / response, 2).toDouble();
    return SpringDescription.withDampingRatio(mass: 1, stiffness: stiffness, ratio: dampingRatio);
  }

  /// Default for UI that moves on its own: critically damped, no overshoot.
  static final SpringDescription standard = of(dampingRatio: 1, response: 0.35);

  /// Press-down and release feedback. Quick, no bounce.
  static final SpringDescription press = of(dampingRatio: 1, response: 0.2);

  /// After a flick or drag release, where the gesture carried momentum.
  static final SpringDescription momentum = of(dampingRatio: 0.8, response: 0.35);

  /// Popovers, dropdowns and tooltips scaling in from their trigger: close
  /// to Cloudscape's 115ms `motion-duration-responsive`.
  static final SpringDescription popup = of(dampingRatio: 1, response: 0.2);

  /// Sheets and drawers settling after a drag.
  static final SpringDescription sheet = of(dampingRatio: 0.86, response: 0.32);
}

/// Motion helpers shared by components.
abstract final class CsMotion {
  /// Scale applied to pressable surfaces while held.
  static const double pressScale = 0.98;

  /// True when motion should be off: the platform asks for reduced motion or
  /// the theme has `disableMotion`. Components swap slides, springs and loops
  /// for instant changes.
  static bool reduceMotion(BuildContext context) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || (CsTheme.maybeOf(context)?.motionDisabled ?? false);

  /// [normal], or zero when motion is off.
  static Duration duration(BuildContext context, Duration normal) => reduceMotion(context) ? Duration.zero : normal;

  /// Where a flick would come to rest, using exponential deceleration (the
  /// projection UIScrollView uses). [velocity] is in logical px per second.
  static double project(double velocity, {double decelerationRate = 0.998}) =>
      (velocity / 1000) * decelerationRate / (1 - decelerationRate);

  /// Progressive resistance past a boundary so drags never stop dead.
  static double rubberband(double overshoot, double dimension, {double constant = 0.55}) {
    if (dimension <= 0) return 0;
    return (overshoot * dimension * constant) / (dimension + constant * overshoot.abs());
  }

  /// Drives [controller] to [target] with a spring that starts from the
  /// controller's current value and [velocity] (controller units per second).
  static TickerFuture springTo(
    AnimationController controller,
    double target, {
    SpringDescription? spring,
    double velocity = 0,
  }) {
    final simulation = SpringSimulation(
      spring ?? CsSprings.standard,
      controller.value,
      target,
      velocity,
      tolerance: const Tolerance(distance: 0.0005, velocity: 0.01),
    );
    final future = controller.animateWith(simulation);
    // Springs stop within tolerance; land exactly on the target so a resting
    // surface is never a fraction of a pixel off. `then` only runs on
    // completion, not when another animation interrupts this one.
    future.then((_) {
      if (controller.value != target) controller.value = target;
    });
    return future;
  }
}
