import 'package:cloudscape_flutter/src/charts/charts.dart';
import 'package:cloudscape_flutter/src/overlays/cs_menu_parts.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';
import 'chart_test_utils.dart';

const running = CsPieChartDatum(title: 'Running', value: 60);
const stopped = CsPieChartDatum(title: 'Stopped', value: 30);
const pending = CsPieChartDatum(title: 'Pending', value: 10);
const data = [running, stopped, pending];

/// A segment type with an extra field, handed back in callbacks.
class Bucket extends CsPieChartDatum {
  const Bucket(String title, num value, this.region) : super(title: title, value: value);
  final String region;
}

Widget pie({
  List<CsPieChartDatum> segments = data,
  CsPieChartVariant variant = CsPieChartVariant.pie,
  CsPieChartSize size = CsPieChartSize.medium,
  bool hideTitles = false,
  bool hideDescriptions = false,
  ValueChanged<CsPieChartDatum?>? onHighlightChange,
  ValueChanged<List<CsPieChartDatum>>? onFilterChange,
  List<CsPieChartDatum>? visibleSegments,
  CsChartStatusType status = CsChartStatusType.finished,
  VoidCallback? onRecoveryClick,
  bool fitHeight = false,
}) => SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: CsPieChart<CsPieChartDatum>(
      data: segments,
      variant: variant,
      size: size,
      hideTitles: hideTitles,
      hideDescriptions: hideDescriptions,
      innerMetricValue: '100',
      innerMetricDescription: 'instances',
      segmentDescription: (d, sum) => '${d.value} instances',
      detailPopoverFooter: (d) => Text('Footer ${d.title}'),
      onHighlightChange: onHighlightChange,
      onFilterChange: onFilterChange,
      visibleSegments: visibleSegments,
      statusType: status,
      onRecoveryClick: onRecoveryClick,
      fitHeight: fitHeight,
      ariaLabel: 'Instance states',
      empty: const Text('No instances'),
      noMatch: const Text('No matching instances'),
    ),
  ),
);

void main() {
  group('CsPieChart', () {
    for (final brightness in Brightness.values) {
      for (final variant in CsPieChartVariant.values) {
        testWidgets('renders ${variant.name} in ${brightness.name}', (tester) async {
          for (final size in CsPieChartSize.values) {
            await pumpCs(
              tester,
              pie(variant: variant, size: size),
              brightness: brightness,
              size: csDesktopSize,
            );
            expect(tester.takeException(), isNull);
            expect(find.text('Running'), findsOneWidget, reason: 'legend entry');
          }
        });
      }
    }

    testWidgets('donut shows the inner metric; small donuts drop the description', (tester) async {
      await pumpCs(tester, pie(variant: CsPieChartVariant.donut), size: csDesktopSize);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('instances'), findsOneWidget);
      await pumpCs(
        tester,
        pie(variant: CsPieChartVariant.donut, size: CsPieChartSize.small),
        size: csDesktopSize,
      );
      expect(find.text('100'), findsOneWidget);
      expect(find.text('instances'), findsNothing);
      await pumpCs(tester, pie(), size: csDesktopSize);
      expect(find.text('100'), findsNothing, reason: 'pies have no inner content');
    });

    testWidgets('hovering a segment shows value and percentage', (tester) async {
      CsPieChartDatum? highlighted;
      await pumpCs(tester, pie(onHighlightChange: (d) => highlighted = d), size: csDesktopSize);
      final rect = tester.getRect(pieFinder);
      // 12 o'clock starts "Running" (60%), which covers the right side.
      final g = await hover(tester, rect.center + const Offset(60, 0));
      expect(highlighted, running);
      expect(find.text('Value'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
      expect(find.text('Percentage'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('Footer Running'), findsOneWidget);
      await g.moveTo(rect.center + const Offset(-60, 30));
      await tester.pumpAndSettle();
      expect(highlighted, stopped);
      await g.removePointer();
    });

    testWidgets('tap pins, tapping the same segment unpins', (tester) async {
      await pumpCs(tester, pie());
      final rect = tester.getRect(pieFinder);
      await tester.tapAt(rect.center + const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(find.text('60%'), findsOneWidget);
      expect(dismissButton, findsOneWidget);
      // Below the popover, still on "Running".
      await tester.tapAt(rect.center + const Offset(30, 60));
      await tester.pumpAndSettle();
      expect(find.text('60%'), findsNothing);
    });

    testWidgets('keyboard: arrows cycle segments, Enter pins, Escape clears', (tester) async {
      final highlights = <CsPieChartDatum?>[];
      await pumpCs(tester, pie(onHighlightChange: highlights.add), size: csDesktopSize);
      await keyboardFocus(tester, pieFinder);
      expect(highlights.last, running);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(highlights.last, stopped);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(highlights.last, pending);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(dismissButton, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(highlights.last, isNull);
      expect(find.text('Percentage'), findsNothing);
    });

    testWidgets('legend highlights segments', (tester) async {
      CsPieChartDatum? highlighted;
      await pumpCs(tester, pie(onHighlightChange: (d) => highlighted = d, hideTitles: true), size: csDesktopSize);
      await tester.tap(find.text('Stopped'));
      await tester.pumpAndSettle();
      expect(highlighted, stopped);
    });

    testWidgets('filter hides segments; hiding all shows noMatch', (tester) async {
      List<CsPieChartDatum>? visible;
      await pumpCs(tester, pie(onFilterChange: (v) => visible = v), size: csDesktopSize);
      await tester.tap(find.text('Filter data'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(CsMenuRow), matching: find.text('Pending')));
      await tester.pumpAndSettle();
      expect(visible, [running, stopped]);
      await pumpCs(tester, pie(visibleSegments: const []), size: csDesktopSize);
      expect(find.text('No matching instances'), findsOneWidget);
    });

    testWidgets('empty when there is no data or every value is zero', (tester) async {
      await pumpCs(tester, pie(segments: const []));
      expect(find.text('No instances'), findsOneWidget);
      await pumpCs(tester, pie(segments: const [CsPieChartDatum(title: 'Idle', value: 0)]));
      expect(find.text('No instances'), findsOneWidget);
    });

    testWidgets('loading and error states', (tester) async {
      await pumpCs(tester, pie(status: CsChartStatusType.loading), settle: false);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Loading chart'), findsOneWidget);
      var retried = false;
      await pumpCs(tester, pie(status: CsChartStatusType.error, onRecoveryClick: () => retried = true));
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('custom datum type and popover content', (tester) async {
      Bucket? last;
      await pumpCs(
        tester,
        CsPieChart<Bucket>(
          data: const [Bucket('example-bucket', 40, 'us-east-1'), Bucket('logs-bucket', 20, 'eu-west-1')],
          hideFilter: true,
          detailPopoverContent: (b, sum) => [
            CsChartDetailPair(key: 'Region', value: b.region),
            CsChartDetailPair(key: 'Size', value: '${b.value} GB'),
          ],
          onHighlightChange: (b) => last = b,
        ),
        size: csDesktopSize,
      );
      await keyboardFocus(tester, pieFinder);
      expect(last?.region, 'us-east-1');
      expect(find.text('Region'), findsOneWidget);
      expect(find.text('40 GB'), findsOneWidget);
    });

    testWidgets('semantics describe the chart and the active segment', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCs(tester, pie(variant: CsPieChartVariant.donut), size: csDesktopSize);
      final node = tester.getSemantics(pieFinder);
      expect(node.label, 'Instance states, Pie chart');
      expect(node.hint, contains('100 instances'));
      expect(node.hint, contains('3 segments: Running 60, Stopped 30, Pending 10'));
      await keyboardFocus(tester, pieFinder);
      expect(tester.getSemantics(pieFinder).value, 'Segment 1 of 3, Running (60), 60%');
      handle.dispose();
    });

    testWidgets('hide titles and descriptions', (tester) async {
      await pumpCs(tester, pie(hideTitles: true, hideDescriptions: true), size: csDesktopSize);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fitHeight, 390px, 2x text and reduced motion', (tester) async {
      await pumpCs(
        tester,
        const SizedBox(height: 500, child: CsPieChart<CsPieChartDatum>(data: data, fitHeight: true)),
        size: csDesktopSize,
      );
      expect(tester.takeException(), isNull);
      // Without a bounded parent, fitHeight falls back to the fixed size.
      await pumpCs(tester, pie(fitHeight: true), size: csDesktopSize);
      expect(tester.takeException(), isNull);
      await pumpCs(tester, pie(variant: CsPieChartVariant.donut, size: CsPieChartSize.large), textScale: 2);
      expect(tester.takeException(), isNull);
      await pumpCs(tester, pie(), disableAnimations: true, settle: false);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('compact density', (tester) async {
      await pumpCs(tester, pie(), density: CsDensity.compact);
      expect(tester.takeException(), isNull);
    });
  });
}
