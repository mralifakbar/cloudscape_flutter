import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/material.dart';

import 'settings_scope.dart';

/// Frame for gallery pages: a top bar with a back button and the theme and
/// density toggles, a page header, and content capped at a readable width.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    this.description,
    required this.children,
    this.maxWidth = 840,
  });

  final String title;
  final String? description;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final canPop = Navigator.of(context).canPop();
    final narrow = context.csIsNarrow;
    final gutter = narrow ? CsSpace.l : CsSpace.xxl;
    return Scaffold(
      backgroundColor: cs.colors.backgroundLayoutMain,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Sticky top bar, separated from scrolling content by a border.
            DecoratedBox(
              decoration: BoxDecoration(
                color: cs.colors.backgroundLayoutMain,
                border: Border(bottom: BorderSide(color: cs.colors.borderDividerDefault)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter - CsSpace.xs, vertical: CsSpace.xxs),
                child: Row(
                  children: [
                    if (canPop)
                      CsButton(
                        icon: CsIcons.arrowLeft,
                        variant: CsButtonVariant.icon,
                        semanticLabel: 'Back',
                        onPress: () => Navigator.of(context).maybePop(),
                      )
                    else
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: CsSpace.xs),
                          child: Text(
                            'cloudscape_flutter',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cs.code().copyWith(fontWeight: CsTypography.bold),
                          ),
                        ),
                      ),
                    const Spacer(),
                    const GalleryToggles(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Constrained(
                      maxWidth: maxWidth,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, CsSpace.l, gutter, CsSpace.l),
                        child: CsHeader(
                          variant: CsHeaderVariant.h1,
                          title: title,
                          description: description,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + CsSpace.xxl),
                    sliver: SliverList.list(
                      children: [
                        for (final c in children)
                          _Constrained(
                            maxWidth: maxWidth,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: gutter),
                              child: c,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Constrained extends StatelessWidget {
  const _Constrained({required this.child, required this.maxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}
