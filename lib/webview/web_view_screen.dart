import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Picks the platform implementation: in-app webview on mobile, system browser
// on desktop (web_view_io.dart), or a dart:ui_web iframe on Flutter web.
import 'web_view_io.dart' if (dart.library.js_interop) 'web_view_web.dart'
    as impl;

/// The Web View target — the Empower Plant React app's products page.
///
/// We open `/products` (not `/`) so the products page is the React *pageload*,
/// which continues the Flutter-initiated trace. (Only the pageload inherits the
/// handed-off trace; subsequent in-app navigations start their own traces.)
/// For local testing, point this at the React dev server instead, e.g.
/// `http://10.0.2.2:3000/products?backend=flask` (Android emulator → host).
const String kWebViewUrl = 'https://empower-plant.com/products';

/// Opens [url] in a webview as its own transaction on a fresh trace, and hands
/// that trace off to the loaded page (Flutter → React distributed tracing).
class WebViewScreen extends StatefulWidget {
  static const String transactionName = 'webview/empower-plant';

  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    this.title = 'Web View',
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  SentrySpanV2? _transaction;

  @override
  void initState() {
    super.initState();
    // Start the Web View journey on its OWN trace. A root span
    // (`parentSpan: null`) adopts the scope's current propagation-context trace
    // id, so we first `generateNewTrace()` to reset that to a brand-new trace —
    // otherwise the journey would inherit the current screen's trace.
    // We use `startInactiveSpan` because the span must outlive this method —
    // it's held for the widget's lifetime and ended when the page loads (or on
    // dispose). We hold the span explicitly and hand it to the platform impl
    // for the trace-header handoff, guaranteeing the loaded page continues THIS
    // webview span's trace.
    // ignore: invalid_use_of_internal_member
    Sentry.currentHub.generateNewTrace();
    final tx = Sentry.startInactiveSpan(
      WebViewScreen.transactionName,
      parentSpan: null,
    );
    tx.setAttribute('sentry.op', SentryAttribute.string('navigation'));
    tx.setAttribute('url', SentryAttribute.string(widget.url));
    _transaction = tx;
  }

  // Finish (and send) the transaction once — when the page loads, or on dispose
  // as a fallback if the user leaves before it loads.
  void _finishTransaction() {
    final tx = _transaction;
    if (tx == null || tx.isEnded) return;
    tx.status = SentrySpanStatusV2.ok;
    tx.end();
  }

  @override
  void dispose() {
    _finishTransaction();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: impl.buildWebViewBody(
        context,
        widget.url,
        // Finish the transaction when the page loads so it's sent and shows up
        // in the trace while the user is still viewing the Web View.
        onPageFinished: _finishTransaction,
        // Hand this journey's span to the impl so the loaded page's URL carries
        // the sentry-trace and continues THIS trace (Flutter → web).
        traceSpan: _transaction,
      ),
    );
  }
}
