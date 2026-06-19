import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../platform/platform_info.dart';
import 'trace_headers.dart';

/// Native body builder.
/// - Android/iOS: in-app [WebViewWidget]; the active trace is passed as URL
///   query params (sentry-trace/baggage) so the loaded page's JS Sentry SDK can
///   continue the trace (request headers aren't readable by browser JS).
/// - Desktop (macOS/Windows/Linux): webview_flutter has no implementation, so
///   open the system browser via url_launcher (trace passed as query params).
Widget buildWebViewBody(
  BuildContext context,
  String url, {
  VoidCallback? onPageFinished,
}) {
  if (isAndroid || isIOS) {
    return _MobileWebView(url: url, onPageFinished: onPageFinished);
  }
  return _DesktopLauncher(url: url, onPageFinished: onPageFinished);
}

class _MobileWebView extends StatefulWidget {
  final String url;
  final VoidCallback? onPageFinished;
  const _MobileWebView({required this.url, this.onPageFinished});

  @override
  State<_MobileWebView> createState() => _MobileWebViewState();
}

class _MobileWebViewState extends State<_MobileWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Notify when the page finishes loading so the owning screen can finish
      // (and send) the Flutter webview transaction.
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => widget.onPageFinished?.call(),
        ),
      )
      // Trace rides in the URL (query params), not request headers, so the
      // loaded page's browser SDK can read and continue it.
      ..loadRequest(withTraceQueryParams(Uri.parse(widget.url)));
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}

class _DesktopLauncher extends StatelessWidget {
  final String url;
  final VoidCallback? onPageFinished;
  const _DesktopLauncher({required this.url, this.onPageFinished});

  Future<void> _open() async {
    final uri = withTraceQueryParams(Uri.parse(url));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    // Auto-open once, and offer a button to reopen. The page loads in an
    // external browser we can't observe, so signal "finished" right after launch.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _open();
      onPageFinished?.call();
    });
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.public, size: 48),
          const SizedBox(height: 12),
          const Text('Opening Empower Plant in your browser…'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _open,
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open again'),
          ),
        ],
      ),
    );
  }
}
