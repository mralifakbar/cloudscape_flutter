import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icons.g.dart';
import 'cs_alert.dart';

/// What [CsErrorBoundary.onError] receives (Cloudscape
/// `ErrorBoundaryProps.OnErrorDetail`).
@immutable
class CsErrorBoundaryErrorDetail {
  const CsErrorBoundaryErrorDetail({required this.error, this.stackTrace, this.details, this.errorBoundaryId});

  /// The thrown error.
  final Object error;
  final StackTrace? stackTrace;

  /// Flutter's report of the failure (Cloudscape `errorInfo`): the widget
  /// that failed to build and the context of the error. Null for an error
  /// thrown by the boundary's own [CsErrorBoundary.builder].
  final FlutterErrorDetails? details;

  /// The boundary's [CsErrorBoundary.errorBoundaryId].
  final String? errorBoundaryId;
}

/// The default slots handed to [CsErrorBoundary.renderFallback] (Cloudscape
/// `ErrorBoundaryProps.FallbackProps`).
@immutable
class CsErrorBoundaryFallbackSlots {
  const CsErrorBoundaryFallbackSlots({
    required this.header,
    required this.description,
    this.action,
    required this.reset,
  });

  /// The header text.
  final Widget header;

  /// The description text.
  final Widget description;

  /// The "Refresh" button, or null when [CsErrorBoundary.showRefreshAction]
  /// is off.
  final Widget? action;

  /// Clears the error and builds the content again.
  final VoidCallback reset;
}

/// Copy of the fallback (Cloudscape `ErrorBoundaryProps.I18nStrings`).
@immutable
class CsErrorBoundaryI18nStrings {
  const CsErrorBoundaryI18nStrings({
    this.headerText = 'Unexpected error, content failed to show',
    this.descriptionText = 'Refresh to try again.',
    this.refreshActionText = 'Refresh',
    this.feedbackBuilder,
    this.feedbackText,
  });

  final String headerText;
  final String descriptionText;
  final String refreshActionText;

  /// Builds an inline feedback action appended to the description
  /// (Cloudscape `components.Feedback`), given [feedbackText].
  final Widget Function(BuildContext context, String text)? feedbackBuilder;

  /// Text of the feedback action, such as "Report a problem".
  final String? feedbackText;
}

/// Cloudscape's `ErrorBoundary`: shows a fallback in place of content that
/// failed to build, instead of a red error screen.
///
/// ```dart
/// CsErrorBoundary(
///   errorBoundaryId: 'instance-details',
///   onError: (detail) => log('${detail.errorBoundaryId}: ${detail.error}'),
///   child: InstanceDetails(id: 'i-0abc123'),
/// )
/// ```
///
/// When a widget below the boundary throws while building, the boundary
/// replaces its whole content with an error alert ("Unexpected error,
/// content failed to show") and a "Refresh" button, and calls [onError] once
/// with the error. "Refresh" clears the error and builds the content again
/// (on the web Cloudscape reloads the page; call [onRefresh] to do more, such
/// as refetching data). Errors thrown by [builder] itself are caught too.
///
/// Flutter cannot catch a descendant's build error the way React does. The
/// boundary installs (while at least one boundary is mounted, chained to the
/// previous builder) an [ErrorWidget.builder] that builds a small probe in
/// place of the failed widget; the probe finds the nearest boundary above it
/// and switches it to the fallback after the frame. With no boundary above,
/// the previous builder runs (the usual red or grey error box). Flutter
/// still reports the error to [FlutterError.onError].
///
/// Errors in layout, paint, gestures or async code are not build errors and
/// do not reach the boundary, as in React.
class CsErrorBoundary extends StatefulWidget {
  const CsErrorBoundary({
    super.key,
    this.child,
    this.builder,
    required this.onError,
    this.errorBoundaryId,
    this.renderFallback,
    this.i18nStrings = const CsErrorBoundaryI18nStrings(),
    this.suppressNested = false,
    this.suppressible = false,
    this.onRefresh,
    this.showRefreshAction = true,
  }) : assert(child != null || builder != null, 'Pass a child or a builder');

  /// The content shown while nothing has failed.
  final Widget? child;

  /// Builds the content. Errors thrown while it runs are caught too. Used in
  /// place of [child] when both are given.
  final WidgetBuilder? builder;

  /// Called once per caught error, to log or report it.
  final ValueChanged<CsErrorBoundaryErrorDetail> onError;

  /// Identifies the boundary in [onError] and in its semantics identifier.
  final String? errorBoundaryId;

  /// Builds a custom fallback from the default slots. Return null to use the
  /// default error alert.
  final Widget? Function(BuildContext context, CsErrorBoundaryFallbackSlots slots)? renderFallback;
  final CsErrorBoundaryI18nStrings i18nStrings;

  /// Disables nested boundaries that are [suppressible], so their errors
  /// reach this one.
  final bool suppressNested;

  /// Lets an outer boundary with [suppressNested] disable this one.
  final bool suppressible;

  /// Called when "Refresh" is pressed, after the error is cleared.
  final VoidCallback? onRefresh;

  /// Shows the "Refresh" action (Cloudscape shows it where the page can be
  /// reloaded).
  final bool showRefreshAction;

  @override
  State<CsErrorBoundary> createState() => CsErrorBoundaryState();
}

/// State of a [CsErrorBoundary]. Reach it with a `GlobalKey` to [reset] the
/// boundary or [forceError] (Cloudscape's test helpers).
class CsErrorBoundaryState extends State<CsErrorBoundary> {
  static int _mounted = 0;
  static ErrorWidgetBuilder? _previous;
  static ErrorWidgetBuilder? _installed;

  CsErrorBoundaryErrorDetail? _error;
  bool _reporting = false;

  /// Whether an outer boundary suppresses this one.
  bool _suppressed = false;

  /// Whether the fallback is showing.
  bool get hasError => _error != null;

  static void _install() {
    if (_mounted++ > 0) return;
    final previous = ErrorWidget.builder;
    _previous = previous;
    ErrorWidgetBuilder installed;
    installed = (details) => _ErrorProbe(details: details, previous: previous);
    _installed = installed;
    ErrorWidget.builder = installed;
  }

  static void _uninstall() {
    if (--_mounted > 0) return;
    // Restore only if nobody replaced the builder after us.
    if (identical(ErrorWidget.builder, _installed) && _previous != null) {
      ErrorWidget.builder = _previous!;
    }
    _previous = null;
    _installed = null;
  }

  @override
  void initState() {
    super.initState();
    _install();
  }

  @override
  void dispose() {
    _uninstall();
    super.dispose();
  }

  /// Shows the fallback as if the content had failed (Cloudscape
  /// `forceError`).
  void forceError([Object error = 'Forced error']) =>
      _capture(CsErrorBoundaryErrorDetail(error: error, errorBoundaryId: widget.errorBoundaryId), report: false);

  /// Clears the error and builds the content again.
  void reset() {
    if (!mounted) return;
    setState(() => _error = null);
  }

  void _capture(CsErrorBoundaryErrorDetail detail, {bool report = true}) {
    if (!mounted || _error != null) return;
    setState(() => _error = detail);
    if (report) widget.onError(detail);
  }

  /// Called by the probe built in place of a failed descendant.
  void _report(FlutterErrorDetails details) {
    if (_error != null || _reporting) return;
    _reporting = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _reporting = false;
      _capture(
        CsErrorBoundaryErrorDetail(
          error: details.exception,
          stackTrace: details.stack,
          details: details,
          errorBoundaryId: widget.errorBoundaryId,
        ),
      );
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _refresh() {
    reset();
    widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    final outer = context.dependOnInheritedWidgetOfExactType<_BoundaryScope>();
    _suppressed = widget.suppressible && (outer?.suppressNested ?? false);
    final nextSuppressed = widget.suppressNested || _suppressed;

    Widget content;
    if (_error != null && !_suppressed) {
      content = _fallback(context);
    } else if (widget.builder != null) {
      try {
        // Run the builder here so a throw is caught by this boundary rather
        // than turned into an error widget.
        content = widget.builder!(context);
      } catch (error, stack) {
        if (_suppressed) rethrow;
        final detail = CsErrorBoundaryErrorDetail(
          error: error,
          stackTrace: stack,
          errorBoundaryId: widget.errorBoundaryId,
        );
        SchedulerBinding.instance.addPostFrameCallback((_) => _capture(detail));
        content = _fallback(context, i18n: widget.i18nStrings);
      }
    } else {
      content = widget.child!;
    }

    content = _BoundaryScope(suppressNested: nextSuppressed, child: content);
    if (widget.errorBoundaryId != null) {
      content = Semantics(identifier: widget.errorBoundaryId, child: content);
    }
    return content;
  }

  Widget _fallback(BuildContext context, {CsErrorBoundaryI18nStrings? i18n}) {
    final strings = i18n ?? widget.i18nStrings;
    final feedback = strings.feedbackBuilder != null && strings.feedbackText != null
        ? strings.feedbackBuilder!(context, strings.feedbackText!)
        : null;
    final description = feedback == null
        ? Text(strings.descriptionText)
        : Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [Text(strings.descriptionText), feedback],
          );
    final action = widget.showRefreshAction
        ? CsButton(text: strings.refreshActionText, icon: CsIcons.refresh, onPress: _refresh)
        : null;
    final slots = CsErrorBoundaryFallbackSlots(
      header: Text(strings.headerText),
      description: description,
      action: action,
      reset: _refresh,
    );
    final custom = widget.renderFallback?.call(context, slots);
    if (custom != null) return custom;
    return CsAlert(type: CsAlertType.error, headerWidget: slots.header, action: slots.action, child: slots.description);
  }
}

class _BoundaryScope extends InheritedWidget {
  const _BoundaryScope({required this.suppressNested, required super.child});

  final bool suppressNested;

  @override
  bool updateShouldNotify(_BoundaryScope old) => old.suppressNested != suppressNested;
}

/// Built by [ErrorWidget.builder] in place of a widget that failed to build.
/// Hands the error to the nearest active boundary, or falls back to the
/// previous error widget.
class _ErrorProbe extends StatelessWidget {
  const _ErrorProbe({required this.details, required this.previous});

  final FlutterErrorDetails details;
  final ErrorWidgetBuilder previous;

  @override
  Widget build(BuildContext context) {
    CsErrorBoundaryState? target;
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is CsErrorBoundaryState) {
        final state = element.state as CsErrorBoundaryState;
        if (!state._suppressed) {
          target = state;
          return false;
        }
      }
      return true;
    });
    if (target == null) return previous(details);
    target!._report(details);
    return const SizedBox.shrink();
  }
}
