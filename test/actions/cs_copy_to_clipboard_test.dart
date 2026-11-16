import 'package:cloudscape_flutter/src/actions/actions.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  String? clipboard;
  setUp(() {
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String?;
        return null;
      },
    );
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  Widget copy(CsCopyToClipboardVariant v, {bool disabled = false, ValueChanged<String>? onCopy}) => CsCopyToClipboard(
    variant: v,
    textToCopy: 'i-0abc123',
    copyButtonText: 'Copy ID',
    copyButtonAriaLabel: 'Copy instance ID',
    copySuccessText: 'Instance ID copied',
    copyErrorText: 'Instance ID failed to copy',
    disabled: disabled,
    onCopySuccess: onCopy,
  );

  testWidgets('renders every variant in light, dark, compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Column(mainAxisSize: MainAxisSize.min, children: [for (final v in CsCopyToClipboardVariant.values) copy(v)]),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('copies and shows the success popover; outside tap closes', (tester) async {
    String? copied;
    await pumpCs(tester, copy(CsCopyToClipboardVariant.button, onCopy: (t) => copied = t));
    await tester.tap(find.text('Copy ID'));
    await tester.pumpAndSettle();
    expect(clipboard, 'i-0abc123');
    expect(copied, 'i-0abc123');
    expect(find.text('Instance ID copied'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Instance ID copied'), findsNothing);
  });

  testWidgets('inline shows the text; icon has a label', (tester) async {
    await pumpCs(tester, copy(CsCopyToClipboardVariant.inline));
    expect(find.text('i-0abc123'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Copy instance ID'));
    await tester.pumpAndSettle();
    expect(find.text('Instance ID copied'), findsOneWidget);
  });

  testWidgets('disabled does not copy', (tester) async {
    await pumpCs(tester, copy(CsCopyToClipboardVariant.icon, disabled: true));
    await tester.tap(find.bySemanticsLabel('Copy instance ID'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(clipboard, isNull);
  });

  testWidgets('Escape closes the popover', (tester) async {
    await pumpCs(tester, copy(CsCopyToClipboardVariant.button));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Instance ID copied'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Instance ID copied'), findsNothing);
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    await pumpCs(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: CsCopyToClipboard(
          variant: CsCopyToClipboardVariant.inline,
          textToCopy: 'arn:aws:s3:::example-bucket/a/very/long/path/to/an/object.json',
          copySuccessText: 'Copied',
          copyErrorText: 'Failed',
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
