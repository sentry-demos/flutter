/// Web-safe platform detection.
///
/// Uses `kIsWeb` + `defaultTargetPlatform` from `package:flutter/foundation.dart`
/// so it works on every target (including web) without importing `dart:io`.
/// Native-only string info (Dart/OS version) comes from a conditional import
/// so web builds never reference `dart:io`.
library;

import 'package:flutter/foundation.dart';

export 'native_info_io.dart' if (dart.library.js_interop) 'native_info_web.dart';

bool get isWeb => kIsWeb;
bool get isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
bool get isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
bool get isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);

/// Human-readable platform name, safe on web ("web").
String get platformName => kIsWeb ? 'web' : defaultTargetPlatform.name;
