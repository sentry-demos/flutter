import 'package:flutter/material.dart';
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
                title: Text('C++ Segfault'),
                onTap: () async {
                  // Simulate a native crash or fallback to Dart error for demo
                  try {
                    throw StateError('Simulated C++ Segfault');
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
                  // Simulate a Dart exception for demo
                  try {
                    throw Exception('Simulated Kotlin Exception');
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
                title: Text('ANR'),
                onTap: () {
                  // Block the main thread for 6 seconds to trigger a real ANR (if native SDK is set up)
                  final start = DateTime.now();
                  while (DateTime.now().difference(start).inSeconds < 6) {}
                  // Optionally, also send a Dart exception for demo visibility
                  Sentry.captureException(
                    Exception('Simulated ANR (App Not Responding)'),
                  );
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
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
