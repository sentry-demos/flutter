import 'package:sentry_flutter/sentry_flutter.dart';

/// Marker exception used to create the "connected event" that a feedback
/// submission is attached to.
///
/// It exists for two reasons:
///  1. It produces a real Issue, which is what supports issue-level search,
///     Alerts and Dashboards on the `userFlow` tag. Feedback alone does not.
///  2. Capturing an *exception* is what flushes the Session Replay buffer.
///     `Sentry.captureMessage` does not trigger the flush, so the ~30s of
///     buffered replay would otherwise never be sent.
class UserFeedbackMarker implements Exception {
  final String userFlow;
  UserFeedbackMarker(this.userFlow);

  @override
  String toString() => 'User feedback submitted';
}

/// Submits user feedback captured by our own UI (see `feedback_modal.dart`).
///
/// Deliberately does not use `SentryFeedbackForm` — customers want full control
/// over styling. The cost of that choice is that the SDK's automatic
/// replay-flush-on-form-open is unavailable, which is exactly what the marker
/// event in step 1 compensates for.
Future<void> submitFeedback({
  required String message,
  required String userFlow, // e.g. 'checkout', 'signup', 'search'
  String? email,
  String? name,
}) async {
  // 1. Connected event — creates the Issue with a userFlow tag, attaches the
  // replay.
  final flowEventId = await Sentry.captureException(
    UserFeedbackMarker(userFlow),
    withScope: (scope) => scope.setTag('userFlow', userFlow),
  );

  // 2. Create the Feedback object with the associated 'connected event'.
  final feedback = SentryFeedback(
    message: message,
    contactEmail: email,
    name: name,
    associatedEventId: flowEventId,
  );

  // 3. Submit the feedback — attaches it to the connected event and its Issue
  // via feedback.associatedEventId, so the userFlow tag on that Issue supports
  // issue-level searching, Alerts & Dashboards.
  await Sentry.captureFeedback(
    feedback,
    withScope: (scope) => scope.setTag('userFlow', userFlow),
  );
}
