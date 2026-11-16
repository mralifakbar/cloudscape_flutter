# Getting started

Install the package, wrap your app in `CsThemeProvider`, and build with `Cs*` widgets.

## Install

```sh
flutter pub add cloudscape_flutter
```

Flutter 3.38 or newer. Open Sans is bundled and the 148 Cloudscape icons are drawn as vectors; there is nothing else to set up.

## Wrap the app

`CsThemeProvider` resolves light or dark mode and density, provides `context.cs` and sets the default text style. Put it above `MaterialApp` and use `csMaterialTheme` so the Material widgets you still use (Scaffold, scroll bars, text selection) match Cloudscape.

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/material.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return CsThemeProvider(
      mode: CsThemeMode.system,
      density: CsDensity.comfortable,
      child: Builder(
        builder: (context) => MaterialApp(
          theme: csMaterialTheme(context.cs),
          home: const InstancesPage(),
        ),
      ),
    );
  }
}

class InstancesPage extends StatelessWidget {
  const InstancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CsSpace.l),
          child: CsSpaceBetween(
            size: CsSpacingSize.l,
            children: [
              CsHeader(
                variant: CsHeaderVariant.h1,
                title: 'Instances',
                actions: CsButton(text: 'Launch instance', variant: CsButtonVariant.primary, onPress: () {}),
              ),
              const CsContainer(
                header: CsHeader(title: 'Details'),
                child: CsStatusIndicator(type: CsStatusType.success, text: 'Running'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Read the theme

```dart
final cs = context.cs;
final surface = cs.colors.backgroundContainerContent; // a token as a field
final error = cs.color(CsColor.textStatusError);     // a token by enum
final body = cs.body;                                 // 14px Open Sans, color-text-body-default
final small = cs.text(CsTypeScale.bodyS, color: CsColor.textBodySecondary);
final gap = cs.space.scaledM;                         // 16px comfortable, 12px compact
```

## Next

- [Theming](theming.md): modes, density, visual contexts, brand overrides, fonts.
- [Tokens](tokens.md): colors, spacing, density, radii, borders, shadows, breakpoints.
- [Motion](motion.md): Cloudscape motion tokens, springs, gestures, disabled motion.
- [Mobile](mobile.md): how a console design system adapts to phones.
- [Accessibility](accessibility.md).
- [For AI agents](for-ai-agents.md): how to build screens with this package from an agent.
