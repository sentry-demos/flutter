import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter_app/navbar_destination.dart';
import 'product_list.dart';
import 'models/cart_state_model.dart';
import 'cart.dart';
import 'product_details.dart';
import 'checkout.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const SENTRY_RELEASE = String.fromEnvironment("SENTRY_RELEASE",
    defaultValue: '614997d2cf7b57dfa7daba24a2fc739f4eb5b7bf');
const SENTRY_ENVIRONMENT =
    String.fromEnvironment("SENTRY_ENVIRONMENT", defaultValue: 'staging');
const DSN = 'https://e8f3c4c4b8ce4590afecf332cb47bf63@o87286.ingest.sentry.io/4505430534324224';

SentryEvent beforeSend(SentryEvent event, {dynamic hint}) {
  final exceptions = event.exceptions;
  if (exceptions?.isNotEmpty == true &&
      exceptions?.first.value == "Exception: 500 + Internal Server Error") {
    // event = event.copyWith(fingerprint: ['backend-error']);
  }
  return event;
}

Future<void> main() async {
  //basic options https://docs.sentry.io/platforms/dart/configuration/options/
  await SentryFlutter.init(
    (options) => options
      ..dsn = DSN
      ..tracesSampleRate = 1.0
      ..release = SENTRY_RELEASE
      ..environment = SENTRY_ENVIRONMENT
      ..beforeSend = beforeSend
      ..attachScreenshot = true
      //debug = true
    ,
    appRunner: () => runApp
      (ChangeNotifierProvider(
        create: (context) => CartModel(),
        child:  SentryScreenshotWidget(
          child: MyApp(),
        )
    )
    ),
  );

  // or define SENTRY_DSN via Dart environment variable (--dart-define)
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(navigatorObservers: [
      SentryNavigatorObserver(),
    ], routes: {
      "/": (context) => HomePage(),
      "/productDetails": (context) => ProductDetails(),
      "/checkout": (context) => CheckoutView()
    }, home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; //tab destination idx

  List<Destination> allDestinations = [
    //place tab destinations here
    Destination.withChild(Icons.home, "Home", ItemsList()),
    Destination.withChild(Icons.shopping_bag, "Cart", CartView()),
  ];

  @override
  Widget build(BuildContext context) {
    //clean release edit
    return Scaffold(
      body: SafeArea(
          top: false,
          child: IndexedStack(
            index: _currentIndex,
            children: allDestinations.map<Widget>((Destination destination) {
              return DestinationView(destination: destination);
            }).toList(),
          )),
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
              icon: Icon(destination.icon), label: destination.title);
        }).toList(),
      ),
    );
  }
}
