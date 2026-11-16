import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../forms/cs_form_field.dart';
import '../forms/cs_input.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../layout/cs_header.dart';
import '../navigation/cs_link.dart';
import '../overlays/cs_dropdown.dart';
import '../overlays/cs_menu_parts.dart';
import '../status/cs_status_indicator.dart';
import '../system/cs_field_box.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';
import 'cs_collection.dart';
import 'cs_collection_internal.dart';
import 'cs_collection_types.dart';
import 'cs_table.dart';

/// Item types that can be chosen in the browse modal (Cloudscape
/// `SelectableItems`).
enum CsS3SelectableItems { buckets, objects, versions }

/// A bucket (Cloudscape `S3ResourceSelectorProps.Bucket`).
@immutable
class CsS3Bucket {
  const CsS3Bucket({required this.name, this.creationDate, this.region});

  final String name;

  /// Shown as given.
  final String? creationDate;
  final String? region;
}

/// An object or a folder prefix (Cloudscape `S3ResourceSelectorProps.Object`).
@immutable
class CsS3Object {
  const CsS3Object({required this.key, this.lastModified, this.size, this.isFolder = false});

  final String key;
  final String? lastModified;

  /// Size in bytes.
  final int? size;
  final bool isFolder;
}

/// A version of an object (Cloudscape `S3ResourceSelectorProps.Version`).
@immutable
class CsS3Version {
  const CsS3Version({required this.versionId, this.lastModified, this.size});

  final String versionId;
  final String? lastModified;
  final int? size;
}

/// The selected resource (Cloudscape `Resource`).
@immutable
class CsS3Resource {
  const CsS3Resource({required this.uri, this.versionId});

  /// An `s3://bucket/path` URI.
  final String uri;
  final String? versionId;

  @override
  bool operator ==(Object other) => other is CsS3Resource && other.uri == uri && other.versionId == versionId;

  @override
  int get hashCode => Object.hash(uri, versionId);

  @override
  String toString() => 'CsS3Resource($uri${versionId == null ? '' : ', $versionId'})';
}

/// A change of the selected resource (Cloudscape `ChangeDetail`).
@immutable
class CsS3ResourceChange {
  const CsS3ResourceChange({required this.resource, this.errorText});

  final CsS3Resource resource;

  /// A validation message for the URI, or null when it is valid. Show it in
  /// the surrounding form field.
  final String? errorText;
}

/// Copy for [CsS3ResourceSelector] (Cloudscape's English messages).
@immutable
class CsS3ResourceSelectorI18nStrings {
  const CsS3ResourceSelectorI18nStrings({
    this.inContextInputClearAriaLabel = 'Clear',
    this.inContextSelectPlaceholder = 'Choose a version',
    this.inContextBrowseButton = 'Browse S3',
    this.inContextViewButton = 'View',
    this.inContextViewButtonAriaLabel = 'View (opens in a new tab)',
    this.inContextLoadingText = 'Loading resource',
    this.inContextUriLabel = 'S3 URI',
    this.inContextVersionSelectLabel = 'Object version',
    this.modalTitle = 'Choose an object in S3',
    this.modalCancelButton = 'Cancel',
    this.modalSubmitButton = 'Choose',
    this.modalBreadcrumbRootItem = 'S3 buckets',
    this.modalLastUpdatedText = 'Last updated',
    this.selectionBuckets = 'Buckets',
    this.selectionObjects = 'Objects',
    this.selectionVersions = 'Versions',
    this.selectionBucketsSearchPlaceholder = 'Find bucket',
    this.selectionObjectsSearchPlaceholder = 'Find object by prefix',
    this.selectionVersionsSearchPlaceholder = 'Find version',
    this.selectionBucketsLoading = 'Loading buckets',
    this.selectionBucketsNoItems = 'No buckets',
    this.selectionObjectsLoading = 'Loading objects',
    this.selectionObjectsNoItems = 'No objects',
    this.selectionVersionsLoading = 'Loading versions',
    this.selectionVersionsNoItems = 'No versions',
    this.filteringNoMatches = 'No matches',
    this.filteringCantFindMatch = "We can't find a match.",
    this.clearFilterButtonText = 'Clear filter',
    this.columnBucketName = 'Name',
    this.columnBucketCreationDate = 'Creation date',
    this.columnBucketRegion = 'Region',
    this.columnObjectKey = 'Key',
    this.columnObjectLastModified = 'Last modified',
    this.columnObjectSize = 'Size',
    this.columnVersionID = 'Version ID',
    this.columnVersionLastModified = 'Last modified',
    this.columnVersionSize = 'Size',
    this.validationPathMustBegin = 'The path must begin with s3:// to be valid.',
    this.validationBucketLowerCase = 'The bucket name must start with a lowercase character or number.',
    this.validationBucketMustNotContain = 'The bucket name must not contain uppercase characters.',
    this.validationBucketLength = 'The bucket name must be from 3 to 63 characters.',
    this.validationBucketMustComplyDns = 'The bucket name must comply with DNS naming conventions.',
    this.labelRefresh = 'Refresh the data',
    this.labelModalDismiss = 'Close',
    this.labelBreadcrumbs = 'S3 Breadcrumbs',
    this.labelIconObject = 'Object',
    this.labelIconFolder = 'Folder',
    this.labelPreviousPage = 'Previous page',
    this.labelNextPage = 'Next page',
    this.filteringCounterText = _count,
    this.labelFiltering = _filtering,
  });

  final String inContextInputClearAriaLabel;
  final String inContextSelectPlaceholder;
  final String inContextBrowseButton;
  final String inContextViewButton;
  final String inContextViewButtonAriaLabel;
  final String inContextLoadingText;
  final String inContextUriLabel;
  final String inContextVersionSelectLabel;
  final String modalTitle;
  final String modalCancelButton;
  final String modalSubmitButton;
  final String modalBreadcrumbRootItem;
  final String modalLastUpdatedText;
  final String selectionBuckets;
  final String selectionObjects;
  final String selectionVersions;
  final String selectionBucketsSearchPlaceholder;
  final String selectionObjectsSearchPlaceholder;
  final String selectionVersionsSearchPlaceholder;
  final String selectionBucketsLoading;
  final String selectionBucketsNoItems;
  final String selectionObjectsLoading;
  final String selectionObjectsNoItems;
  final String selectionVersionsLoading;
  final String selectionVersionsNoItems;
  final String filteringNoMatches;
  final String filteringCantFindMatch;
  final String clearFilterButtonText;
  final String columnBucketName;
  final String columnBucketCreationDate;
  final String columnBucketRegion;
  final String columnObjectKey;
  final String columnObjectLastModified;
  final String columnObjectSize;
  final String columnVersionID;
  final String columnVersionLastModified;
  final String columnVersionSize;
  final String validationPathMustBegin;
  final String validationBucketLowerCase;
  final String validationBucketMustNotContain;
  final String validationBucketLength;
  final String validationBucketMustComplyDns;
  final String labelRefresh;
  final String labelModalDismiss;
  final String labelBreadcrumbs;
  final String labelIconObject;
  final String labelIconFolder;
  final String labelPreviousPage;
  final String labelNextPage;
  final String Function(int count) filteringCounterText;
  final String Function(String itemsType) labelFiltering;

  static String _count(int count) => count == 1 ? '1 match' : '$count matches';
  static String _filtering(String itemsType) => 'Find $itemsType';
}

/// Validates an S3 URI the way Cloudscape's selector does and returns the
/// message for the first rule it breaks, or null when it is valid (an empty
/// URI is valid).
String? csS3ValidateUri(String uri, [CsS3ResourceSelectorI18nStrings s = const CsS3ResourceSelectorI18nStrings()]) {
  const scheme = 's3://';
  if (uri.isEmpty) return null;
  if (!uri.startsWith(scheme)) return s.validationPathMustBegin;
  final bucket = csS3SplitUri(uri).$1;
  if (!RegExp(r'^[a-z0-9]').hasMatch(bucket)) return s.validationBucketLowerCase;
  if (RegExp('[A-Z]').hasMatch(bucket)) return s.validationBucketMustNotContain;
  if (bucket.length < 3 || bucket.length > 63) return s.validationBucketLength;
  final dns = RegExp(r'^(([a-z0-9]|[a-z0-9][a-z0-9-]*[a-z0-9])\.)*([a-z0-9]|[a-z0-9][a-z0-9-]*[a-z0-9])$');
  if (!dns.hasMatch(bucket)) return s.validationBucketMustComplyDns;
  return null;
}

/// Splits an S3 URI into the bucket name and the object path.
(String, String) csS3SplitUri(String uri) {
  final parts = uri.replaceFirst('s3://', '').split('/');
  return (parts.first, parts.skip(1).join('/'));
}

/// Formats a byte count the way Cloudscape's selector does ("1.5 KB").
String csS3FormatSize(int? bytes) {
  if (bytes == null) return '-';
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  if (bytes == 0) return '0 Bytes';
  final i = (math.log(bytes) / math.log(1024)).floor().clamp(0, sizes.length - 1);
  final value = bytes / math.pow(1024, i);
  var text = value.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  return '$text ${sizes[i]}';
}

String _join(List<String> segments) {
  var out = '';
  for (final s in segments) {
    if (out.isNotEmpty && !out.endsWith('/')) out += '/';
    out += s;
  }
  return out;
}

/// Cloudscape's `S3ResourceSelector`: an S3 URI input with a Browse button
/// that opens a modal to pick a bucket, object or object version, plus an
/// optional version picker and View button.
///
/// ```dart
/// CsS3ResourceSelector(
///   resource: resource,
///   selectableItemsTypes: const {CsS3SelectableItems.objects, CsS3SelectableItems.versions},
///   fetchBuckets: api.listBuckets,
///   fetchObjects: api.listObjects,
///   fetchVersions: api.listVersions,
///   onChange: (change) => setState(() {
///     resource = change.resource;
///     error = change.errorText;
///   }),
/// )
/// ```
///
/// Data comes from the fetch callbacks; the component lists, filters, sorts
/// and pages it. Wrap it in a [CsFormField] to show [CsS3ResourceChange.errorText].
class CsS3ResourceSelector extends StatefulWidget {
  const CsS3ResourceSelector({
    super.key,
    required this.resource,
    required this.fetchBuckets,
    required this.fetchObjects,
    required this.fetchVersions,
    this.onChange,
    this.selectableItemsTypes = const {},
    this.alert,
    this.ariaLabel,
    this.inputPlaceholder,
    this.onView,
    this.invalid = false,
    this.bucketsVisibleColumns,
    this.objectsVisibleColumns,
    this.versionsVisibleColumns,
    this.bucketsIsItemDisabled,
    this.objectsIsItemDisabled,
    this.versionsIsItemDisabled,
    this.onInputBlur,
    this.onInputFocus,
    this.i18nStrings = const CsS3ResourceSelectorI18nStrings(),
  });

  final CsS3Resource resource;

  /// Lists every bucket.
  final Future<List<CsS3Bucket>> Function() fetchBuckets;

  /// Lists objects and folders under a path of a bucket.
  final Future<List<CsS3Object>> Function(String bucketName, String pathPrefix) fetchObjects;

  /// Lists the versions of an object.
  final Future<List<CsS3Version>> Function(String bucketName, String pathPrefix) fetchVersions;
  final ValueChanged<CsS3ResourceChange>? onChange;

  /// Which item types can be chosen. Read mode is objects and versions;
  /// write mode is buckets and objects. Empty by default.
  final Set<CsS3SelectableItems> selectableItemsTypes;

  /// Shown in the modal above the table, such as a permissions warning.
  final Widget? alert;
  final String? ariaLabel;
  final String? inputPlaceholder;

  /// Opens the selected object (Cloudscape `viewHref`). Null disables View.
  final VoidCallback? onView;
  final bool invalid;

  /// Visible bucket columns: `Name`, `CreationDate`, `Region`.
  final List<String>? bucketsVisibleColumns;

  /// Visible object columns: `Key`, `LastModified`, `Size`.
  final List<String>? objectsVisibleColumns;

  /// Visible version columns: `ID`, `LastModified`, `Size`.
  final List<String>? versionsVisibleColumns;

  /// Overrides which buckets can be chosen; wins over [selectableItemsTypes].
  final bool Function(CsS3Bucket item)? bucketsIsItemDisabled;
  final bool Function(CsS3Object item)? objectsIsItemDisabled;
  final bool Function(CsS3Version item)? versionsIsItemDisabled;
  final VoidCallback? onInputBlur;
  final VoidCallback? onInputFocus;
  final CsS3ResourceSelectorI18nStrings i18nStrings;

  @override
  State<CsS3ResourceSelector> createState() => CsS3ResourceSelectorState();
}

/// State of a [CsS3ResourceSelector]; [focus] moves focus to the URI input
/// (Cloudscape `S3ResourceSelector.Ref`).
class CsS3ResourceSelectorState extends State<CsS3ResourceSelector> {
  final FocusNode _input = FocusNode(debugLabel: 'CsS3ResourceSelector');
  bool _touched = false;
  bool _loadingVersions = false;
  List<CsS3Version> _versions = const [];
  bool _versionsOpen = false;
  int _versionRequest = 0;

  CsS3ResourceSelectorI18nStrings get _s => widget.i18nStrings;
  bool get _supportsVersions => widget.selectableItemsTypes.contains(CsS3SelectableItems.versions);

  /// Moves focus to the URI input.
  void focus() => _input.requestFocus();

  @override
  void initState() {
    super.initState();
    _input.addListener(_onFocusChange);
    if (_supportsVersions && widget.resource.uri.isNotEmpty) _loadVersions(widget.resource.uri);
  }

  @override
  void dispose() {
    _input.removeListener(_onFocusChange);
    _input.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_input.hasFocus) {
      widget.onInputFocus?.call();
      return;
    }
    setState(() => _touched = true);
    widget.onChange?.call(
      CsS3ResourceChange(resource: widget.resource, errorText: csS3ValidateUri(widget.resource.uri, _s)),
    );
    widget.onInputBlur?.call();
    if (_supportsVersions) _loadVersions(widget.resource.uri);
  }

  Future<void> _loadVersions(String uri) async {
    if (uri.isEmpty || csS3ValidateUri(uri, _s) != null) {
      setState(() => _versions = const []);
      return;
    }
    final request = ++_versionRequest;
    setState(() => _loadingVersions = true);
    try {
      final (bucket, path) = csS3SplitUri(uri);
      final versions = await widget.fetchVersions(bucket, path);
      if (!mounted || request != _versionRequest) return;
      setState(() => _versions = versions);
    } catch (_) {
      // Fetch errors are reported by the caller, outside the component.
      if (mounted && request == _versionRequest) setState(() => _versions = const []);
    } finally {
      if (mounted && request == _versionRequest) setState(() => _loadingVersions = false);
    }
  }

  void _onUriChange(String uri) {
    _versionRequest++;
    setState(() {
      _versions = const [];
      _loadingVersions = false;
    });
    widget.onChange?.call(
      CsS3ResourceChange(
        resource: CsS3Resource(uri: uri),
        errorText: _touched ? csS3ValidateUri(uri, _s) : null,
      ),
    );
  }

  Future<void> _browse() async {
    final result = await showCsCollectionDialog<CsS3Resource>(
      context,
      semanticLabel: _s.modalTitle,
      builder: (context) => CsS3BrowseModal(config: widget),
    );
    if (result == null || !mounted) return;
    widget.onChange?.call(CsS3ResourceChange(resource: result));
    if (_supportsVersions) unawaited(_loadVersions(result.uri));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final uriField = CsFormField(
      label: _s.inContextUriLabel,
      stretch: true,
      child: CsInput(
        value: widget.resource.uri,
        type: CsInputType.search,
        focusNode: _input,
        invalid: widget.invalid,
        placeholder: widget.inputPlaceholder,
        ariaLabel: widget.ariaLabel ?? _s.inContextUriLabel,
        clearAriaLabel: _s.inContextInputClearAriaLabel,
        keyboardType: TextInputType.url,
        onChange: _onUriChange,
      ),
    );
    final version = _supportsVersions
        ? CsFormField(label: _s.inContextVersionSelectLabel, stretch: true, child: _versionPicker(context))
        : null;
    final view = CsButton(
      text: _s.inContextViewButton,
      icon: CsIcons.external,
      iconAlign: CsButtonIconAlign.right,
      semanticLabel: _s.inContextViewButtonAriaLabel,
      onPress: widget.onView,
    );
    final divider = Container(
      width: CsBorderLine.dividerSectionWidth,
      height: 2 * CsBorderLine.dividerSectionWidth + 2 * cs.space.scaledXxs + CsFontTokens.lineHeightBodyM,
      color: cs.colors.borderDividerDefault,
    );
    final browse = CsButton(
      text: _s.inContextBrowseButton,
      onPress: _loadingVersions ? null : _browse,
      disabled: _loadingVersions,
    );
    final buttons = Wrap(
      spacing: CsSpace.m,
      runSpacing: CsSpace.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [view, divider, browse],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: CsSpace.m,
                children: [
                  uriField,
                  ?version,
                  Align(alignment: AlignmentDirectional.centerStart, child: buttons),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: CsSpace.m,
              children: [
                Expanded(child: uriField),
                if (version != null) SizedBox(width: (constraints.maxWidth * 0.2).clamp(140.0, 180.0), child: version),
                buttons,
              ],
            );
          },
        ),
        if (_loadingVersions)
          Padding(
            padding: const EdgeInsets.only(top: CsSpace.s),
            child: Semantics(
              liveRegion: true,
              child: CsStatusIndicator(type: CsStatusType.loading, text: _s.inContextLoadingText),
            ),
          ),
      ],
    );
  }

  Widget _versionPicker(BuildContext context) {
    final cs = context.cs;
    final disabled = _versions.isEmpty;
    final selected = widget.resource.versionId;
    return CsDropdown(
      open: _versionsOpen && !disabled,
      onDismiss: () => setState(() => _versionsOpen = false),
      sheetLabel: _s.inContextVersionSelectLabel,
      contentBuilder: (context, inSheet) => CsMenuPanel(
        semanticLabel: _s.inContextVersionSelectLabel,
        children: [
          for (final v in _versions)
            CsMenuRow(
              label: v.versionId,
              description: v.lastModified,
              selected: v.versionId == selected,
              onPress: () {
                setState(() => _versionsOpen = false);
                widget.onChange?.call(
                  CsS3ResourceChange(
                    resource: CsS3Resource(uri: widget.resource.uri, versionId: v.versionId),
                  ),
                );
              },
            ),
        ],
      ),
      child: CsPressable(
        onPress: disabled ? null : () => setState(() => _versionsOpen = !_versionsOpen),
        disabled: disabled,
        scaleOnPress: false,
        showFocusRing: false,
        expanded: _versionsOpen,
        semanticLabel: _s.inContextVersionSelectLabel,
        semanticValue: selected ?? _s.inContextSelectPlaceholder,
        builder: (context, state) => CsFieldBox(
          focused: state.focused || _versionsOpen,
          disabled: disabled,
          trailing: Padding(
            padding: const EdgeInsetsDirectional.only(end: CsSpace.fieldHorizontal),
            child: CsIcon(CsIcons.caretDownFilled, variant: disabled ? CsIconVariant.disabled : CsIconVariant.normal),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: CsSpace.fieldHorizontal),
            child: Text(
              selected ?? _s.inContextSelectPlaceholder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cs.text(
                CsTypeScale.bodyM,
                color: disabled
                    ? CsColor.textInputPlaceholderDisabled
                    : (selected == null ? CsColor.textInputPlaceholder : CsColor.textBodyDefault),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _View { buckets, objects, versions }

/// The browse modal of [CsS3ResourceSelector]. Exposed for testing and for
/// apps that want to open it on their own; pops with the chosen
/// [CsS3Resource].
class CsS3BrowseModal extends StatefulWidget {
  const CsS3BrowseModal({super.key, required this.config});

  final CsS3ResourceSelector config;

  @override
  State<CsS3BrowseModal> createState() => _CsS3BrowseModalState();
}

class _CsS3BrowseModalState extends State<CsS3BrowseModal> {
  _View _view = _View.buckets;
  List<String> _crumbs = const [];
  String? _selected;

  CsS3ResourceSelector get _c => widget.config;
  CsS3ResourceSelectorI18nStrings get _s => _c.i18nStrings;

  void _go(_View view, List<String> crumbs) => setState(() {
    _view = view;
    _crumbs = crumbs;
    _selected = null;
  });

  void _submit() {
    final s = _selected;
    if (s == null) return;
    final resource = _view == _View.versions
        ? CsS3Resource(uri: 's3://${_join(_crumbs)}', versionId: s)
        : CsS3Resource(uri: 's3://${_join([..._crumbs, s])}');
    Navigator.of(context).pop(resource);
  }

  @override
  Widget build(BuildContext context) {
    final types = _c.selectableItemsTypes;
    Widget table;
    switch (_view) {
      case _View.buckets:
        table = _BrowseTable<CsS3Bucket>(
          key: const ValueKey('buckets'),
          strings: _s,
          title: _s.selectionBuckets,
          loadingText: _s.selectionBucketsLoading,
          emptyText: _s.selectionBucketsNoItems,
          placeholder: _s.selectionBucketsSearchPlaceholder,
          fetch: _c.fetchBuckets,
          trackBy: (b) => b.name,
          field: (b, f) => switch (f) {
            'Name' => b.name,
            'CreationDate' => b.creationDate,
            'Region' => b.region,
            _ => null,
          },
          searchFields: const ['Name'],
          visibleColumns: _c.bucketsVisibleColumns,
          isItemDisabled: _c.bucketsIsItemDisabled ?? (_) => !types.contains(CsS3SelectableItems.buckets),
          onSelect: (b) => setState(() => _selected = b?.name),
          columns: [
            CsTableColumn<CsS3Bucket>(
              id: 'Name',
              header: _s.columnBucketName,
              sortingField: 'Name',
              isRowHeader: true,
              cell: (context, b) => CsLink(text: b.name, onFollow: () => _go(_View.objects, [b.name])),
            ),
            CsTableColumn<CsS3Bucket>(
              id: 'CreationDate',
              header: _s.columnBucketCreationDate,
              sortingField: 'CreationDate',
              cell: (context, b) => Text(b.creationDate ?? '-'),
            ),
            CsTableColumn<CsS3Bucket>(
              id: 'Region',
              header: _s.columnBucketRegion,
              sortingField: 'Region',
              cell: (context, b) => Text(b.region ?? '-'),
            ),
          ],
        );
      case _View.objects:
        final versions = types.contains(CsS3SelectableItems.versions);
        table = _BrowseTable<CsS3Object>(
          key: ValueKey('objects:${_crumbs.join('/')}'),
          strings: _s,
          title: _s.selectionObjects,
          loadingText: _s.selectionObjectsLoading,
          emptyText: _s.selectionObjectsNoItems,
          placeholder: _s.selectionObjectsSearchPlaceholder,
          fetch: () => _c.fetchObjects(_crumbs.first, _join(_crumbs.skip(1).toList())),
          trackBy: (o) => o.key,
          field: (o, f) => switch (f) {
            'Key' => o.key,
            'LastModified' => o.lastModified,
            'Size' => o.size,
            _ => null,
          },
          searchFields: const ['Key'],
          visibleColumns: _c.objectsVisibleColumns,
          isItemDisabled: _c.objectsIsItemDisabled ?? (_) => !types.contains(CsS3SelectableItems.objects),
          onSelect: (o) => setState(() => _selected = o?.key),
          columns: [
            CsTableColumn<CsS3Object>(
              id: 'Key',
              header: _s.columnObjectKey,
              sortingField: 'Key',
              isRowHeader: true,
              cell: (context, o) => Row(
                mainAxisSize: MainAxisSize.min,
                spacing: CsSpace.xs,
                children: [
                  CsIcon(
                    o.isFolder ? CsIcons.folder : CsIcons.file,
                    semanticLabel: o.isFolder ? _s.labelIconFolder : _s.labelIconObject,
                  ),
                  Flexible(
                    child: o.isFolder || versions
                        ? CsLink(
                            text: o.key,
                            onFollow: () => _go(o.isFolder ? _View.objects : _View.versions, [..._crumbs, o.key]),
                          )
                        : Text(o.key),
                  ),
                ],
              ),
            ),
            CsTableColumn<CsS3Object>(
              id: 'LastModified',
              header: _s.columnObjectLastModified,
              sortingField: 'LastModified',
              cell: (context, o) => Text(o.lastModified ?? '-'),
            ),
            CsTableColumn<CsS3Object>(
              id: 'Size',
              header: _s.columnObjectSize,
              sortingField: 'Size',
              cell: (context, o) => Text(o.isFolder ? '-' : csS3FormatSize(o.size)),
            ),
          ],
        );
      case _View.versions:
        table = _BrowseTable<CsS3Version>(
          key: ValueKey('versions:${_crumbs.join('/')}'),
          strings: _s,
          title: _s.selectionVersions,
          loadingText: _s.selectionVersionsLoading,
          emptyText: _s.selectionVersionsNoItems,
          placeholder: _s.selectionVersionsSearchPlaceholder,
          fetch: () => _c.fetchVersions(_crumbs.first, _join(_crumbs.skip(1).toList())),
          trackBy: (v) => v.versionId,
          field: (v, f) => switch (f) {
            'ID' => v.versionId,
            'LastModified' => v.lastModified,
            'Size' => v.size,
            _ => null,
          },
          searchFields: const ['ID'],
          visibleColumns: _c.versionsVisibleColumns,
          isItemDisabled: _c.versionsIsItemDisabled,
          onSelect: (v) => setState(() => _selected = v?.versionId),
          columns: [
            CsTableColumn<CsS3Version>(
              id: 'ID',
              header: _s.columnVersionID,
              sortingField: 'ID',
              isRowHeader: true,
              cell: (context, v) => Text(v.versionId),
            ),
            CsTableColumn<CsS3Version>(
              id: 'LastModified',
              header: _s.columnVersionLastModified,
              sortingField: 'LastModified',
              cell: (context, v) => Text(v.lastModified ?? '-'),
            ),
            CsTableColumn<CsS3Version>(
              id: 'Size',
              header: _s.columnVersionSize,
              sortingField: 'Size',
              cell: (context, v) => Text(csS3FormatSize(v.size)),
            ),
          ],
        );
    }

    return CsCollectionDialogPanel(
      title: _s.modalTitle,
      closeLabel: _s.labelModalDismiss,
      size: CsCollectionDialogSize.max,
      onDismiss: () => Navigator.of(context).maybePop(),
      footer: Wrap(
        alignment: WrapAlignment.end,
        spacing: CsSpace.xs,
        runSpacing: CsSpace.xs,
        children: [
          CsButton(
            text: _s.modalCancelButton,
            variant: CsButtonVariant.link,
            onPress: () => Navigator.of(context).maybePop(),
          ),
          CsButton(
            text: _s.modalSubmitButton,
            variant: CsButtonVariant.primary,
            disabled: _selected == null,
            onPress: _selected == null ? null : _submit,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: CsSpace.xxs,
        children: [_breadcrumbs(context), ?_c.alert, table],
      ),
    );
  }

  /// A local breadcrumb trail: the root item, then each path segment.
  Widget _breadcrumbs(BuildContext context) {
    final cs = context.cs;
    final items = <(String, VoidCallback?)>[
      (_s.modalBreadcrumbRootItem, _crumbs.isEmpty ? null : () => _go(_View.buckets, const [])),
      for (var i = 0; i < _crumbs.length; i++)
        (_crumbs[i], i == _crumbs.length - 1 ? null : () => _go(_View.objects, _crumbs.sublist(0, i + 1))),
    ];
    return Semantics(
      label: _s.labelBreadcrumbs,
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CsSpace.xxs),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: CsSpace.xs,
          runSpacing: CsSpace.xxs,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const CsIcon(CsIcons.angleRight, size: CsIconSize.small, variant: CsIconVariant.subtle),
              if (items[i].$2 == null)
                Text(
                  items[i].$1,
                  style: cs.text(CsTypeScale.bodyM, weight: FontWeight.w700, color: CsColor.textBreadcrumbCurrent),
                )
              else
                CsLink(text: items[i].$1, onFollow: items[i].$2),
            ],
          ],
        ),
      ),
    );
  }
}

/// One of the three browse tables: fetches on mount, then filters, sorts
/// and pages locally with [CsCollection], and reports its single selection.
class _BrowseTable<T> extends StatefulWidget {
  const _BrowseTable({
    super.key,
    required this.strings,
    required this.title,
    required this.loadingText,
    required this.emptyText,
    required this.placeholder,
    required this.fetch,
    required this.trackBy,
    required this.field,
    required this.searchFields,
    required this.columns,
    required this.visibleColumns,
    required this.isItemDisabled,
    required this.onSelect,
  });

  final CsS3ResourceSelectorI18nStrings strings;
  final String title;
  final String loadingText;
  final String emptyText;
  final String placeholder;
  final Future<List<T>> Function() fetch;
  final CsTrackBy<T> trackBy;
  final CsFieldGetter<T> field;
  final List<String> searchFields;
  final List<CsTableColumn<T>> columns;
  final List<String>? visibleColumns;
  final bool Function(T item)? isItemDisabled;
  final ValueChanged<T?> onSelect;

  @override
  State<_BrowseTable<T>> createState() => _BrowseTableState<T>();
}

class _BrowseTableState<T> extends State<_BrowseTable<T>> {
  late final CsCollection<T> _collection;
  bool _loading = false;
  DateTime? _lastUpdated;

  CsS3ResourceSelectorI18nStrings get _s => widget.strings;

  @override
  void initState() {
    super.initState();
    _collection = CsCollection<T>(
      const [],
      getField: widget.field,
      filtering: CsCollectionFiltering<T>(fields: widget.searchFields),
      sorting: const CsCollectionSorting(),
      pagination: const CsCollectionPagination(),
      selection: CsCollectionSelection<T>(trackBy: widget.trackBy),
    );
    _load();
  }

  @override
  void dispose() {
    _collection.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() => _loading = true);
    try {
      final items = await widget.fetch();
      if (!mounted) return;
      _collection.allItems = items;
      if (refresh) _lastUpdated = clock.now();
    } catch (_) {
      // Error handling belongs to the caller, as in Cloudscape.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(List<T> items) {
    _collection.setSelectedItems(items);
    widget.onSelect(items.isEmpty ? null : items.first);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return ListenableBuilder(
      listenable: _collection,
      builder: (context, _) {
        final c = _collection;
        final total = c.allItems.length;
        final selected = c.selectedItems.isNotEmpty;
        final updated = _lastUpdated;
        final empty = c.isFiltered
            ? Column(
                mainAxisSize: MainAxisSize.min,
                spacing: CsSpace.xs,
                children: [
                  Text(
                    _s.filteringNoMatches,
                    style: cs.text(CsTypeScale.bodyM, weight: FontWeight.w700, color: CsColor.textEmpty),
                  ),
                  Text(_s.filteringCantFindMatch),
                  CsButton(
                    text: _s.clearFilterButtonText,
                    onPress: () {
                      c.setFiltering('');
                      widget.onSelect(null);
                    },
                  ),
                ],
              )
            : Text(
                widget.emptyText,
                style: cs.text(CsTypeScale.bodyM, weight: FontWeight.w700, color: CsColor.textEmpty),
              );
        return CsTable<T>(
          variant: CsTableVariant.borderless,
          items: c.items,
          loading: _loading,
          loadingText: widget.loadingText,
          trackBy: widget.trackBy,
          columnDefinitions: widget.columns,
          visibleColumns: widget.visibleColumns,
          selectionType: CsSelectionType.single,
          selectedItems: c.selectedItems,
          onSelectionChange: _select,
          isItemDisabled: widget.isItemDisabled,
          sortingColumn: c.sortingColumn,
          sortingDescending: c.sortingDescending,
          onSortingChange: (s) {
            c.setSorting(s);
            widget.onSelect(null);
          },
          empty: empty,
          ariaLabels: CsTableAriaLabels<T>(tableLabel: widget.title, selectionGroupLabel: widget.title),
          header: CsHeader(
            variant: CsHeaderVariant.h3,
            title: widget.title,
            counter: selected ? '(1/$total)' : '($total)',
            actions: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CsSpace.xs,
              children: [
                if (updated != null)
                  Text(
                    '${_s.modalLastUpdatedText} ${_two(updated.hour)}:${_two(updated.minute)}:${_two(updated.second)}',
                    style: cs.text(CsTypeScale.bodyS, color: CsColor.textBodySecondary),
                  ),
                CsButton(
                  icon: CsIcons.refresh,
                  semanticLabel: _s.labelRefresh,
                  disabled: _loading,
                  onPress: _loading ? null : () => _load(refresh: true),
                ),
              ],
            ),
          ),
          filter: Row(
            spacing: CsSpace.s,
            children: [
              Expanded(
                child: CsInput(
                  value: c.filteringText,
                  type: CsInputType.search,
                  placeholder: widget.placeholder,
                  ariaLabel: _s.labelFiltering(widget.title),
                  onChange: (v) {
                    c.setFiltering(v);
                    widget.onSelect(null);
                  },
                ),
              ),
              if (c.filteringText.isNotEmpty)
                Text(
                  _s.filteringCounterText(c.filteredItemsCount),
                  style: cs.text(CsTypeScale.bodyM, color: CsColor.textBodySecondary),
                ),
            ],
          ),
          pagination: c.pagesCount > 1 ? _pager(context, c) : null,
        );
      },
    );
  }

  Widget _pager(BuildContext context, CsCollection<T> c) {
    final cs = context.cs;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CsButton(
          icon: CsIcons.angleLeft,
          variant: CsButtonVariant.icon,
          semanticLabel: _s.labelPreviousPage,
          disabled: c.currentPageIndex <= 1,
          onPress: c.currentPageIndex <= 1
              ? null
              : () {
                  c.setCurrentPage(c.currentPageIndex - 1);
                  widget.onSelect(null);
                },
        ),
        Text('${c.currentPageIndex} / ${c.pagesCount}', style: cs.body),
        CsButton(
          icon: CsIcons.angleRight,
          variant: CsButtonVariant.icon,
          semanticLabel: _s.labelNextPage,
          disabled: c.currentPageIndex >= c.pagesCount,
          onPress: c.currentPageIndex >= c.pagesCount
              ? null
              : () {
                  c.setCurrentPage(c.currentPageIndex + 1);
                  widget.onSelect(null);
                },
        ),
      ],
    );
  }
}
