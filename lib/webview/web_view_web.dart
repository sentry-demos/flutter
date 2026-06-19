import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'trace_headers.dart';

// Monotonic id so each iframe gets a unique platform-view type.
int _viewCounter = 0;

/// Flutter-web body builder: embeds [url] in an `<iframe>` via a platform view.
/// Trace headers are appended as query params so the loaded app can continue
/// the trace. [onPageFinished] fires when the iframe finishes loading.
Widget buildWebViewBody(
  BuildContext context,
  String url, {
  VoidCallback? onPageFinished,
}) {
  return _IframeWebView(url: url, onPageFinished: onPageFinished);
}

class _IframeWebView extends StatefulWidget {
  final String url;
  final VoidCallback? onPageFinished;
  const _IframeWebView({required this.url, this.onPageFinished});

  @override
  State<_IframeWebView> createState() => _IframeWebViewState();
}

class _IframeWebViewState extends State<_IframeWebView> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'empower-webview-${_viewCounter++}';
    final src = withTraceQueryParams(Uri.parse(widget.url)).toString();

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = web.HTMLIFrameElement()
          ..src = src
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        iframe.onLoad.listen((_) => widget.onPageFinished?.call());
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
