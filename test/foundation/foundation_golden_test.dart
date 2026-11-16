@Tags(['golden'])
library;

import 'package:cloudscape_flutter/src/buttons/buttons.dart';
import 'package:cloudscape_flutter/src/controls/controls.dart';
import 'package:cloudscape_flutter/src/forms/forms.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/status/status.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('foundation in light and dark', (tester) async {
    Widget content() => CsSpaceBetween(
      size: CsSpacingSize.m,
      children: [
        const CsBox(variant: CsBoxVariant.h2, text: 'Instances'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () {}),
            CsButton(text: 'Edit', onPress: () {}),
            CsButton(text: 'Launch', variant: CsButtonVariant.primary, onPress: () {}),
            const CsButton(text: 'Disabled'),
            CsButton(icon: CsIcons.settings, variant: CsButtonVariant.icon, semanticLabel: 'Settings', onPress: () {}),
          ],
        ),
        const Wrap(
          spacing: 12,
          children: [
            CsIcon(CsIcons.statusPositive, variant: CsIconVariant.success),
            CsIcon(CsIcons.statusWarning, variant: CsIconVariant.warning),
            CsIcon(CsIcons.statusNegative, variant: CsIconVariant.error),
            CsIcon(CsIcons.calendar),
            CsIcon(CsIcons.search, size: CsIconSize.medium),
          ],
        ),
        const CsStatusIndicator(type: CsStatusType.success, text: 'Running'),
        CsFormField(
          label: 'Bucket name',
          constraintText: 'Lowercase letters and hyphens.',
          errorText: 'Name is taken.',
          stretch: true,
          child: CsInput(value: 'example-bucket', invalid: true, onChange: (_) {}),
        ),
        CsCheckbox(checked: true, label: 'Enable versioning', onChange: (_) {}),
        const CsContainer(
          header: CsHeader(title: 'Details'),
          child: CsBox(text: 'Container content'),
        ),
      ],
    );
    for (final b in Brightness.values) {
      await pumpCs(
        tester,
        RepaintBoundary(
          child: Padding(padding: const EdgeInsets.all(16), child: content()),
        ),
        brightness: b,
        tapTargetSize: CsTapTargetSize.shrinkWrap,
        center: false,
        size: const Size(400, 640),
      );
      await expectLater(find.byType(RepaintBoundary).first, matchesGoldenFile('goldens/foundation_${b.name}.png'));
    }
  });
}
