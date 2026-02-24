import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:sentry/sentry.dart';
import 'package:sentry_file/sentry_file.dart';
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
              // Platform-specific: ANR for Android, App Hang for iOS/macOS
              if (Platform.isAndroid)
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
              if (Platform.isIOS || Platform.isMacOS)
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
