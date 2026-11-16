import 'package:cloudscape_flutter/src/feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

List<Map<String, Object?>> _captureAnnouncements(WidgetTester tester) {
  final log = <Map<String, Object?>>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
    message,
  ) async {
    final map = (message as Map).cast<String, Object?>();
    if (map['type'] == 'announce') log.add((map['data'] as Map).cast<String, Object?>());
    return null;
  });
  addTearDown(
    () =>
        tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null),
  );
  return log;
}

class _Counter extends StatefulWidget {
  const _Counter({this.assertive = false});

  final bool assertive;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 3;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CsLiveRegion(delay: Duration.zero, assertive: widget.assertive, child: Text('$count instances')),
      TextButton(onPressed: () => setState(() => count++), child: const Text('Add')),
    ],
  );
}

void main() {
  testWidgets('announces child text on mount and on change, once per change', (tester) async {
    final log = _captureAnnouncements(tester);
    await pumpCs(tester, const _Counter());
    expect(log.map((e) => e['message']), ['3 instances']);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(log.map((e) => e['message']), ['3 instances', '4 instances']);
    await tester.pump();
    expect(log.length, 2);
  });

  testWidgets('assertive sets assertiveness', (tester) async {
    final log = _captureAnnouncements(tester);
    await pumpCs(tester, const _Counter(assertive: true));
    expect(log.single['assertiveness'], 1);
  });

  testWidgets('message wins and hidden content is not shown', (tester) async {
    final log = _captureAnnouncements(tester);
    await pumpCs(
      tester,
      const CsLiveRegion(delay: Duration.zero, hidden: true, message: 'Saved', child: Text('Visible?')),
    );
    expect(log.single['message'], 'Saved');
    expect(find.text('Visible?'), findsNothing);
  });

  testWidgets('preventInitialAnnouncement skips the first content', (tester) async {
    final log = _captureAnnouncements(tester);
    await pumpCs(tester, const CsLiveRegion(preventInitialAnnouncement: true, child: Text('Ready')));
    await tester.pump(const Duration(seconds: 2));
    expect(log, isEmpty);
  });

  testWidgets('coalesces updates inside the delay', (tester) async {
    final log = _captureAnnouncements(tester);
    Widget region(String m) => CsLiveRegion(message: m);
    await pumpCs(tester, region('a'), settle: false);
    await tester.pumpWidget(csHarness(region('b')));
    await tester.pumpWidget(csHarness(region('c')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(log.map((e) => e['message']), ['c']);
  });

  testWidgets('reannounce repeats the current text', (tester) async {
    final log = _captureAnnouncements(tester);
    final key = GlobalKey<CsLiveRegionState>();
    await pumpCs(tester, CsLiveRegion(key: key, delay: Duration.zero, child: const Text('Filtered: 2 matches')));
    key.currentState!.reannounce();
    expect(log.map((e) => e['message']), ['Filtered: 2 matches', 'Filtered: 2 matches']);
  });

  testWidgets('static announce sends a polite message', (tester) async {
    final log = _captureAnnouncements(tester);
    await pumpCs(
      tester,
      Builder(
        builder: (context) =>
            TextButton(onPressed: () => CsLiveRegion.announce(context, 'Copied'), child: const Text('Copy')),
      ),
    );
    await tester.tap(find.text('Copy'));
    expect(log.single['message'], 'Copied');
  });
}
