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
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('ANR'),
                onTap: () {
                  // Block the main thread for 6 seconds to trigger a real ANR (if native SDK is set up)
                  Navigator.pop(context);
                  final start = DateTime.now();
                  while (DateTime.now().difference(start).inSeconds < 10) {}
                },
              ),
              ListTile(
                title: Text('C++ Segfault'),
                onTap: () async {
                  try {
                    await channel.invokeMethod('cppSegfault');
                  } catch (error, stackTrace) {
                    await Sentry.captureException(
                      error,
                      stackTrace: stackTrace,
                    );
                  }
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Kotlin Exception'),
                onTap: () async {
                  try {
                    await channel.invokeMethod('kotlinException');
                  } catch (error, stackTrace) {
                    await Sentry.captureException(
                      error,
                      stackTrace: stackTrace,
                    );
                  }
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Dart Exception'),
                onTap: () async {
                  // Actually throw an uncaught Dart exception
                  Navigator.pop(context);
                  throw Exception('Simulated Dart Exception');
                },
              ),
              ListTile(
                title: Text('Timeout Exception'),
                onTap: () async {
                  // Actually throw an uncaught TimeoutException
                  Navigator.pop(context);
                  throw TimeoutException(
                    'Operation timed out',
                    Duration(seconds: 2),
                  );
                },
              ),
              ListTile(
                title: Text('Platform Exception'),
                onTap: () async {
                  // Actually throw an uncaught PlatformException
                  Navigator.pop(context);
                  throw PlatformException(
                    code: 'PLATFORM_ERROR',
                    message: 'Simulated platform error',
                  );
                },
              ),
              ListTile(
                title: Text('Missing Plugin Exception'),
                onTap: () async {
                  // Actually throw an uncaught MissingPluginException
                  Navigator.pop(context);
                  throw MissingPluginException('Simulated missing plugin');
                },
              ),
              ListTile(
                title: Text('Assertion Error'),
                onTap: () async {
                  // Actually trigger an assertion error
                  Navigator.pop(context);
                  assert(false, 'Simulated assertion error');
                },
              ),
              ListTile(
                title: Text('State Error'),
                onTap: () async {
                  // Actually throw an uncaught StateError
                  Navigator.pop(context);
                  throw StateError('Simulated state error');
                },
              ),
              ListTile(
                title: Text('Range Error'),
                onTap: () async {
                  // Actually throw an uncaught RangeError
                  Navigator.pop(context);
                  throw RangeError('Simulated range error');
                },
              ),
              ListTile(
                title: Text('Type Error'),
                onTap: () async {
                  // Actually throw an uncaught TypeError
                  Navigator.pop(context);
                  throw TypeError();
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
