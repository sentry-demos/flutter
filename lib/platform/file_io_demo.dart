// Cross-platform entry point for the file-I/O demo (main-thread blocking).
//
// On mobile/desktop this performs real instrumented `dart:io` file I/O via
// `sentry_file`. On web (no `dart:io`) it falls back to equivalent heavy
// main-thread work so the performance demo still triggers.
export 'file_io_demo_io.dart' if (dart.library.js_interop) 'file_io_demo_web.dart';
