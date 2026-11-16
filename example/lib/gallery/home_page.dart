import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/material.dart';

import 'categories.dart';
import 'category_page.dart';
import 'foundations/colors_page.dart';
import 'foundations/icons_page.dart';
import 'foundations/typography_page.dart';
import 'nav_list.dart';
import 'page_frame.dart';

/// Gallery start page: foundations, then every component category.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.sampleApp});

  /// Opens the sample console, when the app provides one.
  final WidgetBuilder? sampleApp;

  void _push(BuildContext context, WidgetBuilder page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: page));

  @override
  Widget build(BuildContext context) {
    final demoCount = galleryCategories.fold<int>(0, (n, c) => n + c.demos.length);
    return PageFrame(
      title: 'Cloudscape for Flutter',
      description:
          'An unofficial port of the AWS Cloudscape Design System. $demoCount live demos in light, dark and compact.',
      children: [
        if (sampleApp != null) ...[
          const _SectionTitle('Sample app'),
          NavList(
            entries: [
              NavEntry(
                title: 'Cloud console',
                description: 'Instances, a dashboard and a create flow built from cloudscape_flutter. Sample data.',
                icon: CsIcons.multiscreen,
                onPress: () => _push(context, sampleApp!),
              ),
            ],
          ),
          const SizedBox(height: CsSpace.xxl),
        ],
        const _SectionTitle('Foundations'),
        NavList(
          entries: [
            NavEntry(
              title: 'Colors',
              description: 'Every Cloudscape color token in light and dark, searchable.',
              icon: CsIcons.lightDark,
              onPress: () => _push(context, (_) => const ColorsPage()),
            ),
            NavEntry(
              title: 'Typography',
              description: 'Open Sans on the Cloudscape type scale.',
              icon: CsIcons.script,
              onPress: () => _push(context, (_) => const TypographyPage()),
            ),
            NavEntry(
              title: 'Icons',
              description: 'The ${CsIcons.all.length} Cloudscape icons, searchable.',
              icon: CsIcons.gridView,
              onPress: () => _push(context, (_) => const IconsPage()),
            ),
          ],
        ),
        const SizedBox(height: CsSpace.xxl),
        const _SectionTitle('Components'),
        NavList(
          entries: [
            for (final c in galleryCategories)
              NavEntry(
                title: c.title,
                description: c.description,
                icon: c.icon,
                count: c.demos.length,
                onPress: () => _push(context, (_) => CategoryPage(category: c)),
              ),
          ],
        ),
        const SizedBox(height: CsSpace.xxl),
        const CsBox(
          variant: CsBoxVariant.small,
          color: CsBoxColor.textBodySecondary,
          text:
              'Not affiliated with or endorsed by Amazon Web Services. All resource names and numbers in this app are sample data.',
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: CsSpace.s),
    child: CsHeader(variant: CsHeaderVariant.h2, title: text),
  );
}
