import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navbar_destination.dart';
import 'product_list.dart';
import 'models/cart_state_model.dart';
import 'cart.dart';
import 'product_details.dart';
import 'checkout.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'sentry_setup.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'dart:io';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final log = Logger('EmpowerPlantLogger');

Future<void> main() async {
  SentryWidgetsFlutterBinding.ensureInitialized();
  log.info('App starting');
  await dotenv.load();
  log.info('Dotenv loaded');
  Sentry.configureScope((scope) {
    scope.setTag('app.name', 'Empower Plant');
    scope.setTag('platform', 'flutter');
    scope.setTag('dart.version', Platform.version);
    scope.setTag('os', Platform.operatingSystem);
    scope.setTag('os.version', Platform.operatingSystemVersion);
    // ignore: deprecated_member_use
    scope.setTag('locale', WidgetsBinding.instance.window.locale.toString());
    // ignore: deprecated_member_use
    scope.setTag(
      'screen.size',
      // ignore: deprecated_member_use
      '${WidgetsBinding.instance.window.physicalSize.width}x${WidgetsBinding.instance.window.physicalSize.height}',
    );
  });
  await initSentry(
    appRunner: () {
      log.info('Running app');
      runApp(
        DefaultAssetBundle(
          bundle: SentryAssetBundle(),
          child: SentryWidget(
            child: ChangeNotifierProvider(
              create: (context) {
                log.info('Creating CartModel');
                return CartModel();
              },
              child: MyApp(),
            ),
          ),
        ),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    log.info('Building MyApp');
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [SentryNavigatorObserver()],
      routes: {
        "/productDetails": (context) {
          log.info('Navigating to ProductDetails');
          return ProductDetails();
        },
        "/checkout": (context) {
          log.info('Navigating to CheckoutView');
          return CheckoutView();
        },
      },
      home: SentryDisplayWidget(child: HomePage()),
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
  _HomePageState() {
    log.info('Creating HomePageState');
  }
  int _currentIndex = 0;

  List<Destination> allDestinations = [
    Destination.withChild(Icons.home, "Home", ItemsList()),
    Destination.withChild(Icons.shopping_bag, "Cart", CartView()),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SentryDisplayWidget.of(context).reportFullyDisplayed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    log.info('Building HomePage with index: ���_currentIndex');
    return Scaffold(
      // No appBar
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _currentIndex,
          children: allDestinations.map<Widget>((Destination destination) {
            log.info('Building DestinationView: ���{destination.title}');
            return InstrumentedDestinationView(destination: destination);
          }).toList(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: true,
        currentIndex: _currentIndex,
        onTap: (int index) {
          log.info('BottomNavigationBar tapped: ���index');
          setState(() {
            _currentIndex = index;
          });
        },
        items: allDestinations.map((Destination destination) {
          log.info('BottomNavigationBarItem: ���{destination.title}');
          return BottomNavigationBarItem(
            icon: Icon(destination.icon),
            label: destination.title,
          );
        }).toList(),
      ),
    );
  }
}

Future<void> instrumentedOperation(
  String name,
  Future<void> Function(ISentrySpan span) operation,
) async {
  final transaction = Sentry.startTransaction(
    name,
    'custom',
    bindToScope: true,
  );
  // Example custom performance metrics
  transaction.setMeasurement('memoryUsed', 123);
  transaction.setMeasurement('ui.footerComponent.render', 1.3);
  transaction.setMeasurement('localStorageRead', 4);
  try {
    await operation(transaction);
  } catch (exception, stackTrace) {
    transaction.throwable = exception;
    transaction.status = SpanStatus.internalError();
    await Sentry.captureException(exception, stackTrace: stackTrace);
  } finally {
    await transaction.finish();
  }
}

// Example usage for widget build instrumentation
class InstrumentedDestinationView extends StatelessWidget {
  final Destination destination;
  const InstrumentedDestinationView({required this.destination, super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: instrumentedOperation('build_${destination.title}', (span) async {
        span.setData('destination_icon', destination.icon.toString());
        span.setData('destination_title', destination.title);
        // Simulate build work
        await Future.delayed(const Duration(milliseconds: 10));
      }),
      builder: (context, snapshot) {
        return DestinationView(destination: destination);
      },
    );
  }
}
