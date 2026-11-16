import 'package:flutter/widgets.dart';

/// A file chosen by the user, as the file components show it (the fields of
/// the web `File` that Cloudscape reads).
///
/// The package has no file picker, so the app builds these from its own
/// picker (`file_picker`, `image_picker`, a platform channel, a drag and
/// drop plugin) and keeps whatever it needs to upload in [data].
///
/// ```dart
/// CsFile(
///   name: 'invoice-2024-01.pdf',
///   size: 482133,
///   lastModified: DateTime(2024, 1, 15, 13, 45),
///   type: 'application/pdf',
/// )
/// ```
@immutable
class CsFile {
  const CsFile({required this.name, this.size = 0, this.lastModified, this.type = '', this.thumbnail, this.data});

  /// File name with extension.
  final String name;

  /// Size in bytes.
  final int size;
  final DateTime? lastModified;

  /// MIME type, such as `image/png`. Empty when unknown.
  final String type;

  /// Preview for images, shown when a token group has `showFileThumbnail`
  /// (a `FileImage`, `MemoryImage` or `NetworkImage`).
  final ImageProvider? thumbnail;

  /// App data carried with the file: a path, bytes, a platform handle.
  final Object? data;

  /// Whether [type] is an image type.
  bool get isImage => type.startsWith('image/');

  @override
  bool operator ==(Object other) =>
      other is CsFile &&
      other.name == name &&
      other.size == size &&
      other.lastModified == lastModified &&
      other.type == type &&
      other.thumbnail == thumbnail &&
      other.data == data;

  @override
  int get hashCode => Object.hash(name, size, lastModified, type, thumbnail, data);

  @override
  String toString() => 'CsFile($name, $size bytes)';
}

/// What a file input asks the app's picker for.
@immutable
class CsFilePickRequest {
  const CsFilePickRequest({required this.multiple, this.accept});

  /// More than one file may be chosen.
  final bool multiple;

  /// The allow-list of types, in the web `accept` format
  /// (`'image/*,.pdf'`). Null accepts anything.
  final String? accept;
}

/// Opens the app's own file picker and returns what the user chose, or null
/// (or an empty list) when they cancelled.
typedef CsFilePicker = Future<List<CsFile>?> Function(CsFilePickRequest request);

/// Cloudscape's default file size and date formats
/// (`file-token-group/default-formatters.ts`).
abstract final class CsFileFormat {
  /// `482.13 KB`, `1.20 MB`: decimal units with two decimals.
  static String size(int bytes) {
    const kb = 1000.0;
    const mb = kb * 1000;
    const gb = mb * 1000;
    const tb = gb * 1000;
    if (bytes < mb) return '${(bytes / kb).toStringAsFixed(2)} KB';
    if (bytes < gb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    if (bytes < tb) return '${(bytes / gb).toStringAsFixed(2)} GB';
    return '${(bytes / tb).toStringAsFixed(2)} TB';
  }

  /// `2024-01-15T13:45:00`: ISO date and time without an offset.
  static String lastModified(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}'
        'T${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
  }
}
