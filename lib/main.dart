import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter_app/navbar_destination.dart';
import 'navbar_destination.dart';
import 'product_list.dart';
import 'models/cart_state_model.dart';
import 'cart.dart';
import 'product_details.dart';
import 'checkout.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) => options
      ..dsn =
          'https://7d13813fba61475a816ba90a551b1d05@o87286.ingest.sentry.io/5590334'
      ..release = String.fromEnvironment("SENTRY_RELEASE"),
    appRunner: () => runApp(ChangeNotifierProvider(
        create: (context) => CartModel(), child: MyApp())),
  );

  // or define SENTRY_DSN via Dart environment variable (--dart-define)
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(navigatorObservers: [
      SentryNavigatorObserver(),
    ], routes: {
      "/home": (context) => HomePage(),
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
