import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'user_feedback.dart';

/// Approach B: the SDK's built-in [SentryFeedbackForm].
///
/// Kept alongside the custom modal (`feedback_modal.dart`, approach A) so the
/// two can be compared side by side in one app. Both now capture the same
/// [UserFeedbackMarker] connected event, so the only remaining difference
/// between the two approaches is the UI itself:
///
///  - Styling: labels here are configurable via `options.feedback`, but the
///    layout is not. The custom modal is styled top to bottom.
///  - Replay: this path is belt-and-braces — the form flushes the buffer when
///    it opens (`_captureReplay()` in its `initState`) AND the marker exception
///    below flushes it. The custom modal relies on the marker alone.
///  - Tagging: the form calls `captureFeedback(feedback, hint: hint)` with no
///    `withScope` hook, so the ambient scope is the only way to get a tag onto
///    the feedback itself — hence `configureScope` below. The marker event gets
///    its tag through the cloned `withScope` inside `submitFeedback`'s pattern.
Future<void> openSentryFeedbackForm(
  BuildContext context, {
  required String userFlow,
  required String source,
}) async {
  Sentry.addBreadcrumb(Breadcrumb(
    category: 'ui.action',
    message: 'Opened Sentry SDK feedback form',
    level: SentryLevel.info,
    data: {'source': source, 'userFlow': userFlow},
  ));

  // Tag the feedback event itself (the form gives us no withScope hook).
  Sentry.configureScope((scope) => scope.setTag('userFlow', userFlow));

  // Connected event, so this path also produces a searchable/alertable Issue
  // and shows a Linked Error on the feedback — matching the custom modal.
  final flowEventId = await Sentry.captureException(
    UserFeedbackMarker(userFlow),
    withScope: (scope) => scope.setTag('userFlow', userFlow),
  );

  if (context.mounted) {
    SentryFeedbackForm.show(context, associatedEventId: flowEventId);
  }
}
