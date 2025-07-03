import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';

FutureOr<SentryEvent?> beforeSend(SentryEvent event, Hint? hint) {
  final exceptions = event.exceptions;
  if (exceptions?.isNotEmpty == true &&
      exceptions?.first.value == "Exception: 500 + Internal Server Error") {
    // event = event.copyWith(fingerprint: ['backend-error']);
  }
  return event;
}
