import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../forms/cs_form_field.dart';
import '../icons/cs_icons.g.dart';
import '../theme/theme.dart';
import 'cs_editor_utils.dart';

/// Builds one piece of a row (a control, an error message) from the row's
/// item and index (Cloudscape `FieldRenderable`).
typedef CsAttributeEditorRenderable<T, R> = R Function(T item, int itemIndex);

/// One column of an attribute editor row (Cloudscape
/// `AttributeEditorProps.FieldDefinition`).
///
/// ```dart
/// CsAttributeEditorField<Tag>(
///   label: 'Key',
///   control: (tag, i) => CsInput(value: tag.key, onChange: (v) => setKey(i, v)),
///   errorText: (tag, i) => tag.key.isEmpty ? 'Enter a key.' : null,
/// )
/// ```
@immutable
class CsAttributeEditorField<T> {
  const CsAttributeEditorField({
    this.label,
    this.labelWidget,
    this.description,
    this.info,
    this.control,
    this.errorText,
    this.warningText,
    this.constraintText,
  });

  /// Field label. Shown above the first row only when the row fits on one
  /// line; every row keeps it as its accessible name.
  final String? label;

  /// Rich label content in place of [label].
  final Widget? labelWidget;
  final String? description;

  /// An info link after the label.
  final Widget? info;

  /// The control for this column in a row.
  final CsAttributeEditorRenderable<T, Widget>? control;

  /// A validation error for the row. A non-null value marks the field
  /// invalid; pass `invalid: true` to the control as well.
  final CsAttributeEditorRenderable<T, String?>? errorText;

  /// A validation warning for the row, shown when there is no error.
  final CsAttributeEditorRenderable<T, String?>? warningText;

  /// Rules for the value, shown under the control.
  final CsAttributeEditorRenderable<T, String?>? constraintText;
}

/// Placement of the remove button in a [CsAttributeEditorGridLayout].
@immutable
class CsAttributeEditorRemoveButtonLayout {
  const CsAttributeEditorRemoveButtonLayout({this.ownRow = false, this.width, this.autoWidth = false});

  /// Put the remove button on a row of its own, aligned to the end.
  final bool ownRow;

  /// Relative width of the remove button column, in the same units as the
  /// layout's rows. Defaults to 1.
  final int? width;

  /// Size the remove button column to the button (Cloudscape `width: 'auto'`).
  final bool autoWidth;
}

/// A row layout for one container width (Cloudscape
/// `AttributeEditorProps.GridLayout`).
///
/// [rows] lists relative widths: `[[1, 1, 1]]` is one row of three equal
/// fields; `[[1, 2], [1, 1, 1]]` splits five fields over two lines. Without a
/// [breakpoint] the entry is the fallback for the narrowest containers.
@immutable
class CsAttributeEditorGridLayout {
  const CsAttributeEditorGridLayout({this.breakpoint, required this.rows, this.removeButton});

  /// The smallest container breakpoint this layout applies at.
  final CsBreakpoint? breakpoint;
  final List<List<int>> rows;
  final CsAttributeEditorRemoveButtonLayout? removeButton;

  /// The remove button shares the line with the fields.
  bool get removeButtonOnSameLine => rows.length == 1 && !(removeButton?.ownRow ?? false);

  int get _units => rows.fold(0, (m, r) => r.fold<int>(0, (s, c) => s + c) > m ? r.fold<int>(0, (s, c) => s + c) : m);

  int get _fieldCount => rows.fold(0, (n, r) => n + r.length);

  /// Cloudscape's default layouts for one to six fields (`grid-defaults.ts`):
  /// one line on wide containers, wrapping onto more lines and finally
  /// stacking every field on narrow ones.
  static List<CsAttributeEditorGridLayout>? defaultsFor(int fields) => switch (fields) {
    1 => const [
      CsAttributeEditorGridLayout(
        breakpoint: CsBreakpoint.xxs,
        rows: [
          [3],
        ],
      ),
      CsAttributeEditorGridLayout(
        rows: [
          [1],
        ],
        removeButton: CsAttributeEditorRemoveButtonLayout(ownRow: true),
      ),
    ],
    2 => const [
      CsAttributeEditorGridLayout(
        breakpoint: CsBreakpoint.xs,
        rows: [
          [3, 3],
        ],
        removeButton: CsAttributeEditorRemoveButtonLayout(width: 2),
      ),
      CsAttributeEditorGridLayout(
        breakpoint: CsBreakpoint.xxs,
        rows: [
          [1, 1],
        ],
        removeButton: CsAttributeEditorRemoveButtonLayout(ownRow: true),
      ),
      CsAttributeEditorGridLayout(
        rows: [
          [1],
          [1],
        ],
      ),
    ],
    3 => const [
      CsAttributeEditorGridLayout(
        breakpoint: CsBreakpoint.xs,
        rows: [
          [3, 3, 3],
        ],
        removeButton: CsAttributeEditorRemoveButtonLayout(width: 3),
      ),
      CsAttributeEditorGridLayout(
        breakpoint: CsBreakpoint.xxs,
        rows: [
          [1, 1],
          [1],
        ],
        removeButton: CsAttributeEditorRemoveButtonLayout(ownRow: true),
      ),
      CsAttributeEditorGridLayout(
        rows: [
          [1],
          [1],
          [1],
        ],
      ),
    ],
    4 => const [
      CsAttributeEditorGridLayout(
        breakpoint: CsBreakpoint.xs,
        rows: [
          [3, 3, 3, 3],
        ],
        removeButton: CsAttributeEditorRemoveButtonLayout(width: 4),
      ),
      CsAttributeEditorGridLayout(
        breakpoint: CsBreakpoint.xxs,
        rows: [
          [1, 1],
          [1, 1],
        ],
      ),
      CsAttributeEditorGridLayout(
        rows: [
          [1],
          [1],
          [1],
          [1],
        ],
      ),
    ],
    5 => const [
      CsAttributeEditorGridLayout(
        breakpoint: CsBreakpoint.s,
        rows: [
          [3, 3, 3, 3, 3],
        ],
        removeButton: CsAttributeEditorRemoveButtonLayout(width: 5),
      ),
      CsAttributeEditorGridLayout(
        breakpoint: CsBreakpoint.xs,
        rows: [
          [1, 1, 1],
          [1, 1],
        ],
      ),
      CsAttributeEditorGridLayout(
        breakpoint: CsBreakpoint.xxs,
        rows: [
          [1, 1],
          [1, 1],
          [1],
        ],
      ),
      CsAttributeEditorGridLayout(
        rows: [
          [1],
          [1],
          [1],
          [1],
          [1],
        ],
      ),
    ],
    6 => const [
      CsAttributeEditorGridLayout(
        breakpoint: CsBreakpoint.s,
        rows: [
          [3, 3, 3, 3, 3, 3],
        ],
        removeButton: CsAttributeEditorRemoveButtonLayout(width: 6),
      ),
      CsAttributeEditorGridLayout(
        breakpoint: CsBreakpoint.xs,
        rows: [
          [1, 1, 1],
          [1, 1, 1],
        ],
      ),
      CsAttributeEditorGridLayout(
        breakpoint: CsBreakpoint.xxs,
        rows: [
          [1, 1],
          [1, 1],
          [1, 1],
        ],
      ),
      CsAttributeEditorGridLayout(
        rows: [
          [1],
          [1],
          [1],
          [1],
          [1],
          [1],
        ],
      ),
    ],
    _ => null,
  };

  /// Picks the layout for a container [width] from [layouts] (Cloudscape
  /// `matchBreakpointMapping` over container breakpoints).
  static CsAttributeEditorGridLayout? resolve(List<CsAttributeEditorGridLayout> layouts, double width) {
    final map = {for (final l in layouts) l.breakpoint ?? CsBreakpoint.base: l};
    return CsBreakpoint.match(map, CsBreakpoint.of(width));
  }
}

/// Style of the add button (Cloudscape `addButtonVariant`).
enum CsAttributeEditorAddButtonVariant {
  /// A normal button.
  normal,

  /// An inline link with an add icon, for editors nested in expandable
  /// sections.
  inlineLink,
}

/// What [CsAttributeEditor.customRowActions] receives for each row
/// (Cloudscape `RowActionsProps`).
@immutable
class CsAttributeEditorRowActions<T> {
  const CsAttributeEditorRowActions({
    required this.item,
    required this.itemIndex,
    required this.focusNode,
    required this.breakpoint,
    required this.ownRow,
  });

  final T item;
  final int itemIndex;

  /// Give this to the custom trigger so `focusRemoveButton` can focus it.
  final FocusNode focusNode;

  /// The container breakpoint the editor is laid out at.
  final CsBreakpoint breakpoint;

  /// Whether the actions sit on their own line.
  final bool ownRow;
}

/// Copy for [CsAttributeEditor] (Cloudscape `AttributeEditorProps.I18nStrings`).
@immutable
class CsAttributeEditorI18nStrings {
  const CsAttributeEditorI18nStrings({
    this.errorIconAriaLabel,
    this.warningIconAriaLabel,
    this.itemRemovedAriaLive = 'Item removed',
    this.removeButtonText = 'Remove',
  });

  final String? errorIconAriaLabel;
  final String? warningIconAriaLabel;

  /// Announced when the number of items goes down.
  final String itemRemovedAriaLive;

  /// Default text of the remove button.
  final String removeButtonText;
}

/// Cloudscape's `AttributeEditor`: a list of rows of form fields with
/// add and remove buttons, for key-value pairs, environment variables,
/// headers, tags and other repeated attributes.
///
/// The editor is controlled: it renders [items] through [definition] and
/// reports [onAddButtonClick] and [onRemoveButtonClick]; the app updates
/// the list.
///
/// ```dart
/// CsAttributeEditor<EnvVar>(
///   items: vars,
///   addButtonText: 'Add variable',
///   onAddButtonClick: () => setState(() => vars.add(EnvVar('', ''))),
///   onRemoveButtonClick: (i) => setState(() => vars.removeAt(i)),
///   definition: [
///     CsAttributeEditorField(label: 'Key', control: (v, i) => CsInput(value: v.key, onChange: ...)),
///     CsAttributeEditorField(label: 'Value', control: (v, i) => CsInput(value: v.value, onChange: ...)),
///   ],
/// )
/// ```
///
/// Rows follow [gridLayout] by container width (Cloudscape container
/// breakpoints). The defaults put up to six fields on one line in wide
/// containers and stack them in narrow ones, where each row ends with the
/// remove button on its own line and a divider. Use a [GlobalKey] of
/// [CsAttributeEditorState] for `focusAddButton` and `focusRemoveButton`.
class CsAttributeEditor<T> extends StatefulWidget {
  const CsAttributeEditor({
    super.key,
    required this.items,
    required this.definition,
    required this.addButtonText,
    this.onAddButtonClick,
    this.onRemoveButtonClick,
    this.removeButtonText,
    this.removeButtonAriaLabel,
    this.isItemRemovable,
    this.disableAddButton = false,
    this.hideAddButton = false,
    this.additionalActions,
    this.addButtonVariant = CsAttributeEditorAddButtonVariant.normal,
    this.empty,
    this.additionalInfo,
    this.itemLimit,
    this.gridLayout,
    this.customRowActions,
    this.i18nStrings = const CsAttributeEditorI18nStrings(),
  });

  /// The data source, one row per item.
  final List<T> items;

  /// The columns of each row. More than six need a [gridLayout].
  final List<CsAttributeEditorField<T>> definition;
  final String addButtonText;
  final VoidCallback? onAddButtonClick;

  /// Called with the index of the row whose remove button was pressed.
  final ValueChanged<int>? onRemoveButtonClick;

  /// Remove button text. Defaults to [CsAttributeEditorI18nStrings.removeButtonText].
  final String? removeButtonText;

  /// Accessible name of a row's remove button ("Remove MY_VAR").
  final String Function(T item)? removeButtonAriaLabel;

  /// Return false to hide the remove button for an item. All items are
  /// removable by default.
  final bool Function(T item)? isItemRemovable;
  final bool disableAddButton;
  final bool hideAddButton;

  /// Actions next to the add button (or in its place when hidden).
  final Widget? additionalActions;
  final CsAttributeEditorAddButtonVariant addButtonVariant;

  /// Shown when [items] is empty ("No variables.").
  final Widget? empty;

  /// Shown under the add button: a limit message or a hint. Announced when
  /// it changes.
  final Widget? additionalInfo;

  /// Disables the add button once [items] reaches this length. A
  /// convenience on top of [disableAddButton]; describe the limit in
  /// [additionalInfo].
  final int? itemLimit;

  /// Layouts by container breakpoint. Defaults to
  /// [CsAttributeEditorGridLayout.defaultsFor] the number of fields.
  final List<CsAttributeEditorGridLayout>? gridLayout;

  /// Replaces each row's remove button (a button dropdown with more row
  /// actions). Ignores [removeButtonText], [removeButtonAriaLabel] and
  /// [onRemoveButtonClick].
  final Widget Function(BuildContext context, CsAttributeEditorRowActions<T> row)? customRowActions;
  final CsAttributeEditorI18nStrings i18nStrings;

  @override
  State<CsAttributeEditor<T>> createState() => CsAttributeEditorState<T>();
}

/// State of [CsAttributeEditor], reachable through a [GlobalKey] for the
/// focus methods Cloudscape exposes on its ref.
class CsAttributeEditorState<T> extends State<CsAttributeEditor<T>> {
  final FocusNode _addNode = FocusNode(debugLabel: 'CsAttributeEditor add');
  final List<FocusNode> _removeNodes = [];

  /// Focuses the remove button (or custom row action) of row [itemIndex].
  void focusRemoveButton(int itemIndex) {
    if (itemIndex >= 0 && itemIndex < _removeNodes.length) _removeNodes[itemIndex].requestFocus();
  }

  /// Focuses the add button, for example after the last row was removed.
  void focusAddButton() => _addNode.requestFocus();

  FocusNode _removeNode(int i) {
    while (_removeNodes.length <= i) {
      _removeNodes.add(FocusNode(debugLabel: 'CsAttributeEditor remove ${_removeNodes.length}'));
    }
    return _removeNodes[i];
  }

  @override
  void didUpdateWidget(CsAttributeEditor<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length < oldWidget.items.length) {
      csEditorsAnnounce(context, widget.i18nStrings.itemRemovedAriaLive);
    }
    while (_removeNodes.length > widget.items.length) {
      _removeNodes.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    _addNode.dispose();
    for (final n in _removeNodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final layouts =
        widget.gridLayout ??
        CsAttributeEditorGridLayout.defaultsFor(widget.definition.length) ??
        [
          CsAttributeEditorGridLayout(
            rows: [
              for (var i = 0; i < widget.definition.length; i++) [1],
            ],
          ),
        ];
    final gap = cs.space.scaledS;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
        final breakpoint = CsBreakpoint.of(width);
        var layout = CsAttributeEditorGridLayout.resolve(layouts, width);
        if (layout == null || layout._fieldCount != widget.definition.length) {
          layout = CsAttributeEditorGridLayout(
            rows: [
              for (var i = 0; i < widget.definition.length; i++) [1],
            ],
          );
        }
        final children = <Widget>[];
        if (widget.items.isEmpty && widget.empty != null) {
          children.add(
            DefaultTextStyle.merge(
              style: cs.text(CsTypeScale.bodyM, color: CsColor.textEmpty),
              child: widget.empty!,
            ),
          );
        }
        for (var i = 0; i < widget.items.length; i++) {
          children.add(_row(context, layout, breakpoint, i, gap));
        }
        children.add(_addRow(context));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: gap,
          children: children,
        );
      },
    );
  }

  Widget _row(
    BuildContext context,
    CsAttributeEditorGridLayout layout,
    CsBreakpoint breakpoint,
    int index,
    double gap,
  ) {
    final cs = context.cs;
    final item = widget.items[index];
    final sameLine = layout.removeButtonOnSameLine;
    final units = layout._units;

    Widget field(int defIndex) {
      final def = widget.definition[defIndex];
      return CsFormField(
        label: def.label,
        labelWidget: def.labelWidget,
        info: def.info,
        description: def.description,
        constraintText: def.constraintText?.call(item, index),
        errorText: def.errorText?.call(item, index),
        warningText: def.warningText?.call(item, index),
        stretch: true,
        labelHidden: index != 0 && sameLine,
        errorIconAriaLabel: widget.i18nStrings.errorIconAriaLabel,
        warningIconAriaLabel: widget.i18nStrings.warningIconAriaLabel,
        child: def.control?.call(item, index) ?? const SizedBox.shrink(),
      );
    }

    final removable = widget.isItemRemovable?.call(item) ?? true;
    Widget? remove;
    if (removable) {
      final node = _removeNode(index);
      remove = widget.customRowActions != null
          ? widget.customRowActions!(
              context,
              CsAttributeEditorRowActions(
                item: item,
                itemIndex: index,
                focusNode: node,
                breakpoint: breakpoint,
                ownRow: !sameLine,
              ),
            )
          : CsButton(
              text: widget.removeButtonText ?? widget.i18nStrings.removeButtonText,
              semanticLabel: widget.removeButtonAriaLabel?.call(item),
              focusNode: node,
              onPress: widget.onRemoveButtonClick == null ? null : () => widget.onRemoveButtonClick!(index),
            );
    }

    final lines = <Widget>[];
    var defIndex = 0;
    for (final row in layout.rows) {
      final cells = <Widget>[];
      var used = 0;
      for (final flex in row) {
        cells.add(Expanded(flex: flex, child: field(defIndex++)));
        used += flex;
      }
      if (!sameLine && used < units) cells.add(Spacer(flex: units - used));
      if (sameLine) {
        // `remove-button-field-padding`: the first row's button lines up with
        // the controls under the labels (space-xxs + line-height-body-m).
        final top = index == 0 && widget.definition.any((d) => d.label != null || d.labelWidget != null)
            ? CsSpace.xxs + 20
            : 0.0;
        final button = Padding(
          padding: EdgeInsets.only(top: top),
          child: Align(alignment: AlignmentDirectional.topStart, child: remove ?? const SizedBox.shrink()),
        );
        final rb = layout.removeButton;
        cells.add(rb?.autoWidth ?? false ? button : Expanded(flex: rb?.width ?? 1, child: button));
      }
      lines.add(Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: gap, children: cells));
    }
    if (!sameLine) {
      if (remove != null) lines.add(Align(alignment: AlignmentDirectional.centerEnd, child: remove));
      lines.add(Container(height: CsBorderLine.dividerSectionWidth, color: cs.colors.borderDividerDefault));
    }
    final firstLabel = widget.definition.first.label;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: firstLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: gap,
        children: lines,
      ),
    );
  }

  Widget _addRow(BuildContext context) {
    final cs = context.cs;
    final limitReached = widget.itemLimit != null && widget.items.length >= widget.itemLimit!;
    final disabled = widget.disableAddButton || limitReached;
    final actions = <Widget>[
      if (!widget.hideAddButton)
        CsButton(
          text: widget.addButtonText,
          variant: widget.addButtonVariant == CsAttributeEditorAddButtonVariant.inlineLink
              ? CsButtonVariant.inlineLink
              : CsButtonVariant.normal,
          icon: widget.addButtonVariant == CsAttributeEditorAddButtonVariant.inlineLink ? CsIcons.addPlus : null,
          disabled: disabled,
          focusNode: _addNode,
          onPress: widget.onAddButtonClick,
        ),
      ?widget.additionalActions,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (actions.isNotEmpty) Wrap(spacing: CsSpace.xs, runSpacing: CsSpace.xs, children: actions),
        if (widget.additionalInfo != null)
          Padding(
            padding: const EdgeInsets.only(top: CsSpace.xxs),
            child: Semantics(
              liveRegion: true,
              child: DefaultTextStyle.merge(
                style: cs.text(CsTypeScale.bodyS, color: CsColor.textFormSecondary),
                child: widget.additionalInfo!,
              ),
            ),
          ),
      ],
    );
  }
}
