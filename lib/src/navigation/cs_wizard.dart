import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../layout/cs_header.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';
import 'cs_nav_reveal.dart';

/// One step of [CsWizard] (Cloudscape `WizardProps.Step`).
@immutable
class CsWizardStep {
  const CsWizardStep({
    required this.title,
    required this.content,
    this.info,
    this.description,
    this.descriptionWidget,
    this.errorText,
    this.errorWidget,
    this.isOptional = false,
  });

  /// Shown in the step list and as the page heading.
  final String title;

  /// The form of this step: usually containers of form fields.
  final Widget content;

  /// An info link next to the heading (`CsLink(variant: CsLinkVariant.info)`).
  final Widget? info;

  /// Text under the heading.
  final String? description;
  final Widget? descriptionWidget;

  /// A page-level error, such as a failed server-side validation.
  final String? errorText;
  final Widget? errorWidget;

  /// Marks the step "optional" in the list and heading; optional steps can
  /// be skipped with [CsWizard.allowSkipTo].
  final bool isOptional;
}

/// Why [CsWizard.onNavigate] fired (Cloudscape `NavigationReason`).
enum CsWizardNavigationReason {
  /// The next button.
  next,

  /// The previous button.
  previous,

  /// A visited step in the step list.
  step,

  /// The skip-to button, or an unvisited step reachable by skipping optional
  /// steps.
  skip,
}

/// Detail of [CsWizard.onNavigate].
@immutable
class CsWizardNavigateDetail {
  const CsWizardNavigateDetail({required this.requestedStepIndex, required this.reason});

  /// The step asked for, starting at 0.
  final int requestedStepIndex;
  final CsWizardNavigationReason reason;

  @override
  String toString() => 'CsWizardNavigateDetail($requestedStepIndex, $reason)';
}

/// Copy for [CsWizard] (Cloudscape `i18nStrings`).
@immutable
class CsWizardI18nStrings {
  const CsWizardI18nStrings({
    this.stepNumberLabel,
    this.collapsedStepsLabel,
    this.skipToButtonLabel,
    this.navigationAriaLabel = 'Steps',
    this.errorIconAriaLabel = 'Error',
    this.cancelButton = 'Cancel',
    this.previousButton = 'Previous',
    this.nextButton = 'Next',
    this.submitButton = 'Submit',
    this.optional = 'optional',
    this.nextButtonLoadingAnnouncement = 'Loading next step',
    this.submitButtonLoadingAnnouncement = 'Submitting form',
  });

  /// "Step 1". Defaults to `Step N`.
  final String Function(int stepNumber)? stepNumberLabel;

  /// The phone summary "Step 1 of 3".
  final String Function(int stepNumber, int stepsCount)? collapsedStepsLabel;

  /// The skip-to button text. Defaults to "Skip to {title}".
  final String Function(CsWizardStep targetStep, int targetStepNumber)? skipToButtonLabel;
  final String navigationAriaLabel;
  final String errorIconAriaLabel;
  final String cancelButton;
  final String previousButton;
  final String nextButton;

  /// The last step's primary button, unless [CsWizard.submitButtonText] is set.
  final String submitButton;
  final String optional;
  final String nextButtonLoadingAnnouncement;
  final String submitButtonLoadingAnnouncement;

  String stepNumber(int n) => stepNumberLabel?.call(n) ?? 'Step $n';
  String collapsedSteps(int n, int count) => collapsedStepsLabel?.call(n, count) ?? 'Step $n of $count';
  String skipTo(CsWizardStep step, int n) => skipToButtonLabel?.call(step, n) ?? 'Skip to ${step.title}';
}

/// How a step shows in the step list, from Cloudscape's `getStepStatus`.
enum CsWizardStepStatus {
  active,

  /// Visited before: reachable.
  visited,

  /// Not visited and not reachable.
  unvisited,

  /// Not visited, reachable by skipping optional steps.
  next;

  /// The status of step [index].
  static CsWizardStepStatus of({
    required int index,
    required int activeStepIndex,
    required int farthestStepIndex,
    required bool isLoadingNextStep,
    required bool allowSkipTo,
    required List<CsWizardStep> steps,
  }) {
    if (index == activeStepIndex) return active;
    if (isLoadingNextStep) return unvisited;
    if (farthestStepIndex >= index) return visited;
    if (allowSkipTo && index > activeStepIndex) {
      var canSkip = activeStepIndex + 1 < index;
      for (var i = activeStepIndex + 1; i < index && canSkip; i++) {
        if (!steps[i].isOptional) canSkip = false;
      }
      if (canSkip) return next;
      if (index == activeStepIndex + 1 && (steps[index].isOptional || steps[activeStepIndex].isOptional)) return next;
    }
    return unvisited;
  }

  bool get reachable => this == visited || this == next;
}

/// Cloudscape's `Wizard`: a multi-page form that walks people through a
/// complex task one step at a time.
///
/// ```dart
/// CsWizard(
///   activeStepIndex: step,
///   onNavigate: (d) => setState(() => step = d.requestedStepIndex),
///   onCancel: confirmCancel,
///   onSubmit: launch,
///   submitButtonText: 'Launch instance',
///   steps: [
///     CsWizardStep(title: 'Choose an image', content: imageForm),
///     CsWizardStep(title: 'Configure storage', content: storageForm, isOptional: true),
///     CsWizardStep(title: 'Review and launch', content: review),
///   ],
/// )
/// ```
///
/// On wide layouts the step list sits on the side; below 688px the list
/// collapses into a "Step 1 of 3" toggle above the form, as Cloudscape's
/// small container layout. Leave [activeStepIndex] null to let the wizard
/// track the step itself; [onNavigate] still reports every move.
///
/// Visited steps stay reachable from the list. With [allowSkipTo], optional
/// steps ahead can be skipped with a "Skip to" button. While
/// [isLoadingNextStep] the primary button spins and the list locks.
class CsWizard extends StatefulWidget {
  const CsWizard({
    super.key,
    required this.steps,
    this.activeStepIndex,
    this.onNavigate,
    this.onCancel,
    this.onSubmit,
    this.isLoadingNextStep = false,
    this.allowSkipTo = false,
    this.submitButtonText,
    this.secondaryActions,
    this.customPrimaryActions,
    this.i18nStrings = const CsWizardI18nStrings(),
  });

  final List<CsWizardStep> steps;

  /// The current step, from 0. Null makes the wizard uncontrolled. Values
  /// past the last step show the last step.
  final int? activeStepIndex;
  final ValueChanged<CsWizardNavigateDetail>? onNavigate;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  /// Spins the next or submit button and locks navigation, for server-side
  /// validation.
  final bool isLoadingNextStep;

  /// Offers a "Skip to" button over optional steps ahead.
  final bool allowSkipTo;

  /// Text of the last step's primary button. Defaults to
  /// [CsWizardI18nStrings.submitButton].
  final String? submitButtonText;

  /// Start-aligned actions, such as "Save draft".
  final Widget? secondaryActions;

  /// Replaces Cancel, Previous, Skip to and Next or Submit.
  final Widget? customPrimaryActions;
  final CsWizardI18nStrings i18nStrings;

  @override
  State<CsWizard> createState() => _CsWizardState();
}

class _CsWizardState extends State<CsWizard> {
  int _ownIndex = 0;
  int _farthest = 0;
  bool _stepsExpanded = false;
  final FocusNode _headerFocus = FocusNode(debugLabel: 'CsWizard step header', skipTraversal: true);

  int get _active {
    final raw = widget.activeStepIndex ?? _ownIndex;
    if (widget.steps.isEmpty) return 0;
    return raw.clamp(0, widget.steps.length - 1);
  }

  @override
  void initState() {
    super.initState();
    _farthest = _active;
  }

  @override
  void didUpdateWidget(CsWizard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = (oldWidget.activeStepIndex ?? _ownIndex).clamp(
      0,
      oldWidget.steps.isEmpty ? 0 : oldWidget.steps.length - 1,
    );
    if (_active > _farthest) _farthest = _active;
    if (before != _active) _onStepChanged();
  }

  @override
  void dispose() {
    _headerFocus.dispose();
    super.dispose();
  }

  void _onStepChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Cloudscape moves focus to the new step's heading so screen readers
      // read where the person is.
      _headerFocus.requestFocus();
      final step = widget.steps[_active];
      final view = View.of(context);
      SemanticsService.sendAnnouncement(view, step.title, Directionality.of(context));
    });
  }

  void _navigate(int index, CsWizardNavigationReason reason) {
    if (widget.activeStepIndex == null) {
      setState(() {
        _ownIndex = index;
        if (index > _farthest) _farthest = index;
      });
      _onStepChanged();
    }
    widget.onNavigate?.call(CsWizardNavigateDetail(requestedStepIndex: index, reason: reason));
  }

  int _skipTarget() {
    var i = _active;
    do {
      i++;
    } while (i < widget.steps.length - 1 && widget.steps[i].isOptional);
    return i > _active + 1 ? i : -1;
  }

  void _primary() {
    if (_active >= widget.steps.length - 1) {
      widget.onSubmit?.call();
    } else {
      _navigate(_active + 1, CsWizardNavigationReason.next);
    }
  }

  void _stepTapped(int index, CsWizardStepStatus status) {
    if (status == CsWizardStepStatus.visited) {
      _navigate(index, CsWizardNavigationReason.step);
    } else if (status == CsWizardStepStatus.next) {
      _navigate(index, CsWizardNavigationReason.skip);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
        final small = width < CsBreakpoint.xs.minWidth;
        final cs = context.cs;
        final list = _StepList(
          steps: widget.steps,
          activeStepIndex: _active,
          farthestStepIndex: _farthest,
          isLoadingNextStep: widget.isLoadingNextStep,
          allowSkipTo: widget.allowSkipTo,
          strings: widget.i18nStrings,
          onStep: _stepTapped,
        );
        final header = _header(context, small: small);
        final form = _form(context);
        if (small) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CollapsedSteps(
                label: widget.i18nStrings.collapsedSteps(_active + 1, widget.steps.length),
                ariaLabel:
                    '${widget.i18nStrings.collapsedSteps(_active + 1, widget.steps.length)} - ${widget.i18nStrings.navigationAriaLabel}',
                expanded: _stepsExpanded,
                onToggle: () => setState(() => _stepsExpanded = !_stepsExpanded),
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  label: widget.i18nStrings.navigationAriaLabel,
                  child: list,
                ),
              ),
              SizedBox(height: cs.space.scaledXxs),
              header,
              form,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: CsSpace.xs + cs.space.scaledXxs),
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                label: widget.i18nStrings.navigationAriaLabel,
                child: SizedBox(width: 260, child: list),
              ),
            ),
            const SizedBox(width: CsSpace.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  SizedBox(height: cs.space.scaledXxs),
                  form,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context, {required bool small}) {
    final cs = context.cs;
    final step = widget.steps[_active];
    final h1 = cs.text(CsHeaderVariant.h1.scale);
    return Padding(
      padding: EdgeInsets.only(top: small ? 0 : CsSpace.xl + cs.space.scaledXxxs, bottom: cs.space.scaledS),
      child: Focus(
        focusNode: _headerFocus,
        child: CsHeader(
          variant: CsHeaderVariant.h1,
          info: step.info,
          description: step.description,
          descriptionWidget: step.descriptionWidget,
          titleWidget: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: step.title),
                if (step.isOptional)
                  TextSpan(
                    text: ' - ${widget.i18nStrings.optional}',
                    style: h1.copyWith(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            style: h1,
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final cs = context.cs;
    final step = widget.steps[_active];
    final strings = widget.i18nStrings;
    final last = _active >= widget.steps.length - 1;
    final skip = _skipTarget();
    final showSkip = widget.allowSkipTo && skip != -1;
    final loading = widget.isLoadingNextStep;

    final actions =
        widget.customPrimaryActions ??
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: CsSpace.xs,
          runSpacing: CsSpace.xs,
          children: [
            CsButton(text: strings.cancelButton, variant: CsButtonVariant.link, onPress: widget.onCancel ?? () {}),
            if (showSkip)
              CsButton(
                text: strings.skipTo(widget.steps[skip], skip + 1),
                disabled: loading,
                onPress: () => _navigate(skip, CsWizardNavigationReason.skip),
              ),
            if (_active != 0)
              CsButton(
                text: strings.previousButton,
                disabled: loading,
                onPress: () => _navigate(_active - 1, CsWizardNavigationReason.previous),
              ),
            CsButton(
              text: last ? (widget.submitButtonText ?? strings.submitButton) : strings.nextButton,
              variant: CsButtonVariant.primary,
              loading: loading,
              loadingText: last ? strings.submitButtonLoadingAnnouncement : strings.nextButtonLoadingAnnouncement,
              onPress: _primary,
            ),
          ],
        );

    final hasError = step.errorText != null || step.errorWidget != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        KeyedSubtree(key: ValueKey(_active), child: step.content),
        if (hasError) ...[
          SizedBox(height: cs.space.scaledL),
          _ErrorAlert(iconLabel: strings.errorIconAriaLabel, child: step.errorWidget ?? Text(step.errorText!)),
        ],
        SizedBox(height: cs.space.scaledL),
        if (widget.secondaryActions == null)
          Align(alignment: AlignmentDirectional.centerEnd, child: actions)
        else
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [widget.secondaryActions!, actions],
          ),
      ],
    );
  }
}

/// The form's page-level error: Cloudscape's error alert.
class _ErrorAlert extends StatelessWidget {
  const _ErrorAlert({required this.iconLabel, required this.child});

  final String iconLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: CsSpace.alertHorizontal, vertical: cs.space.alertVertical),
        decoration: BoxDecoration(
          color: c.backgroundStatusError,
          borderRadius: BorderRadius.circular(CsBorderRadius.alert),
          border: CsRing.inside(c.borderStatusError, width: CsBorderWidth.alert),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: CsSpace.xs),
              child: SizedBox(
                height: CsTypeScale.bodyM.lineHeight,
                child: Center(
                  widthFactor: 1,
                  child: CsIcon(
                    CsIcons.statusNegative,
                    semanticLabel: iconLabel,
                    dangerouslySetColor: c.textStatusError,
                  ),
                ),
              ),
            ),
            Expanded(
              child: DefaultTextStyle.merge(style: cs.body, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapsedSteps extends StatelessWidget {
  const _CollapsedSteps({
    required this.label,
    required this.ariaLabel,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String label;
  final String ariaLabel;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CsPressable(
          onPress: onToggle,
          expanded: expanded,
          semanticLabel: ariaLabel,
          excludeChildSemantics: true,
          scaleOnPress: false,
          borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
          builder: (context, state) {
            final color = state.active ? c.textExpandableSectionHover : c.textExpandableSectionDefault;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: cs.space.scaledXxs),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: CsSpace.xxs + CsBorderLine.dividerListWidth),
                    child: AnimatedRotation(
                      turns: expanded ? 0 : (rtl ? 0.25 : -0.25),
                      duration: CsMotion.duration(context, CsDurations.rotate90),
                      curve: CsCurves.rotate90,
                      child: CsIcon(CsIcons.caretDownFilled, dangerouslySetColor: color),
                    ),
                  ),
                  Expanded(
                    child: Text(label, style: cs.typography.style(CsTypeScale.headingS, color: color)),
                  ),
                ],
              ),
            );
          },
        ),
        CsNavReveal(
          expanded: expanded,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: CsSpace.xs),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList({
    required this.steps,
    required this.activeStepIndex,
    required this.farthestStepIndex,
    required this.isLoadingNextStep,
    required this.allowSkipTo,
    required this.strings,
    required this.onStep,
  });

  final List<CsWizardStep> steps;
  final int activeStepIndex;
  final int farthestStepIndex;
  final bool isLoadingNextStep;
  final bool allowSkipTo;
  final CsWizardI18nStrings strings;
  final void Function(int index, CsWizardStepStatus status) onStep;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Padding(
      padding: EdgeInsets.only(top: cs.space.scaledXxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < steps.length; i++)
            _StepItem(
              index: i,
              count: steps.length,
              step: steps[i],
              status: CsWizardStepStatus.of(
                index: i,
                activeStepIndex: activeStepIndex,
                farthestStepIndex: farthestStepIndex,
                isLoadingNextStep: isLoadingNextStep,
                allowSkipTo: allowSkipTo,
                steps: steps,
              ),
              strings: strings,
              onStep: onStep,
            ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.index,
    required this.count,
    required this.step,
    required this.status,
    required this.strings,
    required this.onStep,
  });

  final int index;
  final int count;
  final CsWizardStep step;
  final CsWizardStepStatus status;
  final CsWizardI18nStrings strings;
  final void Function(int index, CsWizardStepStatus status) onStep;

  // Column 1 of Cloudscape's step grid is space-l wide, with space-xs gap.
  static const double _rail = CsSpace.l;
  static const double _gap = CsSpace.xs;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final first = index == 0;
    final last = index == count - 1;
    final topGap = first ? 0.0 : CsSpace.m;
    final labelHeight = MediaQuery.textScalerOf(context).scale(CsTypeScale.bodyS.lineHeight);
    final numberLabel = strings.stepNumber(index + 1);
    final small = cs.text(CsTypeScale.bodyS, color: CsColor.textSmall);

    final link = CsPressable(
      onPress: status.reachable ? () => onStep(index, status) : null,
      disabled: status == CsWizardStepStatus.unvisited,
      selected: status == CsWizardStepStatus.active,
      semanticLabel: '$numberLabel: ${step.title}',
      semanticHint: step.isOptional ? strings.optional : null,
      excludeChildSemantics: true,
      scaleOnPress: false,
      minTapTargetSize: 0,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
      builder: (context, state) {
        final hover = state.active && status.reachable;
        final Color titleColor = switch (status) {
          CsWizardStepStatus.active => c.backgroundControlChecked,
          CsWizardStepStatus.unvisited => c.textStatusInactive,
          _ => hover ? c.backgroundControlChecked : c.textInteractiveDefault,
        };
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: cs.minTapTarget > 0 ? 36 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _rail,
                height: CsTypeScale.bodyM.lineHeight,
                child: CustomPaint(
                  painter: _CirclePainter(
                    status: status,
                    hover: hover,
                    container: c.backgroundContainerContent,
                    checked: c.backgroundControlChecked,
                    interactive: c.textInteractiveDefault,
                    disabled: c.textInteractiveDisabled,
                  ),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: Text(
                  step.title,
                  style: cs.body.copyWith(
                    color: titleColor,
                    fontWeight: status == CsWizardStepStatus.active ? CsTypography.bold : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    return Stack(
      children: [
        if (count > 1)
          PositionedDirectional(
            start: (_rail - CsSpace.xxxs) / 2,
            width: CsSpace.xxxs,
            top: first ? topGap + labelHeight : 0,
            bottom: last ? null : 0,
            height: last ? topGap + labelHeight : null,
            child: ColoredBox(color: c.borderDividerDefault),
          ),
        Padding(
          padding: EdgeInsets.only(top: topGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: _rail + _gap),
                child: ExcludeSemantics(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: numberLabel),
                        if (step.isOptional)
                          TextSpan(
                            text: ' - ${strings.optional}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                    style: small,
                  ),
                ),
              ),
              link,
            ],
          ),
        ),
      ],
    );
  }
}

/// The step marker: a 10px dot with rings, per Cloudscape's box-shadows.
class _CirclePainter extends CustomPainter {
  const _CirclePainter({
    required this.status,
    required this.hover,
    required this.container,
    required this.checked,
    required this.interactive,
    required this.disabled,
  });

  final CsWizardStepStatus status;
  final bool hover;
  final Color container;
  final Color checked;
  final Color interactive;
  final Color disabled;

  @override
  void paint(Canvas canvas, Size size) {
    // 10px circle, 6px from the top of the 20px line.
    final center = Offset(size.width / 2, 6 + 5);
    const r = 5.0;
    void ring(double outer, Color color) => canvas.drawCircle(center, outer, Paint()..color = color);
    switch (status) {
      case CsWizardStepStatus.active:
        ring(r + 7, container);
        ring(r + 5, checked);
        ring(r + 3, container);
        ring(r, checked);
      case CsWizardStepStatus.unvisited:
        ring(r + 4, container);
        ring(r + 2, disabled);
        ring(r, container);
      case CsWizardStepStatus.visited || CsWizardStepStatus.next:
        final color = hover ? checked : interactive;
        ring(r + 4, container);
        ring(r + 2, color);
        ring(r, color);
    }
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.status != status ||
      old.hover != hover ||
      old.container != container ||
      old.checked != checked ||
      old.interactive != interactive ||
      old.disabled != disabled;
}
