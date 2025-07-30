import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry_file/sentry_file.dart';
import 'package:sentry_logging/sentry_logging.dart';
import 'package:logging/logging.dart';
import 'se_config.dart';
import 'dart:io';

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
  await SentryFlutter.init((options) {
    options.addIntegration(LoggingIntegration());
    // Core options
    options.dsn = dotenv.env['SENTRY_DSN'];
    options.enableTimeToFullDisplayTracing = true;
    options.release = dotenv.env['SENTRY_RELEASE'];
    options.environment = dotenv.env['SENTRY_ENVIRONMENT'];
    options.debug = false; // Set true for local debugging
    options.diagnosticLevel = SentryLevel.error;
    // options.dist = null; // Set build number if available

    // Event sampling
    options.sampleRate = 1.0; // 100% errors
    options.tracesSampleRate = 1.0; // 100% performance traces
    options.profilesSampleRate =
        1.0; // Enable profiling for all sampled transactions
    // Enable Session Replay
    options.replay.sessionSampleRate = 1.0;
    options.replay.onErrorSampleRate = 1.0;
    // Enable structured logs
    options.enableLogs = true;

    // Breadcrumbs & cache
    options.maxBreadcrumbs = 100;
    options.maxCacheItems = 30;

    // Attachments
    options.attachStacktrace = true;
    options.attachScreenshot = true;
    options.screenshotQuality = SentryScreenshotQuality.high;
    options.attachViewHierarchy = true;

    // Privacy
    options.sendDefaultPii = false; // Enable if you want PII (see docs)
    // inAppInclude/inAppExclude not supported in Flutter SDK

    // Session & crash tracking
    options.enableNativeCrashHandling = true;
    options.enableAutoSessionTracking = true;
    options.enableNdkScopeSync = true;
    options.attachThreads = true;
    options.enableScopeSync = true;
    options.enableAutoPerformanceTracing = true;
    options.enableWatchdogTerminationTracking = true;
    options.reportPackages = true;
    options.anrEnabled = true;
    options.anrTimeoutInterval = const Duration(seconds: 5);
    options.reportSilentFlutterErrors = true;
    options.enableAutoNativeBreadcrumbs = true;
    options.enableUserInteractionBreadcrumbs = true;
    options.enableUserInteractionTracing = true;

    // HTTP request capture
    options.captureFailedRequests = true;
    options.maxRequestBodySize = MaxRequestBodySize.medium;

    // Transport & client reports
    options.sendClientReports = true;

    // Platform-specific (Android)
    // options.proguardUuid = 'YOUR_PROGUARD_UUID'; // If using Proguard

    // Hooks (replace with your actual functions if needed)
    // options.beforeSend = yourBeforeSendFunction;
    // options.beforeBreadcrumb = yourBeforeBreadcrumbFunction;

    // Add LoggingIntegration to Sentry options
    options.addIntegration(LoggingIntegration());
  }, appRunner: appRunner);

  // Sentry Dio integration
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
Future<void> sentryFileExample() async {
  final file = File('my_file.txt');
  final sentryFile = file.sentryTrace();

  final transaction = Sentry.startTransaction(
    'MyFileExample',
    'file',
    bindToScope: true,
  );

  await sentryFile.create();
  await sentryFile.writeAsString('Hello World');
  final text = await sentryFile.readAsString();
  if (kDebugMode) {
    print(text);
  }
  await sentryFile.delete();

  await transaction.finish(status: SpanStatus.ok());
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
