import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../layout/cs_box.dart';
import '../navigation/cs_link.dart';
import '../status/cs_status_indicator.dart';
import '../system/cs_pressable.dart';
import '../system/cs_size_reveal.dart';
import '../theme/theme.dart';
import 'cs_annotation_context.dart';

/// Copy for [CsTutorialPanel], English by default (Cloudscape
/// `i18nStrings`). Indexes passed to the functions are 0-based.
@immutable
class CsTutorialPanelI18nStrings {
  const CsTutorialPanelI18nStrings({
    this.loadingText = 'Loading',
    this.tutorialListTitle = 'Choose a tutorial',
    this.tutorialListDescription = '',
    this.tutorialListDownloadLinkText = 'Download PDF version',
    this.labelTutorialListDownloadLink = 'Download PDF version of this tutorial',
    this.tutorialCompletedText = 'Tutorial completed',
    this.learnMoreLinkText = 'Learn more',
    this.labelLearnMoreLink,
    this.labelLearnMoreExternalIcon = 'Opens in a new tab',
    this.startTutorialButtonText = 'Start tutorial',
    this.restartTutorialButtonText = 'Restart tutorial',
    this.completionScreenTitle = 'Congratulations! You completed the tutorial.',
    this.feedbackLinkText = 'Feedback',
    this.dismissTutorialButtonText = 'Dismiss tutorial',
    this.labelExitTutorial = 'Dismiss tutorial',
    this.taskTitle = _taskTitle,
    this.stepTitle = _stepTitle,
    this.labelTotalSteps = _totalSteps,
    this.labelTaskStatusPending = 'Pending',
    this.labelTaskStatusInProgress = 'In progress',
    this.labelTaskStatusSuccess = 'Success',
  });

  final String loadingText;
  final String tutorialListTitle;

  /// Text under the list title. Empty hides it.
  final String tutorialListDescription;
  final String tutorialListDownloadLinkText;
  final String labelTutorialListDownloadLink;
  final String tutorialCompletedText;
  final String learnMoreLinkText;
  final String? labelLearnMoreLink;
  final String labelLearnMoreExternalIcon;
  final String startTutorialButtonText;
  final String restartTutorialButtonText;
  final String completionScreenTitle;
  final String feedbackLinkText;
  final String dismissTutorialButtonText;

  /// Label of the back arrow in the tutorial detail view.
  final String labelExitTutorial;
  final String Function(int taskIndex, String taskTitle) taskTitle;
  final String Function(int stepIndex, String stepTitle) stepTitle;
  final String Function(int totalStepCount) labelTotalSteps;
  final String labelTaskStatusPending;
  final String labelTaskStatusInProgress;
  final String labelTaskStatusSuccess;

  static String _taskTitle(int i, String title) => 'Task ${i + 1}: $title';
  static String _stepTitle(int i, String title) => 'Step ${i + 1}: $title';
  static String _totalSteps(int n) => 'Total steps: $n';
}

/// Cloudscape's `TutorialPanel`: lists the available tutorials and, while
/// one runs, its tasks and progress. Place it in the help or tools panel,
/// below a [CsAnnotationContext].
///
/// ```dart
/// CsTutorialPanel(
///   tutorials: tutorials,
///   i18nStrings: const CsTutorialPanelI18nStrings(
///     tutorialListDescription: 'Walkthroughs of common tasks in this console.',
///   ),
/// )
/// ```
///
/// Without a running tutorial it shows the list: each tutorial in a
/// bordered box with its title, an expand toggle, "Tutorial completed" when
/// done, the description, an optional "Learn more" link and a Start (or
/// Restart) button. Starting calls the context's `onStartTutorial`. While a
/// tutorial runs it shows the tutorial's tasks, each with its status
/// (done, in progress, pending) and its steps, and a Dismiss button; a
/// completed tutorial shows the completion screen.
class CsTutorialPanel extends StatelessWidget {
  const CsTutorialPanel({
    super.key,
    required this.tutorials,
    this.loading = false,
    this.onDownload,
    this.onFeedbackClick,
    this.i18nStrings = const CsTutorialPanelI18nStrings(),
  });

  final List<CsTutorial> tutorials;

  /// Shows a spinner with [CsTutorialPanelI18nStrings.loadingText] instead
  /// of the list.
  final bool loading;

  /// Shows the "Download PDF version" link (Cloudscape `downloadUrl`).
  final VoidCallback? onDownload;

  /// Shows a "Feedback" link on the completion screen.
  final ValueChanged<CsTutorial>? onFeedbackClick;
  final CsTutorialPanelI18nStrings i18nStrings;

  @override
  Widget build(BuildContext context) {
    final data = CsAnnotationContext.maybeOf(context);
    final current = data?.currentTutorial;
    final Widget body = current != null
        ? _DetailView(
            key: ValueKey(current.title),
            tutorial: current,
            currentStepIndex: data!.currentStepIndex,
            onExit: () => data.exitTutorial(current),
            onFeedbackClick: onFeedbackClick,
            strings: i18nStrings,
          )
        : _ListView(
            tutorials: tutorials,
            loading: loading,
            onStart: data?.startTutorial,
            onDownload: onDownload,
            strings: i18nStrings,
          );
    return Semantics(
      container: true,
      label: current == null ? i18nStrings.tutorialListTitle : null,
      child: DefaultTextStyle(style: context.cs.body, child: body),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({
    required this.tutorials,
    required this.loading,
    required this.onStart,
    required this.onDownload,
    required this.strings,
  });

  final List<CsTutorial> tutorials;
  final bool loading;
  final ValueChanged<CsTutorial>? onStart;
  final VoidCallback? onDownload;
  final CsTutorialPanelI18nStrings strings;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CsBox(
          variant: CsBoxVariant.h2,
          fontSize: CsTypeScale.headingM,
          text: strings.tutorialListTitle,
          padding: const CsBoxSpacing(bottom: CsSpacingSize.n),
        ),
        if (strings.tutorialListDescription.isNotEmpty) ...[
          const SizedBox(height: CsSpace.m),
          CsBox(
            variant: CsBoxVariant.p,
            color: CsBoxColor.textBodySecondary,
            text: strings.tutorialListDescription,
            padding: const CsBoxSpacing(top: CsSpacingSize.n, bottom: CsSpacingSize.n),
          ),
        ],
        const SizedBox(height: CsSpace.s),
        if (onDownload != null) ...[
          _DownloadLink(
            text: strings.tutorialListDownloadLinkText,
            label: strings.labelTutorialListDownloadLink,
            onPress: onDownload!,
          ),
          const SizedBox(height: CsSpace.l),
        ],
        if (loading)
          CsStatusIndicator(type: CsStatusType.loading, text: strings.loadingText)
        else
          Semantics(
            container: true,
            explicitChildNodes: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: CsSpace.l,
              children: [
                for (final t in tutorials)
                  _TutorialBox(key: ValueKey(t.title), tutorial: t, onStart: onStart, strings: strings),
              ],
            ),
          ),
        // Keeps the list from touching the panel edge on scroll.
        SizedBox(height: cs.space.scaledXxxs),
      ],
    );
  }
}

class _DownloadLink extends StatelessWidget {
  const _DownloadLink({required this.text, required this.label, required this.onPress});

  final String text;
  final String label;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: CsPressable(
        onPress: onPress,
        semanticLabel: label,
        excludeChildSemantics: true,
        isLink: true,
        scaleOnPress: false,
        builder: (context, state) {
          final style = cs.text(
            CsTypeScale.bodyM,
            weight: CsTypography.bold,
            color: CsColor.textBodySecondary,
            decoration: state.active || state.focused ? TextDecoration.underline : null,
          );
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CsIcon(CsIcons.download, dangerouslySetColor: style.color),
              const SizedBox(width: CsSpace.xs),
              Flexible(child: Text(text, style: style)),
            ],
          );
        },
      ),
    );
  }
}

class _TutorialBox extends StatefulWidget {
  const _TutorialBox({super.key, required this.tutorial, required this.onStart, required this.strings});

  final CsTutorial tutorial;
  final ValueChanged<CsTutorial>? onStart;
  final CsTutorialPanelI18nStrings strings;

  @override
  State<_TutorialBox> createState() => _TutorialBoxState();
}

class _TutorialBoxState extends State<_TutorialBox> {
  late bool _expanded = !widget.tutorial.prerequisitesNeeded && !widget.tutorial.completed;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final t = widget.tutorial;
    final s = widget.strings;
    final details = Padding(
      padding: const EdgeInsets.only(top: CsSpace.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (t.prerequisitesNeeded && t.prerequisitesAlert != null) ...[
            _InfoAlert(child: t.prerequisitesAlert!),
            const SizedBox(height: CsSpace.m),
          ],
          DefaultTextStyle(
            style: cs.text(CsTypeScale.bodyM, color: CsColor.textBodySecondary),
            child: t.description,
          ),
          if (t.onLearnMore != null) ...[
            const SizedBox(height: CsSpace.s),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CsLink(
                text: s.learnMoreLinkText,
                variant: CsLinkVariant.primary,
                external: true,
                externalIconAriaLabel: s.labelLearnMoreExternalIcon,
                ariaLabel: s.labelLearnMoreLink,
                onFollow: t.onLearnMore,
              ),
            ),
          ],
          const SizedBox(height: CsSpace.l),
          Padding(
            padding: const EdgeInsets.only(bottom: CsSpace.xxs),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: CsButton(
                text: t.completed ? s.restartTutorialButtonText : s.startTutorialButtonText,
                disabled: t.prerequisitesNeeded,
                onPress: widget.onStart == null ? null : () => widget.onStart!(t),
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(CsSpace.m),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CsBorderRadius.tutorialPanelItem),
          border: Border.all(color: cs.colors.borderTutorial, width: CsBorderLine.dividerSectionWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: CsSpace.xs, top: CsSpace.xxs),
                    child: CsBox(
                      variant: CsBoxVariant.h3,
                      fontSize: CsTypeScale.headingS,
                      text: t.title,
                      padding: const CsBoxSpacing(top: CsSpacingSize.n, bottom: CsSpacingSize.n),
                    ),
                  ),
                ),
                CsButton(
                  icon: _expanded ? CsIcons.angleUp : CsIcons.angleDown,
                  variant: CsButtonVariant.icon,
                  semanticLabel: t.title,
                  expanded: _expanded,
                  onPress: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
            if (t.completed) ...[
              const SizedBox(height: CsSpace.xs),
              CsStatusIndicator(type: CsStatusType.success, text: s.tutorialCompletedText),
            ],
            _Reveal(expanded: _expanded, child: details),
          ],
        ),
      ),
    );
  }
}

/// Expands and collapses [child] from the top with the expandable-section
/// motion; reduced motion swaps instantly.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: CsDurations.showPaced, value: widget.expanded ? 1 : 0);
  }

  @override
  void didUpdateWidget(_Reveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded == widget.expanded) return;
    if (CsMotion.reduceMotion(context)) {
      _c.value = widget.expanded ? 1 : 0;
    } else if (widget.expanded) {
      _c.forward();
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        if (_c.value == 0) return const SizedBox.shrink();
        final curved = CsCurves.showPaced.transform(_c.value);
        return CsSizeReveal(
          sizeFactor: AlwaysStoppedAnimation(curved),
          child: Opacity(opacity: curved, child: child),
        );
      },
      child: widget.child,
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({
    super.key,
    required this.tutorial,
    required this.currentStepIndex,
    required this.onExit,
    required this.onFeedbackClick,
    required this.strings,
  });

  final CsTutorial tutorial;
  final int currentStepIndex;
  final VoidCallback onExit;
  final ValueChanged<CsTutorial>? onFeedbackClick;
  final CsTutorialPanelI18nStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final header = Padding(
      padding: const EdgeInsets.only(bottom: CsSpace.xxxs),
      child: Transform.translate(
        // `.tutorial-title`: margin-inline-start -space-xxs aligns the arrow's glyph with the panel edge.
        offset: Offset(Directionality.of(context) == TextDirection.rtl ? CsSpace.xxs : -CsSpace.xxs, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CsButton(
              icon: CsIcons.arrowLeft,
              variant: CsButtonVariant.icon,
              semanticLabel: s.labelExitTutorial,
              onPress: onExit,
            ),
            const SizedBox(width: CsSpace.s),
            Expanded(
              child: CsBox(
                variant: CsBoxVariant.h2,
                fontSize: CsTypeScale.headingM,
                text: tutorial.title,
                padding: const CsBoxSpacing(top: CsSpacingSize.xxs, bottom: CsSpacingSize.n),
              ),
            ),
          ],
        ),
      ),
    );
    final Widget body = tutorial.completed
        ? Semantics(
            liveRegion: true,
            child: _Congratulations(
              tutorial: tutorial,
              strings: s,
              onFeedbackClick: onFeedbackClick == null ? null : () => onFeedbackClick!(tutorial),
            ),
          )
        : _TaskList(tutorial: tutorial, currentStepIndex: currentStepIndex, onExit: onExit, strings: s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        const SizedBox(height: CsSpace.xl),
        body,
      ],
    );
  }
}

class _Congratulations extends StatelessWidget {
  const _Congratulations({required this.tutorial, required this.strings, required this.onFeedbackClick});

  final CsTutorial tutorial;
  final CsTutorialPanelI18nStrings strings;
  final VoidCallback? onFeedbackClick;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final titleStyle = cs.text(CsTypeScale.headingS, color: CsColor.textStatusSuccess);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: CsTypeScale.headingS.lineHeight,
              child: const CsStatusIndicator(type: CsStatusType.success),
            ),
            const SizedBox(width: CsSpace.xxs),
            Expanded(child: Text(strings.completionScreenTitle, style: titleStyle)),
          ],
        ),
        const SizedBox(height: CsSpace.xl),
        DefaultTextStyle(
          style: cs.text(CsTypeScale.bodyM, color: CsColor.textBodySecondary),
          child: tutorial.completedScreenDescription,
        ),
        const SizedBox(height: CsSpace.xxl),
        Container(height: CsBorderLine.dividerSectionWidth, color: cs.colors.borderDividerDefault),
        if (onFeedbackClick != null) ...[
          const SizedBox(height: CsSpace.xxl),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CsLink(text: strings.feedbackLinkText, variant: CsLinkVariant.primary, onFollow: onFeedbackClick),
          ),
        ],
      ],
    );
  }
}

class _TaskList extends StatefulWidget {
  const _TaskList({
    required this.tutorial,
    required this.currentStepIndex,
    required this.onExit,
    required this.strings,
  });

  final CsTutorial tutorial;
  final int currentStepIndex;
  final VoidCallback onExit;
  final CsTutorialPanelI18nStrings strings;

  @override
  State<_TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<_TaskList> {
  late int _currentTask = _taskIndex();
  late Set<int> _expanded = {_currentTask};

  int _taskIndex() => CsTutorialStepInfo.of(widget.tutorial.tasks, widget.currentStepIndex).taskIndex;

  @override
  void didUpdateWidget(_TaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final task = _taskIndex();
    if (task != _currentTask) {
      // Progressing to another task collapses all others.
      _currentTask = task;
      _expanded = {task};
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final tasks = widget.tutorial.tasks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tasks.length; i++) ...[
          if (i > 0) const SizedBox(height: CsSpace.xl),
          _Task(
            task: tasks[i],
            index: i,
            currentTask: _currentTask,
            expanded: _expanded.contains(i),
            onToggle: () => setState(() => _expanded.contains(i) ? _expanded.remove(i) : _expanded.add(i)),
            strings: s,
          ),
        ],
        const SizedBox(height: CsSpace.xxl + CsSpace.xxxs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: CsButton(text: s.dismissTutorialButtonText, onPress: widget.onExit),
        ),
      ],
    );
  }
}

class _Task extends StatelessWidget {
  const _Task({
    required this.task,
    required this.index,
    required this.currentTask,
    required this.expanded,
    required this.onToggle,
    required this.strings,
  });

  final CsTutorialTask task;
  final int index;
  final int currentTask;
  final bool expanded;
  final VoidCallback onToggle;
  final CsTutorialPanelI18nStrings strings;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final s = strings;
    final (type, label) = index < currentTask
        ? (CsStatusType.success, s.labelTaskStatusSuccess)
        : index == currentTask
        ? (CsStatusType.inProgress, s.labelTaskStatusInProgress)
        : (CsStatusType.pending, s.labelTaskStatusPending);
    final title = s.taskTitle(index, task.title);
    final total = s.labelTotalSteps(task.steps.length);
    final titleColor = index < currentTask ? CsColor.textStatusSuccess : CsColor.textStatusInactive;
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: CsTypeScale.headingS.lineHeight,
                child: CsStatusIndicator(type: type, iconAriaLabel: label),
              ),
              const SizedBox(width: CsSpace.xxxs),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: cs.text(CsTypeScale.headingS, color: titleColor)),
                ),
              ),
            ],
          ),
          const SizedBox(height: CsSpace.xxs),
          CsPressable(
            onPress: onToggle,
            expanded: expanded,
            semanticLabel: '$title, $total',
            excludeChildSemantics: true,
            scaleOnPress: false,
            borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
            builder: (context, state) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: expanded ? 0 : -0.25,
                  duration: CsMotion.duration(context, CsDurations.rotate90),
                  curve: CsCurves.rotate90,
                  child: CsIcon(
                    CsIcons.caretDownFilled,
                    dangerouslySetColor: state.active
                        ? cs.colors.textExpandableSectionHover
                        : cs.colors.textExpandableSectionDefault,
                  ),
                ),
                const SizedBox(width: CsSpace.xxs),
                Flexible(child: Text(total, style: cs.body)),
              ],
            ),
          ),
          _Reveal(
            expanded: expanded,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: CsSpace.xxxs, top: CsSpace.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: CsSpace.xxs,
                children: [
                  for (var j = 0; j < task.steps.length; j++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: CsSpace.l),
                      child: Text(
                        s.stepTitle(j, task.steps[j].title),
                        style: cs.text(CsTypeScale.bodyM, color: CsColor.textBodySecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The info alert holding a tutorial's prerequisites (Cloudscape renders an
/// `Alert type="info"`).
class _InfoAlert extends StatelessWidget {
  const _InfoAlert({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.alertHorizontal, vertical: CsSpace.xs),
      decoration: BoxDecoration(
        color: cs.colors.backgroundStatusInfo,
        borderRadius: BorderRadius.circular(CsBorderRadius.alert),
        border: Border.all(color: cs.colors.borderStatusInfo, width: CsBorderWidth.alert),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: CsTypeScale.bodyM.lineHeight,
            child: const CsIcon(CsIcons.statusInfo, variant: CsIconVariant.info),
          ),
          const SizedBox(width: CsSpace.xs),
          Expanded(
            child: DefaultTextStyle(style: cs.body, child: child),
          ),
        ],
      ),
    );
  }
}
