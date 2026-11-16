import 'package:cloudscape_flutter/src/buttons/cs_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The focusable plot of a cartesian chart.
final Finder plotFinder = find.byWidgetPredicate((w) => w is Focus && w.focusNode?.debugLabel == 'Cs chart plot');

/// The focusable plot of a pie chart.
final Finder pieFinder = find.byWidgetPredicate((w) => w is Focus && w.focusNode?.debugLabel == 'Cs pie chart');

/// Moves a mouse to [position] and settles.
Future<TestGesture> hover(WidgetTester tester, Offset position) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  await gesture.moveTo(position);
  await tester.pumpAndSettle();
  return gesture;
}

/// The close button of a pinned detail popover.
final Finder dismissButton = find.byWidgetPredicate((w) => w is CsButton && w.semanticLabel == 'Dismiss');

/// Gives [finder]'s focus node keyboard focus with the keyboard highlight
/// mode on, as a Tab press would.
Future<void> keyboardFocus(WidgetTester tester, Finder finder) async {
  final focus = tester.widget<Focus>(finder);
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
  addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
  focus.focusNode!.requestFocus();
  await tester.pumpAndSettle();
}
