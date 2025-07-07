import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/material.dart';
import 'se_config.dart';

// Sentry constants
// ignore: constant_identifier_names
const SENTRY_RELEASE = String.fromEnvironment(
  "SENTRY_RELEASE",
  defaultValue: '614997d2cf7b57dfa7daba24a2fc739f4eb5b7bf',
);
// ignore: constant_identifier_names
const SENTRY_ENVIRONMENT = String.fromEnvironment(
  "SENTRY_ENVIRONMENT",
  defaultValue: 'staging',
);
// ignore: constant_identifier_names
const DSN =
    'https://b4efd6bd7c574e70b933e60b7de443ce@o1161257.ingest.us.sentry.io/6453502';

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
    options.navigatorKey = navigatorKey;
    options
      ..dsn = DSN
      ..tracesSampleRate = 1.0
      ..release = SENTRY_RELEASE
      ..environment = SENTRY_ENVIRONMENT
      ..attachScreenshot = true
      ..attachViewHierarchy = true
      ..beforeSend = beforeSend
      ..sendDefaultPii = true
      ..profilesSampleRate = 1.0
      ..enableLogs = true;
  }, appRunner: appRunner);
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
