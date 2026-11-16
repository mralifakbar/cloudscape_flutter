import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays out the message and action of an alert or flash message the way
/// Cloudscape's flex-wrap row does: the action sits after the message while
/// the message keeps at least 70% of the width, and otherwise wraps onto its
/// own line, indented by [wrappedIndent] and followed by [wrappedBottom].
///
/// Internal to the package: not exported.
class CsMessageActionLayout extends MultiChildRenderObjectWidget {
  CsMessageActionLayout({
    super.key,
    required Widget message,
    Widget? action,
    this.gap = 12,
    this.wrappedIndent = 0,
    this.wrappedBottom = 0,
  }) : super(children: [message, ?action]);

  /// Space between message and action when they share a line.
  final double gap;

  /// Start inset of the action once it wraps below the message.
  final double wrappedIndent;

  /// Space below a wrapped action.
  final double wrappedBottom;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMessageAction(
    gap: gap,
    wrappedIndent: wrappedIndent,
    wrappedBottom: wrappedBottom,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderMessageAction)
      ..gap = gap
      ..wrappedIndent = wrappedIndent
      ..wrappedBottom = wrappedBottom
      ..textDirection = Directionality.of(context);
  }
}

class _MessageParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderMessageAction extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _MessageParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _MessageParentData> {
  _RenderMessageAction({
    required double gap,
    required double wrappedIndent,
    required double wrappedBottom,
    required TextDirection textDirection,
  }) : _gap = gap,
       _wrappedIndent = wrappedIndent,
       _wrappedBottom = wrappedBottom,
       _textDirection = textDirection;

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  double _wrappedIndent;
  set wrappedIndent(double v) {
    if (v == _wrappedIndent) return;
    _wrappedIndent = v;
    markNeedsLayout();
  }

  double _wrappedBottom;
  set wrappedBottom(double v) {
    if (v == _wrappedBottom) return;
    _wrappedBottom = v;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  /// Whether the action wrapped below the message in the last layout.
  bool wrapped = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _MessageParentData) child.parentData = _MessageParentData();
  }

  RenderBox get _message => firstChild!;
  RenderBox? get _action => childCount > 1 ? lastChild : null;

  @override
  double computeMinIntrinsicWidth(double height) {
    final a = _action;
    return math.max(
      _message.getMinIntrinsicWidth(height),
      a == null ? 0 : a.getMinIntrinsicWidth(height) + _wrappedIndent,
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final a = _action;
    return _message.getMaxIntrinsicWidth(height) + (a == null ? 0 : _gap + a.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMinIntrinsicHeight(double width) => _dryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) => _dryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  Size computeDryLayout(BoxConstraints constraints) => _dryLayout(constraints);

  Size _dryLayout(BoxConstraints constraints) {
    final maxW = constraints.hasBoundedWidth ? constraints.maxWidth : computeMaxIntrinsicWidth(double.infinity);
    final a = _action;
    if (a == null) {
      final m = _message.getDryLayout(BoxConstraints(maxWidth: maxW));
      return constraints.constrain(Size(maxW, m.height));
    }
    final actionSize = a.getDryLayout(BoxConstraints(maxWidth: maxW));
    if (actionSize.width + _gap <= maxW * 0.3) {
      final m = _message.getDryLayout(BoxConstraints(maxWidth: maxW - actionSize.width - _gap));
      return constraints.constrain(Size(maxW, math.max(m.height, actionSize.height)));
    }
    final m = _message.getDryLayout(BoxConstraints(maxWidth: maxW));
    final wrappedAction = a.getDryLayout(BoxConstraints(maxWidth: math.max(0, maxW - _wrappedIndent)));
    return constraints.constrain(Size(maxW, m.height + wrappedAction.height + _wrappedBottom));
  }

  @override
  void performLayout() {
    final maxW = constraints.hasBoundedWidth ? constraints.maxWidth : computeMaxIntrinsicWidth(double.infinity);
    final rtl = _textDirection == TextDirection.rtl;
    final message = _message;
    final a = _action;
    final mData = message.parentData! as _MessageParentData;
    if (a == null) {
      wrapped = false;
      message.layout(BoxConstraints(maxWidth: maxW), parentUsesSize: true);
      mData.offset = Offset(rtl ? maxW - message.size.width : 0, 0);
      size = constraints.constrain(Size(maxW, message.size.height));
      return;
    }
    final aData = a.parentData! as _MessageParentData;
    a.layout(BoxConstraints(maxWidth: maxW), parentUsesSize: true);
    if (a.size.width + _gap <= maxW * 0.3) {
      wrapped = false;
      final messageW = maxW - a.size.width - _gap;
      message.layout(BoxConstraints(minWidth: messageW, maxWidth: messageW), parentUsesSize: true);
      mData.offset = Offset(rtl ? maxW - messageW : 0, 0);
      aData.offset = Offset(rtl ? 0 : maxW - a.size.width, 0);
      size = constraints.constrain(Size(maxW, math.max(message.size.height, a.size.height)));
      return;
    }
    wrapped = true;
    message.layout(BoxConstraints(minWidth: maxW, maxWidth: maxW), parentUsesSize: true);
    final actionMax = math.max(0.0, maxW - _wrappedIndent);
    a.layout(BoxConstraints(maxWidth: actionMax), parentUsesSize: true);
    mData.offset = Offset.zero;
    aData.offset = Offset(rtl ? maxW - _wrappedIndent - a.size.width : _wrappedIndent, message.size.height);
    size = constraints.constrain(Size(maxW, message.size.height + a.size.height + _wrappedBottom));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
