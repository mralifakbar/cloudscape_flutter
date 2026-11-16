import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'cs_editor_utils.dart';
import 'cs_file.dart';
import 'cs_file_dropzone.dart';
import 'cs_file_input.dart';
import 'cs_file_token_group.dart';

/// Copy and formatters for [CsFileUpload] (Cloudscape
/// `FileUploadProps.I18nStrings`).
@immutable
class CsFileUploadI18nStrings {
  const CsFileUploadI18nStrings({
    this.uploadButtonText,
    this.dropzoneText,
    this.removeFileAriaLabel,
    this.limitShowFewer = 'Show fewer',
    this.limitShowMore = 'Show more',
    this.errorIconAriaLabel,
    this.warningIconAriaLabel,
    this.formatFileSize,
    this.formatFileLastModified,
  });

  /// Button text by plurality. Defaults to "Choose file" / "Choose files".
  final String Function(bool multiple)? uploadButtonText;

  /// Dropzone text by plurality. Defaults to "Drop file to upload" /
  /// "Drop files to upload".
  final String Function(bool multiple)? dropzoneText;

  /// Accessible name of a token's remove button. Gets the zero-based index
  /// and file name. Defaults to "Remove file 1".
  final String Function(int fileIndex, String fileName)? removeFileAriaLabel;
  final String limitShowFewer;
  final String limitShowMore;
  final String? errorIconAriaLabel;
  final String? warningIconAriaLabel;
  final String Function(int sizeInBytes)? formatFileSize;
  final String Function(DateTime date)? formatFileLastModified;

  String buttonText(bool multiple) => uploadButtonText?.call(multiple) ?? (multiple ? 'Choose files' : 'Choose file');

  String dropText(bool multiple) =>
      dropzoneText?.call(multiple) ?? (multiple ? 'Drop files to upload' : 'Drop file to upload');
}

/// Cloudscape's `FileUpload`: a "Choose file" button, its constraint and
/// validation text, and the chosen files as tokens.
///
/// It is controlled: [value] holds the files and [onChange] gets the next
/// list. Picking with `multiple: true` adds to the list; otherwise the new
/// file replaces it. The package has no picker, so [onPick] opens the app's
/// own.
///
/// ```dart
/// CsFormField(
///   label: 'Certificate',
///   child: CsFileUpload(
///     value: files,
///     accept: '.pem,.crt',
///     constraintText: 'PEM or CRT, up to 1 MB.',
///     showFileSize: true,
///     onPick: (request) => myPicker(multiple: request.multiple),
///     onChange: (files) => setState(() => this.files = files),
///   ),
/// )
/// ```
///
/// While files are dragged over the app, set [dropzoneActive] (from a drag
/// and drop plugin) to swap the button for a `CsFileDropzone`, as Cloudscape
/// does; the plugin's drop handler calls [onChange] with the merged list. In-app `Draggable<CsFile>` drags
/// are merged for you.
class CsFileUpload extends StatelessWidget {
  const CsFileUpload({
    super.key,
    required this.value,
    this.onChange,
    this.onPick,
    this.accept,
    this.multiple = false,
    this.ariaRequired = false,
    this.showFileSize = false,
    this.showFileLastModified = false,
    this.showFileThumbnail = false,
    this.tokenLimit,
    this.constraintText,
    this.errorText,
    this.warningText,
    this.fileErrors,
    this.fileWarnings,
    this.fileLoading,
    this.fileTokenAlignment = CsFileTokenGroupAlignment.vertical,
    this.dropzoneActive = false,
    this.invalid = false,
    this.disabled = false,
    this.readOnly = false,
    this.focusNode,
    this.i18nStrings = const CsFileUploadI18nStrings(),
  });

  final List<CsFile> value;
  final ValueChanged<List<CsFile>>? onChange;

  /// Opens the app's picker. Null disables the button.
  final CsFilePicker? onPick;

  /// Allow-list of types passed to [onPick] (`'image/*,.pdf'`).
  final String? accept;
  final bool multiple;
  final bool ariaRequired;
  final bool showFileSize;
  final bool showFileLastModified;
  final bool showFileThumbnail;

  /// Maximum number of tokens shown before "Show more".
  final int? tokenLimit;

  /// File type and size rules, under the button.
  final String? constraintText;
  final String? errorText;

  /// Shown when there is no [errorText].
  final String? warningText;

  /// Per-file errors, by index into [value].
  final List<String?>? fileErrors;

  /// Per-file warnings, by index into [value].
  final List<String?>? fileWarnings;

  /// Per-file upload progress flags, by index into [value] (an extra over
  /// Cloudscape, which only exposes this on `FileTokenGroup`).
  final List<bool>? fileLoading;
  final CsFileTokenGroupAlignment fileTokenAlignment;

  /// Files are being dragged over the app: show the dropzone in place of the
  /// button.
  final bool dropzoneActive;

  /// Marks the input invalid for assistive technology. [errorText] and
  /// [fileErrors] imply it.
  final bool invalid;
  final bool disabled;

  /// Tokens cannot be removed and the button is disabled.
  final bool readOnly;
  final FocusNode? focusNode;
  final CsFileUploadI18nStrings i18nStrings;

  void _add(List<CsFile> files) {
    if (files.isEmpty) return;
    onChange?.call(multiple ? [...value, ...files] : files.take(1).toList());
  }

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null || (fileErrors?.any((e) => e != null) ?? false);
    final showWarning = warningText != null && errorText == null;
    final hints = <Widget>[
      if (errorText != null)
        CsEditorsMessage(text: errorText!, warning: false, iconLabel: i18nStrings.errorIconAriaLabel),
      if (showWarning) CsEditorsMessage(text: warningText!, warning: true, iconLabel: i18nStrings.warningIconAriaLabel),
      if (constraintText != null)
        Text(constraintText!, style: context.cs.text(CsTypeScale.bodyS, color: CsColor.textFormSecondary)),
    ];
    final picker = dropzoneActive
        ? CsFileDropzone(active: true, multiple: multiple, onChange: _add, child: Text(i18nStrings.dropText(multiple)))
        : DragTarget<Object>(
            onWillAcceptWithDetails: (d) => d.data is CsFile || d.data is List<CsFile>,
            onAcceptWithDetails: (d) => _add(d.data is CsFile ? [d.data as CsFile] : d.data as List<CsFile>),
            builder: (context, candidates, _) => candidates.isNotEmpty
                ? CsFileDropzone(active: true, multiple: multiple, child: Text(i18nStrings.dropText(multiple)))
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: CsFileInput(
                      value: value,
                      text: i18nStrings.buttonText(multiple),
                      accept: accept,
                      multiple: multiple,
                      ariaRequired: ariaRequired,
                      invalid: invalid || hasError,
                      warning: showWarning,
                      disabled: disabled || readOnly,
                      focusNode: focusNode,
                      onPick: onPick,
                      onChange: _add,
                    ),
                  ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: CsSpace.xs,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            picker,
            if (hints.isNotEmpty) ...[
              const SizedBox(height: CsSpace.staticXxs),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: hints),
            ],
          ],
        ),
        if (value.isNotEmpty)
          CsFileTokenGroup(
            items: [
              for (var i = 0; i < value.length; i++)
                CsFileTokenGroupItem(
                  file: value[i],
                  errorText: fileErrors != null && i < fileErrors!.length ? fileErrors![i] : null,
                  warningText: fileWarnings != null && i < fileWarnings!.length ? fileWarnings![i] : null,
                  loading: fileLoading != null && i < fileLoading!.length && fileLoading![i],
                ),
            ],
            limit: tokenLimit,
            alignment: fileTokenAlignment,
            readOnly: readOnly,
            showFileSize: showFileSize,
            showFileLastModified: showFileLastModified,
            showFileThumbnail: showFileThumbnail,
            onDismiss: disabled ? null : (i) => onChange?.call([...value]..removeAt(i)),
            i18nStrings: CsFileTokenGroupI18nStrings(
              limitShowFewer: i18nStrings.limitShowFewer,
              limitShowMore: i18nStrings.limitShowMore,
              removeFileAriaLabel: i18nStrings.removeFileAriaLabel ?? (i, _) => 'Remove file ${i + 1}',
              errorIconAriaLabel: i18nStrings.errorIconAriaLabel,
              warningIconAriaLabel: i18nStrings.warningIconAriaLabel,
              formatFileSize: i18nStrings.formatFileSize,
              formatFileLastModified: i18nStrings.formatFileLastModified,
            ),
          ),
      ],
    );
  }
}
