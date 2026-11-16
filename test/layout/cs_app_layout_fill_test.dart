import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('fills the width and height it is given under loose constraints', (tester) async {
    for (final size in [csPhoneSize, csDesktopSize]) {
      await pumpCs(
        tester,
        const Column(children: [Expanded(child: CsAppLayout(content: Text('Content')))]),
        size: size,
        center: false,
      );
      expect(tester.getSize(find.byType(CsAppLayout)).width, size.width);
      expect(tester.getRect(find.text('Content')).width, greaterThan(0));
    }
  });
}
