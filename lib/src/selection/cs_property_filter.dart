import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../forms/cs_form_field.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_dropdown.dart';
import '../overlays/cs_menu_parts.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';
import 'cs_autosuggest.dart';
import 'cs_option.dart';
import 'cs_select.dart';
import 'internal/autosuggest_hooks.dart';
import 'internal/token_limit_toggle.dart';

/// Comparison operators (Cloudscape `ComparisonOperator`), each with its
/// symbol.
enum CsPropertyFilterOperator {
  lessThan('<'),
  lessThanOrEqual('<='),
  greaterThan('>'),
  greaterThanOrEqual('>='),
  contains(':'),
  notContains('!:'),
  equals('='),
  notEquals('!='),
  startsWith('^'),
  notStartsWith('!^');

  const CsPropertyFilterOperator(this.symbol);

  /// The symbol used in token text and typed queries ("=", "!:", ">=").
  final String symbol;
}

/// How tokens combine (Cloudscape `JoinOperation`).
enum CsPropertyFilterOperation { and, or }

/// A property the user can filter by (Cloudscape `FilteringProperty`).
@immutable
class CsPropertyFilterProperty {
  const CsPropertyFilterProperty({
    required this.key,
    required this.propertyLabel,
    required this.groupValuesLabel,
    this.operators = const [CsPropertyFilterOperator.equals, CsPropertyFilterOperator.notEquals],
    this.defaultOperator,
    this.group,
  });

  /// Identifies the property in tokens.
  final String key;

  /// Shown in suggestions and tokens, such as "Instance type".
  final String propertyLabel;

  /// Heading of this property's values in suggestions, such as "Instance type values".
  final String groupValuesLabel;

  /// Operators this property supports.
  final List<CsPropertyFilterOperator> operators;

  /// Operator used when a value is picked without one. Defaults to the first
  /// of [operators].
  final CsPropertyFilterOperator? defaultOperator;

  /// Custom group of the property in suggestions; its labels come from
  /// [CsPropertyFilter.customGroupsText].
  final String? group;

  CsPropertyFilterOperator get resolvedDefaultOperator =>
      defaultOperator ?? (operators.isEmpty ? CsPropertyFilterOperator.equals : operators.first);
}

/// A suggested value of a property (Cloudscape `FilteringOption`).
@immutable
class CsPropertyFilterOption {
  const CsPropertyFilterOption({required this.propertyKey, required this.value, this.label});

  final String propertyKey;
  final String value;

  /// Display text. Defaults to [value].
  final String? label;
}

/// One filter (Cloudscape `Token`). A null [propertyKey] is free text.
@immutable
class CsPropertyFilterToken {
  const CsPropertyFilterToken({this.propertyKey, required this.operator, required this.value});

  final String? propertyKey;
  final CsPropertyFilterOperator operator;
  final String value;

  CsPropertyFilterToken copyWith({
    String? propertyKey,
    bool freeText = false,
    CsPropertyFilterOperator? operator,
    String? value,
  }) => CsPropertyFilterToken(
    propertyKey: freeText ? null : (propertyKey ?? this.propertyKey),
    operator: operator ?? this.operator,
    value: value ?? this.value,
  );

  @override
  bool operator ==(Object other) =>
      other is CsPropertyFilterToken &&
      other.propertyKey == propertyKey &&
      other.operator == operator &&
      other.value == value;

  @override
  int get hashCode => Object.hash(propertyKey, operator, value);
}

/// The whole filter (Cloudscape `Query`).
@immutable
class CsPropertyFilterQuery {
  const CsPropertyFilterQuery({this.tokens = const [], this.operation = CsPropertyFilterOperation.and});

  final List<CsPropertyFilterToken> tokens;
  final CsPropertyFilterOperation operation;

  CsPropertyFilterQuery copyWith({List<CsPropertyFilterToken>? tokens, CsPropertyFilterOperation? operation}) =>
      CsPropertyFilterQuery(tokens: tokens ?? this.tokens, operation: operation ?? this.operation);
}

/// Labels of a custom property group in suggestions (Cloudscape `GroupText`).
@immutable
class CsPropertyFilterGroupText {
  const CsPropertyFilterGroupText({required this.group, required this.properties, required this.values});

  /// The `group` of the properties this applies to.
  final String group;

  /// Heading of the group's properties.
  final String properties;

  /// Heading of the group's values.
  final String values;
}

/// A token as text, for labels and announcements (Cloudscape `FormattedToken`).
@immutable
class CsPropertyFilterFormattedToken {
  const CsPropertyFilterFormattedToken({
    this.propertyKey,
    required this.propertyLabel,
    required this.operator,
    required this.value,
  });

  final String? propertyKey;
  final String propertyLabel;
  final CsPropertyFilterOperator operator;
  final String value;
}

/// Details of a [CsPropertyFilter.onLoadItems] request.
@immutable
class CsPropertyFilterLoadItemsDetail {
  const CsPropertyFilterLoadItemsDetail({
    required this.filteringText,
    required this.firstPage,
    required this.samePage,
    this.filteringProperty,
    this.filteringOperator,
  });

  final CsPropertyFilterProperty? filteringProperty;
  final CsPropertyFilterOperator? filteringOperator;
  final String filteringText;
  final bool firstPage;
  final bool samePage;
}

/// Copy for [CsPropertyFilter] (Cloudscape `i18nStrings`), English by default.
@immutable
class CsPropertyFilterI18nStrings {
  const CsPropertyFilterI18nStrings({
    this.filteringAriaLabel = 'Filter',
    this.filteringPlaceholder = 'Filter',
    this.dismissAriaLabel = 'Dismiss',
    this.clearAriaLabel = 'Clear',
    this.groupValuesText = 'Values',
    this.groupPropertiesText = 'Properties',
    this.operatorsText = 'Operators',
    this.operationAndText = 'and',
    this.operationOrText = 'or',
    this.operatorLessText = 'Less than',
    this.operatorLessOrEqualText = 'Less than or equal',
    this.operatorGreaterText = 'Greater than',
    this.operatorGreaterOrEqualText = 'Greater than or equal',
    this.operatorContainsText = 'Contains',
    this.operatorDoesNotContainText = 'Does not contain',
    this.operatorEqualsText = 'Equals',
    this.operatorDoesNotEqualText = 'Does not equal',
    this.operatorStartsWithText = 'Starts with',
    this.operatorDoesNotStartWithText = 'Does not start with',
    this.editTokenHeader = 'Edit filter',
    this.propertyText = 'Property',
    this.operatorText = 'Operator',
    this.valueText = 'Value',
    this.cancelActionText = 'Cancel',
    this.applyActionText = 'Apply',
    this.allPropertiesLabel = 'All properties',
    this.tokenLimitShowMore = 'Show more',
    this.tokenLimitShowFewer = 'Show fewer',
    this.clearFiltersText = 'Clear filters',
    this.tokenOperatorAriaLabel = 'Boolean operator',
    this.formatToken,
    this.removeTokenButtonAriaLabel,
    this.enteredTextLabel,
  });

  final String filteringAriaLabel;
  final String filteringPlaceholder;
  final String dismissAriaLabel;
  final String clearAriaLabel;
  final String groupValuesText;
  final String groupPropertiesText;
  final String operatorsText;
  final String operationAndText;
  final String operationOrText;
  final String operatorLessText;
  final String operatorLessOrEqualText;
  final String operatorGreaterText;
  final String operatorGreaterOrEqualText;
  final String operatorContainsText;
  final String operatorDoesNotContainText;
  final String operatorEqualsText;
  final String operatorDoesNotEqualText;
  final String operatorStartsWithText;
  final String operatorDoesNotStartWithText;
  final String editTokenHeader;
  final String propertyText;
  final String operatorText;
  final String valueText;
  final String cancelActionText;
  final String applyActionText;

  /// Property choice for free text in the token editor.
  final String allPropertiesLabel;
  final String tokenLimitShowMore;
  final String tokenLimitShowFewer;
  final String clearFiltersText;
  final String tokenOperatorAriaLabel;

  /// Accessible text of a token. Defaults to "Instance type equals t3.micro".
  final String Function(CsPropertyFilterFormattedToken token)? formatToken;

  /// Accessible name of a token's remove button. Defaults to "Remove filter, " followed by the token.
  final String Function(CsPropertyFilterFormattedToken token)? removeTokenButtonAriaLabel;

  /// Label of the option that uses the typed text. Defaults to `Use: "<text>"`.
  final String Function(String text)? enteredTextLabel;

  /// The name of [op], such as "Equals".
  String operatorName(CsPropertyFilterOperator op) => switch (op) {
    CsPropertyFilterOperator.lessThan => operatorLessText,
    CsPropertyFilterOperator.lessThanOrEqual => operatorLessOrEqualText,
    CsPropertyFilterOperator.greaterThan => operatorGreaterText,
    CsPropertyFilterOperator.greaterThanOrEqual => operatorGreaterOrEqualText,
    CsPropertyFilterOperator.contains => operatorContainsText,
    CsPropertyFilterOperator.notContains => operatorDoesNotContainText,
    CsPropertyFilterOperator.equals => operatorEqualsText,
    CsPropertyFilterOperator.notEquals => operatorDoesNotEqualText,
    CsPropertyFilterOperator.startsWith => operatorStartsWithText,
    CsPropertyFilterOperator.notStartsWith => operatorDoesNotStartWithText,
  };
}

/// Cloudscape's `PropertyFilter`: builds a query of `property operator
/// value` tokens (and free-text tokens) for filtering a collection.
///
/// ```dart
/// CsPropertyFilter(
///   query: query,
///   onChange: (q) => setState(() => query = q),
///   countText: '5 matches',
///   filteringProperties: const [
///     CsPropertyFilterProperty(key: 'type', propertyLabel: 'Instance type', groupValuesLabel: 'Instance type values'),
///     CsPropertyFilterProperty(key: 'state', propertyLabel: 'State', groupValuesLabel: 'State values'),
///   ],
///   filteringOptions: const [
///     CsPropertyFilterOption(propertyKey: 'type', value: 't3.micro'),
///     CsPropertyFilterOption(propertyKey: 'state', value: 'Running'),
///   ],
/// )
/// ```
///
/// The flow follows Cloudscape: with an empty input the suggestions list
/// properties and values. Picking a property fills "Instance type " and
/// suggests its operators; picking an operator suggests that property's
/// values; picking a value adds the token. Typing a whole query ("State =
/// Running") and pressing Enter works too, and any other text becomes a
/// free-text token unless [disableFreeTextFiltering]. Tokens show below the
/// input with the and/or operation between them; tapping a token opens an
/// editor (a bottom sheet on phones); "Clear filters" removes them all.
class CsPropertyFilter extends StatefulWidget {
  const CsPropertyFilter({
    super.key,
    required this.query,
    required this.onChange,
    required this.filteringProperties,
    this.filteringOptions = const [],
    this.countText,
    this.disabled = false,
    this.hideOperations = false,
    this.readOnlyOperations = false,
    this.disableFreeTextFiltering = false,
    this.freeTextOperators = const [CsPropertyFilterOperator.contains, CsPropertyFilterOperator.notContains],
    this.customGroupsText = const [],
    this.tokenLimit,
    this.i18nStrings = const CsPropertyFilterI18nStrings(),
    this.onLoadItems,
    this.filteringEmpty,
    this.filteringLoadingText,
    this.filteringFinishedText,
    this.filteringErrorText,
    this.filteringRecoveryText,
    this.filteringStatusType = CsDropdownStatusType.finished,
    this.filteringConstraintText,
    this.customControl,
    this.customFilterActions,
    this.loading = false,
    this.tokenLimitShowMoreAriaLabel,
    this.tokenLimitShowFewerAriaLabel,
  });

  final CsPropertyFilterQuery query;

  /// Called with the next query.
  final ValueChanged<CsPropertyFilterQuery> onChange;
  final List<CsPropertyFilterProperty> filteringProperties;

  /// Suggested values for the properties.
  final List<CsPropertyFilterOption> filteringOptions;

  /// Number of matches next to the input, such as "5 matches". Shown while
  /// there are tokens.
  final String? countText;
  final bool disabled;

  /// Hide the and/or operation between tokens.
  final bool hideOperations;

  /// Show the operation as text, not a control.
  final bool readOnlyOperations;

  /// Typed text that is not a property query adds no free-text token.
  final bool disableFreeTextFiltering;

  /// Operators offered for free-text tokens in the editor.
  final List<CsPropertyFilterOperator> freeTextOperators;

  /// Labels of custom property groups.
  final List<CsPropertyFilterGroupText> customGroupsText;

  /// Number of tokens shown before "Show more".
  final int? tokenLimit;
  final CsPropertyFilterI18nStrings i18nStrings;

  /// Called as the user types, for loading suggestions from a server.
  final ValueChanged<CsPropertyFilterLoadItemsDetail>? onLoadItems;

  /// Shown in the suggestions when there are none.
  final Widget? filteringEmpty;
  final String? filteringLoadingText;
  final String? filteringFinishedText;
  final String? filteringErrorText;
  final String? filteringRecoveryText;
  final CsDropdownStatusType filteringStatusType;

  /// Help text under the input.
  final String? filteringConstraintText;

  /// A control before the input, such as a saved-filter select.
  final Widget? customControl;

  /// Replaces the "Clear filters" button.
  final Widget? customFilterActions;

  /// The collection is loading (the count is hidden).
  final bool loading;
  final String? tokenLimitShowMoreAriaLabel;
  final String? tokenLimitShowFewerAriaLabel;

  @override
  State<CsPropertyFilter> createState() => _CsPropertyFilterState();
}

/// Where typed text stands in the query grammar (Cloudscape `ParsedText`).
sealed class _Parsed {
  const _Parsed();
}

class _FreeText extends _Parsed {
  const _FreeText(this.value);
  final String value;
}

class _PropertyStep extends _Parsed {
  const _PropertyStep(this.property, this.value);
  final CsPropertyFilterProperty property;

  /// Text after the property label, where an operator is expected.
  final String value;
}

class _OperatorStep extends _Parsed {
  const _OperatorStep(this.property, this.operator, this.value);
  final CsPropertyFilterProperty property;
  final CsPropertyFilterOperator operator;
  final String value;
}

class _CsPropertyFilterState extends State<CsPropertyFilter> {
  String _text = '';
  bool _expanded = false;

  // Suggestion value -> the token it adds.
  final Map<String, CsPropertyFilterToken> _valueTokens = {};

  CsPropertyFilterI18nStrings get _i18n => widget.i18nStrings;

  CsPropertyFilterProperty? _property(String? key) {
    for (final p in widget.filteringProperties) {
      if (p.key == key) return p;
    }
    return null;
  }

  _Parsed _parse(String text) {
    final lower = text.toLowerCase();
    final props = [...widget.filteringProperties]
      ..sort((a, b) => b.propertyLabel.length.compareTo(a.propertyLabel.length));
    for (final p in props) {
      if (!lower.startsWith(p.propertyLabel.toLowerCase())) continue;
      final rest = text.substring(p.propertyLabel.length);
      final trimmed = rest.trimLeft();
      final ops = [...p.operators]..sort((a, b) => b.symbol.length.compareTo(a.symbol.length));
      for (final op in ops) {
        if (trimmed.startsWith(op.symbol)) {
          return _OperatorStep(p, op, trimmed.substring(op.symbol.length).trimLeft());
        }
      }
      // A space after the label (or nothing) means an operator comes next.
      if (rest.isEmpty || rest.startsWith(' ')) return _PropertyStep(p, trimmed);
    }
    return _FreeText(text);
  }

  String _optionLabel(CsPropertyFilterOption o) => o.label ?? o.value;

  List<CsOptionItem> _suggestions() {
    _valueTokens.clear();
    final parsed = _parse(_text);
    switch (parsed) {
      case _OperatorStep(:final property, :final operator, :final value):
        final lower = value.toLowerCase();
        final options = <CsOption>[];
        for (final o in widget.filteringOptions) {
          if (o.propertyKey != property.key) continue;
          if (!_optionLabel(o).toLowerCase().contains(lower)) continue;
          final v = '${property.propertyLabel} ${operator.symbol} ${o.value}';
          _valueTokens[v] = CsPropertyFilterToken(propertyKey: property.key, operator: operator, value: o.value);
          options.add(CsOption(value: v, label: '${property.propertyLabel} ${operator.symbol} ${_optionLabel(o)}'));
        }
        return [if (options.isNotEmpty) CsOptionGroup(label: property.groupValuesLabel, options: options)];
      case _PropertyStep(:final property, :final value):
        final options = [
          for (final op in property.operators)
            if (op.symbol.startsWith(value) || value.isEmpty)
              CsOption(
                value: '${property.propertyLabel} ${op.symbol} ',
                label: '${property.propertyLabel} ${op.symbol}',
                description: _i18n.operatorName(op),
              ),
        ];
        return [if (options.isNotEmpty) CsOptionGroup(label: _i18n.operatorsText, options: options)];
      case _FreeText(:final value):
        final lower = value.toLowerCase();
        final groups = <String?, List<CsOption>>{};
        final valueGroups = <String?, List<CsOption>>{};
        for (final p in widget.filteringProperties) {
          if (p.propertyLabel.toLowerCase().contains(lower)) {
            (groups[p.group] ??= []).add(CsOption(value: '${p.propertyLabel} ', label: p.propertyLabel));
          }
        }
        for (final o in widget.filteringOptions) {
          final p = _property(o.propertyKey);
          if (p == null) continue;
          if (!_optionLabel(o).toLowerCase().contains(lower) && !p.propertyLabel.toLowerCase().contains(lower)) {
            continue;
          }
          final op = p.resolvedDefaultOperator;
          final v = '${p.propertyLabel} ${op.symbol} ${o.value}';
          _valueTokens[v] = CsPropertyFilterToken(propertyKey: p.key, operator: op, value: o.value);
          (valueGroups[p.group] ??= []).add(
            CsOption(value: v, label: '${p.propertyLabel} ${op.symbol} ${_optionLabel(o)}'),
          );
        }
        String groupLabel(String? group, {required bool values}) {
          if (group == null) return values ? _i18n.groupValuesText : _i18n.groupPropertiesText;
          for (final g in widget.customGroupsText) {
            if (g.group == group) return values ? g.values : g.properties;
          }
          return group;
        }

        return [
          for (final e in groups.entries) CsOptionGroup(label: groupLabel(e.key, values: false), options: e.value),
          for (final e in valueGroups.entries) CsOptionGroup(label: groupLabel(e.key, values: true), options: e.value),
        ];
    }
  }

  void _addToken(CsPropertyFilterToken token) {
    widget.onChange(widget.query.copyWith(tokens: [...widget.query.tokens, token]));
    setState(() => _text = '');
  }

  void _submitText() {
    final parsed = _parse(_text);
    switch (parsed) {
      case _OperatorStep(:final property, :final operator, :final value) when value.isNotEmpty:
        _addToken(CsPropertyFilterToken(propertyKey: property.key, operator: operator, value: value));
      default:
        if (_text.trim().isEmpty || widget.disableFreeTextFiltering) return;
        _addToken(CsPropertyFilterToken(operator: CsPropertyFilterOperator.contains, value: _text.trim()));
    }
  }

  void _onSelect(CsAutosuggestSelectDetail d) {
    final token = d.selectedOption == null ? null : _valueTokens[d.selectedOption!.value];
    if (token != null) {
      _addToken(token);
    } else if (d.selectedOption == null) {
      _submitText();
    }
  }

  bool _keepOpen(CsAutosuggestSelectDetail d) => d.selectedOption != null && d.value.endsWith(' ');

  void _onText(String v) {
    setState(() => _text = v);
    final parsed = _parse(v);
    widget.onLoadItems?.call(
      CsPropertyFilterLoadItemsDetail(
        filteringText: switch (parsed) {
          _OperatorStep(:final value) => value,
          _PropertyStep() => '',
          _FreeText(:final value) => value,
        },
        filteringProperty: switch (parsed) {
          _OperatorStep(:final property) || _PropertyStep(:final property) => property,
          _FreeText() => null,
        },
        filteringOperator: parsed is _OperatorStep ? parsed.operator : null,
        firstPage: true,
        samePage: false,
      ),
    );
  }

  CsPropertyFilterFormattedToken _format(CsPropertyFilterToken t) {
    final p = _property(t.propertyKey);
    String valueLabel = t.value;
    for (final o in widget.filteringOptions) {
      if (o.propertyKey == t.propertyKey && o.value == t.value) valueLabel = _optionLabel(o);
    }
    return CsPropertyFilterFormattedToken(
      propertyKey: t.propertyKey,
      propertyLabel: p?.propertyLabel ?? _i18n.allPropertiesLabel,
      operator: t.operator,
      value: valueLabel,
    );
  }

  String _tokenText(CsPropertyFilterToken t) {
    final f = _format(t);
    if (t.propertyKey == null) {
      return t.operator == CsPropertyFilterOperator.contains ? f.value : '${t.operator.symbol} ${f.value}';
    }
    return '${f.propertyLabel} ${t.operator.symbol} ${f.value}';
  }

  String _tokenAria(CsPropertyFilterToken t) {
    final f = _format(t);
    return _i18n.formatToken?.call(f) ??
        '${f.propertyLabel} ${_i18n.operatorName(t.operator).toLowerCase()} ${f.value}';
  }

  void _removeAt(int i) {
    final tokens = [...widget.query.tokens]..removeAt(i);
    widget.onChange(widget.query.copyWith(tokens: tokens));
  }

  void _replaceAt(int i, CsPropertyFilterToken token) {
    final tokens = [...widget.query.tokens];
    tokens[i] = token;
    widget.onChange(widget.query.copyWith(tokens: tokens));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tokens = widget.query.tokens;
    final input = AutosuggestHooks(
      keepOpenAfterSelect: _keepOpen,
      highlightText: switch (_parse(_text)) {
        _OperatorStep(:final value) => value.isEmpty ? null : value,
        _PropertyStep() => null,
        _FreeText(:final value) => value.isEmpty ? null : value,
      },
      leading: CsIcon(CsIcons.search, variant: widget.disabled ? CsIconVariant.disabled : CsIconVariant.subtle),
      child: CsAutosuggest(
        value: _text,
        options: _suggestions(),
        filteringType: CsFilteringType.manual,
        placeholder: _i18n.filteringPlaceholder,
        ariaLabel: _i18n.filteringAriaLabel,
        clearAriaLabel: _i18n.clearAriaLabel,
        disabled: widget.disabled,
        hideEnteredTextOption:
            _text.trim().isEmpty || (widget.disableFreeTextFiltering && _parse(_text) is! _OperatorStep),
        enteredTextLabel: _i18n.enteredTextLabel ?? (v) => 'Use: "$v"',
        empty: widget.filteringEmpty,
        statusType: widget.filteringStatusType,
        loadingText: widget.filteringLoadingText,
        finishedText: widget.filteringFinishedText,
        errorText: widget.filteringErrorText,
        recoveryText: widget.filteringRecoveryText,
        onChange: _onText,
        onSelect: _onSelect,
        onSubmit: (_) => _submitText(),
      ),
    );

    final showCount = tokens.isNotEmpty && widget.countText != null && !widget.loading;
    Widget top = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.customControl != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: CsSpace.s),
            child: widget.customControl,
          ),
        Expanded(child: input),
        if (showCount)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: CsSpace.s),
            child: Text(widget.countText!, style: cs.body.copyWith(color: cs.colors.textFormLabel)),
          ),
      ],
    );
    if (widget.filteringConstraintText != null) {
      top = CsFormField(constraintText: widget.filteringConstraintText, child: top);
    }

    final limit = widget.tokenLimit;
    final hasHidden = limit != null && tokens.length > limit;
    final visibleCount = hasHidden && !_expanded ? limit : tokens.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UnconstrainedBox(constrainedAxis: Axis.horizontal, child: top),
        if (tokens.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: CsSpace.xs),
            child: Wrap(
              spacing: CsSpace.xs,
              runSpacing: CsSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < visibleCount; i++)
                  _FilteringToken(
                    key: ValueKey('cs-filter-token-$i'),
                    text: _tokenText(tokens[i]),
                    semanticLabel: _tokenAria(tokens[i]),
                    removeLabel:
                        _i18n.removeTokenButtonAriaLabel?.call(_format(tokens[i])) ??
                        'Remove filter, ${_tokenAria(tokens[i])}',
                    disabled: widget.disabled,
                    showOperation: i > 0 && !widget.hideOperations,
                    operation: widget.query.operation,
                    readOnlyOperation: widget.readOnlyOperations,
                    i18n: _i18n,
                    onOperation: (op) => widget.onChange(widget.query.copyWith(operation: op)),
                    onRemove: () => _removeAt(i),
                    editor: (close) => _TokenEditor(
                      token: tokens[i],
                      properties: widget.filteringProperties,
                      options: widget.filteringOptions,
                      freeTextOperators: widget.freeTextOperators,
                      disableFreeText: widget.disableFreeTextFiltering,
                      i18n: _i18n,
                      onCancel: close,
                      onApply: (t) {
                        _replaceAt(i, t);
                        close();
                      },
                    ),
                  ),
                if (hasHidden)
                  TokenLimitToggle(
                    expanded: _expanded,
                    hiddenCount: tokens.length - limit,
                    allHidden: limit == 0,
                    showMoreText: _i18n.tokenLimitShowMore,
                    showFewerText: _i18n.tokenLimitShowFewer,
                    showMoreAriaLabel: widget.tokenLimitShowMoreAriaLabel,
                    showFewerAriaLabel: widget.tokenLimitShowFewerAriaLabel,
                    onPress: () => setState(() => _expanded = !_expanded),
                  ),
                widget.customFilterActions ??
                    CsButton(
                      text: _i18n.clearFiltersText,
                      disabled: widget.disabled,
                      onPress: () => widget.onChange(widget.query.copyWith(tokens: const [])),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A query token: the and/or operation (after the first token), the token
/// text that opens the editor, and a remove button. Drawn with Cloudscape's
/// token chrome (2px `color-border-item-selected`, `color-background-item-selected`).
class _FilteringToken extends StatefulWidget {
  const _FilteringToken({
    super.key,
    required this.text,
    required this.semanticLabel,
    required this.removeLabel,
    required this.disabled,
    required this.showOperation,
    required this.operation,
    required this.readOnlyOperation,
    required this.i18n,
    required this.onOperation,
    required this.onRemove,
    required this.editor,
  });

  final String text;
  final String semanticLabel;
  final String removeLabel;
  final bool disabled;
  final bool showOperation;
  final CsPropertyFilterOperation operation;
  final bool readOnlyOperation;
  final CsPropertyFilterI18nStrings i18n;
  final ValueChanged<CsPropertyFilterOperation> onOperation;
  final VoidCallback onRemove;
  final Widget Function(VoidCallback close) editor;

  @override
  State<_FilteringToken> createState() => _FilteringTokenState();
}

class _FilteringTokenState extends State<_FilteringToken> {
  bool _editing = false;
  bool _operationOpen = false;

  String _operationText(CsPropertyFilterOperation op) =>
      op == CsPropertyFilterOperation.and ? widget.i18n.operationAndText : widget.i18n.operationOrText;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final border = widget.disabled ? c.borderControlDisabled : c.borderItemSelected;
    final background = widget.disabled ? c.backgroundContainerContent : c.backgroundItemSelected;
    final fg = widget.disabled ? c.textDisabled : c.textBodyDefault;
    const radius = Radius.circular(CsBorderRadius.token);

    Widget? operation;
    if (widget.showOperation) {
      final label = Text(_operationText(widget.operation), style: cs.body.copyWith(color: fg));
      if (widget.readOnlyOperation || widget.disabled) {
        operation = Padding(
          padding: const EdgeInsets.symmetric(horizontal: CsSpace.s),
          child: label,
        );
      } else {
        operation = CsDropdown(
          open: _operationOpen,
          onDismiss: () => setState(() => _operationOpen = false),
          matchTriggerWidth: false,
          trapFocus: true,
          presentation: CsPresentation.popover,
          contentBuilder: (context, inSheet) => CsMenuPanel(
            minWidth: 96,
            children: [
              for (final op in CsPropertyFilterOperation.values)
                CsMenuRow(
                  label: _operationText(op),
                  selected: op == widget.operation,
                  onPress: () {
                    setState(() => _operationOpen = false);
                    widget.onOperation(op);
                  },
                ),
            ],
          ),
          child: CsPressable(
            onPress: () => setState(() => _operationOpen = !_operationOpen),
            semanticLabel: widget.i18n.tokenOperatorAriaLabel,
            semanticValue: _operationText(widget.operation),
            expanded: _operationOpen,
            excludeChildSemantics: true,
            scaleOnPress: false,
            minTapTargetSize: 0,
            builder: (context, state) => Padding(
              padding: const EdgeInsetsDirectional.only(start: CsSpace.s, end: CsSpace.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: CsSpace.xxs,
                children: [
                  label,
                  CsIcon(
                    CsIcons.caretDownFilled,
                    dangerouslySetColor: state.hovered ? c.textButtonInlineIconHover : c.textButtonInlineIconDefault,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    final textButton = CsDropdown(
      open: _editing,
      onDismiss: () => setState(() => _editing = false),
      matchTriggerWidth: false,
      trapFocus: true,
      dismissOnOutsideTap: false,
      preferredHeight: 320,
      sheetLabel: widget.i18n.editTokenHeader,
      contentBuilder: (context, inSheet) {
        final editor = widget.editor(() => setState(() => _editing = false));
        if (inSheet) return Padding(padding: const EdgeInsets.all(CsSpace.l), child: editor);
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, minWidth: 280),
          child: _EditorSurface(child: editor),
        );
      },
      child: CsPressable(
        onPress: widget.disabled ? null : () => setState(() => _editing = true),
        disabled: widget.disabled,
        semanticLabel: widget.semanticLabel,
        semanticHint: widget.i18n.editTokenHeader,
        expanded: _editing,
        excludeChildSemantics: true,
        scaleOnPress: false,
        minTapTargetSize: 0,
        borderRadius: BorderRadius.circular(CsBorderRadius.token),
        builder: (context, state) => Padding(
          padding: EdgeInsetsDirectional.only(
            start: widget.showOperation ? CsSpace.xs : CsSpace.fieldHorizontal,
            top: cs.space.tokenVertical,
            bottom: cs.space.tokenVertical,
          ),
          child: Text(widget.text, style: cs.body.copyWith(color: state.hovered ? c.textLinkHover : fg)),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(color: background, borderRadius: const BorderRadius.all(radius)),
      foregroundDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(radius),
        border: Border.all(color: border, width: CsBorderWidth.token),
      ),
      padding: const EdgeInsets.all(CsBorderWidth.token),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (operation != null) ...[operation, SizedBox(height: 20, child: _TokenDivider(color: border))],
          Flexible(child: textButton),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: CsSpace.xxs, end: CsSpace.xxs),
            child: CsButton(
              icon: CsIcons.close,
              variant: CsButtonVariant.inlineIcon,
              semanticLabel: widget.removeLabel,
              disabled: widget.disabled,
              onPress: widget.disabled ? null : widget.onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenDivider extends StatelessWidget {
  const _TokenDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: CsBorderWidth.token,
    child: ColoredBox(color: color),
  );
}

class _EditorSurface extends StatelessWidget {
  const _EditorSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    const radius = BorderRadius.all(Radius.circular(CsBorderRadius.popover));
    return Container(
      decoration: BoxDecoration(
        color: cs.colors.backgroundPopover,
        borderRadius: radius,
        boxShadow: cs.shadows.popover,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: cs.colors.borderPopover, width: CsBorderWidth.popover),
      ),
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.l, vertical: CsSpace.m),
      child: child,
    );
  }
}

/// Cloudscape's token editor: property, operator and value, with Cancel and
/// Apply. Edits a draft; nothing changes until Apply.
class _TokenEditor extends StatefulWidget {
  const _TokenEditor({
    required this.token,
    required this.properties,
    required this.options,
    required this.freeTextOperators,
    required this.disableFreeText,
    required this.i18n,
    required this.onCancel,
    required this.onApply,
  });

  final CsPropertyFilterToken token;
  final List<CsPropertyFilterProperty> properties;
  final List<CsPropertyFilterOption> options;
  final List<CsPropertyFilterOperator> freeTextOperators;
  final bool disableFreeText;
  final CsPropertyFilterI18nStrings i18n;
  final VoidCallback onCancel;
  final ValueChanged<CsPropertyFilterToken> onApply;

  @override
  State<_TokenEditor> createState() => _TokenEditorState();
}

class _TokenEditorState extends State<_TokenEditor> {
  late CsPropertyFilterToken _draft = widget.token;

  static const _allKey = '\u0000all';

  CsPropertyFilterProperty? get _property {
    for (final p in widget.properties) {
      if (p.key == _draft.propertyKey) return p;
    }
    return null;
  }

  List<CsPropertyFilterOperator> get _operators => _property?.operators ?? widget.freeTextOperators;

  CsOption _operatorOption(CsPropertyFilterOperator op) =>
      CsOption(value: op.name, label: op.symbol, description: widget.i18n.operatorName(op));

  @override
  Widget build(BuildContext context) {
    final i18n = widget.i18n;
    final property = _property;
    final propertyOptions = <CsOptionItem>[
      if (!widget.disableFreeText) CsOption(value: _allKey, label: i18n.allPropertiesLabel),
      for (final p in widget.properties) CsOption(value: p.key, label: p.propertyLabel),
    ];
    final valueOptions = <CsOptionItem>[
      for (final o in widget.options)
        if (o.propertyKey == _draft.propertyKey) CsOption(value: o.value, label: o.label),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CsSpace.s,
      children: [
        Semantics(header: true, child: Text(i18n.editTokenHeader, style: context.cs.text(CsTypeScale.headingS))),
        CsFormField(
          label: i18n.propertyText,
          child: CsSelect(
            options: propertyOptions,
            presentation: CsPresentation.popover,
            ariaLabel: i18n.propertyText,
            selectedOption: CsOption(
              value: _draft.propertyKey ?? _allKey,
              label: property?.propertyLabel ?? i18n.allPropertiesLabel,
            ),
            onChange: (o) => setState(() {
              final key = o.value == _allKey ? null : o.value;
              final next = key == null ? null : widget.properties.firstWhere((p) => p.key == key);
              final ops = next?.operators ?? widget.freeTextOperators;
              _draft = CsPropertyFilterToken(
                propertyKey: key,
                operator: ops.contains(_draft.operator)
                    ? _draft.operator
                    : (next?.resolvedDefaultOperator ?? ops.first),
                value: _draft.value,
              );
            }),
          ),
        ),
        CsFormField(
          label: i18n.operatorText,
          child: CsSelect(
            options: [for (final op in _operators) _operatorOption(op)],
            presentation: CsPresentation.popover,
            ariaLabel: i18n.operatorText,
            triggerVariant: CsSelectTriggerVariant.option,
            selectedOption: _operatorOption(_draft.operator),
            onChange: (o) => setState(
              () => _draft = _draft.copyWith(
                operator: CsPropertyFilterOperator.values.firstWhere((op) => op.name == o.value),
              ),
            ),
          ),
        ),
        CsFormField(
          label: i18n.valueText,
          child: CsAutosuggest(
            value: _draft.value,
            options: valueOptions,
            ariaLabel: i18n.valueText,
            hideEnteredTextOption: true,
            onChange: (v) => setState(() => _draft = _draft.copyWith(value: v)),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: CsSpace.xs,
          runSpacing: CsSpace.xs,
          children: [
            CsButton(text: i18n.cancelActionText, variant: CsButtonVariant.link, onPress: widget.onCancel),
            CsButton(
              text: i18n.applyActionText,
              variant: CsButtonVariant.primary,
              onPress: _draft.value.trim().isEmpty ? null : () => widget.onApply(_draft),
            ),
          ],
        ),
      ],
    );
  }
}
