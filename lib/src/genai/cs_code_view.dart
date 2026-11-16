import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_tooltip.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_code_view_highlighter.dart';
import 'cs_gen_ai_gradients.dart';

/// Copy for [CsCodeView] (Cloudscape `CodeViewProps.I18nStrings`).
@immutable
class CsCodeViewI18nStrings {
  const CsCodeViewI18nStrings({this.lineNumberLabel, this.codeLabel});

  /// Label of the line number column. With [codeLabel], line numbers are
  /// read by screen readers ("Line 3: ...") instead of being hidden.
  final String? lineNumberLabel;

  /// Label of the code column.
  final String? codeLabel;
}

/// Cloudscape's `CodeView`: a read-only, monospaced code snippet with
/// optional line numbers, line wrapping, syntax highlighting and an actions
/// slot (usually [CsCodeViewCopyButton]).
///
/// Without [wrapLines] long lines scroll horizontally, and the line numbers
/// stay put while they scroll (`position: sticky` in Cloudscape).
///
/// ```dart
/// CsCodeView(
///   content: '{\n  "Bucket": "example-bucket"\n}',
///   lineNumbers: true,
///   highlight: CsCodeViewHighlighter.of('json'),
///   actions: const CsCodeViewCopyButton(content: '{\n  "Bucket": "example-bucket"\n}'),
/// )
/// ```
class CsCodeView extends StatelessWidget {
  const CsCodeView({
    super.key,
    required this.content,
    this.lineNumbers = false,
    this.wrapLines = false,
    this.highlight,
    this.actions,
    this.ariaLabel,
    this.i18nStrings,
  });

  /// The code to show.
  final String content;

  /// Shows a line number column.
  final bool lineNumbers;

  /// Wraps long lines instead of scrolling horizontally.
  final bool wrapLines;

  /// Splits [content] into colored tokens. Use [CsCodeViewHighlighter.of] with
  /// `json`, `javascript`, `typescript`, `python`, `yaml`, `sh` or `html`, or
  /// pass your own function. Null shows plain text.
  final CsCodeViewHighlight? highlight;

  /// A slot at the top end corner for actions such as copy or download.
  final Widget? actions;

  /// Accessible name of the snippet. Makes the snippet a labelled region.
  final String? ariaLabel;
  final CsCodeViewI18nStrings? i18nStrings;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final colors = CsCodeViewColors.of(cs);
    final base = cs.code(scale: CsTypeScale.bodyM);
    final lineHeight = (base.height ?? 1) * (base.fontSize ?? CsFontTokens.fontSizeBodyM);
    final strut = StrutStyle.fromTextStyle(base, forceStrutHeight: true);

    final tokens = highlight?.call(content) ?? [CsCodeViewToken(CsCodeViewTokenType.plain, content)];
    final lines = CsCodeViewHighlighter.splitLines(tokens);
    final accessibleNumbers = lineNumbers && i18nStrings?.lineNumberLabel != null && i18nStrings?.codeLabel != null;

    Widget codeLine(int i) {
      final spans = [
        for (final t in lines[i])
          TextSpan(
            text: t.text,
            style: TextStyle(color: colors.of(t.type)),
          ),
      ];
      final text = Text.rich(
        TextSpan(children: spans.isEmpty ? [const TextSpan(text: ' ')] : spans),
        style: base.copyWith(color: colors.plain),
        strutStyle: strut,
        softWrap: wrapLines,
        semanticsLabel: accessibleNumbers ? '${i18nStrings!.codeLabel}: ${lines[i].map((t) => t.text).join()}' : null,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: CsSpace.staticXs),
        child: text,
      );
    }

    Widget lineNumber(int i) {
      final n = Text(
        '${i + 1}',
        style: base.copyWith(color: c.textStatusInactive),
        strutStyle: strut,
        textAlign: TextAlign.start,
        semanticsLabel: accessibleNumbers ? '${i18nStrings!.lineNumberLabel} ${i + 1}' : null,
      );
      return accessibleNumbers ? n : ExcludeSemantics(child: n);
    }

    final numberCell = BoxDecoration(
      color: c.backgroundCodeView,
      border: BorderDirectional(end: BorderSide(color: c.borderDividerDefault)),
    );
    const numberPadding = EdgeInsets.symmetric(horizontal: CsSpace.staticXs);
    final hasActions = actions != null;
    // `.code-table-with-actions`: room for the actions at the end (two
    // 40px icon slots, or one 32px slot when lines wrap).
    final endPadding = hasActions ? (wrapLines ? CsSpace.staticXxl : 2 * CsSpace.staticXxxl) : 0.0;
    final minHeight = hasActions ? 2 * cs.space.scaledXs + cs.space.scaledXxl : 0.0;

    Widget body;
    if (wrapLines) {
      body = Table(
        columnWidths: {if (lineNumbers) 0: const IntrinsicColumnWidth(), lineNumbers ? 1 : 0: const FlexColumnWidth()},
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          for (var i = 0; i < lines.length; i++)
            TableRow(
              children: [
                if (lineNumbers)
                  // The decorated cell fills the row so the divider runs through wrapped lines.
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.fill,
                    child: DecoratedBox(
                      decoration: numberCell,
                      child: Padding(padding: numberPadding, child: lineNumber(i)),
                    ),
                  ),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: endPadding),
                  child: codeLine(i),
                ),
              ],
            ),
        ],
      );
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: CsSpace.staticXs),
        child: body,
      );
    } else {
      final code = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: CsSpace.staticXs),
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: endPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (var i = 0; i < lines.length; i++) SizedBox(height: lineHeight, child: codeLine(i))],
          ),
        ),
      );
      body = lineNumbers
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: numberCell,
                    child: Padding(
                      padding: numberPadding.add(const EdgeInsets.symmetric(vertical: CsSpace.staticXs)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < lines.length; i++) SizedBox(height: lineHeight, child: lineNumber(i)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: code),
                ],
              ),
            )
          : code;
    }

    body = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight, minWidth: double.infinity),
      child: body,
    );

    Widget result = DecoratedBox(
      decoration: BoxDecoration(
        color: c.backgroundCodeView,
        borderRadius: const BorderRadius.all(Radius.circular(CsBorderRadius.tiles)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(CsBorderRadius.tiles)),
        child: hasActions
            ? Stack(
                children: [
                  body,
                  PositionedDirectional(top: cs.space.scaledXs, end: cs.space.scaledXs, child: actions!),
                ],
              )
            : body,
      ),
    );

    // Code reads left to right in every locale (`dir="ltr"`).
    result = Directionality(textDirection: TextDirection.ltr, child: result);
    if (ariaLabel != null) {
      result = Semantics(container: true, explicitChildNodes: true, label: ariaLabel, child: result);
    }
    return result;
  }
}

/// Copy for [CsCodeViewCopyButton].
@immutable
class CsCodeViewCopyButtonI18nStrings {
  const CsCodeViewCopyButtonI18nStrings({this.copyButtonAriaLabel, this.copySuccessText, this.copyErrorText});

  /// Accessible name of the button. Defaults to `CsStrings.copy` ("Copy").
  final String? copyButtonAriaLabel;

  /// Shown and announced after copying. Defaults to `CsStrings.copied`.
  final String? copySuccessText;

  /// Shown and announced when the clipboard refuses the text. Defaults to
  /// `CsStrings.copyFailed`.
  final String? copyErrorText;
}

/// An icon button that copies [content] to the clipboard and confirms with
/// a short tooltip. Built for [CsCodeView.actions], the way Cloudscape pairs
/// the code view with `CopyToClipboard` (`variant="icon"`).
///
/// ```dart
/// CsCodeView(content: script, actions: CsCodeViewCopyButton(content: script))
/// ```
class CsCodeViewCopyButton extends StatefulWidget {
  const CsCodeViewCopyButton({
    super.key,
    required this.content,
    this.i18nStrings = const CsCodeViewCopyButtonI18nStrings(),
    this.onCopy,
  });

  /// The text that goes to the clipboard.
  final String content;
  final CsCodeViewCopyButtonI18nStrings i18nStrings;

  /// Called after a copy attempt with whether it succeeded.
  final ValueChanged<bool>? onCopy;

  /// How long the confirmation stays up.
  static const Duration messageDuration = Duration(milliseconds: 1500);

  @override
  State<CsCodeViewCopyButton> createState() => _CsCodeViewCopyButtonState();
}

class _CsCodeViewCopyButtonState extends State<CsCodeViewCopyButton> {
  String? _message;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final strings = context.csStrings;
    var ok = true;
    try {
      await Clipboard.setData(ClipboardData(text: widget.content));
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    final message = ok
        ? (widget.i18nStrings.copySuccessText ?? strings.copied)
        : (widget.i18nStrings.copyErrorText ?? strings.copyFailed);
    setState(() => _message = message);
    csGenAiAnnounce(context, message);
    widget.onCopy?.call(ok);
    _timer?.cancel();
    _timer = Timer(CsCodeViewCopyButton.messageDuration, () {
      if (mounted) setState(() => _message = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final button = CsButton(
      variant: CsButtonVariant.icon,
      icon: CsIcons.copy,
      semanticLabel: widget.i18nStrings.copyButtonAriaLabel ?? context.csStrings.copy,
      onPress: _copy,
    );
    return CsTooltip(content: _message ?? '', open: _message != null, child: button);
  }
}
