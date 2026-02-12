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

    // Get platform dispatcher for locale and screen size (replaces deprecated window API)
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    scope.setTag('locale', view.platformDispatcher.locale.toString());
    scope.setTag(
      'screen.size',
      '${view.physicalSize.width}x${view.physicalSize.height}',
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
      navigatorObservers: [
        SentryNavigatorObserver(
          // Enable automatic breadcrumb tracking for navigation
          enableAutoTransactions: true,
          // Auto-finish transactions after 3 seconds (default)
          autoFinishAfter: const Duration(seconds: 3),
        ),
      ],
      routes: {
        "/productDetails": (context) {
          log.info('Navigating to ProductDetails');
          return SentryDisplayWidget(
            child: ProductDetails(),
          );
        },
        "/checkout": (context) {
          log.info('Navigating to CheckoutView');
          return SentryDisplayWidget(
            child: CheckoutView(),
          );
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
  // Simulate a function regression by making this function slower
  int sumOfSquares(int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
      // Artificially slow down the function
      for (int j = 0; j < 100; j++) {
        sum += i * i;
      }
    }
    return sum;
  }

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
    // Intentionally perform a long-running regex operation on the main thread to trigger Sentry performance issue
    try {
      final largeText = List.generate(
        100000,
        (i) => 'The quick brown fox jumps over the lazy dog. ',
      ).join();
      final regex = RegExp(r'(quick|lazy|dog|fox|jumps|over|brown)');
      final stopwatch = Stopwatch()..start();
      final matches = regex.allMatches(largeText).toList();
      stopwatch.stop();
      log.info(
        'Regex on main thread duration: \x1B[36m${stopwatch.elapsedMilliseconds}ms\x1B[0m, matches: ${matches.length}',
      );
    } catch (e) {
      log.warning('Regex error: $e');
    }
    // Intentionally call a regressed function to trigger Sentry's Function Regression detector
    try {
      final stopwatch = Stopwatch()..start();
      final result = sumOfSquares(1000);
      stopwatch.stop();
      log.info(
        'Function regression demo: sumOfSquares(1000) duration: \x1B[36m${stopwatch.elapsedMilliseconds}ms\x1B[0m, result: $result',
      );
    } catch (e) {
      log.warning('Function regression error: $e');
    }
    // Intentionally perform a long-running computation on the main thread to trigger Sentry's Frame Drop detector
    try {
      final stopwatch = Stopwatch()..start();
      List<int> numbers = List.generate(10000, (i) => i);
      List<int> sortedEvenOdd = [];
      for (var n in numbers) {
        if (n % 2 == 0) {
          // Insert even numbers before the first odd number
          int i = sortedEvenOdd.indexWhere((x) => x % 2 == 1);
          sortedEvenOdd.insert(i == -1 ? 0 : i, n);
        } else {
          // Insert odd numbers after the last odd number
          int i = sortedEvenOdd.lastIndexWhere((x) => x % 2 == 1);
          sortedEvenOdd.insert(i == -1 ? sortedEvenOdd.length : i + 1, n);
        }
      }
      stopwatch.stop();
      log.info(
        'Frame drop computation on main thread duration: \x1B[36m${stopwatch.elapsedMilliseconds}ms\x1B[0m, sorted length: ${sortedEvenOdd.length}',
      );
    } catch (e) {
      log.warning('Frame drop computation error: $e');
    }
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
