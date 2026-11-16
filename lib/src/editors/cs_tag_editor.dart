import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../feedback/cs_spinner.dart';
import '../icons/cs_icons.g.dart';
import '../navigation/cs_link.dart';
import '../overlays/cs_dropdown.dart';
import '../overlays/cs_menu_parts.dart';
import '../status/cs_status_indicator.dart';
import '../system/cs_editable.dart';
import '../system/cs_field_box.dart';
import '../system/cs_strings.dart';
import '../system/cs_text_field_state.dart';
import '../theme/theme.dart';
import 'cs_attribute_editor.dart';
import 'cs_editor_utils.dart';

/// One tag of a [CsTagEditor] (Cloudscape `TagEditorProps.Tag`).
@immutable
class CsTag {
  const CsTag({
    required this.key,
    this.value = '',
    this.existing = false,
    this.markedForRemoval = false,
    this.valueSuggestionOptions,
  });

  final String key;
  final String value;

  /// The tag is already on the resource. Removing it marks it
  /// [markedForRemoval] (with an undo) instead of dropping it, and its key
  /// cannot be edited.
  final bool existing;

  /// Set by the editor when an [existing] tag is removed.
  final bool markedForRemoval;

  /// Value suggestions shown before [CsTagEditor.valuesRequest] answers.
  final List<String>? valueSuggestionOptions;

  CsTag copyWith({String? key, String? value, bool? existing, bool? markedForRemoval}) => CsTag(
    key: key ?? this.key,
    value: value ?? this.value,
    existing: existing ?? this.existing,
    markedForRemoval: markedForRemoval ?? this.markedForRemoval,
    valueSuggestionOptions: valueSuggestionOptions,
  );

  @override
  bool operator ==(Object other) =>
      other is CsTag &&
      other.key == key &&
      other.value == value &&
      other.existing == existing &&
      other.markedForRemoval == markedForRemoval;

  @override
  int get hashCode => Object.hash(key, value, existing, markedForRemoval);

  @override
  String toString() => 'CsTag($key=$value${existing ? ', existing' : ''}${markedForRemoval ? ', removed' : ''})';
}

/// What [CsTagEditor.onChange] receives (Cloudscape `ChangeDetail`).
@immutable
class CsTagEditorChange {
  const CsTagEditorChange({required this.tags, required this.valid});

  /// The full next list, including tags marked for removal.
  final List<CsTag> tags;

  /// No key or value has a validation error.
  final bool valid;
}

/// The result of [CsTagEditor.getTagsDiff]: what to send to a tagging API.
@immutable
class CsTagsDiff {
  const CsTagsDiff({required this.created, required this.removed});

  /// New and changed tags, key to value.
  final Map<String, String> created;

  /// Keys to remove (marked for removal, or changed and re-created).
  final List<String> removed;
}

/// Copy for [CsTagEditor] (Cloudscape `TagEditorProps.I18nStrings`), with
/// Cloudscape's English defaults.
@immutable
class CsTagEditorI18nStrings {
  const CsTagEditorI18nStrings({
    this.keyPlaceholder = 'Enter key',
    this.valuePlaceholder = 'Enter value',
    this.addButton = 'Add new tag',
    this.removeButton = 'Remove',
    this.undoButton = 'Undo',
    this.undoPrompt = 'This tag will be removed upon saving changes',
    this.loading = 'Loading tags that are associated with this resource',
    this.keyHeader = 'Key',
    this.valueHeader = 'Value',
    this.optional = 'optional',
    this.keySuggestion = 'Custom tag key',
    this.valueSuggestion = 'Custom tag value',
    this.tooManyKeysSuggestion = 'You have more keys than can be displayed',
    this.tooManyValuesSuggestion = 'You have more values than can be displayed',
    this.emptyTags = 'No tags associated with the resource.',
    this.errorIconAriaLabel,
    this.keysSuggestionLoading = 'Loading tag keys',
    this.keysSuggestionError = 'Tag keys could not be retrieved',
    this.valuesSuggestionError = 'Tag values could not be retrieved',
    this.valuesSuggestionLoading = 'Loading tag values',
    this.emptyKeyError = 'You must specify a tag key',
    this.maxKeyCharLengthError = 'The maximum number of characters you can use in a tag key is 128.',
    this.maxValueCharLengthError = 'The maximum number of characters you can use in a tag value is 256.',
    this.duplicateKeyError = 'You must specify a unique tag key.',
    this.invalidKeyError =
        'Invalid key. Keys can only contain Unicode letters, digits, white space and any of the following: _.:/=+@-',
    this.invalidValueError =
        'Invalid value. Values can only contain Unicode letters, digits, white space and any of the following: _.:/=+@-',
    this.awsPrefixError = 'Cannot start with aws:',
    this.clearAriaLabel,
    this.itemRemovedAriaLive = 'Item removed',
    this.tagLimit,
    this.tagLimitReached,
    this.tagLimitExceeded,
    this.enteredKeyLabel,
    this.enteredValueLabel,
    this.removeButtonAriaLabel,
  });

  final String keyPlaceholder;
  final String valuePlaceholder;
  final String addButton;
  final String removeButton;
  final String undoButton;
  final String undoPrompt;
  final String loading;
  final String keyHeader;
  final String valueHeader;
  final String optional;
  final String keySuggestion;
  final String valueSuggestion;
  final String tooManyKeysSuggestion;
  final String tooManyValuesSuggestion;
  final String emptyTags;
  final String? errorIconAriaLabel;
  final String keysSuggestionLoading;
  final String keysSuggestionError;
  final String valuesSuggestionError;
  final String valuesSuggestionLoading;
  final String emptyKeyError;
  final String maxKeyCharLengthError;
  final String maxValueCharLengthError;
  final String duplicateKeyError;
  final String invalidKeyError;
  final String invalidValueError;
  final String awsPrefixError;
  final String? clearAriaLabel;
  final String itemRemovedAriaLive;

  /// "You can add up to 3 more tags." Gets the tags left and the limit.
  final String Function(int availableTags, int tagLimit)? tagLimit;

  /// "You have reached the limit of 50 tags."
  final String Function(int tagLimit)? tagLimitReached;

  /// "You have exceeded the limit of 50 tags."
  final String Function(int tagLimit)? tagLimitExceeded;

  /// The suggestion that keeps typed text: `Use: "env"`.
  final String Function(String enteredText)? enteredKeyLabel;
  final String Function(String enteredText)? enteredValueLabel;

  /// Accessible name of a row's remove button. Defaults to "Remove env".
  final String Function(CsTag tag)? removeButtonAriaLabel;

  String limitText(int available, int limit) {
    if (tagLimit != null) return tagLimit!(available, limit);
    if (available == limit) return 'You can add up to $limit tags.';
    return available == 1 ? 'You can add up to 1 more tag.' : 'You can add up to $available more tags.';
  }

  String reachedText(int limit) =>
      tagLimitReached?.call(limit) ??
      (limit == 1 ? 'You have reached the limit of 1 tag.' : 'You have reached the limit of $limit tags.');

  String exceededText(int limit) =>
      tagLimitExceeded?.call(limit) ??
      (limit == 1 ? 'You have exceeded the limit of 1 tag.' : 'You have exceeded the limit of $limit tags.');
}

class _TagError {
  const _TagError({this.key, this.value});
  final String? key;
  final String? value;
}

/// Cloudscape's `TagEditor`: an attribute editor for resource tags, with key
/// and value suggestions, Cloudscape's tag validation, a tag limit, and undo
/// for removing tags the resource already has.
///
/// It is controlled: pass [tags] and replace them in [onChange], which also
/// says whether every tag is valid.
///
/// ```dart
/// CsTagEditor(
///   tags: tags,
///   keysRequest: (key) async => ['environment', 'team', 'cost-center'],
///   valuesRequest: (key, value) async => key == 'environment' ? ['prod', 'staging'] : [],
///   onChange: (change) => setState(() {
///     tags = change.tags;
///     valid = change.valid;
///   }),
/// )
/// ```
///
/// Validation follows Cloudscape: keys are required (once touched), unique,
/// at most 128 characters, never start with `aws:`; values are at most 256;
/// both only use Unicode letters, digits, spaces and `_.:/=+@-` unless
/// [allowedCharacterPattern] says otherwise. Use a [GlobalKey] of
/// [CsTagEditorState] and call `focus()` to move to the first error.
class CsTagEditor extends StatefulWidget {
  const CsTagEditor({
    super.key,
    this.tags = const [],
    this.onChange,
    this.loading = false,
    this.tagLimit = 50,
    this.allowedCharacterPattern,
    this.keysRequest,
    this.valuesRequest,
    this.i18nStrings = const CsTagEditorI18nStrings(),
  });

  final List<CsTag> tags;
  final ValueChanged<CsTagEditorChange>? onChange;

  /// Shows a loading status in place of the editor.
  final bool loading;

  /// Maximum number of tags (not counting ones marked for removal).
  final int tagLimit;

  /// A regular expression that replaces the default allowed characters.
  final String? allowedCharacterPattern;

  /// Returns key suggestions for the typed text. Called on focus with an
  /// empty string, then as the user types.
  final Future<List<String>> Function(String key)? keysRequest;

  /// Returns value suggestions for a key and the typed value.
  final Future<List<String>> Function(String key, String value)? valuesRequest;
  final CsTagEditorI18nStrings i18nStrings;

  /// Compares the tags the resource had ([initialTags], all `existing`) with
  /// the edited [tags] and returns what to create and remove. A changed
  /// value counts as both (Cloudscape `getTagsDiff`).
  static CsTagsDiff getTagsDiff(List<CsTag> initialTags, List<CsTag> tags) {
    final updated = tags.where(
      (t) => initialTags.any((i) => !t.markedForRemoval && t.key == i.key && t.existing && t.value != i.value),
    );
    final created = <String, String>{
      for (final t in [...tags.where((t) => !t.existing), ...updated]) t.key: t.value,
    };
    final removed = [...tags.where((t) => t.existing && t.markedForRemoval), ...updated].map((t) => t.key).toList();
    return CsTagsDiff(created: created, removed: removed);
  }

  @override
  State<CsTagEditor> createState() => CsTagEditorState();
}

/// State of [CsTagEditor], reachable through a [GlobalKey] for [focus].
class CsTagEditorState extends State<CsTagEditor> {
  static const int _maxKeyLength = 128;
  static const int _maxValueLength = 256;
  static final RegExp _defaultChars = RegExp(r'^([\p{L}\p{Z}\p{N}_.:/=+\-@]*)$', unicode: true);

  final List<bool> _keyDirty = [];
  final List<FocusNode> _keyNodes = [];
  final List<FocusNode> _valueNodes = [];
  final List<FocusNode> _undoNodes = [];
  final GlobalKey<CsAttributeEditorState<int>> _editorKey = GlobalKey();
  List<String> _initialKeyOptions = const [];

  FocusNode _nodeIn(List<FocusNode> list, int i, String label) {
    while (list.length <= i) {
      list.add(FocusNode(debugLabel: 'CsTagEditor $label ${list.length}'));
    }
    return list[i];
  }

  bool _dirty(int i) => i < _keyDirty.length && _keyDirty[i];

  void _setDirty(int i) {
    while (_keyDirty.length <= i) {
      _keyDirty.add(false);
    }
    _keyDirty[i] = true;
  }

  @override
  void dispose() {
    for (final n in [..._keyNodes, ..._valueNodes, ..._undoNodes]) {
      n.dispose();
    }
    super.dispose();
  }

  /// Focuses the first key or value with an error. Does nothing when all
  /// tags are valid.
  void focus() {
    final errors = _validate(widget.tags);
    for (var i = 0; i < errors.length; i++) {
      final e = errors[i];
      if (e == null) continue;
      (e.key != null ? _nodeIn(_keyNodes, i, 'key') : _nodeIn(_valueNodes, i, 'value')).requestFocus();
      return;
    }
  }

  List<_TagError?> _validate(List<CsTag> tags) {
    final s = widget.i18nStrings;
    final chars = widget.allowedCharacterPattern != null
        ? RegExp(widget.allowedCharacterPattern!, unicode: true)
        : _defaultChars;
    bool invalidChars(String v) => v.isNotEmpty && !chars.hasMatch(v);
    final counts = <String, int>{};
    for (final t in tags) {
      if (t.key.isNotEmpty && !t.markedForRemoval) counts[t.key] = (counts[t.key] ?? 0) + 1;
    }
    return [
      for (var i = 0; i < tags.length; i++)
        () {
          final t = tags[i];
          String? keyError;
          String? valueError;
          if (_dirty(i) && t.key.trim().isEmpty) {
            keyError = s.emptyKeyError;
          } else if (t.key.toLowerCase().startsWith('aws:')) {
            keyError = s.awsPrefixError;
          } else if (invalidChars(t.key)) {
            keyError = s.invalidKeyError;
          } else if (t.key.length > _maxKeyLength) {
            keyError = s.maxKeyCharLengthError;
          } else if ((counts[t.key] ?? 0) > 1) {
            keyError = s.duplicateKeyError;
          }
          if (!t.markedForRemoval) {
            if (invalidChars(t.value)) {
              valueError = s.invalidValueError;
            } else if (t.value.length > _maxValueLength) {
              valueError = s.maxValueCharLengthError;
            }
          }
          return keyError != null || valueError != null ? _TagError(key: keyError, value: valueError) : null;
        }(),
    ];
  }

  void _fire(List<CsTag> next) {
    widget.onChange?.call(CsTagEditorChange(tags: next, valid: !_validate(next).any((e) => e != null)));
  }

  void _afterFrame(VoidCallback f) => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) f();
  });

  void _add() {
    final row = widget.tags.length;
    _fire([...widget.tags, const CsTag(key: '')]);
    _afterFrame(() => _nodeIn(_keyNodes, row, 'key').requestFocus());
  }

  void _remove(int i) {
    final tags = widget.tags;
    final existing = tags[i].existing;
    _fire([...tags.sublist(0, i), if (existing) tags[i].copyWith(markedForRemoval: true), ...tags.sublist(i + 1)]);
    if (existing) {
      _afterFrame(() => _nodeIn(_undoNodes, i, 'undo').requestFocus());
      return;
    }
    if (i < _keyDirty.length) _keyDirty.removeAt(i);
    _afterFrame(() {
      if (i < widget.tags.length) {
        _nodeIn(_keyNodes, i, 'key').requestFocus();
      } else if (i > 0) {
        final prev = widget.tags[i - 1];
        if (prev.existing) {
          (prev.markedForRemoval ? _nodeIn(_undoNodes, i - 1, 'undo') : _nodeIn(_valueNodes, i - 1, 'value'))
              .requestFocus();
        } else {
          _nodeIn(_keyNodes, i - 1, 'key').requestFocus();
        }
      } else {
        _editorKey.currentState?.focusAddButton();
      }
    });
  }

  void _undo(int i) {
    final tags = widget.tags;
    _fire([...tags.sublist(0, i), tags[i].copyWith(markedForRemoval: false), ...tags.sublist(i + 1)]);
    _afterFrame(() => _editorKey.currentState?.focusRemoveButton(i));
  }

  void _setKey(int i, String v) {
    _setDirty(i);
    final tags = widget.tags;
    _fire([...tags.sublist(0, i), tags[i].copyWith(key: v), ...tags.sublist(i + 1)]);
  }

  void _blurKey(int i) {
    if (_dirty(i)) return;
    _setDirty(i);
    _fire([...widget.tags]);
  }

  void _setValue(int i, String v) {
    final tags = widget.tags;
    _fire([...tags.sublist(0, i), tags[i].copyWith(value: v), ...tags.sublist(i + 1)]);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.i18nStrings;
    if (widget.loading) {
      return Semantics(
        liveRegion: true,
        child: CsStatusIndicator(type: CsStatusType.loading, text: s.loading),
      );
    }
    final tags = widget.tags;
    final errors = _validate(tags);
    final remaining = widget.tagLimit - tags.where((t) => !t.markedForRemoval).length;
    final cs = context.cs;
    final secondary = cs.text(CsTypeScale.bodyS, color: CsColor.textFormSecondary);

    final Widget info = remaining < 0
        ? CsEditorsMessage(text: s.exceededText(widget.tagLimit), warning: false, iconLabel: s.errorIconAriaLabel)
        : Text(
            remaining == 0 ? s.reachedText(widget.tagLimit) : s.limitText(remaining, widget.tagLimit),
            style: secondary,
          );

    return CsAttributeEditor<int>(
      key: _editorKey,
      items: [for (var i = 0; i < tags.length; i++) i],
      addButtonText: s.addButton,
      removeButtonText: s.removeButton,
      removeButtonAriaLabel: (i) => s.removeButtonAriaLabel?.call(tags[i]) ?? 'Remove ${tags[i].key}',
      isItemRemovable: (i) => !tags[i].markedForRemoval,
      disableAddButton: remaining <= 0,
      empty: Text(s.emptyTags),
      additionalInfo: info,
      onAddButtonClick: _add,
      onRemoveButtonClick: _remove,
      i18nStrings: CsAttributeEditorI18nStrings(
        errorIconAriaLabel: s.errorIconAriaLabel,
        itemRemovedAriaLive: s.itemRemovedAriaLive,
        removeButtonText: s.removeButton,
      ),
      definition: [
        CsAttributeEditorField<int>(
          label: s.keyHeader,
          errorText: (i, _) => errors[i]?.key,
          control: (i, _) => _TagField(
            key: ValueKey('key-$i'),
            value: tags[i].key,
            readOnly: tags[i].existing,
            invalid: errors[i]?.key != null,
            placeholder: s.keyPlaceholder,
            ariaLabel: s.keyHeader,
            focusNode: _nodeIn(_keyNodes, i, 'key'),
            loadingText: s.keysSuggestionLoading,
            errorText: s.keysSuggestionError,
            suggestionText: s.keySuggestion,
            tooManySuggestionText: s.tooManyKeysSuggestion,
            enteredTextLabel: s.enteredKeyLabel,
            clearAriaLabel: s.clearAriaLabel,
            initialOptions: _initialKeyOptions,
            onOptionsLoaded: (o) => _initialKeyOptions = o,
            onRequest: widget.keysRequest,
            onChange: (v) => _setKey(i, v),
            onBlur: () => _blurKey(i),
          ),
        ),
        CsAttributeEditorField<int>(
          labelWidget: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${s.valueHeader} - '),
                TextSpan(
                  text: s.optional,
                  style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
          label: '${s.valueHeader} - ${s.optional}',
          errorText: (i, _) => errors[i]?.value,
          control: (i, _) => tags[i].markedForRemoval
              ? Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: CsSpace.xxs),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: CsSpace.xxs,
                      children: [
                        Text(s.undoPrompt, style: cs.body),
                        CsLink(
                          text: s.undoButton,
                          variant: CsLinkVariant.primary,
                          focusNode: _nodeIn(_undoNodes, i, 'undo'),
                          onFollow: () => _undo(i),
                        ),
                      ],
                    ),
                  ),
                )
              : _TagField(
                  key: ValueKey('value-$i'),
                  value: tags[i].value,
                  invalid: errors[i]?.value != null,
                  placeholder: s.valuePlaceholder,
                  ariaLabel: s.valueHeader,
                  focusNode: _nodeIn(_valueNodes, i, 'value'),
                  loadingText: s.valuesSuggestionLoading,
                  errorText: s.valuesSuggestionError,
                  suggestionText: s.valueSuggestion,
                  tooManySuggestionText: s.tooManyValuesSuggestion,
                  enteredTextLabel: s.enteredValueLabel,
                  clearAriaLabel: s.clearAriaLabel,
                  initialOptions: tags[i].valueSuggestionOptions ?? const [],
                  filteringKey: tags[i].key,
                  onRequest: widget.valuesRequest == null ? null : (v) => widget.valuesRequest!(tags[i].key, v),
                  onChange: (v) => _setValue(i, v),
                ),
        ),
      ],
    );
  }
}

enum _Status { idle, loading, error }

/// A key or value field with a suggestion list (a small local autosuggest:
/// `CsFieldBox` + `CsEditable` + `CsDropdown`).
class _TagField extends StatefulWidget {
  const _TagField({
    super.key,
    required this.value,
    required this.focusNode,
    required this.onChange,
    required this.loadingText,
    required this.errorText,
    required this.suggestionText,
    required this.tooManySuggestionText,
    required this.initialOptions,
    this.readOnly = false,
    this.invalid = false,
    this.placeholder,
    this.ariaLabel,
    this.enteredTextLabel,
    this.clearAriaLabel,
    this.onRequest,
    this.onBlur,
    this.onOptionsLoaded,
    this.filteringKey,
  });

  final String value;
  final FocusNode focusNode;
  final ValueChanged<String> onChange;
  final String loadingText;
  final String errorText;
  final String suggestionText;
  final String tooManySuggestionText;
  final List<String> initialOptions;
  final bool readOnly;
  final bool invalid;
  final String? placeholder;
  final String? ariaLabel;
  final String Function(String text)? enteredTextLabel;
  final String? clearAriaLabel;
  final Future<List<String>> Function(String text)? onRequest;
  final VoidCallback? onBlur;
  final ValueChanged<List<String>>? onOptionsLoaded;
  final String? filteringKey;

  @override
  State<_TagField> createState() => _TagFieldState();
}

class _TagFieldState extends State<_TagField> with CsTextFieldState<_TagField> {
  // Cloudscape stops listing suggestions past this many (`limit={200}`).
  static const int _limit = 200;

  bool _open = false;
  int _highlight = -1;
  _Status _status = _Status.idle;
  late List<String> _options = widget.initialOptions;
  int _request = 0;
  String? _lastQuery;
  String? _lastKey;

  @override
  String get value => widget.value;

  @override
  FocusNode get externalFocusNode => widget.focusNode;

  @override
  void onFocusChange(bool hasFocus) {
    if (hasFocus) {
      if (widget.readOnly) return;
      setState(() => _open = true);
      _load('');
    } else {
      setState(() => _open = false);
      widget.onBlur?.call();
    }
  }

  void _load(String text) {
    final request = widget.onRequest;
    if (request == null || (_lastQuery == text && _lastKey == widget.filteringKey)) return;
    if (_lastKey != widget.filteringKey && _lastKey != null) _options = const [];
    _lastQuery = text;
    _lastKey = widget.filteringKey;
    final id = ++_request;
    setState(() => _status = _Status.loading);
    request(text).then(
      (values) {
        if (!mounted || id != _request) return;
        setState(() {
          _status = _Status.idle;
          _options = values;
        });
        if (text.isEmpty) widget.onOptionsLoaded?.call(values);
      },
      onError: (Object _) {
        if (!mounted || id != _request) return;
        setState(() => _status = _Status.error);
      },
    );
  }

  List<String> get _filtered {
    if (_options.length >= _limit) return const [];
    final q = widget.value.toLowerCase();
    return [
      for (final o in _options)
        if (q.isEmpty || o.toLowerCase().contains(q)) o,
    ];
  }

  /// The entered-text option, then the matching suggestions.
  List<String> get _rows => [if (widget.value.isNotEmpty) widget.value, ..._filtered.where((o) => o != widget.value)];

  void _change(String v) {
    widget.onChange(v);
    setState(() {
      _open = true;
      _highlight = -1;
    });
    _load(v);
  }

  void _select(String v) {
    widget.onChange(v);
    setState(() {
      _open = false;
      _highlight = -1;
    });
    focusNode.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (widget.readOnly) return KeyEventResult.ignored;
    final rows = _rows;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
      if (!_open) {
        setState(() => _open = true);
        return KeyEventResult.handled;
      }
      if (rows.isEmpty) return KeyEventResult.handled;
      final step = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      setState(() => _highlight = (_highlight + step) % rows.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter && _open && _highlight >= 0 && _highlight < rows.length) {
      _select(rows[_highlight]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _menu(BuildContext context) {
    final cs = context.cs;
    final rows = _rows;
    final children = <Widget>[
      for (var i = 0; i < rows.length; i++)
        CsMenuRow(
          label: i == 0 && widget.value.isNotEmpty
              ? (widget.enteredTextLabel?.call(widget.value) ?? 'Use: "${widget.value}"')
              : rows[i],
          highlighted: i == _highlight,
          canRequestFocus: false,
          onHover: (h) {
            if (h) setState(() => _highlight = i);
          },
          onPress: () => _select(rows[i]),
        ),
    ];
    final footerStyle = cs.text(CsTypeScale.bodyM, color: CsColor.textDropdownFooter);
    Widget? footer;
    if (_status == _Status.loading) {
      footer = Row(
        spacing: CsSpace.xs,
        children: [
          const CsSpinner(),
          Flexible(child: Text(widget.loadingText, style: footerStyle)),
        ],
      );
    } else if (_status == _Status.error) {
      footer = CsEditorsMessage(text: widget.errorText, warning: false);
    } else if (_options.length >= _limit) {
      footer = Text(widget.tooManySuggestionText, style: footerStyle);
    } else if (_filtered.isEmpty) {
      footer = Text(widget.suggestionText, style: footerStyle);
    }
    if (footer != null) {
      children.add(
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: CsSpace.fieldHorizontal, vertical: CsSpace.xs),
            child: footer,
          ),
        ),
      );
    }
    return CsMenuPanel(maxHeight: 240, children: children);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final showClear = widget.value.isNotEmpty && !widget.readOnly;
    final field = Semantics(
      textField: true,
      readOnly: widget.readOnly,
      label: widget.ariaLabel,
      expanded: widget.readOnly ? null : _open,
      child: CsFieldBox(
        focused: focused,
        readOnly: widget.readOnly,
        status: widget.invalid ? CsFieldStatus.invalid : CsFieldStatus.none,
        trailing: showClear
            ? Padding(
                padding: const EdgeInsetsDirectional.only(end: CsSpace.xs),
                child: CsButton(
                  icon: CsIcons.close,
                  variant: CsButtonVariant.inlineIcon,
                  semanticLabel: widget.clearAriaLabel ?? context.csStrings.clear,
                  onPress: () => _change(''),
                ),
              )
            : null,
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: CsEditable(
            controller: controller,
            focusNode: focusNode,
            placeholder: widget.placeholder,
            readOnly: widget.readOnly,
            color: widget.invalid ? CsColor.textStatusError : CsColor.textBodyDefault,
            onChanged: _change,
            onTapOutside: (_) {},
            onTap: () {
              if (!_open && !widget.readOnly) setState(() => _open = true);
            },
          ),
        ),
      ),
    );
    if (widget.readOnly) return field;
    return CsDropdown(
      open: _open && focused,
      presentation: CsPresentation.popover,
      onDismiss: () => setState(() => _open = false),
      contentBuilder: (context, _) => DefaultTextStyle.merge(style: cs.body, child: _menu(context)),
      child: field,
    );
  }
}
