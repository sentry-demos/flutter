import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Opens the SDK's built-in feedback form so a user can volunteer feedback at
/// any time, instead of only being offered it after a checkout failure.
///
/// Uses [SentryFeedbackForm] rather than the hand-rolled `AlertDialog` in
/// `sentry_setup.dart` on purpose: the form flushes the Session Replay buffer
/// the moment it opens (`_captureReplay()` in its `initState`), so the rolling
/// ~30s of replay that led the user to complain is what gets attached. A bare
/// `Sentry.captureFeedback()` has no Dart-level replay flush.
///
/// Requires replay buffer mode to be meaningful — see the Session Replay block
/// in `sentry_setup.dart` and `SENTRY_REPLAY_MODE` in `.env`.
void openUserFeedbackForm(
  BuildContext context, {
  SentryId? associatedEventId,
  required String source,
}) {
  Sentry.addBreadcrumb(Breadcrumb(
    category: 'ui.action',
    message: 'Opened user feedback form',
    level: SentryLevel.info,
    data: {
      'source': source,
      if (associatedEventId != null)
        'associated_event_id': associatedEventId.toString(),
    },
  ));

  // Opening the form is what flushes the replay buffer, so the tap that gets
  // the user here is the last thing captured in the attached replay.
  SentryFeedbackForm.show(
    context,
    associatedEventId: associatedEventId,
  );
}
