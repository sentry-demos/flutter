import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:sentry/sentry.dart';
import 'sentry_setup.dart';

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
      appBar: AppBar(title: Text(widget.destination.title)),
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
              ListTile(
                title: Text('ANR'),
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
                  final start = DateTime.now();
                  while (DateTime.now().difference(start).inSeconds < 10) {}
                  await span.finish();
                  await transaction.finish();
                },
              ),
              ListTile(
                title: Text('C++ Segfault'),
                onTap: () async {
                  final transaction = Sentry.startTransaction(
                    'drawer.cpp_segfault',
                    'ui.action',
                  );
                  final span = transaction.startChild(
                    'native.crash',
                    description: 'Trigger C++ Segfault: Plant root failure',
                  );
                  transaction.setData('plant_action', 'cpp_segfault');
                  span.setData('drawer', 'cpp_segfault_button');
                  try {
                    await channel.invokeMethod('cppSegfault');
                  } catch (error, stackTrace) {
                    span.throwable = error;
                    span.status = SpanStatus.internalError();
                    await Sentry.captureException(
                      error,
                      stackTrace: stackTrace,
                    );
                  }
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  await span.finish();
                  await transaction.finish();
                },
              ),
              ListTile(
                title: Text('Kotlin Exception'),
                onTap: () async {
                  final transaction = Sentry.startTransaction(
                    'drawer.kotlin_exception',
                    'ui.action',
                  );
                  final span = transaction.startChild(
                    'native.exception',
                    description: 'Trigger Kotlin Exception: Plant leaf error',
                  );
                  transaction.setData('plant_action', 'kotlin_exception');
                  span.setData('drawer', 'kotlin_exception_button');
                  try {
                    await channel.invokeMethod('kotlinException');
                  } catch (error, stackTrace) {
                    span.throwable = error;
                    span.status = SpanStatus.internalError();
                    await Sentry.captureException(
                      error,
                      stackTrace: stackTrace,
                    );
                  }
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  await span.finish();
                  await transaction.finish();
                },
              ),
              ListTile(
                title: Text('Dart Exception'),
                onTap: () async {
                  final transaction = Sentry.startTransaction(
                    'drawer.dart_exception',
                    'ui.action',
                  );
                  final span = transaction.startChild(
                    'dart.exception',
                    description: 'Trigger Dart Exception: Plant soil error',
                  );
                  transaction.setData('plant_action', 'dart_exception');
                  span.setData('drawer', 'dart_exception_button');
                  Navigator.pop(context);
                  try {
                    throw Exception('Simulated Dart Exception');
                  } catch (error) {
                    span.throwable = error;
                    span.status = SpanStatus.internalError();
                    await Sentry.captureException(error);
                  }
                  await span.finish();
                  await transaction.finish();
                },
              ),
              ListTile(
                title: Text('Timeout Exception'),
                onTap: () async {
                  final transaction = Sentry.startTransaction(
                    'drawer.timeout_exception',
                    'ui.action',
                  );
                  final span = transaction.startChild(
                    'dart.timeout',
                    description: 'Trigger Timeout: Plant growth timeout',
                  );
                  transaction.setData('plant_action', 'timeout_exception');
                  span.setData('drawer', 'timeout_exception_button');
                  Navigator.pop(context);
                  try {
                    throw TimeoutException(
                      'Operation timed out',
                      Duration(seconds: 2),
                    );
                  } catch (error) {
                    span.throwable = error;
                    span.status = SpanStatus.internalError();
                    await Sentry.captureException(error);
                  }
                  await span.finish();
                  await transaction.finish();
                },
              ),
              ListTile(
                title: Text('Platform Exception'),
                onTap: () async {
                  final transaction = Sentry.startTransaction(
                    'drawer.platform_exception',
                    'ui.action',
                  );
                  final span = transaction.startChild(
                    'platform.exception',
                    description: 'Trigger Platform Exception: Plant pot error',
                  );
                  transaction.setData('plant_action', 'platform_exception');
                  span.setData('drawer', 'platform_exception_button');
                  Navigator.pop(context);
                  try {
                    throw PlatformException(
                      code: 'PLATFORM_ERROR',
                      message: 'Simulated platform error',
                    );
                  } catch (error) {
                    span.throwable = error;
                    span.status = SpanStatus.internalError();
                    await Sentry.captureException(error);
                  }
                  await span.finish();
                  await transaction.finish();
                },
              ),
              ListTile(
                title: Text('Missing Plugin Exception'),
                onTap: () async {
                  final transaction = Sentry.startTransaction(
                    'drawer.missing_plugin_exception',
                    'ui.action',
                  );
                  final span = transaction.startChild(
                    'plugin.exception',
                    description:
                        'Trigger Missing Plugin: Plant fertilizer missing',
                  );
                  transaction.setData(
                    'plant_action',
                    'missing_plugin_exception',
                  );
                  span.setData('drawer', 'missing_plugin_exception_button');
                  Navigator.pop(context);
                  try {
                    throw MissingPluginException('Simulated missing plugin');
                  } catch (error) {
                    span.throwable = error;
                    span.status = SpanStatus.internalError();
                    await Sentry.captureException(error);
                  }
                  await span.finish();
                  await transaction.finish();
                },
              ),
              ListTile(
                title: Text('Assertion Error'),
                onTap: () async {
                  final transaction = Sentry.startTransaction(
                    'drawer.assertion_error',
                    'ui.action',
                  );
                  final span = transaction.startChild(
                    'dart.assertion',
                    description:
                        'Trigger Assertion Error: Plant sunlight assertion',
                  );
                  transaction.setData('plant_action', 'assertion_error');
                  span.setData('drawer', 'assertion_error_button');
                  Navigator.pop(context);
                  try {
                    assert(false, 'Simulated assertion error');
                  } catch (error) {
                    span.throwable = error;
                    span.status = SpanStatus.internalError();
                    await Sentry.captureException(error);
                  }
                  await span.finish();
                  await transaction.finish();
                },
              ),
              ListTile(
                title: Text('State Error'),
                onTap: () async {
                  final transaction = Sentry.startTransaction(
                    'drawer.state_error',
                    'ui.action',
                  );
                  final span = transaction.startChild(
                    'dart.state',
                    description: 'Trigger State Error: Plant state error',
                  );
                  transaction.setData('plant_action', 'state_error');
                  span.setData('drawer', 'state_error_button');
                  Navigator.pop(context);
                  try {
                    throw StateError('Simulated state error');
                  } catch (error) {
                    span.throwable = error;
                    span.status = SpanStatus.internalError();
                    await Sentry.captureException(error);
                  }
                  await span.finish();
                  await transaction.finish();
                },
              ),
              ListTile(
                title: Text('Range Error'),
                onTap: () async {
                  final transaction = Sentry.startTransaction(
                    'drawer.range_error',
                    'ui.action',
                  );
                  final span = transaction.startChild(
                    'dart.range',
                    description: 'Trigger Range Error: Plant root range error',
                  );
                  transaction.setData('plant_action', 'range_error');
                  span.setData('drawer', 'range_error_button');
                  Navigator.pop(context);
                  try {
                    throw RangeError('Simulated range error');
                  } catch (error) {
                    span.throwable = error;
                    span.status = SpanStatus.internalError();
                    await Sentry.captureException(error);
                  }
                  await span.finish();
                  await transaction.finish();
                },
              ),
              ListTile(
                title: Text('Type Error'),
                onTap: () async {
                  final transaction = Sentry.startTransaction(
                    'drawer.type_error',
                    'ui.action',
                  );
                  final span = transaction.startChild(
                    'dart.type',
                    description: 'Trigger Type Error: Plant type error',
                  );
                  transaction.setData('plant_action', 'type_error');
                  span.setData('drawer', 'type_error_button');
                  Navigator.pop(context);
                  try {
                    throw TypeError();
                  } catch (error) {
                    span.throwable = error;
                    span.status = SpanStatus.internalError();
                    await Sentry.captureException(error);
                  }
                  await span.finish();
                  await transaction.finish();
                },
              ),
              // N+1 API Calls demo button
              ListTile(
                title: Text('N+1 API Calls'),
                onTap: () async {
                  final transaction = Sentry.startTransaction(
                    'drawer.n_plus_one_api_calls',
                    'ui.action',
                  );
                  final span = transaction.startChild(
                    'http.client',
                    description: 'Trigger N+1 API Calls: Plant fetch demo',
                  );
                  transaction.setData('plant_action', 'n_plus_one_api_calls');
                  span.setData('drawer', 'n_plus_one_api_calls_button');
                  Navigator.pop(context);
                  final url =
                      'https://application-monitoring-flask-dot-sales-engineering-sf.appspot.com/products';
                  final client = SentryHttpClient();
                  final futures = List.generate(15, (i) async {
                    final uri = Uri.parse('$url?id=$i');
                    try {
                      await client.get(uri);
                    } catch (e, st) {
                      await Sentry.captureException(e, stackTrace: st);
                    }
                  });
                  await Future.wait(futures);
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
    try {
      await channel.invokeMethod<void>(method);
    } catch (error, stackTrace) {
      final eventId = await Sentry.captureException(
        error,
        stackTrace: stackTrace,
      );
      // Show user feedback dialog for Dart exceptions
      if (mounted && error is! PlatformException) {
        showUserFeedbackDialog(context, eventId);
      }
    }
  }
}
