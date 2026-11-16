import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icons.g.dart';
import '../system/cs_strings.dart';
import 'cs_file.dart';

/// Look of a [CsFileInput] (Cloudscape `variant`).
enum CsFileInputVariant {
  /// A normal button with an upload icon and text.
  button,

  /// An icon-only button. Needs an `ariaLabel`.
  icon,
}

/// Cloudscape's `FileInput`: a button that opens a file picker. Use it on
/// its own in custom upload flows, or through `CsFileUpload`, which adds the
/// file tokens and validation.
///
/// The package has no file picker dependency, so the button calls [onPick]
/// with what to pick and the app opens its own picker; the files it returns
/// go to [onChange].
///
/// ```dart
/// CsFileInput(
///   text: 'Choose file',
///   value: files,
///   accept: 'image/*',
///   onPick: (request) => myPicker(multiple: request.multiple),
///   onChange: (files) => setState(() => this.files = files),
/// )
/// ```
class CsFileInput extends StatelessWidget {
  const CsFileInput({
    super.key,
    required this.value,
    this.onPick,
    this.onChange,
    this.text,
    this.variant = CsFileInputVariant.button,
    this.ariaLabel,
    this.accept,
    this.multiple = false,
    this.ariaRequired = false,
    this.invalid = false,
    this.warning = false,
    this.disabled = false,
    this.focusNode,
  }) : assert(variant == CsFileInputVariant.button || ariaLabel != null, 'Icon file inputs need an ariaLabel');

  /// The selected files. The input itself shows nothing of them; pair it
  /// with `CsFileTokenGroup` or use `CsFileUpload`.
  final List<CsFile> value;

  /// Opens the app's picker. Null renders the button disabled.
  final CsFilePicker? onPick;

  /// Called with the files the picker returned (not merged with [value];
  /// `CsFileUpload` does the merging).
  final ValueChanged<List<CsFile>>? onChange;

  /// Button text (Cloudscape `children`), also the accessible name when
  /// there is no [ariaLabel].
  final String? text;
  final CsFileInputVariant variant;
  final String? ariaLabel;

  /// The allow-list of types handed to [onPick] (`'image/*,.pdf'`).
  final String? accept;

  /// Let the user pick more than one file.
  final bool multiple;

  /// Announces the input as required.
  final bool ariaRequired;

  /// The field is invalid; announced with the button.
  final bool invalid;
  final bool warning;
  final bool disabled;
  final FocusNode? focusNode;

  Future<void> _pick() async {
    final files = await onPick!(CsFilePickRequest(multiple: multiple, accept: accept));
    if (files == null || files.isEmpty) return;
    onChange?.call(multiple ? files : files.take(1).toList());
  }

  @override
  Widget build(BuildContext context) {
    final label = ariaLabel ?? text;
    final strings = context.csStrings;
    final hint = [if (ariaRequired) strings.required, if (invalid) strings.error].join(', ');
    return Semantics(
      hint: hint.isEmpty ? null : hint,
      child: CsButton(
        text: variant == CsFileInputVariant.button ? text : null,
        icon: CsIcons.upload,
        variant: variant == CsFileInputVariant.icon ? CsButtonVariant.icon : CsButtonVariant.normal,
        semanticLabel: label,
        disabled: disabled || onPick == null,
        focusNode: focusNode,
        onPress: onPick == null ? null : _pick,
      ),
    );
  }
}
