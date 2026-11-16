import 'package:flutter/widgets.dart';

import '../system/cs_size_reveal.dart';
import '../theme/theme.dart';

/// Expands and collapses [child] from the top: Cloudscape's expandable
/// content motion (`motion-duration-expandable-content-enter`, 180ms, with a
/// fade). Collapsed content is removed from the tree once hidden, so it
/// leaves focus traversal and semantics. Instant under reduced motion.
/// Internal to the navigation category.
class CsNavReveal extends StatefulWidget {
  const CsNavReveal({super.key, required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  @override
  State<CsNavReveal> createState() => _CsNavRevealState();
}

class _CsNavRevealState extends State<CsNavReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CsDurations.expandableContentEnter,
      reverseDuration: CsDurations.showQuick,
      value: widget.expanded ? 1 : 0,
    );
    _curve = CurvedAnimation(parent: _controller, curve: CsCurves.expandableContentEnter);
    _controller.addStatusListener((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(CsNavReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded == widget.expanded) return;
    if (CsMotion.reduceMotion(context)) {
      _controller.value = widget.expanded ? 1 : 0;
    } else if (widget.expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isDismissed) return const SizedBox(width: double.infinity);
    if (_controller.isCompleted) return widget.child;
    return CsSizeReveal(
      sizeFactor: _curve,
      child: FadeTransition(opacity: _curve, child: widget.child),
    );
  }
}
