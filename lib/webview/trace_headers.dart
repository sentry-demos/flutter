import 'package:sentry_flutter/sentry_flutter.dart';

/// Returns the `sentry-trace` header for [span] so a downstream page/request can
/// continue the Flutter-initiated trace.
///
/// This is the Flutter side of distributed tracing: when the user opens the Web
/// View we attach this to the webview's URL as a query param (browser JS can't
/// read request headers). We build the header from the span we explicitly hold
/// (see [withTraceQueryParams]) rather than from `Sentry.getSpan()`, because the
/// span-streaming API tracks the active span on a zone-forked scope, not on
/// `scope.span` — so the global getter would return null here.
///
/// Note: only `sentry-trace` is propagated (not `baggage`/DSC). `sentry-trace`
/// is what links the web page's trace to this one; the streaming API doesn't
/// expose a public accessor for a span's dynamic sampling context, so baggage
/// is omitted. Traces still connect end-to-end via the shared trace id.
Map<String, String> traceHeadersFor(SentrySpanV2? span) {
  final headers = <String, String>{};
  if (span == null) return headers;

  // Sampling is 100% in this demo (tracesSampleRate = 1.0), so the span is
  // always sampled; mark the propagated trace accordingly.
  final trace = SentryTraceHeader(span.traceId, span.spanId, sampled: true);
  headers[trace.name] = trace.value; // 'sentry-trace'
  return headers;
}

/// Appends [span]'s trace header as URL query parameters. Used where HTTP
/// request headers can't be set (web iframe, external desktop browser).
Uri withTraceQueryParams(Uri uri, SentrySpanV2? span) {
  final headers = traceHeadersFor(span);
  if (headers.isEmpty) return uri;
  return uri.replace(queryParameters: {
    ...uri.queryParameters,
    for (final entry in headers.entries) entry.key: entry.value,
  });
}
