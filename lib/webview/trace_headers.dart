import 'package:sentry_flutter/sentry_flutter.dart';

/// Returns the `sentry-trace` (and `baggage`) headers for the currently active
/// span so a downstream page/request can continue the Flutter-initiated trace.
///
/// This is the Flutter side of distributed tracing: when the user opens the
/// Web View we attach these to the webview's HTTP request (mobile) or as query
/// params (web/desktop, where request headers can't be set).
Map<String, String> currentTraceHeaders() {
  final headers = <String, String>{};
  final span = Sentry.getSpan();
  if (span == null) return headers;

  final trace = span.toSentryTrace();
  headers[trace.name] = trace.value; // 'sentry-trace'

  final baggage = span.toBaggageHeader();
  if (baggage != null) {
    headers[baggage.name] = baggage.value; // 'baggage'
  }
  return headers;
}

/// Appends the trace headers as URL query parameters. Used where HTTP request
/// headers can't be set (web iframe, external desktop browser).
Uri withTraceQueryParams(Uri uri) {
  final headers = currentTraceHeaders();
  if (headers.isEmpty) return uri;
  return uri.replace(queryParameters: {
    ...uri.queryParameters,
    for (final entry in headers.entries) entry.key: entry.value,
  });
}
