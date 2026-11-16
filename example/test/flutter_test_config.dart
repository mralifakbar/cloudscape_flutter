import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads Open Sans so layout checks use real glyph metrics instead of the
/// Ahem test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('packages/cloudscape_flutter/OpenSans');
  for (final f in ['OpenSans-Light.ttf', 'OpenSans-Regular.ttf', 'OpenSans-Bold.ttf']) {
    final bytes = File('../assets/fonts/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
  await testMain();
}
