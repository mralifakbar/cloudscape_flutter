import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import 'demo.dart';
import 'page_frame.dart';

/// Every demo of one category, each under its component name.
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.category});

  final CsDemoCategory category;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: category.title,
      description: category.description,
      children: [for (final demo in category.demos) _DemoBlock(demo: demo)],
    );
  }
}

/// One demo opened on its own page.
class DemoPage extends StatelessWidget {
  const DemoPage({super.key, required this.demo});

  final CsDemo demo;

  @override
  Widget build(BuildContext context) => PageFrame(
    title: demo.title,
    description: demo.description,
    children: [Builder(builder: demo.builder)],
  );
}

class _DemoBlock extends StatelessWidget {
  const _DemoBlock({required this.demo});

  final CsDemo demo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CsSpace.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            demo.title,
            style: context.cs.code(scale: CsTypeScale.headingS).copyWith(fontWeight: CsTypography.bold),
          ),
          const SizedBox(height: CsSpace.xxs),
          CsBox(color: CsBoxColor.textBodySecondary, text: demo.description),
          const SizedBox(height: CsSpace.l),
          Builder(builder: demo.builder),
        ],
      ),
    );
  }
}
