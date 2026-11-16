import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool _registered = false;

/// Adds the licenses of the bundled Open Sans font (SIL OFL) and of
/// Cloudscape (Apache 2.0, the source of the tokens and icons) to Flutter's
/// license registry, so they appear on `showLicensePage`.
///
/// [CsThemeProvider] calls this once; call it yourself only when you use the
/// package without the provider.
void registerCsLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    for (final (package, file) in const [
      ('Open Sans', 'OpenSans-OFL.txt'),
      ('Cloudscape Design System', 'Cloudscape-Apache-2.0.txt'),
    ]) {
      final text = await rootBundle.loadString('packages/cloudscape_flutter/assets/licenses/$file');
      yield LicenseEntryWithLineBreaks([package], text);
    }
  });
}
