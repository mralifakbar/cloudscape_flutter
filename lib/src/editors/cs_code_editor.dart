import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_anchored_overlay.dart';
import '../overlays/cs_dropdown.dart';
import '../overlays/cs_menu_parts.dart';
import '../overlays/cs_sheet.dart';
import '../status/cs_status_indicator.dart';
import '../system/cs_editable.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';
import 'cs_code_editor_highlighter.dart';

/// Editor color theme (Cloudscape `preferences.theme`, which names an Ace
/// theme; this port has Cloudscape's two editor themes).
enum CsCodeEditorTheme {
  /// Follows the app: light in light mode, dark in dark mode.
  auto,

  /// Cloudscape's light editor (`cloud_editor`).
  light,

  /// Cloudscape's dark editor (`cloud_editor_dark`).
  dark,
}

/// User preferences of a [CsCodeEditor] (Cloudscape `Preferences`).
@immutable
class CsCodeEditorPreferences {
  const CsCodeEditorPreferences({this.wrapLines = true, this.theme = CsCodeEditorTheme.auto});

  /// Soft-wrap long lines instead of scrolling sideways.
  final bool wrapLines;
  final CsCodeEditorTheme theme;

  CsCodeEditorPreferences copyWith({bool? wrapLines, CsCodeEditorTheme? theme}) =>
      CsCodeEditorPreferences(wrapLines: wrapLines ?? this.wrapLines, theme: theme ?? this.theme);

  @override
  bool operator ==(Object other) =>
      other is CsCodeEditorPreferences && other.wrapLines == wrapLines && other.theme == theme;

  @override
  int get hashCode => Object.hash(wrapLines, theme);
}

/// Severity of a [CsCodeEditorAnnotation] (Ace `type`).
enum CsCodeEditorAnnotationType { error, warning, info }

/// A problem at a position in the code (Ace `Annotation`), shown in the
/// gutter, counted in the status bar and listed in the errors and warnings
/// pane.
@immutable
class CsCodeEditorAnnotation {
  const CsCodeEditorAnnotation({
    required this.row,
    this.column = 0,
    required this.text,
    this.type = CsCodeEditorAnnotationType.error,
  });

  /// Zero-based line.
  final int row;

  /// Zero-based column.
  final int column;
  final String text;
  final CsCodeEditorAnnotationType type;

  @override
  bool operator ==(Object other) =>
      other is CsCodeEditorAnnotation &&
      other.row == row &&
      other.column == column &&
      other.text == text &&
      other.type == type;

  @override
  int get hashCode => Object.hash(row, column, text, type);
}

/// Checks code and returns its problems.
typedef CsCodeEditorValidator = List<CsCodeEditorAnnotation> Function(String value);

/// Copy for [CsCodeEditor] (Cloudscape `CodeEditorProps.I18nStrings`).
@immutable
class CsCodeEditorI18nStrings {
  const CsCodeEditorI18nStrings({
    this.loadingState = 'Loading code editor',
    this.editorGroupAriaLabel = 'Code editor',
    this.statusBarGroupAriaLabel = 'Status bar',
    this.cursorPosition,
    this.errorsTab = 'Errors',
    this.warningsTab = 'Warnings',
    this.preferencesButtonAriaLabel = 'Preferences',
    this.paneCloseButtonAriaLabel = 'Close',
    this.preferencesWrapLines = 'Wrap lines',
    this.preferencesThemeAuto = 'Match application theme',
    this.preferencesThemeLight = 'Light theme',
    this.preferencesThemeDark = 'Dark theme',
    this.resizeHandleAriaLabel = 'Resize handle',
    this.resizeHandleTooltipText = 'Drag or select to resize',
  });

  final String loadingState;
  final String editorGroupAriaLabel;
  final String statusBarGroupAriaLabel;

  /// "Ln 3, Col 14". Gets one-based row and column.
  final String Function(int row, int column)? cursorPosition;
  final String errorsTab;
  final String warningsTab;
  final String preferencesButtonAriaLabel;
  final String paneCloseButtonAriaLabel;
  final String preferencesWrapLines;
  final String preferencesThemeAuto;
  final String preferencesThemeLight;
  final String preferencesThemeDark;
  final String resizeHandleAriaLabel;

  /// Hint of the resize handle.
  final String resizeHandleTooltipText;

  String position(int row, int column) => cursorPosition?.call(row, column) ?? 'Ln $row, Col $column';
}

/// Cloudscape's `CodeEditor`, rebuilt in Flutter without Ace: a monospace
/// editor with a line number gutter, syntax highlighting, an active line
/// marker, and Cloudscape's status bar (language, cursor position, error
/// and warning counts with their pane, preferences and a resize handle).
///
/// It is controlled: pass [value] and update it in [onChange].
///
/// ```dart
/// CsCodeEditor(
///   value: policy,
///   language: 'json',
///   validator: CsCodeEditor.jsonValidator,
///   preferences: prefs,
///   onPreferencesChange: (p) => setState(() => prefs = p),
///   onChange: (v) => setState(() => policy = v),
/// )
/// ```
///
/// Highlighting covers `json`, `yaml`, `javascript`, `typescript`,
/// `python` and `sh`; other languages show plain text. Problems come from
/// [annotations] or, when that is null, from [validator]. Tab inserts two
/// spaces; Escape leaves the editor so keyboard users are never trapped.
class CsCodeEditor extends StatefulWidget {
  const CsCodeEditor({
    super.key,
    required this.value,
    required this.language,
    this.onChange,
    this.onDelayedChange,
    this.onValidate,
    this.languageLabel,
    this.preferences,
    this.onPreferencesChange,
    this.loading = false,
    this.readOnly = false,
    this.annotations,
    this.validator,
    this.editorContentHeight,
    this.onEditorContentResize,
    this.ariaLabel,
    this.focusNode,
    this.i18nStrings = const CsCodeEditorI18nStrings(),
  });

  final String value;

  /// Language id (`json`, `yaml`, `javascript`, `python`, `sh`, ...).
  final String language;
  final ValueChanged<String>? onChange;

  /// Called 500ms after the last edit, for expensive work (Cloudscape
  /// `onDelayedChange`).
  final ValueChanged<String>? onDelayedChange;

  /// Called when the problems found change (Cloudscape `onValidate`).
  final ValueChanged<List<CsCodeEditorAnnotation>>? onValidate;

  /// Shown in the status bar. Defaults to a readable name for [language].
  final String? languageLabel;

  /// Defaults to wrapping lines with the app's theme.
  final CsCodeEditorPreferences? preferences;

  /// Enables the preferences button and receives new preferences.
  final ValueChanged<CsCodeEditorPreferences>? onPreferencesChange;

  /// Shows the loading state in place of the editor.
  final bool loading;
  final bool readOnly;

  /// Problems to show. Takes precedence over [validator].
  final List<CsCodeEditorAnnotation>? annotations;

  /// Computes problems from the value on every change.
  final CsCodeEditorValidator? validator;

  /// Height of the editing area. Defaults to 480 on wide screens and 240 on
  /// phones, and follows the resize handle unless [onEditorContentResize]
  /// controls it.
  final double? editorContentHeight;

  /// Called with the new height while the resize handle is dragged.
  final ValueChanged<double>? onEditorContentResize;
  final String? ariaLabel;
  final FocusNode? focusNode;
  final CsCodeEditorI18nStrings i18nStrings;

  /// A validator that reports the first JSON syntax error.
  static List<CsCodeEditorAnnotation> jsonValidator(String value) {
    if (value.trim().isEmpty) return const [];
    try {
      jsonDecode(value);
      return const [];
    } on FormatException catch (e) {
      final offset = (e.offset ?? 0).clamp(0, value.length);
      final before = value.substring(0, offset);
      final row = '\n'.allMatches(before).length;
      final column = offset - (before.lastIndexOf('\n') + 1);
      return [CsCodeEditorAnnotation(row: row, column: column, text: e.message)];
    }
  }

  @override
  State<CsCodeEditor> createState() => _CsCodeEditorState();
}

class _HighlightController extends TextEditingController {
  _HighlightController({super.text});

  String language = 'text';
  CsCodeEditorColors? colors;
  String? _cachedText;
  String? _cachedLanguage;
  List<CsCodeEditorToken> _tokens = const [];

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final palette = colors;
    if (palette == null || !CsCodeEditorHighlighter.supports(language)) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }
    if (_cachedText != text || _cachedLanguage != language) {
      _tokens = CsCodeEditorHighlighter.tokenize(text, language);
      _cachedText = text;
      _cachedLanguage = language;
    }
    return TextSpan(
      style: style,
      children: [
        for (final t in _tokens)
          TextSpan(
            text: t.text,
            style: TextStyle(
              color: palette.of(t.type),
              fontStyle: t.type == CsCodeEditorTokenType.comment ? FontStyle.italic : null,
            ),
          ),
      ],
    );
  }
}

class _CsCodeEditorState extends State<CsCodeEditor> {
  late final _HighlightController _controller = _HighlightController(text: widget.value);
  FocusNode? _ownNode;
  final ScrollController _vScroll = ScrollController();
  final ScrollController _hScroll = ScrollController();
  final FocusNode _errorsTab = FocusNode(debugLabel: 'CsCodeEditor errors');
  final FocusNode _warningsTab = FocusNode(debugLabel: 'CsCodeEditor warnings');
  Timer? _delayed;
  double? _height;
  CsCodeEditorAnnotationType? _pane;
  bool _prefsOpen = false;
  bool _focused = false;
  List<CsCodeEditorAnnotation> _lastReported = const [];

  // Line metrics cache, keyed by everything that changes wrapping.
  Object? _metricsKey;
  List<double> _lineHeights = const [];
  double _longest = 0;

  FocusNode get _focusNode => widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'CsCodeEditor'));

  CsCodeEditorPreferences get _prefs => widget.preferences ?? const CsCodeEditorPreferences();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChange);
    _focusNode.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(CsCodeEditor old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownNode)?.removeListener(_onFocus);
      _focusNode.addListener(_onFocus);
    }
    if (_controller.text != widget.value) {
      final offset = _controller.selection.baseOffset.clamp(0, widget.value.length);
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: offset),
      );
    }
  }

  @override
  void dispose() {
    _delayed?.cancel();
    _controller.removeListener(_onControllerChange);
    _focusNode.removeListener(_onFocus);
    _controller.dispose();
    _ownNode?.dispose();
    _vScroll.dispose();
    _hScroll.dispose();
    _errorsTab.dispose();
    _warningsTab.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (mounted && _focused != _focusNode.hasFocus) setState(() => _focused = _focusNode.hasFocus);
  }

  int _lastOffset = -1;

  void _onControllerChange() {
    final offset = _controller.selection.baseOffset;
    if (offset != _lastOffset) {
      _lastOffset = offset;
      if (mounted) setState(() {});
    }
  }

  void _changed(String v) {
    widget.onChange?.call(v);
    if (widget.onDelayedChange != null) {
      _delayed?.cancel();
      _delayed = Timer(const Duration(milliseconds: 500), () => widget.onDelayedChange?.call(_controller.text));
    }
  }

  void _replaceSelection(String insert) {
    final value = _controller.value;
    final sel = value.selection.isValid ? value.selection : TextSelection.collapsed(offset: value.text.length);
    final next = value.text.replaceRange(sel.start, sel.end, insert);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: sel.start + insert.length),
    );
    _changed(next);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (!_focusNode.hasFocus) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_pane != null) {
        setState(() => _pane = null);
      } else {
        _focusNode.nextFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab && !HardwareKeyboard.instance.isShiftPressed && !widget.readOnly) {
      _replaceSelection('  ');
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  (int, int) get _cursor {
    final text = _controller.text;
    final offset = _controller.selection.isValid ? _controller.selection.extentOffset.clamp(0, text.length) : 0;
    final before = text.substring(0, offset);
    final row = '\n'.allMatches(before).length;
    final column = offset - (before.lastIndexOf('\n') + 1);
    return (row, column);
  }

  void _goTo(CsCodeEditorAnnotation a) {
    final lines = _controller.text.split('\n');
    final row = a.row.clamp(0, lines.length - 1);
    var offset = 0;
    for (var i = 0; i < row; i++) {
      offset += lines[i].length + 1;
    }
    offset += a.column.clamp(0, lines[row].length);
    _controller.selection = TextSelection.collapsed(offset: offset);
    _focusNode.requestFocus();
  }

  List<CsCodeEditorAnnotation> _annotations() {
    final list = widget.annotations ?? widget.validator?.call(widget.value) ?? const <CsCodeEditorAnnotation>[];
    if (widget.onValidate != null && !listEquals(list, _lastReported)) {
      _lastReported = list;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValidate?.call(list);
      });
    }
    return list;
  }

  static String _languageName(String id) => switch (id.toLowerCase()) {
    'json' => 'JSON',
    'yaml' || 'yml' => 'YAML',
    'javascript' || 'js' => 'JavaScript',
    'typescript' || 'ts' => 'TypeScript',
    'python' || 'py' => 'Python',
    'sh' || 'bash' || 'shell' => 'Shell',
    'text' || 'plain_text' => 'Text',
    final other => other.isEmpty ? 'Text' : other[0].toUpperCase() + other.substring(1),
  };

  CsThemeData _editorTheme(CsThemeData base) => switch (_prefs.theme) {
    CsCodeEditorTheme.auto => base,
    CsCodeEditorTheme.light =>
      base.isDark
          ? base.copyWith(brightness: Brightness.light, colors: CsColorSchemes.light, shadows: CsShadows.light)
          : base,
    CsCodeEditorTheme.dark =>
      base.isDark
          ? base
          : base.copyWith(brightness: Brightness.dark, colors: CsColorSchemes.dark, shadows: CsShadows.dark),
  };

  void _measure(List<String> lines, TextStyle style, TextScaler scaler, double width, bool wrap) {
    final key = Object.hash(_controller.text, width, wrap, scaler, style);
    if (key == _metricsKey) return;
    _metricsKey = key;
    final painter = TextPainter(textDirection: TextDirection.ltr, textScaler: scaler);
    final heights = <double>[];
    var longest = 0.0;
    for (final line in lines) {
      painter.text = TextSpan(text: line.isEmpty ? ' ' : line, style: style);
      // RenderEditable keeps room for the caret at the end of each line.
      painter.layout(maxWidth: wrap ? math.max(1, width - 2.5) : double.infinity);
      heights.add(painter.height);
      longest = math.max(longest, painter.width);
    }
    painter.dispose();
    _lineHeights = heights;
    _longest = longest;
  }

  @override
  Widget build(BuildContext context) {
    final base = context.cs;
    final s = widget.i18nStrings;
    final height = widget.editorContentHeight ?? _height ?? (context.csIsNarrow ? 240.0 : 480.0);
    final c = base.colors;

    final annotations = widget.loading ? const <CsCodeEditorAnnotation>[] : _annotations();
    Widget body;
    if (widget.loading) {
      body = Container(
        height: height,
        color: c.backgroundCodeEditorLoading,
        alignment: Alignment.center,
        child: Semantics(
          liveRegion: true,
          child: CsStatusIndicator(type: CsStatusType.loading, text: s.loadingState),
        ),
      );
    } else {
      body = CsTheme(
        data: _editorTheme(base),
        child: Builder(builder: (context) => _editor(context, height, annotations)),
      );
    }

    return Semantics(
      container: true,
      label: widget.ariaLabel ?? s.editorGroupAriaLabel,
      explicitChildNodes: true,
      child: Container(
        foregroundDecoration: BoxDecoration(
          border: CsRing.inside(c.borderCodeEditorDefault, width: CsBorderWidth.field),
          borderRadius: BorderRadius.circular(CsBorderRadius.codeEditor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CsBorderRadius.codeEditor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              body,
              if (_pane != null && !widget.loading) _paneView(context, annotations),
              _statusBar(context, annotations, height),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editor(BuildContext context, double height, List<CsCodeEditorAnnotation> annotations) {
    final cs = context.cs;
    final c = cs.colors;
    final style = cs.code(scale: CsTypeScale.bodyM);
    final scaler = MediaQuery.textScalerOf(context);
    final wrap = _prefs.wrapLines;
    final text = _controller.text;
    final lines = text.split('\n');
    final (row, _) = _cursor;
    _controller
      ..language = widget.language
      ..colors = CsCodeEditorColors.of(cs);

    final errorRows = {
      for (final a in annotations)
        if (a.type == CsCodeEditorAnnotationType.error) a.row,
    };
    final warningRows = {
      for (final a in annotations)
        if (a.type != CsCodeEditorAnnotationType.error) a.row,
    };

    final digits = math.max(2, lines.length.toString().length);
    final numberPainter = TextPainter(
      text: TextSpan(text: '9' * digits, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    // Ace gutter: an annotation icon slot, then right-aligned numbers.
    const iconSlot = 12.0 + CsSpace.xxs;
    final gutterWidth = CsSpace.xs + iconSlot + numberPainter.width + CsSpace.s;
    numberPainter.dispose();
    const pad = CsSpace.xs;
    const vPad = CsSpace.xxs;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.maxWidth - gutterWidth;
        _measure(lines, style, scaler, viewport - pad * 2, wrap);
        final heights = _lineHeights;
        final contentWidth = wrap ? viewport : math.max(viewport, _longest + pad * 2 + 4);
        final contentHeight = heights.fold<double>(0, (a, b) => a + b);
        final activeTop = heights.take(row.clamp(0, heights.length)).fold<double>(0, (a, b) => a + b);
        final activeHeight = row < heights.length ? heights[row] : 0.0;
        final filler = math.max(0.0, height - vPad * 2 - contentHeight);

        final gutter = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < lines.length; i++)
              Container(
                height: heights[i],
                color: errorRows.contains(i)
                    ? c.backgroundCodeEditorGutterActiveLineError
                    : (i == row && _focused ? c.backgroundCodeEditorGutterActiveLineDefault : null),
                padding: const EdgeInsetsDirectional.only(start: CsSpace.xs, end: CsSpace.s),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: iconSlot,
                      height: style.fontSize! * (style.height ?? 1),
                      child: errorRows.contains(i) || warningRows.contains(i)
                          ? Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: CsIcon(
                                errorRows.contains(i) ? CsIcons.statusNegative : CsIcons.statusWarning,
                                size: CsIconSize.xSmall,
                                // Error rows have a red gutter, so their icon takes the gutter text color.
                                variant: errorRows.contains(i) ? CsIconVariant.normal : CsIconVariant.warning,
                                dangerouslySetColor: errorRows.contains(i) ? c.textCodeEditorGutterActiveLine : null,
                              ),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        '${i + 1}',
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        style: style.copyWith(
                          color: (i == row && _focused) || errorRows.contains(i)
                              ? c.textCodeEditorGutterActiveLine
                              : c.textCodeEditorGutterDefault,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );

        final activeLine = cs.isDark
            ? c.borderCodeEditorAceActiveLineDarkTheme
            : c.borderCodeEditorAceActiveLineLightTheme;
        Widget textArea = Stack(
          children: [
            if (_focused)
              Positioned(
                top: activeTop,
                left: 0,
                right: 0,
                height: activeHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.symmetric(horizontal: BorderSide(color: activeLine)),
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: pad),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: CsEditable(
                      controller: _controller,
                      focusNode: _focusNode,
                      mono: true,
                      readOnly: widget.readOnly,
                      autocorrect: false,
                      enableSuggestions: false,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      semanticLabel: widget.ariaLabel ?? widget.i18nStrings.editorGroupAriaLabel,
                      onChanged: _changed,
                    ),
                  ),
                ),
                if (filler > 0)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
                      _focusNode.requestFocus();
                    },
                    child: SizedBox(height: filler),
                  ),
              ],
            ),
          ],
        );
        if (!wrap) {
          textArea = SingleChildScrollView(
            controller: _hScroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: contentWidth, child: textArea),
          );
        }

        return Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: c.backgroundContainerContent)),
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  width: gutterWidth,
                  child: ColoredBox(color: c.backgroundCodeEditorGutterDefault),
                ),
                SingleChildScrollView(
                  controller: _vScroll,
                  padding: const EdgeInsets.symmetric(vertical: vPad),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.ltr,
                    children: [
                      SizedBox(
                        width: gutterWidth,
                        child: ExcludeSemantics(child: gutter),
                      ),
                      Expanded(child: textArea),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _paneView(BuildContext context, List<CsCodeEditorAnnotation> all) {
    final cs = context.cs;
    final c = cs.colors;
    final items = [
      for (final a in all)
        if ((a.type == CsCodeEditorAnnotationType.error) == (_pane == CsCodeEditorAnnotationType.error)) a,
    ];
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: c.backgroundCodeEditorStatusBar,
        border: Border(
          top: BorderSide(color: c.borderCodeEditorDefault, width: CsBorderLine.itemWidth / 2),
        ),
      ),
      child: Stack(
        children: [
          ListView(
            shrinkWrap: true,
            padding: const EdgeInsetsDirectional.only(top: CsSpace.s, bottom: CsSpace.s, start: CsSpace.xs, end: 40),
            children: [
              for (final a in items)
                CsPressable(
                  onPress: () => _goTo(a),
                  scaleOnPress: false,
                  semanticLabel: '${widget.i18nStrings.position(a.row + 1, a.column + 1)}: ${a.text}',
                  excludeChildSemantics: true,
                  borderRadius: BorderRadius.circular(CsBorderRadius.item),
                  builder: (context, state) => Container(
                    decoration: BoxDecoration(
                      color: state.active || state.focused ? c.backgroundCodeEditorPaneItemHover : null,
                      borderRadius: BorderRadius.circular(CsBorderRadius.item),
                      border: state.active || state.focused
                          ? CsRing.inside(c.borderCodeEditorPaneItemHover, width: CsBorderLine.itemWidth)
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: CsSpace.s, vertical: CsSpace.xxs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: CsSpace.s,
                      children: [
                        Text(widget.i18nStrings.position(a.row + 1, a.column + 1), style: cs.body),
                        Expanded(child: Text(a.text, style: cs.body)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          PositionedDirectional(
            top: 0,
            end: CsSpace.s / 2,
            child: CsButton(
              icon: CsIcons.close,
              variant: CsButtonVariant.icon,
              semanticLabel: widget.i18nStrings.paneCloseButtonAriaLabel,
              onPress: () {
                final tab = _pane == CsCodeEditorAnnotationType.error ? _errorsTab : _warningsTab;
                setState(() => _pane = null);
                tab.requestFocus();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBar(BuildContext context, List<CsCodeEditorAnnotation> annotations, double height) {
    final cs = context.cs;
    final c = cs.colors;
    final s = widget.i18nStrings;
    final errors = annotations.where((a) => a.type == CsCodeEditorAnnotationType.error).length;
    final warnings = annotations.length - errors;
    final (row, column) = _cursor;
    final textStyle = cs.body;
    final cellPadding = EdgeInsets.symmetric(horizontal: CsSpace.s, vertical: cs.space.scaledXs);

    return LayoutBuilder(
      builder: (context, constraints) {
        // `@container (max-width: 500px)`: tabs show their count only.
        final compact = constraints.maxWidth <= 500;
        final left = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: cellPadding,
              child: Text(widget.languageLabel ?? _languageName(widget.language), style: textStyle),
            ),
            if (!widget.loading)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: cellPadding,
                  child: Text(s.position(row + 1, column + 1), style: textStyle),
                ),
              ),
            _TabButton(
              label: s.errorsTab,
              count: errors,
              compact: compact,
              error: true,
              active: _pane == CsCodeEditorAnnotationType.error,
              focusNode: _errorsTab,
              onPress: () => setState(
                () => _pane = _pane == CsCodeEditorAnnotationType.error ? null : CsCodeEditorAnnotationType.error,
              ),
            ),
            Container(width: CsBorderLine.codeEditorStatusDividerWidth, height: 20, color: c.borderTabsDivider),
            _TabButton(
              label: s.warningsTab,
              count: warnings,
              compact: compact,
              error: false,
              active: _pane == CsCodeEditorAnnotationType.warning,
              focusNode: _warningsTab,
              onPress: () => setState(
                () => _pane = _pane == CsCodeEditorAnnotationType.warning ? null : CsCodeEditorAnnotationType.warning,
              ),
            ),
          ],
        );
        final right = <Widget>[
          if (widget.onPreferencesChange != null)
            CsDropdown(
              open: _prefsOpen,
              matchTriggerWidth: false,
              align: CsAlign.end,
              onDismiss: () => setState(() => _prefsOpen = false),
              contentBuilder: (context, inSheet) => _preferencesMenu(context, inSheet),
              child: CsButton(
                icon: CsIcons.settings,
                variant: CsButtonVariant.icon,
                semanticLabel: s.preferencesButtonAriaLabel,
                expanded: _prefsOpen,
                onPress: () => setState(() => _prefsOpen = !_prefsOpen),
              ),
            ),
          if (widget.editorContentHeight == null || widget.onEditorContentResize != null)
            _ResizeHandle(
              label: s.resizeHandleAriaLabel,
              hint: s.resizeHandleTooltipText,
              onResize: (dy) {
                final next = math.max(60.0, height + dy);
                if (widget.onEditorContentResize != null) {
                  widget.onEditorContentResize!(next);
                } else {
                  setState(() => _height = next);
                }
              },
            ),
        ];
        return Semantics(
          container: true,
          label: s.statusBarGroupAriaLabel,
          explicitChildNodes: true,
          child: Container(
            decoration: BoxDecoration(
              color: c.backgroundCodeEditorStatusBar,
              border: Border(
                top: BorderSide(color: c.borderCodeEditorDefault, width: CsBorderWidth.field),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsetsDirectional.only(start: CsSpace.l - CsSpace.s),
                      decoration: right.isEmpty
                          ? null
                          : BoxDecoration(
                              border: BorderDirectional(
                                end: BorderSide(color: c.borderCodeEditorDefault, width: CsBorderWidth.field),
                              ),
                            ),
                      alignment: AlignmentDirectional.centerStart,
                      child: left,
                    ),
                  ),
                  if (right.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: CsSpace.xxs),
                      child: Row(mainAxisSize: MainAxisSize.min, children: right),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _preferencesMenu(BuildContext context, bool inSheet) {
    final s = widget.i18nStrings;
    void pick(CsCodeEditorPreferences p) {
      widget.onPreferencesChange?.call(p);
      setState(() => _prefsOpen = false);
      if (inSheet) CsSheetScope.closeFrom(context);
    }

    CsMenuRow themeRow(CsCodeEditorTheme theme, String label) => CsMenuRow(
      label: label,
      inset: true,
      checked: _prefs.theme == theme,
      inMutuallyExclusiveGroup: true,
      trailing: _prefs.theme == theme ? const CsIcon(CsIcons.check) : null,
      onPress: () => pick(_prefs.copyWith(theme: theme)),
    );

    return CsMenuPanel(
      children: [
        CsMenuRow(
          label: s.preferencesWrapLines,
          checked: _prefs.wrapLines,
          leading: CsIcon(
            _prefs.wrapLines ? CsIcons.check : CsIcons.dot,
            variant: _prefs.wrapLines ? CsIconVariant.normal : CsIconVariant.subtle,
          ),
          onPress: () => pick(_prefs.copyWith(wrapLines: !_prefs.wrapLines)),
        ),
        const CsMenuSeparator(),
        themeRow(CsCodeEditorTheme.auto, s.preferencesThemeAuto),
        themeRow(CsCodeEditorTheme.light, s.preferencesThemeLight),
        themeRow(CsCodeEditorTheme.dark, s.preferencesThemeDark),
      ],
    );
  }
}

/// The errors or warnings tab of the status bar (`.tab-button`).
class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.count,
    required this.compact,
    required this.error,
    required this.active,
    required this.focusNode,
    required this.onPress,
  });

  final String label;
  final int count;
  final bool compact;
  final bool error;
  final bool active;
  final FocusNode focusNode;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final disabled = count == 0;
    final status = error ? c.textStatusError : c.textStatusWarning;
    return CsPressable(
      onPress: disabled ? null : onPress,
      disabled: disabled,
      focusNode: focusNode,
      scaleOnPress: false,
      selected: active,
      semanticLabel: '$label: $count',
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(CsBorderRadius.item),
      builder: (context, state) {
        final hovered = state.active && !disabled;
        final fg = disabled ? c.textCodeEditorStatusBarDisabled : (hovered ? c.textCodeEditorTabButtonError : status);
        final style = cs
            .text(CsTypeScale.bodyM, weight: disabled ? CsTypography.normal : CsTypography.bold)
            .copyWith(color: fg);
        return Container(
          color: hovered ? status : null,
          padding: EdgeInsets.symmetric(horizontal: CsSpace.s, vertical: cs.space.scaledXs),
          foregroundDecoration: active && !disabled
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: status, width: CsBorderLine.activeWidth),
                  ),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: CsSpace.xxs,
            children: [
              CsIcon(error ? CsIcons.statusNegative : CsIcons.statusWarning, dangerouslySetColor: fg),
              Text(compact ? '$count' : '$label: $count', style: style),
            ],
          ),
        );
      },
    );
  }
}

/// Drag (or arrow keys while focused) to change the editor height.
class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.label, required this.hint, required this.onResize});

  final String label;
  final String hint;
  final ValueChanged<double> onResize;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => onResize(-20),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => onResize(20),
      },
      child: GestureDetector(
        onVerticalDragUpdate: (d) => onResize(d.delta.dy),
        child: CsPressable(
          onPress: () {},
          scaleOnPress: false,
          semanticLabel: label,
          semanticHint: hint,
          mouseCursor: SystemMouseCursors.resizeUpDown,
          borderRadius: BorderRadius.circular(CsBorderRadius.item),
          builder: (context, state) => Padding(
            padding: const EdgeInsets.all(CsSpace.xs),
            child: CsIcon(CsIcons.resizeArea, variant: state.active ? CsIconVariant.normal : CsIconVariant.subtle),
          ),
        ),
      ),
    );
  }
}
