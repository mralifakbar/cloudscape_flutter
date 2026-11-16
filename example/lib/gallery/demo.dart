import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

/// One live example in the gallery.
class CsDemo {
  const CsDemo({required this.title, required this.description, required this.builder, this.docPath});

  /// Component name as it appears in code, such as `CsButton`.
  final String title;

  /// One sentence on what the demo shows.
  final String description;
  final WidgetBuilder builder;

  /// Path of the matching reference page under `doc/components/`.
  final String? docPath;
}

/// A group of demos shown as one section of the gallery.
class CsDemoCategory {
  const CsDemoCategory({required this.title, required this.description, required this.icon, required this.demos});

  final String title;
  final String description;
  final CsIconData icon;
  final List<CsDemo> demos;
}

/// Standard frame for one scenario inside a demo: a heading, an optional
/// caption and the live widget.
class DemoSection extends StatelessWidget {
  const DemoSection({super.key, required this.title, required this.child, this.caption});

  final String title;
  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CsBox(
          variant: CsBoxVariant.h4,
          text: title,
          padding: const CsBoxSpacing(top: CsSpacingSize.n, bottom: CsSpacingSize.n),
        ),
        if (caption != null) ...[
          const SizedBox(height: CsSpace.xxxs),
          CsBox(variant: CsBoxVariant.small, color: CsBoxColor.textBodySecondary, text: caption!),
        ],
        const SizedBox(height: CsSpace.s),
        child,
      ],
    );
  }
}

/// A list of demo sections spaced the Cloudscape way.
class DemoColumn extends StatelessWidget {
  const DemoColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: CsSpace.xl, children: children);
}
