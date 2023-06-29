import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry/sentry.dart';

class Destination {
  IconData icon;
  String title;
  Widget child;

  Destination(this.icon, this.title, this.child);

  Destination.withChild(this.icon, this.title, this.child);
}

class DestinationView extends StatefulWidget {
  const DestinationView({Key? key, required this.destination})
      : super(key: key);
  final Destination destination;
  @override
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
                children: ListTile.divideTiles(context: context, tiles: [
          ListTile(
            title: Text('C++ Segfault'),
            onTap: () async {
              // Update the state of the app
              // ...
              // Then close the drawer
              await execute('crash');
            },
          ),
          ListTile(
            title: Text('Kotlin Exception'),
            onTap: () async {
              // Update the state of the app
              // ...
              // Then close the drawer
              await execute('throw');
            },
          ),
          ListTile(
            title: Text('ANR'),
            onTap: () async {
              // Update the state of the app
              // ...
              // Then close the drawer
              await execute('anr');
            },
          ),
          ListTile(
            title: Text('Back'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
            },
          )
        ]).toList())),
        body: Container(
            padding: const EdgeInsets.all(0.0),
            alignment: Alignment.center,
            child: widget.destination.child));
  }

  Future<void> execute(String method) async {
    try {
      await channel.invokeMethod<void>(method);
    } catch (error, stackTrace) {
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }
}
