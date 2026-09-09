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
import 'backend_config.dart';
import 'platform/platform_info.dart';
import 'feedback_modal.dart';
import 'sentry_form_feedback.dart';

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
    scope.setTag('dart.version', nativeDartVersion);
    scope.setTag('os', nativeOsName);
    scope.setTag('os.version', nativeOsVersion);

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
          // Start a fresh trace on each named-route navigation so each user
          // journey (e.g. the Web View) is its own transaction + trace,
          // instead of the whole session sharing one trace id.
          enableNewTraceOnNavigation: true,
        ),
      ],
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
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  /// Route name used when pushing the OTLP variant so SentryNavigatorObserver
  /// starts a fresh trace for the journey.
  static const String otlpRouteName = 'otlp/home';

  /// When set, this HomePage instance targets the given backend base URL for
  /// the duration it is on screen (used by the OTLP journey). Null = default.
  final String? backendBase;

  const HomePage({super.key, this.backendBase});

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
    // Mark the ItemsList with TTFD because this is the first screen displayed when opening the app
    Destination.withChild(
      Icons.home,
      "Home",
      SentryDisplayWidget(child: ItemsList()),
    ),
    Destination.withChild(Icons.shopping_bag, "Cart", CartView()),
  ];

  // Backend base URL active before this HomePage took over (for save/restore
  // so nested journeys, e.g. OTLP opened from within OTLP, behave correctly).
  String? _previousBackendBase;

  @override
  void initState() {
    super.initState();
    // If this HomePage targets a specific backend (OTLP journey), activate it
    // for the lifetime of this screen, restoring the previous one on dispose.
    if (widget.backendBase != null) {
      _previousBackendBase = BackendConfig.base;
      BackendConfig.base = widget.backendBase!;
    }
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
  }

  @override
  void dispose() {
    // Restore the previous backend base when leaving an OTLP journey.
    if (widget.backendBase != null && _previousBackendBase != null) {
      BackendConfig.base = _previousBackendBase!;
    }
    super.dispose();
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
      // Two user-initiated feedback paths, side by side, so both approaches can
      // be demoed in one app:
      //   left  — the SDK's built-in SentryFeedbackForm
      //   right — our own modal + marker event (see feedback_modal.dart)
      // Distinct heroTags are required: two FABs in one Scaffold otherwise
      // collide on the default Hero tag and throw at runtime.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 28, right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.small(
              heroTag: 'sentry_sdk_feedback',
              key: const ValueKey('sentry_sdk_feedback'),
              tooltip: 'Sentry SDK feedback form (flushes replay on open)',
              backgroundColor: const Color(0xFFE9DDF7),
              onPressed: () => openSentryFeedbackForm(context,
                  source: 'home_fab_sdk', userFlow: 'checkout'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            FloatingActionButton.small(
              heroTag: 'custom_feedback',
              // Keyed so Sentry's user-interaction span reads
              // `ui.action.click - send_feedback` instead of a synthetic label.
              key: const ValueKey('send_feedback'),
              tooltip: 'Our own modal (marker event flushes replay)',
              onPressed: () => showFeedbackModal(context,
                  source: 'home_fab', userFlow: 'checkout'),
              child: const Icon(Icons.rate_review_outlined),
            ),
          ],
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
  Future<void> Function(SentrySpanV2 span) operation,
) async {
  await Sentry.startSpan(name, (span) async {
    span.setAttribute('sentry.op', SentryAttribute.string('custom'));
    // Example custom performance measurements. `setMeasurement` was a v1
    // transaction-only concept; in the span-streaming API these are recorded
    // as span attributes.
    span.setAttribute('measurement.memoryUsed', SentryAttribute.int(123));
    span.setAttribute('measurement.ui.footerComponent.render', SentryAttribute.double(1.3));
    span.setAttribute('measurement.localStorageRead', SentryAttribute.int(4));
    try {
      await operation(span);
    } catch (exception, stackTrace) {
      span.status = SentrySpanStatusV2.error;
      await Sentry.captureException(exception, stackTrace: stackTrace);
    }
  }, parentSpan: null);
}

// Example usage for widget build instrumentation
class InstrumentedDestinationView extends StatelessWidget {
  final Destination destination;
  const InstrumentedDestinationView({required this.destination, super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: instrumentedOperation('build_${destination.title}', (span) async {
        span.setAttribute('destination_icon', SentryAttribute.string(destination.icon.toString()));
        span.setAttribute('destination_title', SentryAttribute.string(destination.title));
        // Simulate build work
        await Future.delayed(const Duration(milliseconds: 10));
      }),
      builder: (context, snapshot) {
        return DestinationView(destination: destination);
      },
    );
  }
}
