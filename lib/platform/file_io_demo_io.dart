// Native file-I/O demo (mobile/desktop). Uses Sentry's file instrumentation.
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_file/sentry_file.dart';

/// Writes and reads a large file synchronously on the main thread to trigger
/// the "File I/O on Main Thread" performance issue. Returns the byte length.
int performFileIODemo() {
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/plant_cache.txt').sentryTrace();
  file.writeAsStringSync(List.filled(500000, 'Plant data ').join());
  final content = file.readAsStringSync();
  return content.length;
}

/// Standalone instrumented file-operations transaction example.
Future<void> sentryFileExample() async {
  final file = File('my_file.txt');
  final sentryFile = file.sentryTrace();

  await Sentry.startSpan('file_operations_example', (span) async {
    span.setAttribute('sentry.op', SentryAttribute.string('file.io'));
    try {
      await sentryFile.create();
      await sentryFile.writeAsString('Hello World');
      final text = await sentryFile.readAsString();
      if (kDebugMode) {
        print(text);
      }
      await sentryFile.delete();
    } catch (error, stackTrace) {
      span.status = SentrySpanStatusV2.error;
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }, parentSpan: null);
}
