import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:sentry/sentry.dart';
import 'backend_config.dart';
import 'main.dart';
import 'platform/platform_info.dart';
import 'sentry_setup.dart';
import 'webview/web_view_screen.dart';

class Destination {
  IconData icon;
  String title;
  Widget child;

  Destination(this.icon, this.title, this.child);

  Destination.withChild(this.icon, this.title, this.child);
}

class DestinationView extends StatefulWidget {
  const DestinationView({super.key, required this.destination});
  final Destination destination;
  @override
  // ignore: library_private_types_in_public_api
  _DestinationViewState createState() => _DestinationViewState();
}

class _DestinationViewState extends State<DestinationView> {
  final channel = const MethodChannel('example.flutter.sentry.io');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
        // Custom, keyed drawer button so Sentry's user-interaction span reads
        // `ui.action.click - open_navigation_menu` instead of the cryptic
        // built-in `StandardComponentType.drawerButton`. The tooltip preserves
        // the "Open navigation menu" accessibility label.
        leading: Builder(
          builder: (context) => IconButton(
            key: const ValueKey('open_navigation_menu'),
            icon: const Icon(Icons.menu),
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: [
              ListTile(
                title: Text('Back'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () async {
                  final transaction = Sentry.startTransaction(
                    'drawer.back',
                    'ui.action',
                  );
                  final span = transaction.startChild(
                    'ui.action',
                    description: 'User navigates back from Drawer',
                  );
                  transaction.setData('plant_action', 'navigate_back');
                  span.setData('drawer', 'back_button');
                  Navigator.pop(context);
                  await span.finish();
                  await transaction.finish();
                },
              ),
              // Web View — opens empower-plant.com with Flutter-side
              // distributed tracing (sentry-trace/baggage attached to the load).
              // Shown on all platforms (in-app webview on mobile, iframe on web,
              // system browser on desktop).
              ListTile(
                title: const Text('Web View'),
                onTap: () {
                  // The Web View journey gets its own transaction + trace,
                  // started inside WebViewScreen after navigation settles
                  // (so it doesn't inherit the current screen's trace).
                  Sentry.addBreadcrumb(Breadcrumb(
                    category: 'ui.action',
                    message: 'Opened Web View',
                    level: SentryLevel.info,
                    data: {'url': kWebViewUrl},
                  ));
                  Navigator.pop(context);
                  // No named route here: WebViewScreen owns its own trace +
                  // transaction (bound to scope) so the trace handed to the
                  // loaded page is unambiguously the webview transaction's.
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WebViewScreen(
                        url: kWebViewUrl,
                        title: 'Empower Plant (Web)',
                      ),
                    ),
                  );
                },
              ),
              // OTLP — opens the home page but routes all backend calls
              // (/products, /checkout) to the OpenTelemetry-instrumented
              // backend (flask-otlp), as its own new trace/journey.
              ListTile(
                title: const Text('OTLP'),
                onTap: () {
                  Sentry.addBreadcrumb(Breadcrumb(
                    category: 'ui.action',
                    message: 'Opened OTLP backend journey',
                    level: SentryLevel.info,
                    data: {'backend': BackendConfig.otlpBase},
                  ));
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      // Named route → new trace for the OTLP journey.
                      settings: const RouteSettings(
                        name: HomePage.otlpRouteName,
                      ),
                      builder: (_) =>
                          const HomePage(backendBase: BackendConfig.otlpBase),
                    ),
                  );
                },
              ),
              // Platform-specific: ANR for Android, App Hang for iOS/macOS
              if (isAndroid)
                ListTile(
                  title: Text('ANR (Android)'),
                  onTap: () async {
                    final transaction = Sentry.startTransaction(
                      'drawer.anr',
                      'ui.action',
                    );
                    final span = transaction.startChild(
                      'main.thread.block',
                      description: 'Simulate ANR: Watering plant too long',
                    );
                    transaction.setData('plant_action', 'simulate_anr');
                    span.setData('duration', 10);
                    Navigator.pop(context);
                    // Block main thread for 10 seconds to trigger ANR
                    final start = DateTime.now();
                    while (DateTime.now().difference(start).inSeconds < 10) {}
                    await span.finish();
                    await transaction.finish();
                  },
                ),
              if (isIOS || isMacOS)
                ListTile(
                  title: Text('App Hang (iOS/macOS)'),
                  onTap: () async {
                    final transaction = Sentry.startTransaction(
                      'drawer.app_hang',
                      'ui.action',
                    );
                    final span = transaction.startChild(
                      'main.thread.block',
                      description: 'Simulate App Hang: Plant processing stuck',
                    );
                    transaction.setData('plant_action', 'simulate_app_hang');
                    span.setData('duration', 3);
                    Navigator.pop(context);
                    // Block main thread for 3 seconds to trigger App Hang
                    // (App hang threshold is 2 seconds by default)
                    final start = DateTime.now();
                    while (DateTime.now().difference(start).inSeconds < 3) {}
                    await span.finish();
                    await transaction.finish();
                  },
                ),
            ],
          ).toList(),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(0.0),
        alignment: Alignment.center,
        child: widget.destination.child,
      ),
    );
  }

  Future<void> execute(String method) async {
    final transaction = Sentry.startTransaction(
      'execute.$method',
      'ui.action',
    );
    final span = transaction.startChild(
      'method.channel.invoke',
      description: 'Execute method: $method',
    );
    transaction.setData('method', method);
    span.setData('channel', 'example.flutter.sentry.io');

    try {
      await channel.invokeMethod<void>(method);
      span.status = SpanStatus.ok();
    } catch (error, stackTrace) {
      span.throwable = error;
      span.status = SpanStatus.internalError();
      final eventId = await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
      // Show user feedback dialog for Dart exceptions
      if (mounted && error is! PlatformException) {
        showUserFeedbackDialog(context, eventId);
      }
    } finally {
      await span.finish();
      await transaction.finish();
    }
  }
}
