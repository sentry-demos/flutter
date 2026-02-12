import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry_file/sentry_file.dart';
import 'package:sentry_logging/sentry_logging.dart';
import 'package:logging/logging.dart';
import 'se_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

FutureOr<SentryEvent?> beforeSend(SentryEvent event, Hint? hint) async {
  // Add the se tag for engineer separation
  final tags = <String, String>{};
  if (event.tags != null) tags.addAll(event.tags!);
  tags['se'] = se;
  event.tags = tags;

  // Add the se tag to the fingerprint for grouping by engineer
  event.fingerprint = ['{{ default }}', 'se:$se'];

  return event;
}

Future<void> initSentry({required VoidCallback appRunner}) async {
  // Get configuration from dart-define (for release builds) or dotenv (for debug)
  const dartDefineDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  const dartDefineRelease = String.fromEnvironment('SENTRY_RELEASE', defaultValue: '');
  const dartDefineEnvironment = String.fromEnvironment('SENTRY_ENVIRONMENT', defaultValue: '');

  final String? sentryDsn = dartDefineDsn.isNotEmpty ? dartDefineDsn : dotenv.env['SENTRY_DSN'];
  final String? sentryRelease = dartDefineRelease.isNotEmpty ? dartDefineRelease : dotenv.env['SENTRY_RELEASE'];
  final String? sentryEnvironment = dartDefineEnvironment.isNotEmpty ? dartDefineEnvironment : dotenv.env['SENTRY_ENVIRONMENT'];

  await SentryFlutter.init((options) {
    // ========================================
    // Core Configuration
    // ========================================
    options.dsn = sentryDsn;

    // Release must match exactly with uploaded debug symbols
    // CRITICAL: This must be in format "appname@version+build" (e.g., "empower_flutter@1.0.0+2")
    options.release = sentryRelease;
    options.environment = sentryEnvironment;

    // Set distribution to match build number for better symbol matching
    options.dist = '2'; // Matches version 1.0.0+2

    // Debug settings (disabled for production to ensure proper symbol resolution)
    // Set to true only when debugging Sentry configuration issues
    options.debug = false;
    options.diagnosticLevel = SentryLevel.error;

    // ========================================
    // Sampling Configuration
    // ========================================
    // Capture 100% of errors (recommended for demo, adjust in production)
    options.sampleRate = 1.0;

    // Capture 100% of performance traces (adjust in production based on volume)
    options.tracesSampleRate = 1.0;

    // Enable profiling (relative to tracesSampleRate)
    // Required for JSON Decoding, Image Decoding, and Frame Drop detection
    // Profiling is available on iOS, macOS, and Android
    options.profilesSampleRate = 1.0;

    // ========================================
    // Session Replay Configuration
    // ========================================
    // Capture 100% of error sessions with replay
    options.replay.onErrorSampleRate = 1.0;
    // Capture 100% of normal sessions with replay (adjust in production)
    options.replay.sessionSampleRate = 1.0;

    // ========================================
    // Performance Tracking
    // ========================================
    // Enable automatic performance tracking
    options.enableAutoPerformanceTracing = true;

    // Enable Time to Initial Display (TTID) and Time to Full Display (TTFD) tracking
    options.enableTimeToFullDisplayTracing = true;

    // Enable user interaction tracing (tap, swipe, etc.)
    options.enableUserInteractionTracing = true;
    options.enableUserInteractionBreadcrumbs = true;

    // ========================================
    // Breadcrumbs & Context
    // ========================================
    options.maxBreadcrumbs = 100;
    options.enableAutoNativeBreadcrumbs = true;

    // ========================================
    // Attachments & Screenshots
    // ========================================
    options.attachStacktrace = true;
    options.attachScreenshot = true;
    options.screenshotQuality = SentryScreenshotQuality.high;
    options.attachViewHierarchy = true;
    options.attachThreads = true;

    // ========================================
    // Crash & Error Handling
    // ========================================
    options.enableNativeCrashHandling = true;
    options.enableNdkScopeSync = true;
    options.reportSilentFlutterErrors = true;

    // ANR (Application Not Responding) detection for Android
    options.anrEnabled = true;
    options.anrTimeoutInterval = const Duration(seconds: 5);

    // App Hang tracking for iOS/macOS
    // Enabled by default in Sentry Flutter SDK 9.0.0+
    // Watchdog termination tracking (iOS/macOS)
    options.enableWatchdogTerminationTracking = true;

    // Configure App Hang tracking for iOS/macOS
    if (Platform.isIOS || Platform.isMacOS) {
      // App hang timeout interval (default is 2 seconds)
      options.appHangTimeoutInterval = const Duration(seconds: 2);
      // Note: App Hang Tracking V2 is enabled by default in SDK 9.0.0+
      // It automatically measures duration and differentiates between
      // fully-blocking and non-fully-blocking app hangs
    }

    // ========================================
    // Session Tracking
    // ========================================
    options.enableAutoSessionTracking = true;
    options.enableScopeSync = true;

    // ========================================
    // HTTP Request Tracking
    // ========================================
    options.captureFailedRequests = true;
    options.maxRequestBodySize = MaxRequestBodySize.medium;

    // ========================================
    // Logging Integration
    // ========================================
    options.enableLogs = true;
    options.addIntegration(LoggingIntegration());

    // ========================================
    // Privacy & PII
    // ========================================
    // Set to true if you want to capture personally identifiable information
    // (user IP, request headers, etc.)
    options.sendDefaultPii = false;

    // ========================================
    // Additional Configuration
    // ========================================
    options.maxCacheItems = 30;
    options.sendClientReports = true;
    options.reportPackages = true;

    // ========================================
    // Custom Hooks
    // ========================================
    // Ensure the se tag is added to all events for engineer separation
    options.beforeSend = beforeSend;
    // options.beforeBreadcrumb = yourBeforeBreadcrumbFunction;
  }, appRunner: appRunner);

  // ========================================
  // HTTP Client Integration (Dio)
  // ========================================
  // Create a global Dio instance with Sentry integration
  final dio = Dio();
  dio.addSentry();
  // You can now use this dio instance throughout your app for HTTP requests
}

// Show user feedback dialog from a global error handler
void showUserFeedbackDialog(BuildContext context, SentryId eventId) async {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Send Feedback'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(hintText: 'Your Name'),
          ),
          SizedBox(height: 8),
          TextField(
            controller: descController,
            decoration: InputDecoration(hintText: 'Describe what happened'),
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).pop({'name': nameController.text, 'desc': descController.text}),
          child: Text('Send'),
        ),
      ],
    ),
  );
  if (result != null &&
      result['desc'] != null &&
      result['desc']!.trim().isNotEmpty) {
    await Sentry.captureFeedback(
      SentryFeedback(
        message: result['desc']!,
        associatedEventId: eventId,
        name: result['name'],
      ),
    );
  }
}

// Sentry file I/O instrumentation example
// Use this to automatically track file operations performance
Future<void> sentryFileExample() async {
  final file = File('my_file.txt');
  final sentryFile = file.sentryTrace();

  final transaction = Sentry.startTransaction(
    'file_operations_example',
    'file.io',
    bindToScope: true,
  );

  try {
    await sentryFile.create();
    await sentryFile.writeAsString('Hello World');
    final text = await sentryFile.readAsString();
    if (kDebugMode) {
      print(text);
    }
    await sentryFile.delete();
    await transaction.finish(status: SpanStatus.ok());
  } catch (error, stackTrace) {
    transaction.throwable = error;
    transaction.status = SpanStatus.internalError();
    await Sentry.captureException(error, stackTrace: stackTrace);
    await transaction.finish();
  }
}

// Example logger usage
final log = Logger('EmpowerPlantLogger');

void testSentryLogging() {
  log.info('Sentry logging breadcrumb!');
  try {
    throw StateError('Intentional error for Sentry logging test');
  } catch (error, stackTrace) {
    log.severe('Sentry logging error!', error, stackTrace);
  }
}
