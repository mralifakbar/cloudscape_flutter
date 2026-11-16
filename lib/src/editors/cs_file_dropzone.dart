import 'package:flutter/widgets.dart';

import '../system/cs_pressable.dart';
import '../theme/theme.dart';
import 'cs_file.dart';

/// Cloudscape's `FileDropzone`: the dashed area files are dropped on.
///
/// Flutter has no cross-platform drag and drop of OS files without a
/// plugin, so this dropzone works three ways:
///
/// * **Tap target.** Give it [onPick] and a tap (or Enter and Space) opens
///   the app's picker; the files go to [onChange].
/// * **App driven.** Wire a drag and drop plugin (`desktop_drop`,
///   `super_drag_and_drop`) around it, set [active] while files hover over
///   it and call your handler on drop. [active] shows Cloudscape's hovered
///   look.
/// * **In-app drags.** It is also a [DragTarget] for `Draggable<CsFile>` and
///   `Draggable<List<CsFile>>`: hovering lights it up, dropping calls
///   [onChange].
///
/// ```dart
/// CsFileDropzone(
///   active: draggingOver,
///   onPick: (request) => myPicker(multiple: request.multiple),
///   onChange: (files) => setState(() => this.files = [...this.files, ...files]),
///   child: const Text('Drop files to upload'),
/// )
/// ```
class CsFileDropzone extends StatefulWidget {
  const CsFileDropzone({
    super.key,
    required this.child,
    this.onChange,
    this.onPick,
    this.active = false,
    this.multiple = true,
    this.accept,
    this.semanticLabel,
  });

  /// Content, centered in a column with a 4px gap (usually a line of text
  /// and a `CsFileInput`).
  final Widget child;

  /// Called with dropped or picked files.
  final ValueChanged<List<CsFile>>? onChange;

  /// Makes the whole area a button that opens the app's picker.
  final CsFilePicker? onPick;

  /// Files are being dragged over the zone (Cloudscape `hovered` state).
  final bool active;

  /// Passed to [onPick].
  final bool multiple;

  /// Passed to [onPick].
  final String? accept;

  /// Accessible name when the zone is tappable.
  final String? semanticLabel;

  @override
  State<CsFileDropzone> createState() => _CsFileDropzoneState();
}

class _CsFileDropzoneState extends State<CsFileDropzone> {
  bool _dragOver = false;

  Future<void> _pick() async {
    final files = await widget.onPick!(CsFilePickRequest(multiple: widget.multiple, accept: widget.accept));
    if (files != null && files.isNotEmpty) widget.onChange?.call(files);
  }

  Widget _surface(BuildContext context, bool hovered) {
    final c = context.cs.colors;
    final fg = hovered ? c.dropzoneTextHover : c.dropzoneTextDefault;
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: hovered ? c.dropzoneBorderHover : c.dropzoneBorderDefault,
        radius: CsBorderRadius.dropzone,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: hovered ? c.dropzoneBackgroundHover : c.dropzoneBackgroundDefault,
          borderRadius: BorderRadius.circular(CsBorderRadius.dropzone),
        ),
        padding: const EdgeInsets.all(CsSpace.staticL),
        child: DefaultTextStyle.merge(
          style: context.cs.body.copyWith(color: fg),
          textAlign: TextAlign.center,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, spacing: CsSpace.staticXxs, children: [widget.child]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onPick != null;
    final Widget zone = tappable
        ? CsPressable(
            onPress: _pick,
            semanticLabel: widget.semanticLabel,
            scaleOnPress: false,
            borderRadius: BorderRadius.circular(CsBorderRadius.dropzone),
            builder: (context, state) => _surface(context, widget.active || _dragOver || state.active),
          )
        : Semantics(container: true, label: widget.semanticLabel, child: _surface(context, widget.active || _dragOver));
    return DragTarget<Object>(
      onWillAcceptWithDetails: (d) {
        final ok = d.data is CsFile || d.data is List<CsFile>;
        if (ok) setState(() => _dragOver = true);
        return ok;
      },
      onLeave: (_) => setState(() => _dragOver = false),
      onAcceptWithDetails: (d) {
        setState(() => _dragOver = false);
        final data = d.data;
        final files = data is CsFile ? [data] : (data as List<CsFile>);
        if (files.isNotEmpty) widget.onChange?.call(files);
      },
      builder: (context, candidate, rejected) => zone,
    );
  }
}

/// Cloudscape's `1px dashed` border, drawn on the box edge.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect = RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.radius != radius;
}
