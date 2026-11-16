import 'package:flutter/widgets.dart';

/// One step of a [CsTutorialTask]: a popover attached to a [hotspotId]
/// (Cloudscape `TutorialPanelProps.Step`).
@immutable
class CsTutorialStep {
  const CsTutorialStep({required this.title, required this.content, required this.hotspotId, this.warningAlert});

  /// Shown in the step list of the tutorial panel.
  final String title;

  /// Body of the step's annotation popover.
  final Widget content;

  /// Shown in a warning alert inside the popover.
  final Widget? warningAlert;

  /// The `CsHotspot.hotspotId` this step points to. Hotspot IDs are unique in
  /// the whole app and can be reused by several tutorials.
  final String hotspotId;
}

/// A group of steps (Cloudscape `TutorialPanelProps.Task`).
@immutable
class CsTutorialTask {
  const CsTutorialTask({required this.title, required this.steps});

  final String title;
  final List<CsTutorialStep> steps;
}

/// A tutorial: tasks of steps that walk the user through the app
/// (Cloudscape `TutorialPanelProps.Tutorial`).
@immutable
class CsTutorial {
  const CsTutorial({
    required this.title,
    required this.description,
    required this.tasks,
    required this.completedScreenDescription,
    this.completed = false,
    this.prerequisitesNeeded = false,
    this.prerequisitesAlert,
    this.onLearnMore,
  });

  final String title;

  /// Short description shown in the tutorial list.
  final Widget description;
  final List<CsTutorialTask> tasks;

  /// Shown on the completion screen.
  final Widget completedScreenDescription;

  /// The user already completed this tutorial: the list shows "Tutorial
  /// completed" and a restart button, and hotspots stay closed.
  final bool completed;

  /// The tutorial cannot start yet: its start button is disabled and
  /// [prerequisitesAlert] is shown.
  final bool prerequisitesNeeded;
  final Widget? prerequisitesAlert;

  /// Shows a "Learn more" link in the list (Cloudscape `learnMoreUrl`).
  final VoidCallback? onLearnMore;

  /// Total number of steps across all tasks.
  int get totalStepCount => tasks.fold(0, (n, t) => n + t.steps.length);

  CsTutorial copyWith({bool? completed, bool? prerequisitesNeeded}) => CsTutorial(
    title: title,
    description: description,
    tasks: tasks,
    completedScreenDescription: completedScreenDescription,
    completed: completed ?? this.completed,
    prerequisitesNeeded: prerequisitesNeeded ?? this.prerequisitesNeeded,
    prerequisitesAlert: prerequisitesAlert,
    onLearnMore: onLearnMore,
  );
}

/// Where a global step index falls inside the tasks of a tutorial.
@immutable
class CsTutorialStepInfo {
  const CsTutorialStepInfo({this.task, this.step, this.localIndex = 0, this.taskIndex = 0});

  final CsTutorialTask? task;
  final CsTutorialStep? step;

  /// Index of the step inside its task.
  final int localIndex;
  final int taskIndex;

  /// Resolves the global step [index] in [tasks].
  static CsTutorialStepInfo of(List<CsTutorialTask> tasks, int index) {
    if (index < 0) return const CsTutorialStepInfo();
    var i = index;
    var taskIndex = 0;
    for (final task in tasks) {
      if (task.steps.length <= i) {
        i -= task.steps.length;
        taskIndex++;
        continue;
      }
      return CsTutorialStepInfo(task: task, step: task.steps[i], localIndex: i, taskIndex: taskIndex);
    }
    return const CsTutorialStepInfo();
  }
}

/// Why the current step changed (Cloudscape `StepChangeDetail.reason`).
enum CsStepChangeReason {
  /// The Next button.
  next,

  /// The Previous button.
  previous,

  /// A closed hotspot was opened.
  open,

  /// The current step's hotspot left the screen and the nearest available
  /// one took over (after navigating to another page, for example).
  autoFallback,
}

/// Copy for [CsAnnotationContext] and its hotspots, English by default
/// (Cloudscape `i18nStrings`). Indexes passed to the functions are 0-based.
@immutable
class CsAnnotationI18nStrings {
  const CsAnnotationI18nStrings({
    this.nextButtonText = 'Next',
    this.previousButtonText = 'Previous',
    this.finishButtonText = 'Finish',
    this.labelDismissAnnotation = 'Dismiss annotation',
    this.labelHotspot = _labelHotspot,
    this.stepCounterText = _stepCounter,
    this.taskTitle = _taskTitle,
  });

  final String nextButtonText;
  final String previousButtonText;
  final String finishButtonText;

  /// Label of the popover's dismiss button.
  final String labelDismissAnnotation;

  /// Label of a hotspot: `(open, stepIndex, totalStepCount)`.
  final String Function(bool open, int stepIndex, int totalStepCount) labelHotspot;

  /// Step counter in the popover: `(stepIndex, totalStepCount)` within the task.
  final String Function(int stepIndex, int totalStepCount) stepCounterText;

  /// Popover title: `(taskIndex, taskTitle)`.
  final String Function(int taskIndex, String taskTitle) taskTitle;

  static String _labelHotspot(bool open, int step, int total) => 'Annotation for step ${step + 1} of $total';
  static String _stepCounter(int step, int total) => 'Step ${step + 1} of $total';
  static String _taskTitle(int task, String title) => 'Task ${task + 1}: $title';
}

/// What a [CsHotspot] shows for its ID at the moment.
@immutable
class CsHotspotSlot {
  const CsHotspotSlot({
    required this.globalStepIndex,
    required this.open,
    required this.current,
    required this.taskLocalStepIndex,
    required this.totalLocalSteps,
    this.title,
    this.content,
    this.warningAlert,
    this.showPreviousButton = false,
    this.showFinishButton = false,
    this.previousButtonEnabled = false,
    this.nextButtonEnabled = false,
  });

  /// The first step of the tutorial that uses this hotspot.
  final int globalStepIndex;

  /// The popover is showing.
  final bool open;

  /// This hotspot belongs to the current step (open, or dismissed).
  final bool current;
  final int taskLocalStepIndex;
  final int totalLocalSteps;
  final String? title;
  final Widget? content;
  final Widget? warningAlert;
  final bool showPreviousButton;
  final bool showFinishButton;
  final bool previousButtonEnabled;
  final bool nextButtonEnabled;
}

/// What [CsAnnotationContext] shares with the hotspots and the tutorial
/// panel below it. Read it with [CsAnnotationContext.maybeOf].
@immutable
class CsAnnotationContextData {
  const CsAnnotationContextData({
    required this.currentTutorial,
    required this.currentStepIndex,
    required this.i18nStrings,
    required this.pulseHotspots,
    required this.slotFor,
    required this.startTutorial,
    required this.exitTutorial,
    required this.openStep,
    required this.dismiss,
    required this.next,
    required this.previous,
    required this.finish,
    required this.registerHotspot,
    required this.unregisterHotspot,
  });

  final CsTutorial? currentTutorial;

  /// Global index of the current step across all tasks.
  final int currentStepIndex;
  final CsAnnotationI18nStrings i18nStrings;
  final bool pulseHotspots;

  /// The slot of a hotspot ID, or null when the current tutorial does not
  /// use it (or no tutorial runs).
  final CsHotspotSlot? Function(String hotspotId) slotFor;
  final ValueChanged<CsTutorial> startTutorial;
  final ValueChanged<CsTutorial> exitTutorial;

  /// Opens the popover of a global step index.
  final ValueChanged<int> openStep;
  final VoidCallback dismiss;
  final VoidCallback next;
  final VoidCallback previous;
  final VoidCallback finish;

  /// Called by [CsHotspot] when it mounts and unmounts.
  final ValueChanged<String> registerHotspot;
  final ValueChanged<String> unregisterHotspot;
}

/// Cloudscape's `AnnotationContext`: runs a tutorial over the app. Wrap the
/// page in it; [CsHotspot]s anywhere below open the current step's
/// annotation popover, and a [CsTutorialPanel] lists the tutorials and the
/// progress of the current one.
///
/// ```dart
/// CsAnnotationContext(
///   currentTutorial: _tutorial,
///   onStartTutorial: (t) => setState(() => _tutorial = t),
///   onExitTutorial: (_) => setState(() => _tutorial = null),
///   onFinish: () => setState(() => _tutorial = _tutorial!.copyWith(completed: true)),
///   child: page,
/// )
/// ```
///
/// The parent owns which tutorial runs ([currentTutorial]); this widget
/// owns the current step and whether its popover is open. Starting a
/// tutorial (a new [currentTutorial]) resets to its first step, open.
/// When the current step's hotspot is not on screen (another page), the
/// nearest available step takes over and [onStepChange] reports
/// [CsStepChangeReason.autoFallback].
class CsAnnotationContext extends StatefulWidget {
  const CsAnnotationContext({
    super.key,
    required this.currentTutorial,
    required this.onStartTutorial,
    required this.onExitTutorial,
    required this.child,
    this.onStepChange,
    this.onFinish,
    this.i18nStrings = const CsAnnotationI18nStrings(),
    this.pulseHotspots = true,
  });

  /// The running tutorial, or null.
  final CsTutorial? currentTutorial;

  /// The user chose a tutorial in the panel. Set [currentTutorial] to it.
  final ValueChanged<CsTutorial> onStartTutorial;

  /// The user left the tutorial. Set [currentTutorial] to null.
  final ValueChanged<CsTutorial> onExitTutorial;

  /// The current step changed: `(stepIndex, reason)`.
  final void Function(int step, CsStepChangeReason reason)? onStepChange;

  /// The user pressed Finish on the last step. Mark the tutorial completed.
  final VoidCallback? onFinish;
  final CsAnnotationI18nStrings i18nStrings;

  /// The current step's hotspot pulses while a tutorial runs, to lead the
  /// eye. Reduced motion turns it off.
  final bool pulseHotspots;
  final Widget child;

  /// The nearest context data, or null outside a [CsAnnotationContext].
  static CsAnnotationContextData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CsAnnotationScope>()?.data;

  @override
  State<CsAnnotationContext> createState() => _CsAnnotationContextState();
}

class _CsAnnotationContextState extends State<CsAnnotationContext> {
  bool _open = true;
  int _step = 0;
  final Map<String, int> _mounted = {};
  bool _fallbackScheduled = false;

  List<CsTutorialTask> get _tasks => widget.currentTutorial?.tasks ?? const [];

  late Map<String, int> _id2index = _computeIds();

  Map<String, int> _computeIds() {
    final map = <String, int>{};
    var counter = 0;
    for (final task in _tasks) {
      for (final step in task.steps) {
        map.putIfAbsent(step.hotspotId, () => counter);
        counter++;
      }
    }
    return map;
  }

  int get _total => _tasks.fold(0, (n, t) => n + t.steps.length);

  bool _available(String? id) => id != null && (_mounted[id] ?? 0) > 0 && _id2index.containsKey(id);

  @override
  void didUpdateWidget(CsAnnotationContext oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.currentTutorial, widget.currentTutorial)) {
      _id2index = _computeIds();
      final old = oldWidget.currentTutorial;
      final next = widget.currentTutorial;
      // Marking the running tutorial completed keeps its progress; another
      // tutorial, or restarting a completed one, starts over.
      final restarted = old == null || !_sameTasks(old, next) || (old.completed && !next!.completed);
      if (restarted) {
        _step = 0;
        _open = true;
      }
      _scheduleFallback();
    }
  }

  bool _sameTasks(CsTutorial a, CsTutorial? b) => b != null && identical(a.tasks, b.tasks) && a.title == b.title;

  void _setStep(int step, CsStepChangeReason reason, {bool open = true}) {
    setState(() {
      _step = step;
      _open = open;
    });
    widget.onStepChange?.call(step, reason);
  }

  void _register(String id) {
    _mounted[id] = (_mounted[id] ?? 0) + 1;
    _scheduleFallback();
  }

  void _unregister(String id) {
    final n = (_mounted[id] ?? 0) - 1;
    if (n <= 0) {
      _mounted.remove(id);
    } else {
      _mounted[id] = n;
    }
    _scheduleFallback();
  }

  /// Hotspots mount and unmount during build and layout, so availability
  /// is settled after the frame: then Next and Previous buttons update, and
  /// a missing current hotspot hands over to the nearest available one.
  void _scheduleFallback() {
    if (_fallbackScheduled) return;
    _fallbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fallbackScheduled = false;
      if (!mounted) return;
      final tutorial = widget.currentTutorial;
      final currentId = CsTutorialStepInfo.of(_tasks, _step).step?.hotspotId;
      if (tutorial == null || currentId == null || _available(currentId)) {
        setState(() {});
        return;
      }
      String? nearest;
      var distance = 1 << 30;
      for (final id in _mounted.keys) {
        final index = _id2index[id];
        if (index == null) continue;
        final d = (index - _step).abs();
        if (d < distance) {
          distance = d;
          nearest = id;
        }
      }
      if (nearest != null) {
        _setStep(_id2index[nearest]!, CsStepChangeReason.autoFallback);
      } else {
        setState(() {});
      }
    });
  }

  CsHotspotSlot? _slotFor(String id) {
    final tutorial = widget.currentTutorial;
    if (tutorial == null || tutorial.completed) return null;
    final global = _id2index[id];
    if (global == null) return null;
    final info = CsTutorialStepInfo.of(_tasks, _step);
    final currentId = info.step?.hotspotId;
    if (info.task == null || !_open || id != currentId) {
      final own = CsTutorialStepInfo.of(_tasks, global);
      return CsHotspotSlot(
        globalStepIndex: global,
        open: false,
        current: id == currentId,
        taskLocalStepIndex: own.localIndex,
        totalLocalSteps: own.task?.steps.length ?? 0,
      );
    }
    final prevId = CsTutorialStepInfo.of(_tasks, _step - 1).step?.hotspotId;
    final nextId = CsTutorialStepInfo.of(_tasks, _step + 1).step?.hotspotId;
    return CsHotspotSlot(
      globalStepIndex: global,
      open: true,
      current: true,
      taskLocalStepIndex: info.localIndex,
      totalLocalSteps: info.task!.steps.length,
      title: widget.i18nStrings.taskTitle(info.taskIndex, info.task!.title),
      content: info.step!.content,
      warningAlert: info.step!.warningAlert,
      showPreviousButton: _step != 0,
      showFinishButton: _step + 1 == _total,
      previousButtonEnabled: _available(prevId),
      nextButtonEnabled: _available(nextId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = CsAnnotationContextData(
      currentTutorial: widget.currentTutorial,
      currentStepIndex: _step,
      i18nStrings: widget.i18nStrings,
      pulseHotspots: widget.pulseHotspots,
      slotFor: _slotFor,
      startTutorial: widget.onStartTutorial,
      exitTutorial: widget.onExitTutorial,
      openStep: (i) => _setStep(i, CsStepChangeReason.open),
      dismiss: () => setState(() => _open = false),
      next: () => _setStep((_step + 1).clamp(0, _total), CsStepChangeReason.next),
      previous: () => _setStep((_step - 1).clamp(0, _total), CsStepChangeReason.previous),
      finish: () => widget.onFinish?.call(),
      registerHotspot: _register,
      unregisterHotspot: _unregister,
    );
    return _CsAnnotationScope(
      data: data,
      revision: Object.hash(_step, _open, widget.currentTutorial, Object.hashAll(_mounted.keys)),
      child: widget.child,
    );
  }
}

class _CsAnnotationScope extends InheritedWidget {
  const _CsAnnotationScope({required this.data, required this.revision, required super.child});

  final CsAnnotationContextData data;
  final int revision;

  @override
  bool updateShouldNotify(_CsAnnotationScope oldWidget) =>
      oldWidget.revision != revision ||
      oldWidget.data.i18nStrings != data.i18nStrings ||
      oldWidget.data.pulseHotspots != data.pulseHotspots;
}
