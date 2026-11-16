import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Cloudscape's `LiveRegion`: announces content to screen readers whenever
/// it changes, without moving focus.
///
/// The announcement text is [message] when set; otherwise it is the text
/// rendered by [child], read after each build the way Cloudscape reads the
/// `textContent` of its children. Equal consecutive messages are announced
/// once; changes inside [delay] are coalesced into one announcement.
///
/// ```dart
/// CsLiveRegion(
///   child: Text('$count instances match'),
/// )
///
/// // Announce without showing anything:
/// CsLiveRegion(hidden: true, message: 'Saved $name')
/// ```
///
/// Announcements go through [SemanticsService.sendAnnouncement], so they
/// reach VoiceOver and TalkBack on every platform Flutter supports. For a
/// one-off announcement without a widget, call [CsLiveRegion.announce].
class CsLiveRegion extends StatefulWidget {
  const CsLiveRegion({
    super.key,
    this.child,
    this.message,
    this.assertive = false,
    this.hidden = false,
    this.delay = const Duration(seconds: 1),
    this.preventInitialAnnouncement = false,
  });

  /// Content shown on screen (unless [hidden]) and, when [message] is null,
  /// the source of the announcement.
  final Widget? child;

  /// Text to announce. Takes precedence over the text of [child].
  final String? message;

  /// Interrupt the screen reader (Cloudscape `assertive`). Use only for
  /// messages that cannot wait, such as errors that block the task.
  final bool assertive;

  /// Hide [child] visually and from the semantics tree; it is still
  /// announced when it changes.
  final bool hidden;

  /// Minimum time between announcements. Updates inside this window are
  /// merged into one announcement of the latest text. [Duration.zero]
  /// announces synchronously after each frame.
  final Duration delay;

  /// Do not announce the content present when the region first builds,
  /// only later changes.
  final bool preventInitialAnnouncement;

  /// Sends [message] to the screen reader once.
  static void announce(BuildContext context, String message, {bool assertive = false}) {
    if (message.trim().isEmpty) return;
    final view = View.maybeOf(context);
    if (view == null) return;
    SemanticsService.sendAnnouncement(
      view,
      message.trim(),
      Directionality.maybeOf(context) ?? TextDirection.ltr,
      assertiveness: assertive ? Assertiveness.assertive : Assertiveness.polite,
    );
  }

  /// The text rendered under [context], in reading order and with runs of
  /// whitespace collapsed: the Flutter counterpart of an element's
  /// `textContent`.
  static String textOf(BuildContext context) {
    final buffer = StringBuffer();
    void visit(Element e) {
      final render = e.renderObject;
      if (e is RenderObjectElement && render is RenderParagraph) {
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(render.text.toPlainText());
        return;
      }
      e.visitChildElements(visit);
    }

    (context as Element).visitChildElements(visit);
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  State<CsLiveRegion> createState() => CsLiveRegionState();
}

/// State of a [CsLiveRegion]. Reach it with a `GlobalKey<CsLiveRegionState>`
/// to [reannounce] the current text.
class CsLiveRegionState extends State<CsLiveRegion> {
  final GlobalKey _contentKey = GlobalKey();
  String? _lastAnnounced;
  String? _pending;
  bool _initial = true;
  Timer? _timer;

  /// Announces the current text again, even when it has not changed (a
  /// filter that returned the same count, a retried action).
  void reannounce() {
    final text = _currentText();
    if (text.isEmpty) return;
    _timer?.cancel();
    _timer = null;
    _send(text);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _currentText() {
    final explicit = widget.message;
    if (explicit != null) return explicit.trim();
    final element = _contentKey.currentContext;
    if (element == null) return '';
    return CsLiveRegion.textOf(element);
  }

  void _send(String text) {
    _lastAnnounced = text;
    if (!mounted) return;
    CsLiveRegion.announce(context, text, assertive: widget.assertive);
  }

  void _afterBuild(Duration _) {
    if (!mounted) return;
    final text = _currentText();
    if (_initial) {
      _initial = false;
      if (widget.preventInitialAnnouncement) {
        _lastAnnounced = text;
        return;
      }
    }
    if (text.isEmpty || text == _lastAnnounced) {
      _pending = null;
      return;
    }
    if (widget.delay == Duration.zero) {
      _send(text);
      return;
    }
    _pending = text;
    _timer ??= Timer(widget.delay, () {
      _timer = null;
      final next = _pending;
      _pending = null;
      if (next != null && next != _lastAnnounced) _send(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_afterBuild);
    final child = widget.child;
    if (child == null) return const SizedBox.shrink();
    final content = KeyedSubtree(key: _contentKey, child: child);
    if (widget.hidden) return Offstage(child: content);
    return content;
  }
}
