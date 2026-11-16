import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  group('generated tokens match Cloudscape', () {
    test('known light and dark colors', () {
      // From @cloudscape-design/design-tokens index-visual-refresh.json.
      expect(CsColorSchemes.light.textBodyDefault, const Color(0xFF0F141A));
      expect(CsColorSchemes.light.chartsRed300, const Color(0xFFEA7158));
      expect(CsColorSchemes.dark.chartsRed300, const Color(0xFFD63F38));
      expect(CsColorSchemes.light.backgroundButtonPrimaryDefault, const Color(0xFF006CE0));
    });

    test('every token has a value in both schemes', () {
      expect(CsColorSchemes.light.values.length, CsColor.values.length);
      expect(CsColorSchemes.dark.values.length, CsColor.values.length);
    });

    test('density tokens', () {
      expect(CsDensityTokens.comfortable.sizeVerticalInput, 32);
      expect(CsDensityTokens.compact.sizeVerticalInput, 28);
      expect(CsDensityTokens.comfortable.scaledM, 16);
      expect(CsDensityTokens.compact.scaledM, 12);
      expect(CsSpace.l, 20);
      expect(CsBorderRadius.button, 20);
      expect(CsBorderRadius.container, 16);
    });

    test('type scale', () {
      expect(CsTypeScale.bodyM.fontSize, 14);
      expect(CsTypeScale.bodyM.lineHeight, 20);
      expect(CsTypeScale.headingXl.fontSize, 24);
      expect(CsTypeScale.headingXl.weight, FontWeight.w700);
    });

    test('motion', () {
      expect(CsDurations.responsive, const Duration(milliseconds: 115));
      expect(CsDurations.complex, const Duration(milliseconds: 250));
    });
  });

  test('header and top navigation contexts are dark in light mode', () {
    final light = CsThemeData.light();
    final header = light.withVisualContext(CsVisualContextName.header);
    expect(header.isDark, isTrue);
    expect(header.visualContext, CsVisualContextName.header);
    final flash = light.withVisualContext(CsVisualContextName.flashbar);
    expect(flash.isDark, isFalse);
    expect(flash.colors, isNot(light.colors));
  });

  test('color overrides', () {
    const purple = Color(0xFF7B2FBE);
    final t = CsThemeData.light(colorOverrides: {CsColor.backgroundButtonPrimaryDefault: purple});
    expect(t.colors.backgroundButtonPrimaryDefault, purple);
    expect(t.colors.textBodyDefault, CsColorSchemes.light.textBodyDefault);
  });

  test('copyWith density switches tokens', () {
    final t = CsThemeData.light().copyWith(density: CsDensity.compact);
    expect(t.space.sizeVerticalInput, 28);
  });

  test('breakpoints', () {
    expect(CsBreakpoint.of(390), CsBreakpoint.base);
    expect(CsBreakpoint.of(700), CsBreakpoint.xs);
    expect(CsBreakpoint.of(1280), CsBreakpoint.m);
    expect(CsBreakpoint.match({CsBreakpoint.base: 1, CsBreakpoint.s: 2}, CsBreakpoint.m), 2);
    expect(CsBreakpoint.match({CsBreakpoint.s: 2}, CsBreakpoint.xs), isNull);
  });

  testWidgets('provider resolves mode and density and cross-fades', (tester) async {
    late CsThemeData seen;
    Widget app(CsThemeMode mode, CsDensity density) => MediaQuery(
      data: const MediaQueryData(),
      child: CsThemeProvider(
        mode: mode,
        density: density,
        child: Builder(
          builder: (context) {
            seen = context.cs;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(app(CsThemeMode.light, CsDensity.comfortable));
    expect(seen.isDark, isFalse);
    await tester.pumpWidget(app(CsThemeMode.dark, CsDensity.compact));
    await tester.pumpAndSettle();
    expect(seen.isDark, isTrue);
    expect(seen.space.sizeVerticalInput, 28);
  });

  testWidgets('CsVisualContext recolors text', (tester) async {
    late Color inside;
    await pumpCs(
      tester,
      CsVisualContext(
        context: CsVisualContextName.header,
        child: Builder(
          builder: (context) {
            inside = context.cs.colors.textBodyDefault;
            return const CsBox(text: 'Header');
          },
        ),
      ),
    );
    expect(inside, isNot(CsColorSchemes.light.textBodyDefault));
  });
}
