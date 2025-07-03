import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navbar_destination.dart';
import 'product_list.dart';
import 'models/cart_state_model.dart';
import 'cart.dart';
import 'product_details.dart';
import 'checkout.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:async';

// ignore: constant_identifier_names
const SENTRY_RELEASE = String.fromEnvironment(
  "SENTRY_RELEASE",
  defaultValue: '614997d2cf7b57dfa7daba24a2fc739f4eb5b7bf',
);
// ignore: constant_identifier_names
const SENTRY_ENVIRONMENT = String.fromEnvironment(
  "SENTRY_ENVIRONMENT",
  defaultValue: 'staging',
);
// ignore: constant_identifier_names
const DSN =
    'https://b4efd6bd7c574e70b933e60b7de443ce@o1161257.ingest.us.sentry.io/6453502';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

FutureOr<SentryEvent?> sentryBeforeSend(SentryEvent event, Hint? hint) async {
  if (event.throwable != null) {
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final nameController = TextEditingController();
        final emailController = TextEditingController();
        final descController = TextEditingController();
        final result = await showDialog<Map<String, String>>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Send Feedback'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(hintText: 'Your Name'),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(hintText: 'Your Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    hintText: 'Describe what happened',
                  ),
                  maxLines: 4,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop({
                  'name': nameController.text,
                  'email': emailController.text,
                  'desc': descController.text,
                }),
                child: Text('Send'),
              ),
            ],
          ),
        );
        if (result != null &&
            result['desc'] != null &&
            result['desc']!.trim().isNotEmpty) {
          await Sentry.captureFeedback(
            SentryFeedback(
              message: result['desc']!,
              associatedEventId: event.eventId,
              name: result['name'],
            ),
          );
        }
      });
    }
  }
  return event;
}

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.navigatorKey = navigatorKey;
      options
        ..dsn = DSN
        ..tracesSampleRate = 1.0
        ..release = SENTRY_RELEASE
        ..environment = SENTRY_ENVIRONMENT
        ..attachScreenshot = true
        ..attachViewHierarchy = true
        ..beforeSend = sentryBeforeSend;
    },
    appRunner: () => runApp(
      SentryWidget(
        child: ChangeNotifierProvider(
          create: (context) => CartModel(),
          child: MyApp(),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [SentryNavigatorObserver()],
      routes: {
        "/productDetails": (context) => ProductDetails(),
        "/checkout": (context) => CheckoutView(),
      },
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  List<Destination> allDestinations = [
    Destination.withChild(Icons.home, "Home", ItemsList()),
    Destination.withChild(Icons.shopping_bag, "Cart", CartView()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No appBar
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _currentIndex,
          children: allDestinations.map<Widget>((Destination destination) {
            return DestinationView(destination: destination);
          }).toList(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: true,
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: allDestinations.map((Destination destination) {
          return BottomNavigationBarItem(
            icon: Icon(destination.icon),
            label: destination.title,
          );
        }).toList(),
      ),
    );
  }
}
