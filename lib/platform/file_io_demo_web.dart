// Web fallback for the file-I/O demo (no dart:io on web).
//
// Browsers have no synchronous filesystem, so we reproduce the equivalent
// heavy main-thread work to still surface a performance issue in Sentry.

/// Builds a large string on the main thread (mirrors the native file write/read
/// size) so the "main thread blocking" performance demo still triggers on web.
int performFileIODemo() {
  final content = List.filled(500000, 'Plant data ').join();
  // Touch the data so the work isn't optimized away.
  return content.length;
}

/// No-op on web (the standalone instrumented file example is native-only).
Future<void> sentryFileExample() async {}
